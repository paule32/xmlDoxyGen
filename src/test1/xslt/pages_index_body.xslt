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
  <table class="doxy-table">
    <thead><tr><th>Name</th><th>Beschreibung</th></tr></thead>
    <tbody>
      <xsl:for-each select="/doxygenindex/compound[@kind='page']">
        <xsl:sort select="name"/>
        <xsl:variable name="doc" select="document(concat(@refid,'.xml'), /)/doxygen/compounddef"/>
        <tr>
          <td><a href="{concat('page_', translate(@refid,'/','_'), '.html')}"><xsl:value-of select="($doc/title|name)[1]"/></a></td>
          <td><xsl:value-of select="normalize-space($doc/briefdescription)"/></td>
        </tr>
      </xsl:for-each>
    </tbody>
  </table>
</div>
</xsl:template>
</xsl:stylesheet>
