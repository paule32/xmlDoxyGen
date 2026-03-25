<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="codeline highlight"/>

<xsl:template match="sp"><xsl:text> </xsl:text></xsl:template>
<xsl:template match="linebreak"><xsl:text>&#10;</xsl:text></xsl:template>
<xsl:template match="highlight"><xsl:apply-templates/></xsl:template>
<xsl:template match="ref"><xsl:apply-templates/></xsl:template>
<xsl:template match="text()"><xsl:value-of select="."/></xsl:template>
<xsl:template match="codeline"><xsl:apply-templates/><xsl:text>&#10;</xsl:text></xsl:template>

<xsl:template name="basename">
  <xsl:param name="path"/>
  <xsl:choose>
    <xsl:when test="contains($path, '/')">
      <xsl:call-template name="basename">
        <xsl:with-param name="path" select="substring-after($path, '/')"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="contains($path, '\')">
      <xsl:call-template name="basename">
        <xsl:with-param name="path" select="substring-after($path, '\')"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$path"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="file-language">
  <xsl:param name="file"/>
  <xsl:variable name="f" select="translate($file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
  <xsl:choose>
    <xsl:when test="substring($f, string-length($f) - 2) = '.py'
                 or substring($f, string-length($f) - 3) = '.pyw'">Python</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.pas'
                 or substring($f, string-length($f) - 2) = '.pp'
                 or substring($f, string-length($f) - 1) = '.p'">Pascal</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 1) = '.c'
                 or substring($f, string-length($f) - 1) = '.h'
                 or substring($f, string-length($f) - 2) = '.hh'
                 or substring($f, string-length($f) - 3) = '.hpp'
                 or substring($f, string-length($f) - 3) = '.h++'
                 or substring($f, string-length($f) - 2) = '.cc'
                 or substring($f, string-length($f) - 3) = '.cpp'
                 or substring($f, string-length($f) - 3) = '.cxx'
                 or substring($f, string-length($f) - 3) = '.c++'">C++</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 2) = '.js'">JavaScript</xsl:when>
    <xsl:otherwise>C++</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="file-letter">
  <xsl:param name="file"/>
  <xsl:variable name="base">
    <xsl:call-template name="basename">
      <xsl:with-param name="path" select="$file"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:value-of select="translate(substring(normalize-space($base), 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
</xsl:template>

<xsl:template name="ace-mode-from-file">
  <xsl:param name="file"/>
  <xsl:variable name="f" select="translate($file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
  <xsl:choose>
    <xsl:when test="substring($f, string-length($f) - 2) = '.py'
                 or substring($f, string-length($f) - 3) = '.pyw'">python</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.pas'
                 or substring($f, string-length($f) - 2) = '.pp'
                 or substring($f, string-length($f) - 1) = '.p'">pascal</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 1) = '.h'
                 or substring($f, string-length($f) - 3) = '.hpp'
                 or substring($f, string-length($f) - 2) = '.hh'
                 or substring($f, string-length($f) - 3) = '.cpp'
                 or substring($f, string-length($f) - 1) = '.c'
                 or substring($f, string-length($f) - 2) = '.cc'
                 or substring($f, string-length($f) - 3) = '.cxx'">c_cpp</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.qml'
                 or substring($f, string-length($f) - 3) = '.js'">javascript</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.xml'">xml</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.htm'
                 or substring($f, string-length($f) - 4) = '.html'">html</xsl:when>
    <xsl:otherwise>text</xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="target-file-from-refid">
  <xsl:param name="refid"/>
  <xsl:variable name="slug" select="translate($refid, '/', '_')"/>
  <xsl:choose>
    <xsl:when test="starts-with($refid, 'class') or starts-with($refid, 'struct') or starts-with($refid, 'union')">
      <xsl:value-of select="concat('class_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="starts-with($refid, 'namespace')">
      <xsl:value-of select="concat('namespace_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="starts-with($refid, 'group')">
      <xsl:value-of select="concat('group_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="starts-with($refid, 'dir')">
      <xsl:value-of select="concat('dir_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="starts-with($refid, 'file')">
      <xsl:value-of select="concat('file_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="starts-with($refid, 'page')">
      <xsl:value-of select="concat('page_', $slug, '.html')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat($slug, '.html')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="find-page-href-by-label">
  <xsl:param name="label"/>
  <xsl:variable name="idx" select="document('../out/dark/de/xml/index.xml')/doxygenindex"/>
  <xsl:variable name="compound" select="$idx/compound[@kind='page'][name=$label][1]"/>
  <xsl:choose>
    <xsl:when test="$compound">
      <xsl:call-template name="target-file-from-refid">
        <xsl:with-param name="refid" select="$compound/@refid"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise/>
  </xsl:choose>
</xsl:template>

<xsl:template name="emit-keyword-link">
  <xsl:param name="token"/>
  <xsl:param name="label"/>
  <xsl:text>      '</xsl:text><xsl:value-of select="$token"/><xsl:text>': '</xsl:text>
  <xsl:call-template name="find-page-href-by-label">
    <xsl:with-param name="label" select="$label"/>
  </xsl:call-template>
  <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template name="alphabet-links">
  <xsl:param name="lang"/>
  <xsl:param name="letters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <xsl:if test="string-length($letters) &gt; 0">
    <xsl:variable name="letter" select="substring($letters, 1, 1)"/>
    <xsl:variable name="matchingCount" select="count(/doxygenindex/compound[@kind='file' and not(contains(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '.dox'))][
      (( $lang = 'Python' and (
               substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.py'
            or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pyw'))
            or
       ( $lang = 'Pascal' and (
               substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pas'
            or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.pp'
            or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 1) = '.p'))
            or
       ( $lang = 'JavaScript' and (
               substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.js'))
            or
       ( $lang = 'C++' and not(
               substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.py'
            or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pyw'
            or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pas'
            or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.js'
            or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.pp'
            or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 1) = '.p')))
      and translate(substring(name, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') = $letter
    ])"/>
    <xsl:choose>
      <xsl:when test="$matchingCount &gt; 0">
        <a href="{concat('#files-', translate($lang, '+', ''), '-', $letter)}"><xsl:value-of select="$letter"/></a>
      </xsl:when>
      <xsl:otherwise>
        <span class="doxy-alpha-disabled"><xsl:value-of select="$letter"/></span>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text> </xsl:text>
    <xsl:call-template name="alphabet-links">
      <xsl:with-param  name="lang" select="$lang"/>
      <xsl:with-param  name="letters" select="substring($letters, 2)"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="render-file-language">
  <xsl:param name="lang"/>
  <xsl:variable name="rows" select="/doxygenindex/compound[@kind='file' and not(contains(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '.dox'))]"/>
  <xsl:variable name="langCount" select="count($rows[
      ($lang = 'Python' and (substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.py' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pyw')) or
      ($lang = 'Pascal' and (substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pas' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.pp' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 1) = '.p')) or
      ($lang = 'C++' and not(substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.py' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pyw' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pas' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.pp' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 1) = '.p'))
    ])"/>
  <xsl:if test="$langCount &gt; 0">
    <div class="doxy-card doxy-section-gap">
      <h3><xsl:value-of select="$lang"/></h3>
      <div class="doxy-alpha-nav">
        <xsl:call-template name="alphabet-links">
          <xsl:with-param name="lang" select="$lang"/>
        </xsl:call-template>
      </div>
      <xsl:call-template name="render-file-letters">
        <xsl:with-param name="lang" select="$lang"/>
        <xsl:with-param name="letters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
      </xsl:call-template>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template name="render-file-letters">
  <xsl:param name="lang"/>
  <xsl:param name="letters"/>
  <xsl:if test="string-length($letters) &gt; 0">
    <xsl:variable name="letter" select="substring($letters, 1, 1)"/>
    <xsl:variable name="items" select="/doxygenindex/compound[@kind='file' and not(contains(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '.dox'))][
      (( $lang = 'Python' and (substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.py'
                           or  substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pyw')
       ) or
       ( $lang = 'Pascal' and (substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pas'
                           or  substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.pp'
                           or  substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 1) = '.p')
       ) or
       ( $lang = 'C++' and not(substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.py'
                           or substring(translate(document(concat(@refid, '.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pyw'
                           or substring(translate(document(concat(@refid, '.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pas'
                           or substring(translate(document(concat(@refid, '.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.pp'
                           or substring(translate(document(concat(@refid, '.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 1) = '.p')))
      and translate(substring(name, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') = $letter
    ]"/>
    <xsl:if test="count($items) &gt; 0">
      <div class="doxy-file-letter-group">
        <h4 id="{concat('files-', translate($lang, '+', ''), '-', $letter)}"><xsl:value-of select="$letter"/></h4>
        <table class="doxy-table">
          <thead><tr><th>Datei</th><th>Pfad</th></tr></thead>
          <tbody>
            <xsl:for-each select="$items">
              <xsl:sort select="document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file"/>
              <xsl:variable name="doc" select="document(concat(@refid,'.xml'), /)/doxygen/compounddef"/>
              <tr>
                <td>
                  <a href="{concat('file_', translate(@refid,'/','_'), '.html')}">
                    <xsl:call-template name="basename">
                      <xsl:with-param name="path" select="$doc/location/@file"/>
                    </xsl:call-template>
                  </a>
                </td>
                <td><xsl:value-of select="$doc/location/@file"/></td>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
      </div>
    </xsl:if>
    <xsl:call-template name="render-file-letters">
      <xsl:with-param name="lang" select="$lang"/>
      <xsl:with-param name="letters" select="substring($letters, 2)"/>
    </xsl:call-template>
  </xsl:if>
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
    <h2>Datei-Ansicht</h2>
    <table class="doxy-file-meta" style="width:100%; border-collapse:collapse;">
      <thead>
        <tr>
          <th style="text-align:left; padding:6px 8px; border-bottom:1px solid #ccc;">Dateiname</th>
          <th style="text-align:left; padding:6px 8px; border-bottom:1px solid #ccc;">Pfad</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td style="padding:8px; vertical-align:top;">
            <strong>
              <xsl:call-template name="basename">
                <xsl:with-param name="path" select="compounddef/location/@file"/>
              </xsl:call-template>
            </strong>
          </td>
          <td style="padding:8px; vertical-align:top;" class="doxy-muted">
            <xsl:value-of select="compounddef/location/@file"/>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
  <div class="doxy-card doxy-section-gap">
    <h3>Programmlisting</h3>
    <xsl:variable name="ace-mode">
      <xsl:call-template name="ace-mode-from-file">
        <xsl:with-param name="file" select="compounddef/location/@file"/>
      </xsl:call-template>
    </xsl:variable>
    <div class="doxy-ace-host">
      <div class="doxy-code-toolbar">
        <span class="doxy-code-lang">Syntaxmodus: <xsl:value-of select="$ace-mode"/></span>
        <span class="doxy-code-note">ACE Editor Ansicht mit Fallback auf Preformatted Text</span>
      </div>
      <div id="doxy-ace-editor" class="doxy-ace-editor">
        <xsl:attribute name="data-mode"><xsl:value-of select="$ace-mode"/></xsl:attribute>
        <pre class="doxy-source"><xsl:apply-templates select="compounddef/programlisting/codeline"/></pre>
      </div>
      <noscript>
        <pre class="doxy-pre"><xsl:apply-templates select="compounddef/programlisting/codeline"/></pre>
      </noscript>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/ace-builds@latest/src-min-noconflict/ace.js"></script>
  <script>
    <xsl:text>(function () {&#10;</xsl:text>
    <xsl:text>  var aceHost = document.getElementById('doxy-ace-editor');&#10;</xsl:text>
    <xsl:text>  if (!aceHost) return;&#10;</xsl:text>
    <xsl:text>  var sourceNode = aceHost.querySelector('.doxy-source');&#10;</xsl:text>
    <xsl:text>  var source = sourceNode ? sourceNode.textContent : (aceHost.textContent || '');&#10;</xsl:text>
    <xsl:text>  function fallbackToPre(text) {&#10;</xsl:text>
    <xsl:text>    var pre = document.createElement('pre');&#10;</xsl:text>
    <xsl:text>    pre.className = 'doxy-pre';&#10;</xsl:text>
    <xsl:text>    pre.textContent = text;&#10;</xsl:text>
    <xsl:text>    if (aceHost.parentNode) { aceHost.parentNode.replaceChild(pre, aceHost); }&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>
    <xsl:text>  if (!window.ace || !window.ace.edit) { fallbackToPre(source); return; }&#10;</xsl:text>
    <xsl:text>  window.ace.config.set('basePath', 'https://cdn.jsdelivr.net/npm/ace-builds@latest/src-min-noconflict/');&#10;</xsl:text>
    <xsl:text>  var editor = window.ace.edit('doxy-ace-editor');&#10;</xsl:text>
    <xsl:text>  if (sourceNode) { sourceNode.style.display = 'none'; }&#10;</xsl:text>
    <xsl:text>  var mode = aceHost.getAttribute('data-mode') || 'text';&#10;</xsl:text>
    <xsl:text>  editor.session.setMode('ace/mode/' + mode);&#10;</xsl:text>
    <xsl:text>  editor.setTheme('ace/theme/twilight');&#10;</xsl:text>
    <xsl:text>  editor.setValue(source, -1);&#10;</xsl:text>
    <xsl:text>  editor.setReadOnly(true);&#10;</xsl:text>
    <xsl:text>  editor.setHighlightActiveLine(false);&#10;</xsl:text>
    <xsl:text>  editor.setShowPrintMargin(false);&#10;</xsl:text>
    <xsl:text>  editor.setOptions({ useWorker: false, wrap: false, showLineNumbers: true, displayIndentGuides: true, tabSize: 4, useSoftTabs: true, fontSize: '14px' });&#10;</xsl:text>
    <xsl:text>  var lines = source.split('\n').length;&#10;</xsl:text>
    <xsl:text>  var height = Math.max(320, Math.min(1200, (lines * 19) + 24));&#10;</xsl:text>
    <xsl:text>  aceHost.style.height = height + 'px';&#10;</xsl:text>
    <xsl:text>  editor.resize();&#10;</xsl:text>

    <xsl:text>  var aceRange = window.ace.require('ace/range').Range;&#10;</xsl:text>
    <xsl:text>  var hoverMarkerId = null;&#10;</xsl:text>
    <xsl:text>  var hoverKey = null;&#10;</xsl:text>
    <xsl:text>  var keywordLinks = {&#10;</xsl:text>
    <xsl:text>    python: {&#10;</xsl:text>
    <xsl:call-template name="emit-keyword-link">
      <xsl:with-param name="token" select="'class'"/>
      <xsl:with-param name="label" select="'kw_py_class'"/>
    </xsl:call-template>
    <xsl:text>,&#10;</xsl:text>
    <xsl:call-template name="emit-keyword-link">
      <xsl:with-param name="token" select="'def'"/>
      <xsl:with-param name="label" select="'kw_py_def'"/>
    </xsl:call-template>
    <xsl:text>&#10;    },&#10;</xsl:text>
    <xsl:text>    c_cpp: {&#10;</xsl:text>
    <xsl:call-template name="emit-keyword-link">
      <xsl:with-param name="token" select="'class'"/>
      <xsl:with-param name="label" select="'kw_cpp_class'"/>
    </xsl:call-template>
    <xsl:text>,&#10;</xsl:text>
    <xsl:call-template name="emit-keyword-link">
      <xsl:with-param name="token" select="'public'"/>
      <xsl:with-param name="label" select="'kw_cpp_public'"/>
    </xsl:call-template>
    <xsl:text>&#10;    },&#10;</xsl:text>
    <xsl:text>    pascal: {&#10;</xsl:text>
    <xsl:call-template name="emit-keyword-link">
      <xsl:with-param name="token" select="'class'"/>
      <xsl:with-param name="label" select="'kw_pas_class'"/>
    </xsl:call-template>
    <xsl:text>&#10;    }&#10;</xsl:text>
    <xsl:text>  };&#10;</xsl:text>
    <xsl:text>  var languageLabels = { python: 'Python', pascal: 'Pascal', c_cpp: 'C++' };&#10;</xsl:text>
    <xsl:text>  if (!document.getElementById('doxy-ace-link-style')) {&#10;</xsl:text>
    <xsl:text>    var style = document.createElement('style');&#10;</xsl:text>
    <xsl:text>    style.id = 'doxy-ace-link-style';&#10;</xsl:text>
    <xsl:text>    style.textContent = '.doxy-ace-link-marker{position:absolute;border-bottom:2px solid #7aa2f7;pointer-events:none;}.doxy-ace-editor,.doxy-pre,.doxy-source{white-space:pre;font-family:Consolas,"Courier New",monospace;}';&#10;</xsl:text>
    <xsl:text>    document.head.appendChild(style);&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function clearHoverState() {&#10;</xsl:text>
    <xsl:text>    if (hoverMarkerId !== null) { editor.session.removeMarker(hoverMarkerId); hoverMarkerId = null; }&#10;</xsl:text>
    <xsl:text>    hoverKey = null;&#10;</xsl:text>
    <xsl:text>    editor.container.style.cursor = '';&#10;</xsl:text>
    <xsl:text>    if (editor.renderer &amp;&amp; editor.renderer.scroller) editor.renderer.scroller.style.cursor = '';&#10;</xsl:text>
    <xsl:text>    editor.container.title = '';&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function getTokenTarget(ev) {&#10;</xsl:text>
    <xsl:text>    var pos = editor.renderer.screenToTextCoordinates(ev.clientX, ev.clientY);&#10;</xsl:text>
    <xsl:text>    var line = editor.session.getLine(pos.row) || '';&#10;</xsl:text>
    <xsl:text>    var re = /[A-Za-z_][A-Za-z0-9_]*/g;&#10;</xsl:text>
    <xsl:text>    var match;&#10;</xsl:text>
    <xsl:text>    while ((match = re.exec(line)) !== null) {&#10;</xsl:text>
    <xsl:text>      var start = match.index;&#10;</xsl:text>
    <xsl:text>      var end = start + match[0].length;&#10;</xsl:text>
    <xsl:text>      if (pos.column &gt;= start &amp;&amp; pos.column &lt;= end) {&#10;</xsl:text>
    <xsl:text>        var ident = match[0];&#10;</xsl:text>
    <xsl:text>        var modeLinks = keywordLinks[mode] || null;&#10;</xsl:text>
    <xsl:text>        if (!modeLinks || !Object.prototype.hasOwnProperty.call(modeLinks, ident) || !modeLinks[ident]) return null;&#10;</xsl:text>
    <xsl:text>        var label = languageLabels[mode] || mode;&#10;</xsl:text>
    <xsl:text>        return { ident: ident, href: modeLinks[ident], row: pos.row, start: start, end: end, title: 'Zur ' + label + '-Dokumentation für ' + ident };&#10;</xsl:text>
    <xsl:text>      }&#10;</xsl:text>
    <xsl:text>    }&#10;</xsl:text>
    <xsl:text>    return null;&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function applyHoverState(target) {&#10;</xsl:text>
    <xsl:text>    if (!target) { clearHoverState(); return; }&#10;</xsl:text>
    <xsl:text>    var key = target.ident + ':' + target.row + ':' + target.start;&#10;</xsl:text>
    <xsl:text>    if (hoverKey === key &amp;&amp; hoverMarkerId !== null) {&#10;</xsl:text>
    <xsl:text>      editor.container.style.cursor = 'pointer';&#10;</xsl:text>
    <xsl:text>      if (editor.renderer &amp;&amp; editor.renderer.scroller) editor.renderer.scroller.style.cursor = 'pointer';&#10;</xsl:text>
    <xsl:text>      editor.container.title = target.title;&#10;</xsl:text>
    <xsl:text>      return;&#10;</xsl:text>
    <xsl:text>    }&#10;</xsl:text>
    <xsl:text>    clearHoverState();&#10;</xsl:text>
    <xsl:text>    hoverKey = key;&#10;</xsl:text>
    <xsl:text>    hoverMarkerId = editor.session.addMarker(new aceRange(target.row, target.start, target.row, target.end), 'doxy-ace-link-marker', 'text', false);&#10;</xsl:text>
    <xsl:text>    editor.container.style.cursor = 'pointer';&#10;</xsl:text>
    <xsl:text>    editor.container.title = target.title;&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  editor.container.addEventListener('mousemove', function (ev) { applyHoverState(getTokenTarget(ev)); });&#10;</xsl:text>
    <xsl:text>  editor.container.addEventListener('mouseleave', function () { clearHoverState(); });&#10;</xsl:text>
    <xsl:text>  editor.container.addEventListener('click', function (ev) {&#10;</xsl:text>
    <xsl:text>    var target = getTokenTarget(ev);&#10;</xsl:text>
    <xsl:text>    if (!target) return;&#10;</xsl:text>
    <xsl:text>    window.location.href = target.href;&#10;</xsl:text>
    <xsl:text>  });&#10;</xsl:text>
    <xsl:text>})();</xsl:text>
  </script>
</div>
</xsl:template>

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
  <div class="doxy-card"><h2>Dateien</h2></div>
  <xsl:call-template name="render-file-language"><xsl:with-param name="lang" select="'Python'"/></xsl:call-template>
  <xsl:call-template name="render-file-language"><xsl:with-param name="lang" select="'Pascal'"/></xsl:call-template>
  <xsl:call-template name="render-file-language"><xsl:with-param name="lang" select="'C++'"/></xsl:call-template>
</div>
</xsl:template>
</xsl:stylesheet>
