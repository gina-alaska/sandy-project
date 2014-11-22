(function() {
  $(function() {
    var node_types, options, processing_types, updateChart;
    node_types = [
      {
        name: 'BareMetal High Performance Compute Node - Spinning Disks Raid 1',
        file: 'bm-hpc-spinning_r1'
      }, {
        name: 'BareMetal High Performance Compute Node - SSD Raid 0',
        file: 'bm-hpc-ssd_r0'
      }, {
        name: 'BareMetal Base Compute Node - Spinning Disks Raid 1',
        file: 'bm-bc-spinning_r1'
      }, {
        name: 'BareMetal Base Compute Node - SSD Raid 0',
        file: 'bm-bc-ssd_r0'
      }
    ];
    processing_types = ['rtstps', 'viirs_sdr'];
    options = {
      series: []
    };
    $(".chart").highcharts(options);
    updateChart = function() {
      var chartType, dataType, opts, xAxis, yAxis;
      xAxis = $("#xAxis option:selected");
      yAxis = $("#yAxis option:selected");
      chartType = $("#chartType option:selected");
      dataType = $("#dataType option:selected");
      opts = $.extend({}, options, {
        chart: {
          type: $(chartType).val()
        },
        yAxis: {
          title: $(yAxis).text()
        },
        xAxis: {
          title: $(xAxis).text()
        },
        title: {
          text: $(dataType).text()
        }
      });
      $(".chart").highcharts().destroy();
      $(".chart").highcharts(opts);
      return $.each(node_types, (function(_this) {
        return function(index, node) {
          return $.getJSON("data/" + node.file + "-" + ($(dataType).val()) + ".json", function(data) {
            var series;
            series = {
              name: node.name,
              data: []
            };
            $.each(data, function(idx, item) {
              return series.data.push({
                x: item[$(xAxis).val()],
                y: item[$(yAxis).val()]
              });
            });
            return $(".chart").highcharts().addSeries(series);
          });
        };
      })(this));
    };
    $("#chartControl").on('change', function() {
      return updateChart();
    });
    return updateChart();
  });

}).call(this);
