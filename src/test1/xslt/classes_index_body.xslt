<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
<xsl:strip-space elements="*"/>

<xsl:key name="classes-by-letter" match="/doxygenindex/compound[@kind='class']"
         use="translate(substring(name, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
<xsl:key name="pas-files-by-letter" match="/doxygenindex/compound[@kind='file'][substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-3) = '.pas' or substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-2) = '.pp' or substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-1) = '.p']"
         use="'ALL'"/>

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

<xsl:template name="pascal-fallback-href">
  <xsl:param name="fileRefId"/>
  <xsl:param name="className"/>
  <xsl:variable name="safeClassName" select="translate($className, ' -.:,;()[]{}&lt;&gt;/\', '___________________')"/>
  <xsl:value-of select="concat('class_pas_', translate($fileRefId, '/', '_'), '_', $safeClassName, '.html')"/>
</xsl:template>

<xsl:template name="class-language">
  <xsl:param name="file"/>
  <xsl:variable name="f" select="translate($file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
  <xsl:choose>
    <xsl:when test="substring($f, string-length($f) - 2) = '.py' or substring($f, string-length($f) - 3) = '.pyw'">Python</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.pas' or substring($f, string-length($f) - 2) = '.pp' or substring($f, string-length($f) - 1) = '.p'">Pascal</xsl:when>
    <xsl:otherwise>C++</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="render-real-language-section">
  <xsl:param name="letter"/>
  <xsl:param name="lang"/>
  <xsl:variable name="rows" select="key('classes-by-letter', $letter)"/>
  <xsl:if test="$rows">
    <xsl:variable name="langCount" select="count($rows[
      ($lang = 'Python' and (substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.py' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pyw')) or
      ($lang = 'Pascal' and (substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pas' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.pp' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 1) = '.p')) or
      ($lang = 'C++' and not(substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.py' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pyw' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 3) = '.pas' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 2) = '.pp' or substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) - 1) = '.p'))
    ])"/>
    <xsl:if test="$langCount &gt; 0">
      <div class="doxy-class-language-group">
        <h4><xsl:value-of select="$lang"/></h4>
        <table class="doxy-table doxy-class-table">
          <thead>
            <tr>
              <th>Klasse</th>
              <th>Beschreibung</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="$rows">
              <xsl:sort select="name"/>
              <xsl:variable name="doc" select="document(concat(@refid,'.xml'), /)/doxygen/compounddef"/>
              <xsl:variable name="file" select="$doc/location/@file"/>
              <xsl:variable name="currentLang">
                <xsl:call-template name="class-language">
                  <xsl:with-param name="file" select="$file"/>
                </xsl:call-template>
              </xsl:variable>
              <xsl:if test="normalize-space($currentLang) = $lang">
                <tr>
                  <td class="doxy-class-name-cell">
                    <a href="{concat('class_', translate(@refid,'/','_'), '.html')}">
                      <xsl:call-template name="last-scope-part">
                        <xsl:with-param name="text" select="$doc/compoundname"/>
                      </xsl:call-template>
                    </a>
                  </td>
                  <td class="doxy-class-desc-cell">
                    <xsl:choose>
                      <xsl:when test="normalize-space($doc/briefdescription) != ''">
                        <xsl:value-of select="normalize-space($doc/briefdescription)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <span class="doxy-muted">—</span>
                      </xsl:otherwise>
                    </xsl:choose>
                  </td>
                </tr>
              </xsl:if>
            </xsl:for-each>
          </tbody>
        </table>
      </div>
    </xsl:if>
  </xsl:if>
</xsl:template>

<xsl:template name="render-pascal-fallback-section">
  <xsl:param name="letter"/>
  <xsl:variable name="files" select="key('pas-files-by-letter', 'ALL')"/>
  <xsl:variable name="classLines" select="$files/document(concat(@refid,'.xml'), /)/doxygen/compounddef/programlisting/codeline[highlight[contains(translate(normalize-space(.), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '= class')]]"/>
  <xsl:if test="count($classLines[translate(substring(normalize-space(substring-before(normalize-space(string(highlight)), '=')),1,1),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ') = $letter]) &gt; 0">
    <div class="doxy-class-language-group">
      <h4>Pascal</h4>
      <table class="doxy-table doxy-class-table">
        <thead>
          <tr>
            <th>Klasse</th>
            <th>Beschreibung</th>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="$classLines[translate(substring(normalize-space(substring-before(normalize-space(string(highlight)), '=')),1,1),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ') = $letter]">
            <xsl:sort select="normalize-space(substring-before(normalize-space(string(highlight)), '='))"/>
            <xsl:variable name="className" select="normalize-space(substring-before(normalize-space(string(highlight)), '='))"/>
            <xsl:variable name="fileDoc" select="ancestor::doxygen/compounddef"/>
            <xsl:variable name="fileRefId" select="$fileDoc/@id"/>
            <tr>
              <td class="doxy-class-name-cell">
                <a>
                  <xsl:attribute name="href">
                    <xsl:call-template name="pascal-fallback-href">
                      <xsl:with-param name="fileRefId" select="$fileRefId"/>
                      <xsl:with-param name="className" select="$className"/>
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:value-of select="$className"/>
                </a>
              </td>
              <td class="doxy-class-desc-cell">
                <xsl:choose>
                  <xsl:when test="preceding-sibling::codeline[1]/highlight[contains(., '@brief')]">
                    <xsl:value-of select="normalize-space(substring-after(string(preceding-sibling::codeline[1]/highlight), '@brief'))"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <span class="doxy-muted">Aus Pascal-Datei extrahiert</span>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template name="render-letter-section">
  <xsl:param name="letter"/>
  <div class="doxy-card doxy-section-gap">
    <h3 id="classes-{$letter}"><xsl:value-of select="$letter"/></h3>
    <xsl:call-template name="render-real-language-section">
      <xsl:with-param name="letter" select="$letter"/>
      <xsl:with-param name="lang" select="'Python'"/>
    </xsl:call-template>
    <xsl:call-template name="render-real-language-section">
      <xsl:with-param name="letter" select="$letter"/>
      <xsl:with-param name="lang" select="'Pascal'"/>
    </xsl:call-template>
    <xsl:if test="count(key('classes-by-letter', $letter)[substring(translate(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file, string-length(document(concat(@refid,'.xml'), /)/doxygen/compounddef/location/@file)-3), '.pas') = '.pas']) = 0">
      <xsl:call-template name="render-pascal-fallback-section">
        <xsl:with-param name="letter" select="$letter"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:call-template name="render-real-language-section">
      <xsl:with-param name="letter" select="$letter"/>
      <xsl:with-param name="lang" select="'C++'"/>
    </xsl:call-template>
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

  <div class="doxy-card">
    <h2>Klassen</h2>
    <div class="doxy-alpha-nav">
      <xsl:call-template name="alphabet-links">
        <xsl:with-param name="letters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
      </xsl:call-template>
    </div>
  </div>

  <xsl:for-each select="/doxygenindex/compound[@kind='class'][generate-id() = generate-id(key('classes-by-letter', translate(substring(name, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'))[1])] | /doxygenindex/compound[@kind='file'][substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-3) = '.pas' or substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-2) = '.pp' or substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-1) = '.p'][generate-id() = generate-id(key('pas-files-by-letter', 'ALL')[1])]">
    <xsl:sort select="translate(substring(name, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
    <xsl:if test="self::compound[@kind='class']">
      <xsl:variable name="letter" select="translate(substring(name, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
      <xsl:if test="generate-id() = generate-id(key('classes-by-letter', $letter)[1])">
        <xsl:call-template name="render-letter-section">
          <xsl:with-param name="letter" select="$letter"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
    <xsl:if test="self::compound[@kind='file'] and position()=last()">
      <xsl:for-each select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'">
      </xsl:for-each>
    </xsl:if>
  </xsl:for-each>

  <xsl:for-each select="/doxygenindex/compound[@kind='file'][substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-3) = '.pas' or substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-2) = '.pp' or substring(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), string-length(name)-1) = '.p']">
    <xsl:variable name="doc" select="document(concat(@refid,'.xml'), /)/doxygen/compounddef"/>
    <xsl:for-each select="$doc/programlisting/codeline[highlight[contains(translate(normalize-space(.), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '= class')]]">
      <xsl:variable name="letter" select="translate(substring(normalize-space(substring-before(normalize-space(string(highlight)), '=')),1,1),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
      <xsl:if test="not(count(/doxygenindex/compound[@kind='class'][translate(substring(name,1,1),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ') = $letter]) &gt; 0)">
        <xsl:if test="not(preceding::codeline[translate(substring(normalize-space(substring-before(normalize-space(string(highlight)), '=')),1,1),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ') = $letter])">
          <xsl:call-template name="render-letter-section">
            <xsl:with-param name="letter" select="$letter"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:for-each>
</div>
</xsl:template>

<xsl:template name="alphabet-links">
  <xsl:param name="letters"/>
  <xsl:if test="string-length($letters) &gt; 0">
    <xsl:variable name="letter" select="substring($letters, 1, 1)"/>
    <xsl:variable name="hasReal" select="count(key('classes-by-letter', $letter)) &gt; 0"/>
    <xsl:variable name="hasPasFallback" select="false()"/>
    <xsl:choose>
      <xsl:when test="$hasReal or $hasPasFallback">
        <a href="{concat('#classes-', $letter)}"><xsl:value-of select="$letter"/></a>
      </xsl:when>
      <xsl:otherwise>
        <span class="doxy-alpha-disabled"><xsl:value-of select="$letter"/></span>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text> </xsl:text>
    <xsl:call-template name="alphabet-links">
      <xsl:with-param name="letters" select="substring($letters, 2)"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>
</xsl:stylesheet>
