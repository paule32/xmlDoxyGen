<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
<xsl:strip-space elements="*"/>


<xsl:template match="para|briefdescription|detaileddescription|sect1|sect2|sect3|itemizedlist|orderedlist|listitem|simplesect">
  <xsl:apply-templates/>
  <xsl:if test="self::para or self::listitem or self::sect1 or self::sect2 or self::sect3"><xsl:text>&#10;</xsl:text></xsl:if>
</xsl:template>
<xsl:template match="title">
  <xsl:value-of select="."/><xsl:text>&#10;</xsl:text>
</xsl:template>
<xsl:template match="ref|computeroutput|bold|emphasis|sp|linebreak|mdash|ndash|lsquo|rsquo|ldquo|rdquo|nonbreakablespace|umlaut|Uumlaut|auml|ouml|uuml|Auml|Ouml|Uuml|szlig|fouml|uumlaut">
  <xsl:value-of select="."/>
</xsl:template>
<xsl:template match="text()">
  <xsl:value-of select="."/>
</xsl:template>

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
    <h2><xsl:value-of select="compounddef/compoundname"/></h2>
  </div>
  <div class="doxy-card doxy-section-gap">
    <pre class="doxy-pre"><xsl:apply-templates select="compounddef/detaileddescription|compounddef/briefdescription"/></pre>
  </div>
</div>
</xsl:template>
</xsl:stylesheet>
