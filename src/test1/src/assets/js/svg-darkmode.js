(function () {
  const darkQuery = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)");

  function isDarkMode() {
    // Built-in Doxygen Darkmode setzt je nach Modus Klassen/Attribute,
    // aber prefers-color-scheme ist der stabilste Trigger.
    return !!(darkQuery && darkQuery.matches);
  }

  function injectSvgStyle(svgDoc) {
    if (!svgDoc) return;
    const svg = svgDoc.documentElement;
    if (!svg || svg.querySelector("style[data-dox-dark]")) return;

    const style = svgDoc.createElementNS("http://www.w3.org/2000/svg", "style");
    style.setAttribute("data-dox-dark", "1");
    style.textContent = `
      /* Nodes: Rechteck/Polygon */
      .node polygon, .node path, .node ellipse {
        stroke: #808080 !important;   /* graue Umrandung */
        fill:   #000080 !important;   /* navy Hintergrund */
      }

      /* Text in Nodes */
      .node text, text {
        fill: #ffd400 !important;     /* gelbe Schrift */
      }

      /* Kanten */
      .edge path, .edge polygon {
        stroke: #808080 !important;
        fill:   #808080 !important;
      }
    `;
    svg.insertBefore(style, svg.firstChild);
  }

  function restyleAll() {
    const objects = document.querySelectorAll('object[type="image/svg+xml"], object[data$=".svg"]');
    objects.forEach(obj => {
      // Bei <object> ist die SVG ein eigenes Document
      const apply = () => injectSvgStyle(obj.contentDocument);
      if (obj.contentDocument) apply();
      obj.addEventListener("load", apply, { once: false });
    });
  }

  function run() {
    if (!isDarkMode()) return;
    restyleAll();
  }

  document.addEventListener("DOMContentLoaded", run);
  if (darkQuery) darkQuery.addEventListener("change", () => location.reload());
})();
