$ ->
  node_types = [{
    name: 'BareMetal High Performance Compute Node - Spinning Disks Raid 1'
    file: 'bm-hpc-spinning_r1'
    color: '#6B425E'
  },{
    name: 'BareMetal High Performance Compute Node - SSD Raid 0'
    file: 'bm-hpc-ssd_r0'
    color: '#6AAC3F'
  },{
    name: 'BareMetal High Performance Compute Node - 10G'
    file: 'bm-hpc-10g'
    color: '#C94DC4'
  },{
    name: 'Virtual Machine High Performance Compute Node - SSD Raid 0'
    file: 'vm-hpc-ssd_r0'
    color: '#C15434'
  },{
    name: 'Virtual Machine High Performance Compute Node - 10G'
    file: 'vm-hpc-10g'
    color: '#6591B4'
  },{
    name: 'BareMetal Base Compute Node - Spinning Disks Raid 1'
    file: 'bm-bc-spinning_r1'
    color: '#9E7F32'
  },{
    name: 'BareMetal Base Compute Node - SSD Raid 0'
    file: 'bm-bc-ssd_r0'
    color: '#4B8A64'
  },{
    name: 'BareMetal Base Compute Node - 10G'
    file: 'bm-bc-10g'
    color: '#736AC7'
  },{
    name: 'Virtual Machine Base Compute Node - SSD Raid 0'
    file: 'vm-bc-ssd_r0'
    color: '#CA466A'
  },{
    name: 'Virtual Machine Base Compute Node - 10G'
    file: 'vm-bc-10g'
    color: '#C47AAF'
  }]

  processing_types = ['rtstps', 'viirs_sdr']

  options =
    series: []

  $(".chart").highcharts(options)

  updateChart = ->
    xAxis = $("#xAxis option:selected")
    yAxis = $("#yAxis option:selected")
    chartType = $("#chartType option:selected")
    dataType = $("#dataType option:selected")

    opts = $.extend {}, options,
      chart:
        type: $(chartType).val()
      yAxis:
        title: $(yAxis).text()
      xAxis:
        title: $(xAxis).text()
      title:
        text: $(dataType).text()

    $(".chart").highcharts().destroy()
    $(".chart").highcharts(opts)

    $.each node_types, (index, node) =>
      $.getJSON "data/#{node.file}-#{$(dataType).val()}.json", (data) =>
        series =
          name: node.name
          color: node.color
          data: []

        $.each data, (idx, item) =>
          series.data.push
            x: item[$(xAxis).val()]
            y: item[$(yAxis).val()]

        $(".chart").highcharts().addSeries(series)

  $("#chartControl").on 'change', ->
    updateChart()

  updateChart()
