<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="codeline highlight"/>


<xsl:template match="sp"><xsl:text> </xsl:text></xsl:template>
<xsl:template match="linebreak"><xsl:text>&#10;</xsl:text></xsl:template>
<xsl:template match="highlight"><xsl:apply-templates/></xsl:template>
<xsl:template match="codeline"><xsl:apply-templates/><xsl:text>&#10;</xsl:text></xsl:template>
<xsl:template match="para|briefdescription|detaileddescription|itemizedlist|orderedlist|listitem|simplesect">
  <xsl:apply-templates/>
  <xsl:if test="self::para or self::listitem"><xsl:text>&#10;</xsl:text></xsl:if>
</xsl:template>
<xsl:template match="title">
  <xsl:value-of select="."/><xsl:text>&#10;</xsl:text>
</xsl:template>
<xsl:template match="ref|computeroutput|bold|emphasis|mdash|ndash|lsquo|rsquo|ldquo|rdquo|nonbreakablespace|umlaut|Uumlaut|auml|ouml|uuml|Auml|Ouml|Uuml|szlig|fouml|uumlaut">
  <xsl:value-of select="."/>
</xsl:template>
<xsl:template match="text()">
  <xsl:value-of select="."/>
</xsl:template>

<xsl:template name="ace-mode-from-file">
  <xsl:param name="file"/>
  <xsl:variable name="f" select="translate($file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
  <xsl:choose>
    <xsl:when test="substring($f, string-length($f) - 2) = '.py' or substring($f, string-length($f) - 3) = '.pyw'">python</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.pas' or substring($f, string-length($f) - 2) = '.pp' or substring($f, string-length($f) - 1) = '.p'">pascal</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 1) = '.h' or substring($f, string-length($f) - 3) = '.hpp' or substring($f, string-length($f) - 2) = '.hh' or substring($f, string-length($f) - 3) = '.cpp' or substring($f, string-length($f) - 1) = '.c' or substring($f, string-length($f) - 2) = '.cc' or substring($f, string-length($f) - 3) = '.cxx'">c_cpp</xsl:when>
    <xsl:otherwise>text</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="keyword-heading">
  <xsl:variable name="compoundname" select="compounddef/compoundname"/>
  <xsl:choose>
    <xsl:when test="starts-with($compoundname, 'kw_py_')">
      <h2>Python Schlüsselwort:<xsl:text>&#160;&#160;</xsl:text><span class="doxy-keyword-name"><xsl:value-of select="substring-after($compoundname, 'kw_py_')"/></span></h2>
    </xsl:when>
    <xsl:when test="starts-with($compoundname, 'kw_pas_')">
      <h2>Pascal Schlüsselwort:<xsl:text>&#160;&#160;</xsl:text><span class="doxy-keyword-name"><xsl:value-of select="substring-after($compoundname, 'kw_pas_')"/></span></h2>
    </xsl:when>
    <xsl:when test="starts-with($compoundname, 'kw_cpp_')">
      <h2>C++ Schlüsselwort:<xsl:text>&#160;&#160;</xsl:text><span class="doxy-keyword-name"><xsl:value-of select="substring-after($compoundname, 'kw_cpp_')"/></span></h2>
    </xsl:when>
    <xsl:otherwise>
      <h2><xsl:value-of select="(compounddef/title|compounddef/compoundname)[1]"/></h2>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="sect1">
  <div class="doxy-card doxy-section-gap">
    <h3><xsl:value-of select="title"/></h3>
    <xsl:apply-templates select="node()[not(self::title)]"/>
  </div>
</xsl:template>

<xsl:template match="programlisting">
  <xsl:variable name="ace-mode">
    <xsl:call-template name="ace-mode-from-file">
      <xsl:with-param name="file" select="@filename"/>
    </xsl:call-template>
  </xsl:variable>
  <div class="doxy-ace-host doxy-page-ace-host">
    <div class="doxy-page-ace-editor">
      <xsl:attribute name="data-mode"><xsl:value-of select="$ace-mode"/></xsl:attribute>
      <xsl:apply-templates select="codeline"/>
    </div>
    <noscript>
      <pre class="doxy-pre"><xsl:apply-templates select="codeline"/></pre>
    </noscript>
  </div>
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
    <xsl:call-template name="keyword-heading"/>
    <xsl:if test="compounddef/briefdescription/para">
      <div class="doxy-muted"><xsl:apply-templates select="compounddef/briefdescription"/></div>
    </xsl:if>
  </div>
  <xsl:apply-templates select="compounddef/detaileddescription/sect1"/>
  <script src="https://cdn.jsdelivr.net/npm/ace-builds@latest/src-min-noconflict/ace.js"></script>
  <script>
    <xsl:text>(function () {&#10;</xsl:text>
    <xsl:text>  if (!window.ace || !window.ace.edit) return;&#10;</xsl:text>
    <xsl:text>  window.ace.config.set('basePath', 'https://cdn.jsdelivr.net/npm/ace-builds@latest/src-min-noconflict/');&#10;</xsl:text>
    <xsl:text>  var hosts = document.querySelectorAll('.doxy-page-ace-editor');&#10;</xsl:text>
    <xsl:text>  for (var i = 0; i &lt; hosts.length; i++) {&#10;</xsl:text>
    <xsl:text>    var host = hosts[i];&#10;</xsl:text>
    <xsl:text>    var source = host.textContent || '';&#10;</xsl:text>
    <xsl:text>    var mode = host.getAttribute('data-mode') || 'text';&#10;</xsl:text>
    <xsl:text>    var editor = window.ace.edit(host);&#10;</xsl:text>
    <xsl:text>    editor.session.setMode('ace/mode/' + mode);&#10;</xsl:text>
    <xsl:text>    editor.setTheme('ace/theme/twilight');&#10;</xsl:text>
    <xsl:text>    editor.setValue(source, -1);&#10;</xsl:text>
    <xsl:text>    editor.setReadOnly(true);&#10;</xsl:text>
    <xsl:text>    editor.setHighlightActiveLine(false);&#10;</xsl:text>
    <xsl:text>    editor.setShowPrintMargin(false);&#10;</xsl:text>
    <xsl:text>    editor.setOptions({ useWorker: false, wrap: false, showLineNumbers: true, displayIndentGuides: true, tabSize: 4, useSoftTabs: true, fontSize: '14px', maxLines: Infinity });&#10;</xsl:text>
    <xsl:text>    var lines = Math.max(1, editor.session.getLength());&#10;</xsl:text>
    <xsl:text>    var height = (lines * 19) + 4;&#10;</xsl:text>
    <xsl:text>    host.style.height = height + 'px';&#10;</xsl:text>
    <xsl:text>    editor.resize();&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>
    <xsl:text>})();</xsl:text>
  </script>
</div>
</xsl:template>
</xsl:stylesheet>
