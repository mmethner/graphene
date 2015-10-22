class Graphene.BarChart extends Graphene.GraphiteModel
  process_data: (js)=>
    console.log 'process data barchart'
    data = _.map js, (dp)->
      min = d3.min(dp.datapoints, (d) -> d[0])
      return null unless min != undefined
      max = d3.max(dp.datapoints, (d) -> d[0])
      return null unless max != undefined

      _.each dp.datapoints, (d) -> d[1] = new Date(d[1] * 1000)
      return {
      points: _.reject(dp.datapoints, (d)-> d[0] == null),
      ymin: min,
      ymax: max,
      label: dp.target
      }
    data = _.reject data, (d)-> d == null
    @set(data: data)
