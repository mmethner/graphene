class Graphene.ProgressBarGadgetView extends Backbone.View
  className: 'progressbar-gadget-view'
  tagName: 'div'
  initialize: ()->
    @unit   = @options.unit
    @title  = @options.title
    @type   = @options.type
    @parent = @options.parent || '#parent'
    @value_format  = @options.value_format || ".3s"
    @value_format = d3.format(@value_format)
    @null_value = 0
    @observer = @options.observer
    @to = @options.to || 1
    @multiplier   = 100/@to

    @vis = d3.select(@parent).append("div")
    .attr("class", "pbview")
    @area = @vis.append("div")
    .attr("class", "progress").append("div")
    .attr("class", "bar")
    .attr("style", "width: 50%")
    if @title
      @area.append("div")
      .attr("class", "label")
      .text(@title)

    @model.bind('change', @render)
    console.log("PB view ")


  by_type:(d)=>
    switch @type
      when "min"     then d.ymin
      when "max"     then d.ymax
      when "current" then d.last
      else d.points[0][0] * @multiplier

  render: ()=>
    data = @model.get('data')
    console.log data
    datum = if data && data.length > 0 then data[0] else { ymax: @null_value, ymin: @null_value, points: [[@null_value, 0]] }

    # let observer know about this
    @observer(@by_type(datum)) if @observer

    area = @area
    metric_items = area.selectAll('div.metric')
    .data([datum], (d)=> @by_type(d))

    metric_items.exit().remove()

    metric = metric_items.enter()
    .insert('div', ":first-child")
    .attr('class',"metric#{if @type then ' '+@type else ''}")

    @area.attr("style", "width: "+@by_type(datum)+"%")

    metric.text(@title)
    metric.append('span')
    .attr('class', 'value')
    .text((d)=>" "+@value_format(@by_type(d)))
    if @unit
      metric.append('span')
      .attr('class', 'unit')
      .text(@unit)

