class Graphene.BarChartView extends Backbone.View
  tagName: 'div'
  initialize: () ->
    @silent = @options.silent || false
    @line_height = @options.line_height || 16
    @animate_ms = @options.animate_ms || 500
    @num_labels = @options.num_labels || 3
    @sort_labels = @options.labels_sort || 'desc'
    @display_verticals = @options.display_verticals || false
    @width = @options.width || 400
    @height = @options.height || 100
    @padding = @options.padding || [@line_height * 2, 32, @line_height * (3 + @num_labels), 32] #trbl
    @title = @options.title
    @label_formatter = @options.label_formatter || (label) -> label
    @firstrun = true
    @parent = @options.parent || '#parent'
    @null_value = 0
    @value_format = @options.value_format || ".3s"
    @value_format = d3.format(@value_format)

    @vis = d3.select(@parent).append("svg")
    .attr("class", "tsview")
    .attr("width", @width + (@padding[1] + @padding[3]))
    .attr("height", @height + (@padding[0] + @padding[2]))
    .append("g")
    .attr("transform", "translate(" + @padding[3] + "," + @padding[0] + ")")
    @model.bind('change', @render)
  render: () =>
    console.log "rendering bar chart." if not @silent

    # Getting data
    data = @model.get('data')

    dmax = _.max data, (d)-> d.ymax
    dmin = _.min data, (d)-> d.ymin
    data = _.sortBy(data, (d)-> 1 * d.ymax)
    points = _.map data, (d)-> d.points

    # Find the minimum and maximum timestamps
    timestamps = _.flatten (_.map points, (series)-> (_.map series, (point)-> point[1]))
    minTimestamp = _.min timestamps
    maxTimestamp = _.max timestamps

    # Find the closest two timestamps (that aren't equal), use that as the difference between timestamps
    orderedTimestamps = _.uniq (_.sortBy timestamps, (ts)-> ts), true, (ts)-> ts.getTime()
    differences = []
    _.each orderedTimestamps, (ts, index, list)->
      if list[index + 1] != undefined
        differences.push list[index + 1] - ts
    timestampDifference = (_.min differences)

    # Create x and y scales
    x = d3.time.scale().domain([minTimestamp, maxTimestamp + timestampDifference]).range([0, @width])
    y = d3.scale.linear().domain([dmin.ymin, dmax.ymax]).range([@height, 0]).nice()

    # The total number of groups of columns
    columnGroups = (maxTimestamp - minTimestamp) / timestampDifference + 1
    # The number of columns per group (the number of targets)
    columnsPerGroup = points.length
    # The total number of columns
    columnsTotal = columnGroups * columnsPerGroup
    # The width of each bar
    barWidth = _.max [@width / columnsTotal - 2, 0.1]

    # Functions used to draw rectangles
    calculateX = (d, outerIndex, innerIndex)->
      x(d[1]) + innerIndex * (barWidth + 2)
    calculateY = (d)->
      y(d[0])

    # Create axes
    xtick_sz = if @display_verticals then -@height else 0
    xAxis = d3.svg.axis().scale(x).ticks(_.min([4, columnGroups])).tickSize(xtick_sz).tickSubdivide(true)
    yAxis = d3.svg.axis().scale(y).ticks(4).tickSize(-@width).orient("left").tickFormat(d3.format("s"))
    vis = @vis

    # We need this value because the bars are drawn starting at the top
    canvas_height = @height

    if @firstrun
      @firstrun = false

      # Draw axes
      vis.append("svg:g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + @height + ")")
      .transition()
      .duration(@animate_ms)
      .call(xAxis)
      vis.append("svg:g").attr("class", "y axis").call(yAxis)

      # Draw title and legend
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

    # update the legend (dynamic legend ordering responds to min/max)
    # first inject datapoints into legend items.
    # note the data mapping is by label name (not index)
    leg_items = @legend.selectAll('g.l').data(_.first(data, @num_labels), (d)-> Math.random())

    # remove legend item.
    leg_items.exit().remove()

    # only per entering item, attach a color box and text.
    litem_enters = leg_items.enter()
    .append('svg:g')
    .attr('transform', (d, i) => "translate(0, #{i * @line_height})")
    .attr('class', 'l')
    litem_enters.append('svg:rect')
    .attr('width', 5)
    .attr('height', 5)
    .attr('class', (d, i) -> 'ts-color ' + "h-col-#{i + 1}")
    litem_enters_text = litem_enters.append('svg:text')
    .attr('dx', 10)
    .attr('dy', 6)
    .attr('class', 'ts-text')
    .text((d) => @label_formatter(d.label))

    # Draw minimum and maximum information
    litem_enters_text.append('svg:tspan')
    .attr('class', 'min-tag')
    .attr('dx', 10)
    .text((d) => @value_format(d.ymin) + "min")
    litem_enters_text.append('svg:tspan')
    .attr('class', 'max-tag')
    .attr('dx', 2)
    .text((d) => @value_format(d.ymax) + "max")

    # Draw new rectangles
    _.each points, (series, i)->
      className = "h-col-" + (i + 1)
      vis.selectAll("rect.area." + className)
      .data(series)
      .enter()
      .append("rect")
      .attr("class", className + " area")
      .attr("x", (d, j)-> calculateX(d, j, i))
      .attr("y", canvas_height)
      .attr("width", barWidth)

    # Update existing rectangles
    _.each points, (series, i)->
      className = "h-col-" + (i + 1)
      vis.selectAll("rect.area." + className)
      .data(series)
      .transition().ease("linear").duration(@animate_ms)
      .attr("x", (d, j)-> calculateX(d, j, i))
      .attr("y", (d, j)-> calculateY(d))
      .attr("width", barWidth)
      .attr("height", (d, j) -> canvas_height - calculateY(d))
      .attr("class", className + " area")

    # Update axes
    vis.transition().ease("linear").duration(@animate_ms).select(".x.axis").call(xAxis)
    vis.select(".y.axis").call(yAxis)

    console.log "done drawing barchart" if not @silent
