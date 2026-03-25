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
  <a href="toc.html">TOC</a>
</div>
  <div class="doxy-grid">
    <div class="doxy-card"><a class="doxy-badge-label" href="dirs.html">Verzeichnisse</a><div class="doxy-kpi"><xsl:value-of select="count(/doxygenindex/compound[@kind='dir'])"/></div></div>
    <div class="doxy-card"><a class="doxy-badge-label" href="files.html">Dateien</a><div class="doxy-kpi"><xsl:value-of select="count(/doxygenindex/compound[@kind='file'])"/></div></div>
    <div class="doxy-card"><a class="doxy-badge-label" href="groups.html">Gruppen</a><div class="doxy-kpi"><xsl:value-of select="count(/doxygenindex/compound[@kind='group'])"/></div></div>
    <div class="doxy-card"><a class="doxy-badge-label" href="pages.html">Seiten</a><div class="doxy-kpi"><xsl:value-of select="count(/doxygenindex/compound[@kind='page'])"/></div></div>
    <div class="doxy-card"><a class="doxy-badge-label" href="classes.html">Klassen</a><div class="doxy-kpi"><xsl:value-of select="count(/doxygenindex/compound[@kind='class'])"/></div></div>
    <div class="doxy-card"><a class="doxy-badge-label" href="namespaces.html">Namespaces</a><div class="doxy-kpi"><xsl:value-of select="count(/doxygenindex/compound[@kind='namespace'])"/></div></div>
    <div class="doxy-card"><a class="doxy-badge-label" href="toc.html">TOC</a><div class="doxy-kpi"><xsl:value-of select="count(/doxygenindex/compound[@kind='group']) + count(/doxygenindex/compound[@kind='page'])"/></div></div>
  </div>
  <div class="doxy-grid doxy-section-gap">
    <div class="doxy-card"><h3>Dateien</h3><p class="doxy-muted">Baumansicht und Tabellenübersicht.</p><p><a href="files.html">Zu den Dateien</a></p></div>
    <div class="doxy-card"><h3>Gruppen und Seiten</h3><p class="doxy-muted">Eigene Übersichtsseiten für Gruppen und Seiten.</p><p><a href="groups.html">Gruppen</a> · <a href="pages.html">Seiten</a></p></div>
    <div class="doxy-card"><h3>Typen</h3><p class="doxy-muted">Klassen- und Namespace-Listen sowie Detailseiten.</p><p><a href="classes.html">Klassen</a> · <a href="namespaces.html">Namespaces</a> · <a href="toc.html">TOC</a></p></div>
  </div>
</div>
</xsl:template>
</xsl:stylesheet>
