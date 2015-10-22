class Graphene.GaugeGadgetView extends Backbone.View
  className: 'gauge-gadget-view'
  tagName: 'div'
  initialize: ()->
    @title = @options.title
    @type = @options.type

    @parent = @options.parent || '#parent'
    @value_format = @options.value_format || ".3s"
    @null_value = 0

    @from = @options.from || 0
    @to = @options.to || 100

    @observer = @options.observer

    @vis = d3.select(@parent).append("div")
    .attr("class", "ggview")
    .attr("id", @title + "GaugeContainer")

    config =
      size: @options.size || 120
      label: @title
      minorTicks: 5
      min: @from
      max: @to


    config.redZones = []
    config.redZones.push({from: @options.red_from || 0.9 * @to, to: @options.red_to || @to})

    config.yellowZones = []
    config.yellowZones.push({from: @options.yellow_from || 0.75 * @to, to: @options.yellow_to || 0.9 * @to})

    @gauge = new Gauge("#{@title}GaugeContainer", config)
    @gauge.render()

    @model.bind('change', @render)
    console.log("GG view ")


  by_type: (d)=>
    switch @type
      when "min"     then d.ymin
      when "max"     then d.ymax
      when "current" then d.last
      else
        d.points[0][0]

  render: ()=>
    console.log("rendering.")
    data = @model.get('data')
    datum = if data && data.length > 0 then data[0] else {
    ymax: @null_value,
    ymin: @null_value,
    points: [[@null_value, 0]]
    }

    @observer(@by_type(datum)) if @observer

    @gauge.redraw(@by_type(datum), @value_format)
