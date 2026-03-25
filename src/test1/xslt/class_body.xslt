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

<xsl:template name="last-scope-part">
  <xsl:param name="text"/>
  <xsl:choose>
    <xsl:when test="contains($text, '::')">
      <xsl:call-template name="last-scope-part">
        <xsl:with-param name="text" select="substring-after($text, '::')"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="file-language">
  <xsl:param name="file"/>
  <xsl:variable name="f" select="translate($file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
  <xsl:choose>
    <xsl:when test="substring($f, string-length($f) - 2) = '.py' or substring($f, string-length($f) - 3) = '.pyw'">Python</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.pas' or substring($f, string-length($f) - 2) = '.pp' or substring($f, string-length($f) - 1) = '.p'">Pascal</xsl:when>
    <xsl:otherwise>C++</xsl:otherwise>
  </xsl:choose>
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

  <xsl:variable name="class-name" select="string(compounddef/compoundname)"/>
  <xsl:variable name="simple-class-name">
    <xsl:call-template name="last-scope-part">
      <xsl:with-param name="text" select="$class-name"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="lang">
    <xsl:call-template name="file-language">
      <xsl:with-param name="file" select="compounddef/location/@file"/>
    </xsl:call-template>
  </xsl:variable>

  <div class="doxy-card">
    <h2><xsl:text>Klasse:&#160;&#160;</xsl:text><xsl:value-of select="$simple-class-name"/></h2>
  </div>

  <div class="doxy-card doxy-section-gap">
    <pre class="doxy-pre"><xsl:apply-templates select="compounddef/detaileddescription|compounddef/briefdescription"/></pre>
  </div>

  <xsl:if test="compounddef/sectiondef/memberdef[@kind='function' and (name = '__init__' or name = $simple-class-name or contains(definition, concat('::', $simple-class-name)) or contains(argsstring, concat($simple-class-name, '(')))]">
    <div class="doxy-card doxy-section-gap">
      <h3 id="constructors">Konstruktoren</h3>
      <ul class="doxy-link-list">
        <xsl:for-each select="compounddef/sectiondef/memberdef[@kind='function' and (name = '__init__' or name = $simple-class-name or contains(definition, concat('::', $simple-class-name)) or contains(argsstring, concat($simple-class-name, '(')))]">
          <li>
            <code>
              <xsl:choose>
                <xsl:when test="normalize-space($lang) = 'Python'">__init__</xsl:when>
                <xsl:when test="name = '__init__' or contains(definition, '__init__')">__init__</xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$simple-class-name"/>
                  <xsl:text> :: </xsl:text>
                  <xsl:value-of select="name"/>
                </xsl:otherwise>
              </xsl:choose>
            </code>
            <xsl:if test="normalize-space(briefdescription) != ''">
              <div class="doxy-member-desc">
                <xsl:value-of select="normalize-space(briefdescription)"/>
              </div>
            </xsl:if>
          </li>
        </xsl:for-each>
      </ul>
    </div>
  </xsl:if>
</div>
</xsl:template>
</xsl:stylesheet>
