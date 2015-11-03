class Graphene.DemoTimeSeries extends Backbone.Model
  defaults:
    range: [0, 1000]
    num_points: 100
    num_new_points: 1
    num_series: 2
    refresh_interval: 3000

  debug: ()->
    console.log("#{@get('refresh_interval')}") if not @get('silent')

  start: ()=>
    console.log("Starting to poll at #{@get('refresh_interval')}") if not @get('silent')
    @data = []
    _.each _.range(@get 'num_series'), (i)=>
      @data.push({
        label: "Series #{i}",
        ymin: 0,
        ymax: 0,
        points: []
      })
    @point_interval = @get('refresh_interval') / @get('num_new_points')

    _.each @data, (d)=>
      @add_points(new Date(), @get('range'), @get('num_points'), @point_interval, d)
    @set(data: @data)

    @t_index = setInterval(@refresh, @get('refresh_interval'))

  stop: ()=>
    clearInterval(@t_index)

  refresh: ()=>
    # clone data - tricks d3/backbone refs
    @data = _.map @data, (d)->
      d = _.clone(d)
      d.points = _.map(d.points, (p)-> [p[0], p[1]])
      d

    last = @data[0].points.pop()
    @data[0].points.push last
    start_date = last[1]

    num_new_points = @get 'num_new_points'
    _.each @data, (d)=>
      @add_points(start_date, @get('range'), num_new_points, @point_interval, d)
    @set(data: @data)


  add_points: (start_date, range, num_new_points, point_interval, d)=>
    _.each _.range(num_new_points), (i)=>
      # lay out i points in time. base time x i*interval
      new_point = [
        range[0] + Math.random() * (range[1] - range[0]),
        new Date(start_date.getTime() + (i + 1) * point_interval)
      ]
      d.points.push(new_point)
      d.points.shift() if d.points.length > @get('num_points')
    d.ymin = d3.min(d.points, (d) -> d[0])
    d.ymax = d3.max(d.points, (d) -> d[0])
