(function() {
  $(function() {
    var node_types, options, processing_types;
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
      chart: {
        type: 'scatter'
      },
      xAxis: {
        title: {
          text: 'File Size (MB)',
          enabled: true
        }
      },
      yAxis: {
        title: {
          text: 'Duration (sec)'
        },
        min: 0
      },
      plotOptions: {
        scatter: {
          marker: {
            radius: 5,
            hover: {
              enabled: false
            }
          }
        }
      },
      series: []
    };
    return $.each(processing_types, function(index, ptype) {
      var chart;
      $.extend(options, {
        title: {
          text: ptype
        }
      });
      chart = $("#" + ptype + "-comparison-chart").highcharts(options);
      return $.each(node_types, function(index, type) {
        return $.getJSON("data/" + type.file + "-" + ptype + ".json", function(data) {
          var series;
          series = {
            name: type.name,
            data: []
          };
          $.each(data, function(name, item) {
            var point;
            point = {
              x: parseInt(item.file_size),
              y: parseFloat(item.duration)
            };
            return series.data.push(point);
          });
          return $(chart).highcharts().addSeries(series);
        });
      });
    });
  });

}).call(this);
