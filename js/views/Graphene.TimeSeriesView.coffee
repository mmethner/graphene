class Graphene.TimeSeriesView extends Backbone.View
  tagName: 'div'

  initialize: ()->
    @name = @options.name || "g-" + parseInt(Math.random() * 1000000)
    @line_height = @options.line_height || 16
    @x_ticks = @options.x_ticks || 4
    @y_ticks = @options.y_ticks || 4
    @animate_ms = @options.animate_ms || 500
    @label_offset = @options.label_offset || 0
    @label_columns = @options.label_columns || 1
    @label_href = @options.label_href || (label) -> '#'
    @label_formatter = @options.label_formatter || (label) -> label
    @num_labels = @options.num_labels || 3
    @sort_labels = @options.labels_sort
    @display_verticals = @options.display_verticals || false
    @width = @options.width || 400
    @height = @options.height || 100
    @padding = @options.padding || [@line_height * 2, 32, @line_height * (3 + (@num_labels / @label_columns)), 32] #trbl
    @title = @options.title
    @firstrun = true
    @parent = @options.parent || '#parent'
    @null_value = 0
    @show_current = @options.show_current || false
    @observer = @options.observer
    @postrender = @options.post_render || postRenderTimeSeriesView

    @vis = d3.select(@parent).append("svg")
    .attr("class", "tsview")
    .attr("width", @width + (@padding[1] + @padding[3]))
    .attr("height", @height + (@padding[0] + @padding[2]))
    .append("g")
    .attr("transform", "translate(" + @padding[3] + "," + @padding[0] + ")")
    # Is this used in the timeseries? -dvdv
    @value_format = @options.value_format || ".3s"
    @value_format = d3.format(@value_format)

    @model.bind('change', @render)
    console.log("TS view: #{@name} #{@width}x#{@height} padding:#{@padding} animate: #{@animate_ms} labels: #{@num_labels}")


  render: ()=>
    console.log("rendering.")
    data = @model.get('data')

    data = if data && data.length > 0 then data else [{
      ymax: @null_value,
      ymin: @null_value,
      points: [[@null_value, 0], [@null_value, 0]]
    }]

    #
    # find overall min/max of sets
    #
    dmax = _.max data, (d)-> d.ymax
    dmax.ymax_graph = @options.ymax || dmax.ymax
    dmin = _.min data, (d)-> d.ymin
    dmin.ymin_graph = @options.ymin ? dmin.ymin

    #
    # build dynamic x & y metrics.
    #
    xpoints = _.flatten (d.points.map((p)-> p[1]) for d in data)
    xmin = _.min xpoints, (x)-> x.valueOf()
    xmax = _.max xpoints, (x)-> x.valueOf()

    x = d3.time.scale().domain([xmin, xmax]).range([0, @width])
    y = d3.scale.linear().domain([dmin.ymin_graph, dmax.ymax_graph]).range([@height, 0]).nice()

    #
    # build axis
    #
    xtick_sz = if @display_verticals then -@height else 0
    xAxis = d3.svg.axis().scale(x).ticks(@x_ticks).tickSize(xtick_sz).tickSubdivide(true)
    yAxis = d3.svg.axis().scale(y).ticks(@y_ticks).tickSize(-@width).orient("left").tickFormat(d3.format("s"))

    vis = @vis

    #
    # build dynamic line & area, note that we're using dynamic x & y.
    #
    line = d3.svg.line().x((d) -> x(d[1])).y((d) -> y(d[0]))
    area = d3.svg.area().x((d) -> x(d[1])).y0(@height - 1).y1((d) -> y(d[0]))

    #
    # get first X labels
    #
    if @sort_labels
      order = if(@sort_labels == 'desc') then -1 else 1
      data = _.sortBy(data, (d)-> order * d.ymax)


    # let observer know about this
    @observer(data) if @observer

    #
    # get raw data points (throw away all of the other blabber
    #
    points = _.map data, (d)-> d.points


    if @firstrun
      @firstrun = false

      #
      # Axis
      #
      vis.append("svg:g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + @height + ")")
      .transition()
      .duration(@animate_ms)
      .call(xAxis)

      vis.append("svg:g").attr("class", "y axis").call(yAxis)

      #
      # Line + Area
      #
      # Note that we can't use idiomatic d3 here - data is one big chunk of data (single property),
      # this is a result of us wanting to use a *single* SVG line element to render the data.
      # so enter() exit() semantics are invalid. We will append here, and later just replace (update).
      # To see an idiomatic d3 handling, take a look at the legend fixture.
      #
      vis.selectAll("path.line").data(points).enter().append('path').attr("d", line).attr('class',
        (d, i) -> 'line ' + "h-col-#{i + 1}")
      vis.selectAll("path.area").data(points).enter().append('path').attr("d", area).attr('class',
        (d, i) -> 'area ' + "h-col-#{i + 1}")

      if (@options.warn && (dmax.ymax_graph > @options.warn))
        warnData = [[[@options.warn, xmin], [@options.warn, xmax]]]
        vis.selectAll("path.line-warn")
        .data(warnData)
        .enter()
        .append('path')
        .attr('d', line)
        .attr('stroke-dasharray', '10,10')
        .attr('class', 'line-warn')

      if (@options.error && (dmax.ymax_graph > @options.error))
        errorData = [[[@options.error, xmin], [@options.error, xmax]]]
        vis.selectAll("path.line-error")
        .data(errorData)
        .enter()
        .append('path')
        .attr('d', line)
        .attr('stroke-dasharray', '10,10')
        .attr('class', 'line-error')

      #
      # Title + Legend
      #
      if @title
        title = vis.append('svg:text')
        .attr('class', 'title')
        .attr('transform', "translate(0, -#{@line_height})")
        .text(@title)

      @legend = vis.append('svg:g')
      .attr('transform', "translate(0, #{@height + @line_height * 2})")
      .attr('class', 'legend')

    #---------------------------------------------------------------------------------------#
    # Update Graph
    #---------------------------------------------------------------------------------------#


    #
    # update the legend (dynamic legend ordering responds to min/max)
    #

    # first inject datapoints into legend items.
    # note the data mapping is by label name (not index)
    leg_items = @legend.selectAll('g.l').data(_.first(data, @num_labels), (d)-> Math.random())

    # remove legend item.
    leg_items.exit().remove()

    # only per entering item, attach a color box and text.
    litem_enters = leg_items.enter()
    .append('svg:g')
    .attr('transform',
      (d, i) => "translate(#{(i % @label_columns) * @label_offset}, #{parseInt(i / @label_columns) * @line_height})")
    .attr('class', 'l')
    litem_enters.append('svg:rect')
    .attr('width', 5)
    .attr('height', 5)
    .attr('class', (d, i) -> 'ts-color ' + "h-col-#{i + 1}")

    litem_enters_a = litem_enters.append('svg:a')
    .attr('xlink:href', (d) => @label_href(d.label))
    .attr('class', 'l')
    .attr('id', (d, i) => @name + "-" + i)

    litem_enters_text = litem_enters_a.append('svg:text')
    .attr('dx', 10)
    .attr('dy', 6)
    .attr('class', 'ts-text')
    .text((d) => @label_formatter(d.label))

    litem_enters_text.append('svg:tspan')
    .attr('class', 'min-tag')
    .attr('dx', 10)
    .text((d) => @value_format(d.ymin) + "min")

    litem_enters_text.append('svg:tspan')
    .attr('class', 'max-tag')
    .attr('dx', 2)
    .text((d) => @value_format(d.ymax) + "max")

    if @show_current is true
      litem_enters_text.append('svg:tspan')
      .attr('class', 'last-tag')
      .attr('dx', 2)
      .text((d) => @value_format(d.last) + "last")

    #
    # update the graph
    #
    vis.transition().ease("linear").duration(@animate_ms).select(".x.axis").call(xAxis)
    vis.select(".y.axis").call(yAxis)

    vis.selectAll("path.area")
    .data(points)
    .attr("d", area)
    .attr("id", (d, i) => "a-" + @name + "-" + i)
    .transition()
    .ease("linear")
    .duration(@animate_ms)

    vis.selectAll("path.line")
    .data(points)
    .attr("d", line)
    .attr("id", (d, i) => "l-" + @name + "-" + i)
    .transition()
    .ease("linear")
    .duration(@animate_ms)

    @postrender(@vis)

