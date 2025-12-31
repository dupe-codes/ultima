/**
 * Chart rendering library for Ultima
 * Renders Chart.js charts based on JSON data with metadata
 *
 * JSON format:
 * {
 *   "title": "Chart Title",
 *   "chart": "bar|line|scatter|pie|doughnut",
 *   "xKey": "dataFieldName",
 *   "xLabel": "X Axis Label",
 *   "yLabel": "Y Axis Label",
 *   "subtitle": "Optional subtitle",
 *   "valueKey": "nestedValueField",  // for nested objects
 *   "groupKey": "fieldToGroupBy",    // for scatter plots
 *   ...data
 * }
 *
 * Usage in markdown:
 *   <div class="chart" data-src="/static/data/file.json"></div>
 */

const ChartRenderer = {
  colors: [
    'rgba(142, 124, 195, 0.8)',
    'rgba(52, 152, 219, 0.8)',
    'rgba(46, 204, 113, 0.8)',
    'rgba(241, 196, 15, 0.8)',
    'rgba(231, 76, 60, 0.8)',
    'rgba(155, 89, 182, 0.8)',
    'rgba(26, 188, 156, 0.8)',
    'rgba(230, 126, 34, 0.8)',
  ],

  init() {
    document.querySelectorAll('.chart[data-src]').forEach(el => this.render(el));
  },

  async render(container) {
    const src = container.dataset.src;

    try {
      const res = await fetch(src);
      const data = await res.json();

      const canvas = document.createElement('canvas');
      container.appendChild(canvas);

      this.renderChart(canvas, data);
    } catch (err) {
      container.innerHTML = `<p class="chart-error">Failed to load chart: ${err.message}</p>`;
    }
  },

  renderChart(canvas, data) {
    const type = data.chart || 'bar';
    const chartData = data[data.xKey];

    // Build title array
    const titleText = data.subtitle ? [data.title, data.subtitle] : data.title;

    // Handle different chart types
    if (type === 'scatter' && data.dataPoints) {
      this.renderScatter(canvas, data, titleText);
      return;
    }

    // Extract labels and values
    let labels, values;

    if (typeof Object.values(chartData)[0] === 'object') {
      // Nested objects (e.g., { "5": { avgDrawingHours: 1.5, sampleSize: 10 } })
      labels = Object.keys(chartData).sort((a, b) => parseFloat(a) - parseFloat(b));
      values = labels.map(k => chartData[k][data.valueKey]);
    } else {
      // Simple key-value pairs
      labels = Object.keys(chartData);
      values = labels.map(k => chartData[k]);
    }

    // Clean up month labels (remove year prefix)
    const cleanLabels = labels.map(l => l.replace(/^\d{4}-/, ''));

    // orientation: "vertical" (default) or "horizontal"
    const isHorizontal = type === 'bar' && data.orientation === 'horizontal';

    new Chart(canvas, {
      type: type,
      data: {
        labels: cleanLabels,
        datasets: [{
          label: data.yLabel || 'Value',
          data: values,
          backgroundColor: type === 'line'
            ? 'rgba(142, 124, 195, 0.3)'
            : this.colors.slice(0, labels.length),
          borderColor: 'rgba(142, 124, 195, 1)',
          borderWidth: type === 'line' ? 2 : 1,
          fill: type === 'line',
          tension: type === 'line' ? 0.3 : 0
        }]
      },
      options: {
        responsive: true,
        indexAxis: isHorizontal ? 'y' : 'x',
        plugins: {
          title: { display: true, text: titleText }
        },
        scales: type !== 'pie' && type !== 'doughnut' ? {
          x: {
            title: { display: !!data.xLabel, text: data.xLabel },
            beginAtZero: true
          },
          y: {
            title: { display: !!data.yLabel, text: data.yLabel },
            beginAtZero: true
          }
        } : undefined
      }
    });
  },

  renderScatter(canvas, data, titleText) {
    const points = data.dataPoints;
    const groupKey = data.groupKey;

    // Group by category if groupKey is provided
    const groups = {};
    points.forEach(p => {
      const group = p[groupKey] || 'default';
      if (!groups[group]) groups[group] = [];
      groups[group].push({ x: p[data.xKey], y: p[data.yKey] });
    });

    const datasets = Object.keys(groups).map((group, i) => ({
      label: group,
      data: groups[group],
      backgroundColor: this.colors[i % this.colors.length],
      pointRadius: 6
    }));

    new Chart(canvas, {
      type: 'scatter',
      data: { datasets },
      options: {
        responsive: true,
        plugins: {
          title: { display: true, text: titleText }
        },
        scales: {
          x: {
            title: { display: true, text: data.xLabel },
            beginAtZero: true
          },
          y: {
            title: { display: true, text: data.yLabel },
            min: 0,
            max: 6,
            ticks: {
              callback: v => ['', 'F', 'D', 'C', 'B', 'A'][v] || ''
            }
          }
        }
      }
    });
  }
};

document.addEventListener('DOMContentLoaded', () => ChartRenderer.init());
