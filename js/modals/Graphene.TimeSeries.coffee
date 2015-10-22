class Graphene.TimeSeries extends Graphene.GraphiteModel
  process_data: (js) =>
    data = _.map js, (dp)->
      min = d3.min(dp.datapoints, (d) -> d[0])
      return null unless min != undefined
      max = d3.max(dp.datapoints, (d) -> d[0])
      return null unless max != undefined
      last = _.last(dp.datapoints)[0] ? 0
      return null unless last != undefined
      _.each dp.datapoints, (d) -> d[1] = new Date(d[1] * 1000)
      return {
      points: _.reject(dp.datapoints, (d)-> d[0] == null),
      ymin: min,
      ymax: max,
      last: last,
      label: dp.target
      }
    data = _.reject data, (d)-> d == null
    @set(data: data)
