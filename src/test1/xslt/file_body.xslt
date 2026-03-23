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

<xsl:template name="slug-refid">
  <xsl:param name="refid"/>
  <xsl:value-of select="translate($refid, '/', '_')"/>
</xsl:template>

<xsl:template name="target-file-from-refid">
  <xsl:param name="refid"/>
  <xsl:param name="kind"/>

  <xsl:variable name="slug">
    <xsl:call-template name="slug-refid">
      <xsl:with-param name="refid" select="$refid"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$kind = 'class' or $kind = 'struct' or $kind = 'union'">
      <xsl:value-of select="concat('class_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="$kind = 'namespace'">
      <xsl:value-of select="concat('namespace_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="$kind = 'group'">
      <xsl:value-of select="concat('group_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="$kind = 'dir'">
      <xsl:value-of select="concat('dir_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="$kind = 'file'">
      <xsl:value-of select="concat('file_', $slug, '.html')"/>
    </xsl:when>
    <xsl:when test="$kind = 'page'">
      <xsl:value-of select="concat('page_', $slug, '.html')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat($slug, '.html')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="find-page-href-by-label">
  <xsl:param name="label"/>
  <xsl:param name="anchor"/>

  <xsl:variable name="idx" select="document('../xml/index.xml')/doxygenindex"/>
  <xsl:variable name="compound" select="$idx/compound[@kind='page'][name=$label][1]"/>

  <xsl:choose>
    <xsl:when test="$compound">
      <xsl:call-template name="target-file-from-refid">
        <xsl:with-param name="refid" select="$compound/@refid"/>
        <xsl:with-param name="kind" select="$compound/@kind"/>
      </xsl:call-template>
      <xsl:if test="string($anchor) != ''">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="$anchor"/>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise/>
  </xsl:choose>
</xsl:template>


<xsl:template name="find-owner-href-by-member-refid">
  <xsl:param name="member-refid"/>
  <xsl:param name="anchor"/>

  <xsl:variable name="idx" select="document('../xml/index.xml')/doxygenindex"/>
  <xsl:variable name="owner" select="$idx/compound[member/@refid=$member-refid][1]"/>

  <xsl:choose>
    <xsl:when test="$owner">
      <xsl:call-template name="target-file-from-refid">
        <xsl:with-param name="refid" select="$owner/@refid"/>
        <xsl:with-param name="kind" select="$owner/@kind"/>
      </xsl:call-template>
      <xsl:if test="string($anchor) != ''">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="$anchor"/>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise/>
  </xsl:choose>
</xsl:template>

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

<xsl:template name="ace-mode-from-file">
  <xsl:param name="file"/>
  <xsl:variable name="f" select="translate($file, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
  <xsl:choose>
    <xsl:when test="substring($f, string-length($f) - 2) = '.py' or substring($f, string-length($f) - 3) = '.pyw'">python</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.pas' or substring($f, string-length($f) - 2) = '.pp' or substring($f, string-length($f) - 1) = '.p'">pascal</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 1) = '.h' or substring($f, string-length($f) - 3) = '.hpp' or substring($f, string-length($f) - 2) = '.hh' or substring($f, string-length($f) - 3) = '.cpp' or substring($f, string-length($f) - 1) = '.c' or substring($f, string-length($f) - 2) = '.cc' or substring($f, string-length($f) - 3) = '.cxx'">c_cpp</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.qml'">javascript</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.xml'">xml</xsl:when>
    <xsl:when test="substring($f, string-length($f) - 3) = '.htm' or substring($f, string-length($f) - 4) = '.html'">html</xsl:when>
    <xsl:otherwise>text</xsl:otherwise>
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
  </div>

  <div class="doxy-card">
    <h2><xsl:text>Datei:&#160;&#160;</xsl:text><xsl:call-template name="basename"><xsl:with-param name="path" select="compounddef/location/@file"/></xsl:call-template></h2>
    <div class="doxy-muted"><xsl:value-of select="compounddef/location/@file"/></div>
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
        <xsl:apply-templates select="compounddef/programlisting/codeline"/>
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
    <xsl:text>  var source = aceHost.textContent || '';&#10;</xsl:text>

    <xsl:text>  var keywordLinks = {&#10;</xsl:text>
    <xsl:text>    python: {&#10;</xsl:text>
    <xsl:text>      "class": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_py_class'"/><xsl:with-param name="anchor" select="'kw_py_class'"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "def": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_py_def'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>"&#10;</xsl:text>
    <xsl:text>    },&#10;</xsl:text>
    <xsl:text>    pascal: {&#10;</xsl:text>
    <xsl:text>      "class": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_class'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "program": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_program'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "unit": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_unit'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "library": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_library'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "uses": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_uses'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "type": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_type'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "const": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_const'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "boolean": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_boolean'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "string": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_string'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "char": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_char'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "byte": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_byte'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "word": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_word'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "integer": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_integer'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "extended": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_extended'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "real": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_real'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "for": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_for'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "if": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_if'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "else": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_else'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "end": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_end'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "while": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_while'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "loop": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_loop'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "repeat": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_repeat'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "until": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_until'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "record": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_record'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "array": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_array'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "forward": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_forward'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "var": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_var'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "virtual": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_virtual'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "interface": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_interface'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "implementation": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_implementation'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "procedure": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_procedure'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "function": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_function'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "case": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_case'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "of": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_of'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "default": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_default'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "switch": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_switch'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "begin": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_begin'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "exit": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_exit'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "halt": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_halt'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "break": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_break'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "continue": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_continue'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "goto": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_goto'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "label": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_label'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "overwrite": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_overwrite'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "overload": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_overload'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "object": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_object'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "reintroduce": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_reintroduce'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "set": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_pas_set'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>"&#10;</xsl:text>
    <xsl:text>    },&#10;</xsl:text>
    <xsl:text>    c_cpp: {&#10;</xsl:text>
    <xsl:text>      "class": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_class'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "virtual": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_virtual'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "int": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_int'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "char": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_char'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "void": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_void'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "struct": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_struct'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "reinterpret_cast": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_reinterpret_cast'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "static_cast": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_static_cast'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "dynamic_cast": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_dynamic_cast'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "return": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_return'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "switch": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_switch'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "case": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_case'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "for": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_for'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "while": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_while'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "if": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_if'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "else": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_else'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "include": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_include'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "define": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_define'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "ifdef": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_ifdef'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "defined": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_defined'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "typeof": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_typeof'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "cout": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_cout'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "cin": "</xsl:text><xsl:call-template name="find-page-href-by-label"><xsl:with-param name="label" select="'kw_cpp_cin'"/><xsl:with-param name="anchor" select="''"/></xsl:call-template><xsl:text>"&#10;</xsl:text>
    <xsl:text>    }&#10;</xsl:text>
    <xsl:text>  };&#10;</xsl:text>

    <xsl:text>  var docLinks = {};&#10;</xsl:text>
    <xsl:for-each select="compounddef/programlisting//ref[@refid and normalize-space(.) != '']">
      <xsl:if test="generate-id() = generate-id((//ref[@refid and normalize-space(.) = normalize-space(current())])[1])">
        <xsl:text>  docLinks["</xsl:text><xsl:value-of select="normalize-space(.)"/><xsl:text>"] = "</xsl:text>
        <xsl:choose>
          <xsl:when test="@kindref = 'member'">
            <xsl:call-template name="find-owner-href-by-member-refid">
              <xsl:with-param name="member-refid" select="@refid"/>
              <xsl:with-param name="anchor">
                <xsl:choose>
                  <xsl:when test="normalize-space(.) = '__init__'">constructors</xsl:when>
                  <xsl:otherwise></xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="resolved-kind">
              <xsl:choose>
                <xsl:when test="@kindref = 'compound'">class</xsl:when>
                <xsl:when test="@kindref != ''"><xsl:value-of select="@kindref"/></xsl:when>
                <xsl:when test="starts-with(@refid, 'class')">class</xsl:when>
                <xsl:when test="starts-with(@refid, 'struct')">struct</xsl:when>
                <xsl:when test="starts-with(@refid, 'union')">union</xsl:when>
                <xsl:when test="starts-with(@refid, 'namespace')">namespace</xsl:when>
                <xsl:when test="starts-with(@refid, 'group')">group</xsl:when>
                <xsl:when test="starts-with(@refid, 'dir')">dir</xsl:when>
                <xsl:when test="starts-with(@refid, 'file')">file</xsl:when>
                <xsl:otherwise>class</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:call-template name="target-file-from-refid"><xsl:with-param name="refid" select="@refid"/><xsl:with-param name="kind" select="string($resolved-kind)"/></xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>";&#10;</xsl:text>
      </xsl:if>
    </xsl:for-each>

    <xsl:text>  function fallbackToPre(text) {&#10;</xsl:text>
    <xsl:text>    var pre = document.createElement('pre');&#10;</xsl:text>
    <xsl:text>    pre.className = 'doxy-pre';&#10;</xsl:text>
    <xsl:text>    pre.textContent = text;&#10;</xsl:text>
    <xsl:text>    if (aceHost.parentNode) { aceHost.parentNode.replaceChild(pre, aceHost); }&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  if (!window.ace || !window.ace.edit) {&#10;</xsl:text>
    <xsl:text>    fallbackToPre(source);&#10;</xsl:text>
    <xsl:text>    return;&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  window.ace.config.set('basePath', 'https://cdn.jsdelivr.net/npm/ace-builds@latest/src-min-noconflict/');&#10;</xsl:text>
    <xsl:text>  var editor = window.ace.edit('doxy-ace-editor');&#10;</xsl:text>
    <xsl:text>  var mode = aceHost.getAttribute('data-mode') || 'text';&#10;</xsl:text>
    <xsl:text>  editor.session.setMode('ace/mode/' + mode);&#10;</xsl:text>
    <xsl:text>  editor.setTheme('ace/theme/twilight');&#10;</xsl:text>
    <xsl:text>  editor.setValue(source, -1);&#10;</xsl:text>
    <xsl:text>  editor.setReadOnly(true);&#10;</xsl:text>
    <xsl:text>  editor.setHighlightActiveLine(false);&#10;</xsl:text>
    <xsl:text>  editor.setShowPrintMargin(false);&#10;</xsl:text>
    <xsl:text>  editor.setOptions({ useWorker: false, wrap: false, showLineNumbers: true, displayIndentGuides: true, tabSize: 4, useSoftTabs: true, fontSize: '14px' });&#10;</xsl:text>

    <xsl:text>  var lines = source.split('&#92;n').length;&#10;</xsl:text>
    <xsl:text>  var height = Math.max(320, Math.min(1200, (lines * 19) + 24));&#10;</xsl:text>
    <xsl:text>  aceHost.style.height = height + 'px';&#10;</xsl:text>
    <xsl:text>  editor.resize();&#10;</xsl:text>

    <xsl:text>  function lookupKeywordDoc(language, tokenText) {&#10;</xsl:text>
    <xsl:text>    var lang = (language || '').toLowerCase();&#10;</xsl:text>
    <xsl:text>    var table = keywordLinks[lang] || {};&#10;</xsl:text>
    <xsl:text>    return table[tokenText] || null;&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function getIdentifierAtPosition(session, row, column) {&#10;</xsl:text>
    <xsl:text>    var line = session.getLine(row) || '';&#10;</xsl:text>
    <xsl:text>    var re = /[A-Za-z_][A-Za-z0-9_]*/g;&#10;</xsl:text>
    <xsl:text>    var match;&#10;</xsl:text>
    <xsl:text>    while ((match = re.exec(line)) !== null) {&#10;</xsl:text>
    <xsl:text>      var start = match.index;&#10;</xsl:text>
    <xsl:text>      var end = start + match[0].length;&#10;</xsl:text>
    <xsl:text>      if (column &gt;= start &amp;&amp; column &lt;= end) {&#10;</xsl:text>
    <xsl:text>        return { ident: match[0], start: start, end: end };&#10;</xsl:text>
    <xsl:text>      }&#10;</xsl:text>
    <xsl:text>    }&#10;</xsl:text>
    <xsl:text>    return null;&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function buildTarget(ident, href, row, start, end, title) {&#10;</xsl:text>
    <xsl:text>    return { ident: ident, href: href, row: row, start: start, end: end, title: title };&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  var aceRange = window.ace.require('ace/range').Range;&#10;</xsl:text>
    <xsl:text>  var hoverMarkerId = null;&#10;</xsl:text>
    <xsl:text>  var hoverKey = null;&#10;</xsl:text>
    <xsl:text>  var languageLabels = { python: 'Python', pascal: 'Pascal', c_cpp: 'C++' };&#10;</xsl:text>

    <xsl:text>  function setInteractiveCursor(enabled) {&#10;</xsl:text>
    <xsl:text>    var value = enabled ? 'pointer' : '';&#10;</xsl:text>
    <xsl:text>    editor.container.style.cursor = value;&#10;</xsl:text>
    <xsl:text>    if (enabled) { aceHost.classList.add('doxy-ace-pointer'); } else { aceHost.classList.remove('doxy-ace-pointer'); }&#10;</xsl:text>
    <xsl:text>    if (editor.renderer &amp;&amp; editor.renderer.scroller) editor.renderer.scroller.style.cursor = value;&#10;</xsl:text>
    <xsl:text>    if (editor.textInput &amp;&amp; editor.textInput.getElement) editor.textInput.getElement().style.cursor = value;&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function clearHoverState() {&#10;</xsl:text>
    <xsl:text>    if (hoverMarkerId !== null) { editor.session.removeMarker(hoverMarkerId); hoverMarkerId = null; }&#10;</xsl:text>
    <xsl:text>    hoverKey = null;&#10;</xsl:text>
    <xsl:text>    setInteractiveCursor(false);&#10;</xsl:text>
    <xsl:text>    editor.container.title = '';&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function resolveConstructorTarget(row) {&#10;</xsl:text>
    <xsl:text>    for (var r = row; r &gt;= 0; r--) {&#10;</xsl:text>
    <xsl:text>      var line = editor.session.getLine(r) || '';&#10;</xsl:text>
    <xsl:text>      var m = line.match(/^\s*class\s+([A-Za-z_][A-Za-z0-9_]*)\b/);&#10;</xsl:text>
    <xsl:text>      if (m &amp;&amp; m[1] &amp;&amp; Object.prototype.hasOwnProperty.call(docLinks, m[1])) {&#10;</xsl:text>
    <xsl:text>        return { ident: '__init__', href: docLinks[m[1]] + '#constructors', title: 'Zur Konstruktor-Dokumentation von ' + m[1] };&#10;</xsl:text>
    <xsl:text>      }&#10;</xsl:text>
    <xsl:text>    }&#10;</xsl:text>
    <xsl:text>    return null;&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function resolveKeywordTarget(ident, row, start, end) {&#10;</xsl:text>
    <xsl:text>    var href = lookupKeywordDoc(mode, ident);&#10;</xsl:text>
    <xsl:text>    if (!href) return null;&#10;</xsl:text>
    <xsl:text>    var label = languageLabels[mode] || mode;&#10;</xsl:text>
    <xsl:text>    return buildTarget(ident, href, row, start, end, 'Zur ' + label + '-Dokumentation für ' + ident);&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function targetAtEvent(ev) {&#10;</xsl:text>
    <xsl:text>    var pos = editor.renderer.screenToTextCoordinates(ev.clientX, ev.clientY);&#10;</xsl:text>
    <xsl:text>    var hit = getIdentifierAtPosition(editor.session, pos.row, pos.column);&#10;</xsl:text>
    <xsl:text>    if (!hit) return null;&#10;</xsl:text>
    <xsl:text>    if (Object.prototype.hasOwnProperty.call(docLinks, hit.ident)) {&#10;</xsl:text>
    <xsl:text>      return buildTarget(hit.ident, docLinks[hit.ident], pos.row, hit.start, hit.end, 'Zur Dokumentation von ' + hit.ident);&#10;</xsl:text>
    <xsl:text>    }&#10;</xsl:text>
    <xsl:text>    if (hit.ident === '__init__') {&#10;</xsl:text>
    <xsl:text>      var ctorTarget = resolveConstructorTarget(pos.row);&#10;</xsl:text>
    <xsl:text>      if (ctorTarget) { ctorTarget.row = pos.row; ctorTarget.start = hit.start; ctorTarget.end = hit.end; return ctorTarget; }&#10;</xsl:text>
    <xsl:text>    }&#10;</xsl:text>
    <xsl:text>    return resolveKeywordTarget(hit.ident, pos.row, hit.start, hit.end);&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  function applyHoverState(target) {&#10;</xsl:text>
    <xsl:text>    if (!target) { clearHoverState(); return; }&#10;</xsl:text>
    <xsl:text>    var key = target.row + ':' + target.start + ':' + target.ident;&#10;</xsl:text>
    <xsl:text>    if (hoverKey === key &amp;&amp; hoverMarkerId !== null) { setInteractiveCursor(true); editor.container.title = target.title || ''; return; }&#10;</xsl:text>
    <xsl:text>    clearHoverState();&#10;</xsl:text>
    <xsl:text>    hoverKey = key;&#10;</xsl:text>
    <xsl:text>    hoverMarkerId = editor.session.addMarker(new aceRange(target.row, target.start, target.row, target.end), 'doxy-ace-link-marker', 'text', false);&#10;</xsl:text>
    <xsl:text>    setInteractiveCursor(true);&#10;</xsl:text>
    <xsl:text>    editor.container.title = target.title || '';&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>

    <xsl:text>  editor.container.addEventListener('mousemove', function (ev) { applyHoverState(targetAtEvent(ev)); });&#10;</xsl:text>
    <xsl:text>  editor.container.addEventListener('mouseleave', function () { clearHoverState(); });&#10;</xsl:text>
    <xsl:text>  editor.container.addEventListener('click', function (ev) { var target = targetAtEvent(ev); if (!target) return; window.location.href = target.href; });&#10;</xsl:text>
    <xsl:text>})();</xsl:text>
  </script>
</div>
</xsl:template>
</xsl:stylesheet>
