$ ->
  node_types = [{
    name: 'BareMetal High Performance Compute Node - Spinning Disks Raid 1'
    file: 'bm-hpc-spinning_r1'
  },{
    name: 'BareMetal High Performance Compute Node - SSD Raid 0'
    file: 'bm-hpc-ssd_r0'
  },{
    name: 'BareMetal Base Compute Node - Spinning Disks Raid 1'
    file: 'bm-bc-spinning_r1'
  },{
    name: 'BareMetal Base Compute Node - SSD Raid 0'
    file: 'bm-bc-ssd_r0'
  }]

  processing_types = ['rtstps', 'viirs_sdr']

  options =
    chart:
      type: 'scatter'
    xAxis:
      title:
        text: 'File Size (MB)'
        enabled: true
    yAxis:
      title:
        text: 'Duration (sec)'
    plotOptions:
      scatter:
        marker:
          radius: 5
          hover:
            enabled: false
    series: []

  $.each processing_types, (index, ptype) ->
    chart = $("##{ptype}-comparison-chart").highcharts(options)
    $.each node_types, (index,type) ->
      $.getJSON "data/#{type.file}-#{ptype}.json", (data) ->
        series =
          name: type.name
          data: []

        $.each data, (name, item) ->
          point =
            x: parseInt(item.file_size)
            y: parseFloat(item.duration)

          series.data.push(point)

        $(chart).highcharts().addSeries(series)
