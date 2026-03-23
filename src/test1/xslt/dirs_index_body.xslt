<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
<xsl:strip-space elements="*"/>

<xsl:template match="/">
<div class="doxy-docs">
  <div class="doxy-nav">
    <a href="index.html">Start</a>
    <a href="files.html">Dateien</a>
    <a href="dirs.html">Verzeichnisse</a>
    <a href="groups.html">Gruppen</a>
    <a href="pages.html">Seiten</a>
    <a href="classes.html">Klassen</a>
    <a href="namespaces.html">Namespaces</a>
  </div>

  <div class="doxy-card">
    <h2>Verzeichnisstruktur</h2>
    <div id="doxy-dir-tree"></div>
    <ul id="doxy-dir-flat-source" style="display:none;">
      <xsl:for-each select="/doxygenindex/compound[@kind='dir']">
        <xsl:sort select="name"/>
        <xsl:variable name="doc" select="document(concat(@refid,'.xml'), /)/doxygen/compounddef"/>
        <li>
          <xsl:attribute name="data-path"><xsl:value-of select="name"/></xsl:attribute>
          <xsl:attribute name="data-link"><xsl:value-of select="concat('dir_', translate(@refid,'/','_'), '.html')"/></xsl:attribute>
          <xsl:attribute name="data-dirs"><xsl:value-of select="count($doc/innerdir)"/></xsl:attribute>
          <xsl:attribute name="data-files"><xsl:value-of select="count($doc/innerfile)"/></xsl:attribute>
        </li>
      </xsl:for-each>
    </ul>
  </div>

  <script><![CDATA[
  (function () {
    var source = document.getElementById('doxy-dir-flat-source');
    var target = document.getElementById('doxy-dir-tree');
    if (!source || !target) return;

    function createNode(name, path) {
      return { name: name, path: path, link: '', dirs: 0, files: 0, children: {} };
    }

    var root = createNode('', '');
    Array.prototype.forEach.call(source.querySelectorAll('li[data-path]'), function (item) {
      var path = item.getAttribute('data-path') || '';
      if (!path) return;
      var parts = path.split('/').filter(Boolean);
      var current = root;
      var currentPath = '';
      parts.forEach(function (part) {
        currentPath = currentPath ? currentPath + '/' + part : part;
        if (!current.children[part]) {
          current.children[part] = createNode(part, currentPath);
        }
        current = current.children[part];
      });
      current.link = item.getAttribute('data-link') || '#';
      current.dirs = item.getAttribute('data-dirs') || '0';
      current.files = item.getAttribute('data-files') || '0';
    });

    function sortedChildren(node) {
      return Object.keys(node.children).sort(function (a, b) {
        return a.localeCompare(b, undefined, { sensitivity: 'base' });
      }).map(function (key) { return node.children[key]; });
    }

    function renderChildren(parentNode) {
      var children = sortedChildren(parentNode);
      if (!children.length) return null;
      var ul = document.createElement('ul');
      ul.className = 'doxy-tree-view';

      children.forEach(function (node) {
        var li = document.createElement('li');
        li.className = 'doxy-tree-row';
        var kids = sortedChildren(node);

        if (kids.length) {
          var details = document.createElement('details');
          if (node.path.split('/').length <= 1) details.open = true;
          var summary = document.createElement('summary');
          var label = document.createElement('span');
          label.className = 'doxy-tree-label';
          label.innerHTML = '<span class="doxy-tree-caret"></span><span class="folder-icon"></span>';

          var link = document.createElement('a');
          link.href = node.link || '#';
          link.textContent = node.name;
          label.appendChild(link);

          var meta = document.createElement('span');
          meta.className = 'doxy-tree-meta';
          meta.textContent = 'Unterverzeichnisse: ' + node.dirs + ' · Dateien: ' + node.files;
          label.appendChild(meta);
          summary.appendChild(label);
          details.appendChild(summary);
          var childTree = renderChildren(node);
          if (childTree) details.appendChild(childTree);
          li.appendChild(details);
        } else {
          var row = document.createElement('span');
          row.className = 'doxy-tree-label';
          row.innerHTML = '<span class="doxy-tree-caret"></span><span class="folder-icon"></span>';
          var linkLeaf = document.createElement('a');
          linkLeaf.href = node.link || '#';
          linkLeaf.textContent = node.name;
          row.appendChild(linkLeaf);
          var metaLeaf = document.createElement('span');
          metaLeaf.className = 'doxy-tree-meta';
          metaLeaf.textContent = 'Unterverzeichnisse: ' + node.dirs + ' · Dateien: ' + node.files;
          row.appendChild(metaLeaf);
          li.appendChild(row);
        }
        ul.appendChild(li);
      });

      return ul;
    }

    var tree = renderChildren(root);
    if (tree) {
      target.appendChild(tree);
    } else {
      target.innerHTML = '<div class="doxy-tree-empty">Keine Verzeichnisse gefunden.</div>';
    }
  })();
  ]]></script>
</div>
</xsl:template>
</xsl:stylesheet>
