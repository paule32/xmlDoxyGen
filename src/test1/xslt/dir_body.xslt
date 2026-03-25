<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
<xsl:strip-space elements="*"/>

<xsl:template match="/doxygen">
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
  <div class="doxy-card">
    <h2><xsl:text>Verzeichnis:&#160;&#160;</xsl:text><xsl:value-of select="compounddef/compoundname"/></h2>
    <div class="doxy-muted"><xsl:value-of select="compounddef/location/@file"/></div>
  </div>
  <div class="doxy-card doxy-section-gap">
    <h3>Inhalt</h3>
    <div class="doxy-tree-view">
      <details open="open">
        <summary class="doxy-tree-row">
          <span class="doxy-tree-label">
            <span class="doxy-tree-caret"></span>
            <span class="folder-icon"></span>
            <strong><xsl:text>Verzeichnis:&#160;&#160;</xsl:text><xsl:value-of select="compounddef/compoundname"/></strong>
          </span>
        </summary>
        <ul class="doxy-tree-list">
          <xsl:choose>
            <xsl:when test="compounddef/innerdir or compounddef/innerfile">
              <xsl:for-each select="compounddef/innerdir">
                <li class="folder"><a href="{concat('dir_', translate(@refid,'/','_'), '.html')}"><xsl:value-of select="."/></a></li>
              </xsl:for-each>
              <xsl:for-each select="compounddef/innerfile">
                <li class="file"><a href="{concat('file_', translate(@refid,'/','_'), '.html')}"><xsl:value-of select="."/></a></li>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <li class="doxy-muted">Keine Einträge</li>
            </xsl:otherwise>
          </xsl:choose>
        </ul>
      </details>
    </div>
  </div>
</div>
</xsl:template>
</xsl:stylesheet>
