<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:xlink="http://www.w3.org/1999/xlink" 
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xsl xlink mml xsi xs">

  <xsl:import href="xml2json-2.0.xsl"/>
  <xsl:output method="text" encoding="UTF-8"/>

  <!-- needed by xml2json -->
  <xsl:variable name="dtd-annotation">
    <foo/>
  </xsl:variable>

  <xsl:param name="pmcid"/>
  <xsl:param name="nbkid"/>
  <xsl:param name="pmid"/>
  <xsl:param name="doi"/>
  <xsl:param name="accessed"/>

  <!--
    Overrides the named template in xml2json.xsl.  This is the top-level template that will
    generate the intermediate XML format, before conversion into JSON.
  -->
  <xsl:template name="root">
    <xsl:apply-templates/>
  </xsl:template>


  <xsl:template match="pm-record|pub-one-record">
    <xsl:variable name="article-id">
      <xsl:choose>
        <xsl:when test="$pmcid">
          <xsl:value-of select="$pmcid"/>
        </xsl:when>
        <xsl:when test="$nbkid">
          <xsl:value-of select="$nbkid"/>
        </xsl:when>
        <xsl:when test="$pmid">
          <xsl:value-of select="$pmid"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="generate-id(self::node())"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <o>
      <s k="source">PMC</s>
      <xsl:call-template name="accessed"/>
      <s k="id">
        <xsl:value-of select="$article-id"/>
      </s>
      <xsl:apply-templates select="document-meta" mode="title"/>
      <xsl:if test="@record-type='book'">
        <xsl:apply-templates select="source-meta" mode="title"/>
      </xsl:if>
      <xsl:call-template name="contrib-group"/>
      <xsl:apply-templates select="source-meta" mode="container"/>
      <xsl:apply-templates select="document-meta|source-meta"/>
      <s k="type">
        <xsl:choose>
          <xsl:when test="@record-type='article'">
            <xsl:text>article-journal</xsl:text>
          </xsl:when>
          <xsl:when test="@record-type='book'">
            <xsl:text>book</xsl:text>
          </xsl:when>
          <xsl:when test="@record-type='section'">
            <xsl:text>chapter</xsl:text>
          </xsl:when>
        </xsl:choose>
      </s>
    </o>
  </xsl:template>

  <xsl:template match="document-meta|source-meta" mode="title">
    <s k="title">
      <xsl:apply-templates select="title-group/title"/>
      <xsl:if test="title-group/subtitle">
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="title-group/subtitle"/>
      </xsl:if>
    </s>
  </xsl:template>

  <xsl:template match="title|subtitle">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="italic">
    <xsl:text>&lt;i></xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&lt;/i></xsl:text>
  </xsl:template>

  <xsl:template match="bold">
    <xsl:text>&lt;b></xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&lt;/b></xsl:text>
  </xsl:template>

  <xsl:template match="sub|sup">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>></xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>></xsl:text>
  </xsl:template>

  <xsl:template
    match="*[ancestor::title or ancestor::subtitle][not(self::italic or self::bold or self::sub or self::sup)]">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()[ancestor::title or ancestor::subtitle]">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template name="contrib-group">
    <xsl:if test="//contrib[@contrib-type='author']">
      <a k="author">
        <xsl:for-each select="//contrib[@contrib-type='author']">
          <o>
            <xsl:apply-templates
              select="string-name | collab | on-behalf-of | name/* | name-alternatives"/>
          </o>
        </xsl:for-each>
      </a>
    </xsl:if>
    <xsl:if test="//contrib[@contrib-type='editor']">
      <a k="editor">
        <xsl:for-each select="//contrib[@contrib-type='editor']">
          <o>
            <xsl:apply-templates
              select="string-name | collab | on-behalf-of | name/* | name-alternatives"/>
          </o>
        </xsl:for-each>
      </a>
    </xsl:if>
  </xsl:template>

  <xsl:template match="string-name|collab|on-behalf-of">
    <s k="family">
      <xsl:value-of select="."/>
    </s>
  </xsl:template>

  <xsl:template match="name/*">
    <s>
      <xsl:attribute name="k">
        <xsl:choose>
          <xsl:when test="local-name(.)='surname'">family</xsl:when>
          <xsl:when test="local-name(.)='given-names'">given</xsl:when>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="."/>
    </s>
  </xsl:template>

  <!-- For name-alternatives, we'll pick one, in a defined precedence order. -->
  <xsl:template match="name-alternatives">
    <xsl:choose>
      <xsl:when test="name[@name-style='western']">
        <xsl:apply-templates select="name[@name-style='western']/*"/>
      </xsl:when>
      <xsl:when test="name[@name-style='given-only']">
        <xsl:apply-templates select="name[@name-style='given-only']/*"/>
      </xsl:when>
      <xsl:when test="name[@name-style='eastern']">
        <xsl:apply-templates select="name[@name-style='eastern']/*"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates
          select="name[@name-style != 'western' and @name-style != 'given-only' and
                       @name-style != 'eastern'][1]/*"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="source-meta" mode="container">
    <!-- process abbreviated journal title as container-title-short -->
    <xsl:choose>
      <xsl:when test="object-id[@pub-id-type='nlm-ta']">
        <s k="container-title-short">
          <xsl:value-of select="object-id[@pub-id-type='nlm-ta']"/>
        </s>
      </xsl:when>
      <xsl:when test="object-id[@pub-id-type='iso-abbrev']">
        <s k="container-title-short">
          <xsl:value-of select="object-id[@pub-id-type='iso-abbrev']"/>
        </s>
      </xsl:when>
    </xsl:choose>
    <!-- process full title as container-title -->
    <xsl:choose>
      <xsl:when test="parent::node()/@record-type='section'">
        <s k="container-title">
          <xsl:apply-templates select="title-group/title"/>
          <xsl:if test="title-group/subtitle">
            <xsl:text>: </xsl:text>
            <xsl:apply-templates select="title-group/subtitle"/>
          </xsl:if>
        </s>
      </xsl:when>
      <xsl:when test="normalize-space(title-group/title/text())">
        <s k="container-title">
          <xsl:apply-templates select="title-group/title"/>
          <xsl:if test="title-group/subtitle">
            <xsl:text>: </xsl:text>
            <xsl:apply-templates select="title-group/subtitle"/>
          </xsl:if>
        </s>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>OTHERWISE!</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="publisher/publisher-name"/>
    <xsl:apply-templates select="publisher/publisher-loc"/>

    <!-- ISSN Processing - use issn-l first, then print, then electronic -->
    <xsl:choose>
      <xsl:when test="issn-l">
        <xsl:apply-templates select="issn-l"/>
      </xsl:when>
      <xsl:when test="issn[@publication-format='print']">
        <xsl:apply-templates select="issn[@publication-format='print']"/>
      </xsl:when>
      <xsl:when test="issn[@publication-format='electronic']">
        <xsl:apply-templates select="issn[@publication-format='electronic']"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="publisher-name">
    <s k="publisher">
      <xsl:value-of select="."/>
    </s>
  </xsl:template>
  <xsl:template match="publisher-loc">
    <s k="publisher-place">
      <xsl:value-of select="."/>
    </s>
  </xsl:template>


  <xsl:template match="issn | issn-l">
    <s k="ISSN">
      <xsl:value-of select="."/>
    </s>
  </xsl:template>

  <xsl:template match="document-meta|source-meta">
    <!-- issued date and online date-->
    <xsl:choose>
      <xsl:when test="pub-date[@date-type='ppub' or @date-type='epub-ppub']">
        <xsl:call-template name="issued-date">
          <xsl:with-param name="pub-date" 
                          select="pub-date[@date-type='ppub' or @date-type='epub-ppub'][1]"/>
        </xsl:call-template>
        <xsl:if test='pub-date[@date-type="epub"]'>
          <xsl:call-template name="online-date">
            <xsl:with-param name="pub-date" 
                            select="pub-date[@date-type='epub'][1]"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="pub-date[@date-type='collection']">
        <xsl:call-template name="issued-date">
          <xsl:with-param name="pub-date" 
                          select="pub-date[@date-type='collection'][1]"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="pub-date[@date-type='epub' or @date-type='epubr']">
        <xsl:call-template name="issued-date">
          <xsl:with-param name="pub-date" 
                          select="pub-date[@date-type='epub' or @date-type='epubr'][1]"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
    
    <xsl:if test="@ahead-of-print = 'yes'">
      <s k='status'>
        <xsl:text>ahead-of-print</xsl:text>
      </s>
    </xsl:if>

    <xsl:apply-templates select="fpage|elocation-id"/>
    <xsl:apply-templates select="volume"/>
    <xsl:apply-templates select="issue"/>
    <xsl:if test="not(following-sibling::document-meta)">
      <xsl:call-template name="object-ids"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name='issued-date'>
    <xsl:param name="pub-date"/>
    <o k="issued">
      <xsl:call-template name='date-parts'>
        <xsl:with-param name="pub-date" select="$pub-date"/>
      </xsl:call-template>
    </o>
  </xsl:template>
  
  <xsl:template name='online-date'>
    <xsl:param name="pub-date"/>
    <o k="epub-date">
      <xsl:call-template name='date-parts'>
        <xsl:with-param name="pub-date" select="$pub-date"/>
      </xsl:call-template>
    </o>
  </xsl:template>
  
  <xsl:template name='date-parts'>
    <xsl:param name="pub-date"/>
    <a k="date-parts">
      <a>
        <xsl:apply-templates select="$pub-date/year"/>
        <xsl:apply-templates select="$pub-date/month"/>
        <xsl:apply-templates select="$pub-date/day"/>
      </a>
    </a>
  </xsl:template>

 
  <!--
    Output the accessed date.  If it was passed in as a parameter, use that.  Otherwise, use today's date.
  -->
  <xsl:template name="accessed">
    <xsl:variable name="date">
      <xsl:choose>
        <xsl:when test="$accessed != &quot;&quot;">
          <xsl:value-of select="$accessed"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="string(current-date())"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:analyze-string regex="^(\d+)(-(\d+)(-(\d+))?)?" select="$date">
      <xsl:matching-substring>
        <xsl:variable name="year" select="regex-group(1)"/>
        <xsl:variable name="month" select="regex-group(3)"/>
        <xsl:variable name="day" select="regex-group(5)"/>
        <o k="accessed">
          <a k="date-parts">
            <a>
              <n>
                <xsl:value-of select="number($year)"/>
              </n>
              <xsl:if test="$month != ''">
                <n>
                  <xsl:value-of select="number($month)"/>
                </n>
                <xsl:if test="$day != ''">
                  <n>
                    <xsl:value-of select="number($day)"/>
                  </n>
                </xsl:if>
              </xsl:if>
            </a>
          </a>
        </o>
      </xsl:matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:template match="year|month|day">
    <n>
      <xsl:value-of select="."/>
    </n>
  </xsl:template>

  <xsl:template match="fpage|elocation-id">
    <s k="page">
      <xsl:value-of select="."/>
      <xsl:if test="following-sibling::lpage and (string() != string(following-sibling::lpage))">
        <xsl:text>-</xsl:text>
        <xsl:value-of select="following-sibling::lpage"/>
      </xsl:if>
    </s>
  </xsl:template>

  <xsl:template match="volume|issue">
    <s>
      <xsl:attribute name="k">
        <xsl:value-of select="local-name(.)"/>
      </xsl:attribute>
      <xsl:value-of select="."/>
    </s>
  </xsl:template>

  <xsl:template name="object-ids">
    <xsl:choose>
      <xsl:when test="$pmid">
        <s k="PMID">
          <xsl:value-of select="$pmid"/>
        </s>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="object-id[@pub-id-type='pmid']"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="$pmcid">
        <s k="PMCID">
          <xsl:value-of select="$pmcid"/>
        </s>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="object-id[@pub-id-type='pmcid']"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="$doi">
        <s k="DOI">
          <xsl:value-of select="$doi"/>
        </s>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="object-id[@pub-id-type='doi']"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="isbn">
      <s k="ISBN">
        <xsl:value-of select="isbn"/>
      </s>
    </xsl:if>
  </xsl:template>

  <xsl:template match="object-id">
    <s>
      <xsl:attribute name="k" select="upper-case(@pub-id-type)"/>
      <xsl:value-of select="."/>
    </s>
  </xsl:template>

</xsl:stylesheet>
