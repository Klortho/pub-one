<?xml version="1.0"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:ncbi="http://www.ncbi.nlm.nih.gov"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="ncbi xs">

  <xsl:output method="xml" omit-xml-declaration="yes" indent="no"
    doctype-system="http://www.ncbi.nlm.nih.gov/staff/beck/pub-one/schemas/dtd/pub-one0.dtd"/>

  <xsl:include href="dates-and-strings.xsl"/>
  
  <xsl:param name="pmid" as="xs:string" select="''"/>
  <!-- 
    pmcid can either be numeric (in which case it is assumed to be a pmcid, and "PMC" is prepended)
    or of the canonical form like "PMC12345", "NBK12345".
  -->
  <xsl:param name="pmcid" as="xs:string" select="''"/>
  
  <!-- <xsl:param name="book_id" as="xs:string?" select="tokenize(base-uri(), '\.')[last()-1]"/>  -->
  <xsl:param name="book_id" as="xs:string?"/>

  <xsl:template match="/">
    <xsl:apply-templates select="article | PubmedArticle | PubmedArticleSet | book | book-part | book-part-wrapper"/>
  </xsl:template>

  <xsl:template match="PubmedArticleSet">
    <pub-one-record-set>
      <xsl:apply-templates select="PubmedArticle"/> 
    </pub-one-record-set>
  </xsl:template>
  
  <xsl:template match="*|@*|text()|processing-instruction()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="*|@*|text()|processing-instruction()"/>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="article">
    <pub-one-record record-type="article">
	 	<xsl:attribute name="xml:lang">
	 		<xsl:call-template name="get-lang">
				<xsl:with-param name="code" select="if (@xml:lang) then (normalize-space(@xml:lang)) else 'eng'"/>
				</xsl:call-template>
			</xsl:attribute>
      <xsl:call-template name="write-source-meta"/>
      <xsl:call-template name="write-document-meta"/>
    </pub-one-record>
  </xsl:template>
  
  <xsl:template match="book | book-part[@book-part-type='toc']">
    <pub-one-record record-type="book">
	 	<xsl:attribute name="xml:lang">
	 		<xsl:call-template name="get-lang">
				<xsl:with-param name="code" select="if (@xml:lang) then (normalize-space(@xml:lang)) else 'eng'"/>
				</xsl:call-template>
			</xsl:attribute>
      <xsl:call-template name="write-source-meta">
        <xsl:with-param name="abbreviated" select="'yes'"/>
        </xsl:call-template>
      <xsl:call-template name="repeat-source-meta-as-document-meta"/>
    </pub-one-record>
  </xsl:template>
  
  <xsl:template match="book-part[not(@book-part-type='toc')]">
    <pub-one-record record-type="{@book-part-type}">
	 	<xsl:attribute name="xml:lang">
	 		<xsl:call-template name="get-lang">
				<xsl:with-param name="code" select="if (@xml:lang) then (normalize-space(@xml:lang)) else 'eng'"/>
				</xsl:call-template>
			</xsl:attribute>
      <xsl:call-template name="write-source-meta"/>
      <xsl:call-template name="write-document-meta"/>
    </pub-one-record>
  </xsl:template>
  
  <xsl:template match="PubmedArticle">
    <pub-one-record record-type="article">
	 	<xsl:attribute name="xml:lang">
	 		<xsl:call-template name="get-lang">
				<xsl:with-param name="code" select="normalize-space(MedlineCitation/Article/Language[1])"/>
				</xsl:call-template>
			</xsl:attribute>
    <!-- TODO - map pubmed article types to @record-type -->
      <xsl:call-template name="write-source-meta"/>
      <xsl:call-template name="write-document-meta"/>
    </pub-one-record>
  </xsl:template>
  
  
  <xsl:template name="write-source-meta">
    <xsl:param name="abbreviated"/>
    <source-meta>
      <xsl:call-template name="write-source-meta-guts">
        <xsl:with-param name="metalevel" select="if ($abbreviated='yes') then 'abbreviated' else ''"/>
        </xsl:call-template>
    </source-meta>
  </xsl:template>

  <xsl:template name="repeat-source-meta-as-document-meta">
    <document-meta>
      <xsl:call-template name="write-source-meta-guts"/>
    </document-meta>
  </xsl:template>

<xsl:template name="write-source-meta-guts">
  <xsl:param name="metalevel"/>
      <!-- write <object-id> -->
      <xsl:apply-templates select="MedlineCitation/Article/Journal/ISOAbbreviation |
              MedlineCitation/MedlineJournalInfo/NlmUniqueId |
              MedlineCitation/MedlineJournalInfo/MedlineTA |
              MedlineCitation/MedlineJournalInfo/NlmUniqueID |
              front/journal-meta//journal-id[not(@journal-id-type='pubmed-jr-id') and not(@journal-id-type='issn')] "/>
      <xsl:choose>
        <xsl:when test="/book-part/@book-part-type='toc'">
          <xsl:call-template name="write-oids-from-params"/>
        </xsl:when>
        <xsl:when test="/book-part and $book_id != '' and $book_id != '0'">
          <object-id pub-id-type="pmcbookid">
            <xsl:value-of select="concat('NBK', $book_id)"/>
          </object-id>
        </xsl:when>
      </xsl:choose>
    
      <!-- write source title -->
      <xsl:apply-templates select="front/journal-meta/journal-title-group | 
              front/journal-meta/journal-title | 
              book-meta/book-title-group |
                                    MedlineCitation/Article/Journal/Title"/>
      <!--write issns -->
      <xsl:apply-templates select="front/journal-meta/issn | 
              front/journal-meta/issn-l | 
              MedlineCitation/Article/Journal/ISSN | 
              MedlineCitation/MedlineJournalInfo/ISSNLinking"/>
      
      <!-- write-isbns -->
      <xsl:apply-templates select="book-meta/isbn"/>

      <!-- write-contributors -->
      <xsl:apply-templates select="book-meta/contrib-group"/>
      
      <!-- write book publication details -->
      <xsl:apply-templates select="book-meta/pub-date"/>
      
      <!-- write publisher -->
      <xsl:apply-templates select="front/journal-meta/publisher | 
              book-meta/publisher"/>
      
      <xsl:apply-templates select="book-meta/edition"/>
      <xsl:apply-templates select="book-meta/volume"/>
      <xsl:apply-templates select="book-meta/history"/>
      <xsl:apply-templates select="book-meta/permissions"/>
      <xsl:if test="$metalevel!='abbreviated'">
        <xsl:apply-templates select="book-meta/abstract"/>
        </xsl:if>
      
      <!-- write subsections in <document-meta> -->
      <xsl:if test="self::book-part and /book-part/@book-part-type='toc' and body/list and $metalevel!='abbreviated'">
        <xsl:apply-templates select="body" mode="write-chapters"/>
        </xsl:if>
      
  </xsl:template>


  <xsl:template name="write-document-meta">
    <xsl:variable name="bookpartype" select="/book-part/@book-part-type"/>
    <document-meta>
      <xsl:if test='//processing-instruction(OLF)'>
        <ahead-of-print/>
      </xsl:if>

      <!-- write <object-id> -->
      <xsl:apply-templates select="PubmedData/ArticleIdList/ArticleId | MedlineCitation/OtherID[not(@Source='NLM')] |
              front/article-meta/article-id | 
              book-part-meta/book-part-id"/>
		<xsl:if test="PubmedData and not(PubmedData/ArticleIdList/ArticleId[@IdType='doi'])">
			<xsl:call-template name="get-pm-doi"/>
			</xsl:if>		  
      <!-- write article-ids from parameters pmid and pmcid -->
      <xsl:if test="self::article or self::book-part">
        <xsl:call-template name="write-oids-from-params"/>
      </xsl:if>


      <!-- write publication-types in subject-group -->
      <xsl:apply-templates select="MedlineCitation/Article/PublicationTypeList"/>

      <!-- write-document-title -->
      <xsl:apply-templates select="MedlineCitation/Article/ArticleTitle | 
              front/article-meta/title-group"/>

      <xsl:apply-templates select="book-part-meta/title-group/subtitle[@content-type=$bookpartype]" mode="doctitle"/>
      
      <!-- write-contrib-group -->
      <xsl:apply-templates select="front/article-meta/contrib-group | book-part-meta/contrib-group | 
              MedlineCitation/Article/AuthorList"/>
      <xsl:if test="not(MedlineCitation/Article/AuthorList//CollectiveName) and MedlineCitation/InvestigatorList">
        <xsl:apply-templates select="MedlineCitation/InvestigatorList"/>
      </xsl:if>
      
      <!-- write pub-dates -->
      <xsl:apply-templates select="front/article-meta/pub-date | book-part-meta/pub-date"/>
      <xsl:if test="self::PubmedArticle">
        <xsl:call-template name="build-pub-dates">
          <xsl:with-param name="PubModel">
            <xsl:choose>
              <xsl:when test="PubmedData/PublicationStatus='aheadofprint'">
                <xsl:text>Electronic</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="MedlineCitation/Article/@PubModel"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:if>
      
      <!-- write citation details -->
      <xsl:apply-templates select="front/article-meta/edition | front/article-meta/volume | front/article-meta/issue | front/article-meta/fpage | 
              front/article-meta/lpage | front/article-meta/elocation-id |
              book-part-meta/edition | book-part-meta/volume | book-part-meta/issue | book-part-meta/fpage | 
              book-part-meta/lpage | book-part-meta/elocation-id "/>
      
      <xsl:choose>
        <xsl:when test="contains(MedlineCitation/Article/Pagination/MedlinePgn,'Suppl')">
          <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/Volume"/>
          <!-- Processing for Part or Suppl is done inside the Volume template.
                This creates a duplicate issue tag.
                <xsl:call-template name="suppl-issue"/> -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/Volume"/>
          <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/Issue"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="MedlineCitation/Article/Pagination">
          <xsl:apply-templates select="MedlineCitation/Article/Pagination"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="get-elocid"/>
        </xsl:otherwise>
      </xsl:choose>
      
      <!-- write history -->
      <xsl:apply-templates select="front/article-meta/history | book-part-meta/history | PubmedData/History"/>
      <xsl:if test="not(PubmedData/History) and (MedlineCitation/DateCreated or MedlineCitation/DateCompleted or MedlineCitation/DateRevised)">
        <pub-history>
          <xsl:apply-templates select="MedlineCitation/DateCreated | MedlineCitation/DateCompleted | MedlineCitation/DateRevised"/>
        </pub-history>
      </xsl:if>
      
      <!-- write permissions -->
      <xsl:apply-templates select="front/article-meta/permissions | book-part-meta/permissions"/>
      <xsl:apply-templates select="MedlineCitation/Article/Abstract/CopyrightInformation"/>
      
      <!-- write related articles -->
      <xsl:call-template name="relart"/>
      <xsl:apply-templates select="front/article-meta/related-object | /article//related-article"/>
      
      <!-- write abstract(s) -->
      <xsl:apply-templates select="MedlineCitation/Article/Abstract | MedlineCitation/OtherAbstract | front/article-meta/abstract | front/article-meta/trans-abstract |
              book-part-meta/abstract"/>
      
      <xsl:if test="book-part-meta and not(book-part-meta/abstract) and body/sec[@sec-type='pubmed-excerpt']">
        <xsl:apply-templates select="body/sec[@sec-type='pubmed-excerpt']" mode="as-abstract"/>
      </xsl:if>
      
      <!-- write keyword groups : these include MESH headings and chemical lists -->
      <xsl:apply-templates select="MedlineCitation/ChemicalList | MedlineCitation/KeywordList | MedlineCitation/MeshHeadingList | MedlineCitation/GeneSymbolList |
        MedlineCitation/PersonalNameSubjectList | MedlineCitation/Article/DataBankList | MedlineCitation/SupplMeshList"/>
      <xsl:if test="MedlineCitation/SpaceFlightMission">
        <xsl:call-template name="write-space-flight-keywords"/>
        </xsl:if>
      
      <!-- write article language(s) -->
      <!-- context node = PubmedArticle or article or book-part -->
      <xsl:call-template name="write-languages"/>
      
      <!-- write funding information -->
      <xsl:apply-templates select="front/article-meta/funding-group | MedlineCitation/Article/GrantList"/>
      
		<custom-meta-group>
			<xsl:if test="PubmedData/PublicationStatus">
				<custom-meta>
					<meta-name>PublicationStatus</meta-name>
					<meta-value>
						<xsl:value-of select="PubmedData/PublicationStatus"/>
					</meta-value>
				</custom-meta>
				</xsl:if>
			<custom-meta>
 				<meta-name>MedlineCitation-Status</meta-name>
				<meta-value><xsl:value-of select="MedlineCitation/@Status"/></meta-value>
			</custom-meta>
			<custom-meta>
				<meta-name>MedlineCitation-Owner</meta-name>
				<meta-value><xsl:value-of select="MedlineCitation/@Owner"/></meta-value>
			</custom-meta>
			<!-- write citationsubset in custom-meta -->
      	<xsl:apply-templates select="MedlineCitation/CitationSubset"/>
		</custom-meta-group>
      
      <!-- write cited articles -->
      <xsl:apply-templates select="MedlineCitation/CommentsCorrectionsList" mode="cited"/>
      
      <!--- write general notes from pubmed -->
      <xsl:apply-templates select="MedlineCitation/GeneralNote"/>
      
      
      <!-- write subsections -->
      <xsl:if test="self::book-part and body/sec">
        <xsl:apply-templates select="body" mode="write-sections"/>
        </xsl:if>
      
    </document-meta>
  </xsl:template>

<!-- JATS-specific templates -->
  <xsl:template match="journal-id">
    <object-id pub-id-type="{@journal-id-type}">
      <xsl:value-of select="if (.='PLoS ONE' and @journal-id-type='nlm-ta') then 'PLoS One' else ."/>
    </object-id>
  </xsl:template> 
  
  <xsl:template match="journal-title-group ">
    <title-group>
      <xsl:apply-templates/>
    </title-group>  
  </xsl:template> 

  <xsl:template match="journal-title[parent::journal-title-group] | article-title[parent::title-group]">
    <title>
      <xsl:apply-templates/>
    </title>
  </xsl:template>
  
  <xsl:template match="journal-subtitle">
    <subtitle>
      <xsl:apply-templates/>
    </subtitle>
  </xsl:template>
  
  <xsl:template match="trans-title[parent::title-group | parent::book-title-group]">
    <trans-title-group>
      <trans-title>
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates/>
        <xsl:apply-templates select="following-sibling::trans-subtitle" mode="wrap-trans"/>
      </trans-title>
    </trans-title-group>
    </xsl:template>

  <xsl:template match="trans-subtitle[parent::title-group]"/>
  
  <xsl:template match="trans-subtitle" mode="wrap-trans">
    <trans-subtitle>
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates/>
        <xsl:apply-templates select="following-sibling::trans-subtitle" mode="wrap-trans"/>
    </trans-subtitle>
    </xsl:template>
  
  <xsl:template match="journal-title[parent::journal-meta]">
    <title-group>
      <title><xsl:apply-templates/></title>
    </title-group>
  </xsl:template>
  
  <xsl:template match="issn[@pub-type]">
    <issn publication-format="{if (@pub-type='ppub') then 'print' else 'electronic'}">
      <xsl:apply-templates/>
    </issn>
  </xsl:template>
  
  <xsl:template match="article-id">
    <xsl:if test='@pub-id-type != "pmid" or not($pmid) or not($pmid = "0")'>
      <object-id pub-id-type="{@pub-id-type}">
        <xsl:apply-templates/>
      </object-id>
    </xsl:if>
  </xsl:template>

  <!-- <xsl:template match="article-id[@pub-id-type='pmid']">
    <object-id pub-id-type="pubmed">
      <xsl:apply-templates/>
      </object-id>
  </xsl:template> -->

  <xsl:template match="article-id[@pub-id-type='doi']">
 		<xsl:variable name="pmc-doi">
			<xsl:variable name="d1c">
				<xsl:call-template name="clean-doi">
					<xsl:with-param name="str" select="normalize-space(/article/front/article-meta/article-id[@pub-id-type='doi'])"/>
					</xsl:call-template>
				</xsl:variable>
			<xsl:variable name="d1">
				<xsl:call-template name="doi-format-test">
					<xsl:with-param name="doi" select="$d1c"/>
					</xsl:call-template>
				</xsl:variable>
			<xsl:if test="$d1='true'">
				<xsl:value-of select="$d1c"/>
			 </xsl:if>
			</xsl:variable>
  		<xsl:if test="normalize-space($pmc-doi)">
      	<object-id pub-id-type="doi">
        		<xsl:value-of select="$pmc-doi"/>
      	</object-id>
			</xsl:if>
		</xsl:template>
  
  
  
  <xsl:template match="article-id[@pub-id-type='manuscript']">
    <object-id pub-id-type="manuscript-id">
      <xsl:value-of select="translate(.,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
      </object-id>
  </xsl:template>


  <xsl:template name="write-oids-from-params">
    <!--<xsl:message> got here! pmcid="<xsl:value-of select="$pmcid"/>" | pmid="<xsl:value-of select="$pmid"/>"</xsl:message>-->
    <xsl:if test="$pmcid != ''">
      <xsl:choose>
        <xsl:when test="number($pmcid) and /article">
          <object-id pub-id-type="pmcid">
            <xsl:value-of select="concat('PMC', $pmcid)"/>
          </object-id>
        </xsl:when>
        <xsl:when test="number($pmcid) and (/book or /book-part)">
          <object-id pub-id-type="pmcbookid">
            <xsl:value-of select="concat('NBK', $pmcid)"/>
          </object-id>
        </xsl:when>
        <xsl:when test="starts-with($pmcid, 'PMC')">
          <object-id pub-id-type="pmcid">
            <xsl:value-of select="$pmcid"/>
          </object-id>
        </xsl:when>
        <xsl:otherwise>
          <object-id pub-id-type="pmcbookid">
            <xsl:value-of select="$pmcid"/>
          </object-id>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="$pmid!='' and $pmid != '0'">
      <object-id pub-id-type="pmid">
        <xsl:value-of select="$pmid"/>
      </object-id>
    </xsl:if>
  </xsl:template>

  <xsl:template match="contrib-group">
   <contrib-group>
      <xsl:apply-templates select="* except aff[@id]"/>
    </contrib-group>
    </xsl:template>
  
  <xsl:template match="contrib[@rid]">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="*|@*|text()|processing-instruction()"/>
      <xsl:variable name="RID" select="@rid"/>
      <xsl:choose>
        <xsl:when test="parent::contrib-group/parent::collab">
          <xsl:choose>
            <xsl:when test="$RID=ancestor::contrib/@id"/>
            <xsl:otherwise>
              <xsl:if test="not(parent::article-title)">
                <xsl:apply-templates select="/descendant::node()[@id=$RID]"/>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="not(parent::article-title)">
          <xsl:apply-templates select="/descendant::node()[@id=$RID]"/>
        </xsl:when>       
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="given-names">
    <given-names>
      <xsl:attribute name="initials">
        <xsl:choose>
          <xsl:when test="@initials">
            <xsl:value-of select="@initials"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="ncbi:get-initials(normalize-space(.))"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates/>
    </given-names>
  </xsl:template>
  
  <xsl:template match="name[surname/xref[@ref-type='aff' or @ref-type='corresp']]">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="*|@*|text()|processing-instruction()"/>
    </xsl:copy>
    <xsl:apply-templates select="surname/xref[@ref-type='aff' or @ref-type='corresp']">
      <xsl:with-param name="write-out" select="'yes'"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="xref[@ref-type='aff' or @ref-type='corresp']">
    <xsl:param name="write-out"/>
    <xsl:variable name="RID" select="@rid"/>    
    <xsl:choose>
      <xsl:when test="parent::surname">
        <xsl:if test="$write-out='yes'">
          <xsl:apply-templates select="descendant::node()[@id=$RID]"/>
        </xsl:if>
      </xsl:when>
      <xsl:when test="//target[@id=$RID]">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*|*|processing-instruction()"/>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="not(ancestor::article-title) and not(parent::p) and not(parent::aff[@id=$RID])">
        <xsl:apply-templates select="descendant::node()[@id=$RID] | following::node()[@id=$RID]"/>
      </xsl:when>
    </xsl:choose>
    
  </xsl:template>

  <xsl:template match="xref[not(@ref-type) or (@ref-type!='aff' and @ref-type!='corresp')] | 
        label"/>
        

  <xsl:template match="aff/@id | aff/@rid | aff-alternatives/@id | contrib/@rid | author-notes/fn/@id | aff/fn/@id | p/@id | mml:math/@name"/>
  
  <xsl:template match="collab/named-content">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="address">
    <xsl:choose>
	 	<xsl:when test="email and parent::contrib">
			<xsl:apply-templates select="email"/>
			<xsl:if test="*[not(self::email)]">
				<address>
					<xsl:apply-templates select="* except email"/>
				</address>
				</xsl:if>
			</xsl:when>
		<xsl:otherwise>
			<address>
				<xsl:apply-templates/>
			</address>
			</xsl:otherwise>
	 	</xsl:choose>
  </xsl:template>

  <xsl:template match="corresp">
    <fn fn-type="corresp">
      <p><xsl:apply-templates/></p>
    </fn>
  </xsl:template>
  
  <xsl:template match="corresp/break">
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="p[parent::license]">
    <license-p>
      <xsl:apply-templates/>
    </license-p>
    </xsl:template>

  <xsl:template match="phone[parent::corresp] | fax[parent::corresp] | addr-line[parent::corresp] |
    country[parent::corresp] | institution[parent::corresp]">
    <xsl:apply-templates/>
    </xsl:template>

  <xsl:template match="history">
    <xsl:if test="date">
      <pub-history>
        <xsl:apply-templates/>
      </pub-history>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="boxed-text/title">
    <caption>
      <title><xsl:apply-templates/></title>
    </caption>
  </xsl:template>
  
  <xsl:template match="citation">
    <mixed-citation>
      <xsl:apply-templates select="@id, @citation-type"/>
      <xsl:apply-templates select="*|text()"/>
    </mixed-citation>
  </xsl:template>
  
  <xsl:template match="@citation-type">
    <xsl:attribute name="publication-type">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="font">
    <styled-content style="{concat('font-color:',@color)}">
      <xsl:apply-templates/>
    </styled-content>
  </xsl:template>
  
  <xsl:template match="target[not(@id)]">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="graphic">
    <xsl:choose>
      <xsl:when test="@alt-version='no' or not(@alt-version)">        
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="*|@*|text()|processing-instruction()"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <FAIL/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@alt-version"/>
  
  <xsl:template match="inline-formula[inline-graphic[@alternate-form-of]]">
    <xsl:variable name="alt-form-id" select="inline-graphic/@alternate-form-of"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="*[not(self::inline-graphic[@alternate-form-of]) and not(self::*/@id=$alt-form-id)]|@*|text()|processing-instruction()"/>
      <alternatives>
        <xsl:apply-templates select="inline-graphic[@alternate-form-of] | *[@id=$alt-form-id]"/>
      </alternatives>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="on-behalf-of[xref[@ref-type='aff']]">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="*[not(self::xref[@ref-type='aff'])]|@*|text()|processing-instruction()"/>
    </xsl:copy>
    <xsl:apply-templates select="xref[@ref-type='aff']"/>
  </xsl:template>

  


<!--PMC-book-specific templates -->
  <xsl:template match="book-id">
    <object-id pub-id-type="{@pub-id-type}">
      <xsl:value-of select="."/>
    </object-id>
  </xsl:template> 
  
  
  <xsl:template match="@indexed | @alternate-form-of"/>
      
  <xsl:template match="book-title-group ">
    <title-group>
      <xsl:apply-templates/>
    </title-group>  
  </xsl:template> 
  
  <xsl:template match="book-title ">
    <title>
      <xsl:apply-templates/>
    </title>  
  </xsl:template> 
  
  
  <xsl:template match="pub-date">
    <pub-date date-type="{if (@publication-format='electronic') then 'epub' else
	                       (if (@publication-format='print') then 'ppub' else
								   (if (@date-type) then (@date-type) else (@pub-type)))}">
      <xsl:attribute name="iso-8601-date">
        <xsl:call-template name="build-iso-date">
          <xsl:with-param name="year" select="year"/>
          <xsl:with-param name="month" select="month"/>
          <xsl:with-param name="day" select="day"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates/>
    </pub-date>
  </xsl:template> 
  
  
  <xsl:template match="date">
    <date date-type="{if (@date-type) then (@date-type) else (@pub-type)}">
      <xsl:attribute name="iso-8601-date">
        <xsl:call-template name="build-iso-date">
          <xsl:with-param name="year" select="year"/>
          <xsl:with-param name="month" select="month"/>
          <xsl:with-param name="day" select="day"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates/>
    </date>
  </xsl:template> 
  
  
  <xsl:template match="subtitle" mode="doctitle">
    <title-group>
      <title><xsl:apply-templates/></title>
    </title-group>
  </xsl:template> 
  
  <xsl:template match="sec[@sec-type='pubmed-excerpt']" mode="as-abstract">
    <abstract>
      <xsl:apply-templates/> 
    </abstract>
  </xsl:template>
  
  <xsl:template match="body" mode="write-sections">
    <xsl:variable name="sid" select="/book-part/book-meta/book-id[@pub-id-type='pmcid']"/>
    <xsl:variable name="did" select="/book-part/@id"/>
    <notes notes-type="sections">
      <xsl:for-each select="sec">
        <sec id="{concat($sid,'__',$did,'__',@id)}">
          <xsl:apply-templates select="title"/>
        </sec>
        </xsl:for-each>
    </notes>
    </xsl:template> 
  
  <xsl:template match="body" mode="write-chapters">
    <xsl:variable name="sid" select="/book-part/book-meta/book-id[@pub-id-type='pmcid']"/>
    <notes notes-type="sections">
      <xsl:apply-templates select="list" mode="write-chapters"/>
    </notes>
    </xsl:template> 
  
  <xsl:template match="list" mode="write-chapters">
    <xsl:apply-templates select="list-item" mode="write-chapters"/>
    </xsl:template>
  
  <xsl:template match="list-item" mode="write-chapters">
    <sec id="{if (p/@id) then (concat(/book-part/book-meta/book-id[@pub-id-type='pmcid'],'__',p/@id)) else (concat(/book-part/book-meta/book-id[@pub-id-type='pmcid'],'__',p/related-object/@document-id))}">
      <xsl:apply-templates select="p/related-object/named-content[@content-type='label']" mode="write-chapters"/>
      <title><xsl:value-of select="p/related-object/text()"/></title>
      <xsl:if test="p/related-object[@document-type='part']">
        <xsl:apply-templates select="list" mode="write-chapters"/>
        </xsl:if>
    </sec>
    </xsl:template>
  
  <xsl:template match="named-content[@content-type='label']" mode="write-chapters">
    <label><xsl:apply-templates/></label>
    </xsl:template>
    
  <xsl:template match="ext-link[@qualifier]/@xlink:href">
    <xsl:attribute name="xlink:href" select="concat(../@qualifier, ':', .)"/>
  </xsl:template>
  
  <xsl:template match="ext-link/@qualifier"/>
  
  <xsl:template match="isbn/@pub-type">
    <xsl:attribute name="publication-format" select="."/>
  </xsl:template>
  
  <xsl:template match="book-part-meta/elocation-id">
    <!-- for some historic reason it's the book-part-id and that's really not helpful -->
  </xsl:template>
  
  <xsl:template match="multi-link">
    <xsl:apply-templates select="term/node()"/>   
  </xsl:template>
  
  <xsl:template match="map-group">
    <xsl:apply-templates select="graphic"/>   
  </xsl:template>
  








    

<!-- PubMed-Specific templates -->
  <xsl:template match="ISOAbbreviation">
    <object-id pub-id-type="iso-abbrev">
      <xsl:value-of select="."/>
    </object-id>
  </xsl:template> 
  
  <xsl:template match="MedlineTA">
    <object-id pub-id-type="nlm-ta">
      <xsl:value-of select="."/>
    </object-id>
  </xsl:template> 
  
  <xsl:template match="NlmUniqueID">
    <object-id pub-id-type="nlm-journal-id">
      <xsl:value-of select="."/>
    </object-id>
  </xsl:template> 
  
  <xsl:template match="Title">
    <title-group>
      <title><xsl:value-of select="."/></title>
    </title-group>
  </xsl:template> 
  
  <xsl:template match="ArticleTitle">
    <title-group>
      <xsl:choose>
        <xsl:when test="(starts-with(normalize-space(),'[') and (ends-with(normalize-space(),']') or ends-with(normalize-space(),'].'))) and count(following-sibling::Language) = 1 and following-sibling::VernacularTitle">
          <!-- vernacular title is article title . article title is english version -->
          <title><xsl:apply-templates select="following-sibling::VernacularTitle"/></title>
          <trans-title-group xml:lang="en">
            <trans-title>
              <xsl:apply-templates select="self::node()" mode="trans-title"/>
            </trans-title>
            </trans-title-group>
        </xsl:when>
        <xsl:otherwise>
          <title><xsl:value-of select="."/></title>
          <xsl:for-each select="following-sibling::VernacularTitle">
            <trans-title-group>
              <trans-title>
                <xsl:call-template name="find-lang"/>
                <xsl:apply-templates/>
              </trans-title>
            </trans-title-group>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose> 
      
    </title-group>
  </xsl:template> 
 
 <xsl:template match="VernacularTitle">
 	<xsl:choose>
		<xsl:when test="ends-with(.,'.')">
			<xsl:value-of select="substring(.,1,string-length()-1)"/>
			</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates/>
			</xsl:otherwise>
 		</xsl:choose>
 	</xsl:template>
 
<xsl:template match="ArticleTitle" mode="trans-title">
	<xsl:variable name="txt" select="translate(normalize-space(),'[]','')" as="xs:string"/>
 	<xsl:choose>
		<xsl:when test="ends-with($txt,'.')">
			<xsl:value-of select="substring($txt,1,string-length($txt)-1)"/>
			</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$txt"/>
			</xsl:otherwise>
 		</xsl:choose>
		
	</xsl:template>

  
  <xsl:template name="find-lang">
    <xsl:variable name="vtno" select="count(preceding-sibling::VernacularTitle) + 1"/>
    <xsl:if test="/descendant::Language[position()=$vtno + 1]">
	 	<xsl:attribute name="xml:lang">
	 		<xsl:call-template name="get-lang">
				<xsl:with-param name="code" select="normalize-space(/descendant::Language[position()=$vtno + 1])"/>
				</xsl:call-template>
			</xsl:attribute>
    </xsl:if>
    </xsl:template>


  
  <xsl:template match="ISSNLinking">
    <issn-l><xsl:apply-templates/></issn-l>
  </xsl:template>
  
  <xsl:template match="ISSN">
    <issn publication-format="{lower-case(@IssnType)}"><xsl:apply-templates/></issn>
  </xsl:template>
  
  <xsl:template match="PMID">
    <object-id pub-id-type="pmid"><xsl:comment>Boo</xsl:comment>
      <xsl:apply-templates/>
    </object-id>
  </xsl:template>
  
  <xsl:template match="ArticleId[@IdType!='doi']">
    <object-id pub-id-type="{if (@IdType='mid') then 'manuscript-id' else (if (@IdType='pubmed') then 'pmid' else (if (@IdType='pmc') then 'pmcid' else @IdType))}">
      <xsl:apply-templates/>
    </object-id>
  </xsl:template>


	<xsl:template match="ArticleId[@IdType='doi']" name="get-pm-doi">
		<xsl:variable name="article-doi">
			<xsl:variable name="pm-ArticleId">
				<xsl:variable name="d2c">
					<xsl:call-template name="clean-doi">
						<xsl:with-param name="str" select="normalize-space()"/>
						</xsl:call-template>
					</xsl:variable>
				<xsl:variable name="d2">
					<xsl:call-template name="doi-format-test">
						<xsl:with-param name="doi" select="$d2c"/>
						</xsl:call-template>
					</xsl:variable>
				<xsl:if test="$d2='true'">
					<xsl:value-of select="$d2c"/>
			 		</xsl:if>
				</xsl:variable>
			<xsl:variable name="pm-elocdoi">
				<xsl:variable name="d3c">
					<xsl:call-template name="clean-doi">
						<xsl:with-param name="str" select="normalize-space(ancestor-or-self::PubmedArticle/MedlineCitation/Article/ELocationID[@EIdType='doi' and not(@ValidYN='N')])"/> 
						</xsl:call-template>
					</xsl:variable>
				<xsl:variable name="d3">
					<xsl:call-template name="doi-format-test">
						<xsl:with-param name="doi" select="$d3c"/>
						</xsl:call-template>
					</xsl:variable>
				<xsl:if test="$d3='true'">
					<xsl:value-of select="$d3c"/>
			 	</xsl:if>
				</xsl:variable>
			<xsl:choose>
				<xsl:when test="normalize-space($pm-ArticleId) and normalize-space($pm-elocdoi)">
					<xsl:if test="$pm-ArticleId=$pm-elocdoi">
						<xsl:value-of select="$pm-ArticleId"/>
						</xsl:if>
					</xsl:when>
				<xsl:when test="normalize-space($pm-ArticleId)">
					<xsl:value-of select="$pm-ArticleId"/>
					</xsl:when>
				<xsl:when test="normalize-space($pm-elocdoi)">
					<xsl:value-of select="$pm-elocdoi"/>
					</xsl:when>
				</xsl:choose>
				<!--<xsl:message>self="<xsl:value-of select="name()"/> | pm-ArticleId="<xsl:value-of select="$pm-ArticleId"/>" | pm-elocdoi="<xsl:value-of select="$pm-elocdoi"/>"</xsl:message> -->
			</xsl:variable>
		
  		<xsl:if test="normalize-space($article-doi)">
			<object-id pub-id-type="doi">
  				<xsl:value-of select="$article-doi"/>
			</object-id>
			</xsl:if>
		</xsl:template>
	
  <xsl:template match="PublicationTypeList">
    <subj-group subj-group-type="publication-type">
      <xsl:for-each select="PublicationType">
        <subject><xsl:apply-templates/></subject>
      </xsl:for-each>
    </subj-group>
  </xsl:template>
  
  
  <xsl:template match="AuthorList">
    <contrib-group>
      <xsl:apply-templates select="Author[@ValidYN='Y'] | Author[not(@ValidYN)]"/>
    </contrib-group>
  </xsl:template>
  
  <xsl:template match="InvestigatorList">
    <contrib-group>
      <xsl:apply-templates select="Investigator[@ValidYN='Y'] | Investigator[not(@ValidYN)]"/>
    </contrib-group>
  </xsl:template>
  
  <xsl:template match="Author | Investigator">
    <contrib contrib-type="{lower-case(local-name())}">
      <xsl:apply-templates select="Identifier"/>
      <xsl:choose>
        <xsl:when test="CollectiveName">
          <xsl:apply-templates select="CollectiveName"/>
          </xsl:when>
        <xsl:otherwise>
          <name><xsl:apply-templates select="LastName, ForeName, Initials, Suffix"/></name>
          </xsl:otherwise>
        </xsl:choose>
      <xsl:apply-templates select="Affiliation | AffiliationInfo"/>
    </contrib>
  </xsl:template>
  
  <xsl:template match="LastName">
    <surname>
      <xsl:apply-templates/>
    </surname>
  </xsl:template>
  
  <xsl:template match="Identifier">
    <contrib-id contrib-id-type='{lower-case(@Source)}'>
	 <xsl:choose>
      <xsl:when test="@Source='ORCID'">
			<xsl:call-template name="clean-orcid">
				<xsl:with-param name="str" select="normalize-space()"/>
				</xsl:call-template>
       </xsl:when>
		<xsl:otherwise>
      <xsl:apply-templates/>
		</xsl:otherwise>
		</xsl:choose>
    </contrib-id>
  </xsl:template>
  
  <xsl:template match="contrib-id">
    <contrib-id contrib-id-type='{lower-case(@contrib-id-type)}'>
	 	<xsl:choose>
      	<xsl:when test="lower-case(@contrib-id-type)='orcid'">
				<xsl:call-template name="clean-orcid">
					<xsl:with-param name="str" select="normalize-space()"/>
					</xsl:call-template>
       		</xsl:when>
			<xsl:otherwise>
      		<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
    </contrib-id>
  	</xsl:template>
  
  <xsl:template name="clean-orcid">
  	<xsl:param name="str"/>
	<xsl:if test="$str">
		<xsl:choose>
			<xsl:when test="contains($str,'orcid.org/')">
				<xsl:call-template name="clean-orcid">
					<xsl:with-param name="str" select="substring-after($str,'orcid.org/')"/>
					</xsl:call-template>
				</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$str"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		</xsl:template>	
  
  
  
  
  
  <xsl:template match="AffiliationInfo">
      <xsl:apply-templates/>
  </xsl:template>
  
   <xsl:template match="Affiliation">
    <aff>
      <xsl:apply-templates/>
    </aff>
  </xsl:template>
  
  <xsl:template match="ForeName">
    <given-names>
      <xsl:attribute name="initials">
        <xsl:choose>
          <xsl:when test="following-sibling::Initials">
            <xsl:value-of select="following-sibling::Initials"/>
            </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="ncbi:get-initials(normalize-space(.))"/>
          </xsl:otherwise>
      </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates/>
    </given-names>
  </xsl:template>
  
  <xsl:template match="Initials">
  	<xsl:if test="not(preceding-sibling::ForeName)">
    	<given-names initials="{.}">
       	<xsl:apply-templates/>
    	</given-names>
		</xsl:if>
  </xsl:template>
  
   <xsl:template match="Suffix">
    <suffix>
      <xsl:apply-templates/>
    </suffix>
  </xsl:template>
  
 
  <xsl:template name="build-pub-dates">
    <xsl:param name="PubModel"/>
    <xsl:choose>
      <xsl:when test="$PubModel='Print'">
        <pub-date date-type="ppub">
          <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/PubDate"/>
        </pub-date>
      </xsl:when>
      <xsl:when test="$PubModel='Print-Electronic' and MedlineCitation/Article/ArticleDate[@DateType='Electronic']">
        <pub-date date-type="ppub">
          <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/PubDate"/>
        </pub-date>
        <pub-date date-type="epub">
          <xsl:apply-templates select="MedlineCitation/Article/ArticleDate[@DateType='Electronic']"/>
        </pub-date>
      </xsl:when>
      <xsl:when test="$PubModel='Electronic-Print'">
        <pub-date date-type="collection">
          <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/PubDate"/>
        </pub-date>
        <pub-date date-type="epub">
          <xsl:apply-templates select="MedlineCitation/Article/ArticleDate[@DateType='Electronic']"/>
        </pub-date>
      </xsl:when>
      <xsl:when test="$PubModel='Electronic'">
        <xsl:choose>
          <xsl:when test="MedlineCitation/Article/ArticleDate[@DateType='Electronic']">
            <pub-date date-type="epub">
              <xsl:apply-templates select="MedlineCitation/Article/ArticleDate[@DateType='Electronic']"/>
            </pub-date>
          </xsl:when>
          <xsl:otherwise>
            <pub-date date-type="epub">
              <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/PubDate/Day"/>
              <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/PubDate/Month"/>
              <xsl:apply-templates select="MedlineCitation/Article/Journal//JournalIssue/PubDate/Year"/>
            </pub-date>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <xsl:when test="$PubModel='Electronic-eCollection'">
        <pub-date date-type="collection">
          <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/PubDate"/>
        </pub-date>
        <pub-date date-type="epub">
          <xsl:apply-templates select="MedlineCitation/Article/ArticleDate[@DateType='Electronic']"/>
        </pub-date>
      </xsl:when>
      
      <xsl:when test="not(attribute::PubModel)">
        <pub-date date-type="ppub">
          <xsl:apply-templates select="MedlineCitation/Article/Journal/JournalIssue/PubDate"/>
        </pub-date>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  
<!--  <xsl:template match="PubDate | ArticleDate">
    <xsl:choose>
      <xsl:when test="MedlineDate">
        <xsl:apply-templates select="MedlineDate"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="dateguts"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> 
-->

  <!-- Construct pub-date - context = /PubmedArticleSet/PubmedArticle/MedlineCitation -->
  <xsl:template match="PubDate | ArticleDate">
    <xsl:choose>
      <xsl:when test="Year">
        <xsl:call-template name="dateguts"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains(MedlineDate,'-')">
            <!-- if date spans years, parse beginning date and 
            put entire date in string-date -->
            <xsl:variable name="created" select="ancestor::PubmedArticle/MedlineCitation/DateCreated/Year"/>
            <xsl:variable name="plus" select="string(number($created) + 1)"/>
            <xsl:variable name="minus" select="string(number($created)- 1)"/>
            <xsl:choose>
              <xsl:when test="contains(substring-after(MedlineDate,'-'),$created)
                or contains(substring-after(MedlineDate,'-'),$plus)
                or contains(substring-after(MedlineDate,'-'),$minus)">
                <xsl:call-template name="get-date-from-string">
                  <xsl:with-param name="date" select="substring-before(MedlineDate,'-')"/>
                </xsl:call-template>
                <string-date><xsl:value-of select="MedlineDate"/></string-date>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="get-date-from-string">
                  <xsl:with-param name="date" select="MedlineDate"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="get-date-from-string">
              <xsl:with-param name="date" select="MedlineDate"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  











  <xsl:template match="History">
    <pub-history>
      <xsl:apply-templates select="/PubmedArticle/MedlineCitation/DateCreated | /PubmedArticle/MedlineCitation/DateCompleted | /PubmedArticle/MedlineCitation/DateRevised"></xsl:apply-templates>
      <xsl:apply-templates/>
    </pub-history>
  </xsl:template>
  
  <xsl:template match="PubMedPubDate">
    <xsl:if test="number(Year)">
      <date date-type="{@PubStatus}">
        <xsl:call-template name="dateguts"/>
      </date>
      </xsl:if>
  </xsl:template>
  
  <xsl:template match="DateCreated">
    <date date-type="MEDLINE-created">
      <xsl:call-template name="dateguts"/>
    </date>
  </xsl:template>
  
  <xsl:template match="DateCompleted">
    <date date-type="MEDLINE-completed">
      <xsl:call-template name="dateguts"/>
    </date>
  </xsl:template>
  
  <xsl:template match="DateRevised">
    <date date-type="MEDLINE-revised">
      <xsl:call-template name="dateguts"/>
    </date>
  </xsl:template>
  
  <xsl:template name="dateguts">
    <xsl:variable name="mo" select="ncbi:month-name-to-number(Month)"/>
    <xsl:variable name="da" select="if (number(Day)) then (Day) else 0"/>
    <xsl:attribute name="iso-8601-date">
      <xsl:call-template name="build-iso-date">
        <xsl:with-param name="day" select="$da"/>
        <xsl:with-param name="month" select="$mo"/>
        <xsl:with-param name="year" select="Year"/>
        <xsl:with-param name="hour" select="if (Hour) then (Hour) else 0" as="xs:double"/>
        <xsl:with-param name="minute" select="if (Minute) then (Minute) else 0" as="xs:double"/>
        <xsl:with-param name="second" select="if (Second) then (Second) else 0" as="xs:double"/>
      </xsl:call-template>
    </xsl:attribute>
    <xsl:apply-templates select="Day"/>
    <xsl:apply-templates select="Month"/>
    <xsl:apply-templates select="Year"/>
  </xsl:template>


  <xsl:template match="Day | day">
    <xsl:if test="normalize-space()">
      <day>
        <xsl:value-of select="number()"/>
      </day>
      </xsl:if>
  </xsl:template> 
  
  <xsl:template match="month">
    <month>
      <xsl:choose>
        <xsl:when test="number()">
          <xsl:value-of select="number()"/>
          </xsl:when>
        <xsl:otherwise>
          <xsl:value-of  select="ncbi:month-name-to-number(.)"/>
          </xsl:otherwise>
        </xsl:choose>
    </month>
  </xsl:template> 
  
  <xsl:template match="volume | issue">
    <xsl:element name="{local-name()}">
      <xsl:value-of select="if (number()) then (number()) else ."/>
    </xsl:element>
  </xsl:template> 
  
  <xsl:template match="Month">
    <xsl:if test="normalize-space()">
      <month>
        <xsl:value-of  select="ncbi:month-name-to-number(.)"/>
      </month>
      </xsl:if>
  </xsl:template> 
  <xsl:template match="Year">
    <year>
      <xsl:apply-templates/>
    </year>
  </xsl:template> 
  
  <xsl:template match="Volume">
    <volume>
      <xsl:apply-templates/>
    </volume>
  </xsl:template> 
  
  <xsl:template match="Issue">
    <issue>
      <xsl:apply-templates/>
    </issue>
  </xsl:template> 
  
  <xsl:template match="Pagination">
    
    <xsl:choose>
      <xsl:when test="StartPage">
        <xsl:apply-templates select="StartPage|EndPage"/>
      </xsl:when>
      <xsl:when test="not(descendant::text()) and following-sibling::ELocationID">
        <elocation-id>
          <xsl:value-of select="following-sibling::ELocationID"/>
        </elocation-id>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="MedlinePgn"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="StartPage">
    
    <fpage>
      <xsl:apply-templates/>
    </fpage>
    <xsl:choose>
      <xsl:when test="following-sibling::EndPage"/>
      <xsl:otherwise>
        <lpage><xsl:apply-templates/></lpage>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="EndPage">
    
    <lpage>
      <xsl:apply-templates/>
    </lpage>
  </xsl:template>
  
  <xsl:template match="MedlinePgn">
    <xsl:variable name="pgn">
	 	<xsl:choose>
			<xsl:when test="contains(.,'--')">
				<xsl:call-template name="cleanPgn">
					<xsl:with-param name="str" select="."/>
					</xsl:call-template>
				</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
	 	</xsl:variable>
    
    <xsl:choose>
      <xsl:when test="contains(lower-case($pgn),'suppl:')">
        <xsl:call-template name="fpage">
          <xsl:with-param name="pagestring" select="substring-after(lower-case($pgn),'suppl:')"/>
        </xsl:call-template>
        <xsl:call-template name="lpage">
          <xsl:with-param name="pagestring" select="substring-after(lower-case($pgn),'suppl:')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains(lower-case($pgn),'suppl ')">
        <xsl:choose>
          <!-- <MedlinePgn>Suppl 1:9-14</MedlinePgn> -->
          <xsl:when test="contains(substring-after(lower-case($pgn),'suppl '),':')">
            <xsl:call-template name="fpage">
              <xsl:with-param name="pagestring" select="substring-after($pgn,':')"/>
            </xsl:call-template>
            <xsl:call-template name="lpage">
              <xsl:with-param name="pagestring" select="substring-after($pgn,':')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="fpage">
              <xsl:with-param name="pagestring" select="substring-after(lower-case($pgn),'suppl ')"/>
            </xsl:call-template>
            <xsl:call-template name="lpage">
              <xsl:with-param name="pagestring" select="substring-after(lower-case($pgn),'suppl ')"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains($pgn,'-') and contains(substring-after($pgn,'-'),'-') and contains(substring-after($pgn,'-'),',')">
		<!-- <MedlinePgn>163-6,171-7</MedlinePgn> pmid="636101" -->
			<fpage>
				<xsl:value-of select="substring-before($pgn,'-')"/>
			</fpage>
         <xsl:call-template name="lpage">
				<xsl:with-param name="pagestring" select="normalize-space(substring-after($pgn,','))"/>
				</xsl:call-template>
			<page-range><xsl:value-of select="$pgn"/></page-range>
			</xsl:when>
      <xsl:when test="contains($pgn,'-') and contains(substring-after($pgn,'-'),'-')">
      <!--<MedlinePgn>29-1 - 29-3</MedlinePgn> pmid="12179563 -->
        <fpage>
          <xsl:value-of select="normalize-space(substring-before($pgn,substring-after(substring-after($pgn,'-'),' ')))"/>
        </fpage>
        <lpage>
          <xsl:value-of select="normalize-space(substring-after(substring-after($pgn,'-'),'-'))"/>
        </lpage>
			<page-range><xsl:value-of select="$pgn"/></page-range>
		  </xsl:when>
      <xsl:when test="contains($pgn,'-') and contains($pgn,',')">
        <xsl:variable name="ef" select="substring-before($pgn,',')"/>
        <xsl:variable name="el">
            <xsl:call-template name="substring-after-last-space">
              <xsl:with-param name="str" select="$pgn"/>
            </xsl:call-template>
            </xsl:variable>
      <xsl:choose>
        <xsl:when test="number(translate($ef,'-','')) and number(translate($ef,'-',''))">
              <xsl:call-template name="fpage">
                <xsl:with-param name="pagestring" select="$ef"/>
                </xsl:call-template>
              <xsl:call-template name="lpage">
                <xsl:with-param name="pagestring" select="$el"/>
                </xsl:call-template>
          </xsl:when>
        <xsl:when test="number(substring-before($ef,'-')) != number(substring-after($ef,'-'))">
          <fpage>
            <xsl:value-of select="$ef"/>
          </fpage>
          <lpage>
            <xsl:value-of select="$el"/>
          </lpage>
          </xsl:when>
        <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains(substring-before($pgn,','),'-')">
            <xsl:call-template name="fpage">
              <xsl:with-param name="pagestring" select="substring-before($pgn,'-')"/>
            </xsl:call-template>                        
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="fpage">
              <xsl:with-param name="pagestring" select="substring-before($pgn,',')"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="lpage">
          <xsl:with-param name="pagestring">
            <xsl:call-template name="find-lpage-string">
              <xsl:with-param name="str" select="$pgn"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
        </xsl:otherwise>
        </xsl:choose>
        
        <page-range><xsl:value-of select="$pgn"/></page-range>
      </xsl:when>
      <xsl:when test="starts-with($pgn,':')">
        <xsl:call-template name="fpage">
          <xsl:with-param name="pagestring" select="substring-after($pgn,':')"/>
        </xsl:call-template>
        <xsl:call-template name="lpage">
          <xsl:with-param name="pagestring" select="substring-after($pgn,':')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($pgn,';')">
        <xsl:variable name="beforesemi" select="substring-before($pgn,';')"/>
        <xsl:variable name="aftersemi" select="substring-after($pgn,';')"/>
          <xsl:choose>
            <xsl:when test="contains(substring-before($pgn,';'),'-')">
              <xsl:call-template name="fpage">
                <xsl:with-param name="pagestring" select="$beforesemi"/>
                </xsl:call-template>
              <xsl:call-template name="lpage">
                <xsl:with-param name="pagestring" select="$beforesemi"/>
                </xsl:call-template>
                </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="fpage">
                <xsl:with-param name="pagestring" select="$beforesemi"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
        <page-range><xsl:value-of select="$pgn"/></page-range>
        </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="fpage">
          <xsl:with-param name="pagestring" select="$pgn"/>
        </xsl:call-template>
        <xsl:call-template name="lpage">
          <xsl:with-param name="pagestring" select="$pgn"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
 
 	<xsl:template name="cleanPgn">
		<xsl:param name="str"/>
		<xsl:if test="$str">
			<xsl:choose>
				<xsl:when test="contains($str,'--')">
					<xsl:call-template name="cleanPgn">
						<xsl:with-param name="str" select="replace($str,'--','-')"/>
						</xsl:call-template>
					</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$str"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:template>
 
 
  
  <xsl:template name="find-lpage-string">
    <xsl:param name="str"/>
    <xsl:if test="$str!=''">
      <xsl:choose>
        <xsl:when test="contains(substring-after($str,','),',')">
          <xsl:call-template name="find-lpage-string">
            <xsl:with-param name="str" select="substring-after($str,',')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$str"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  
  <!-- ============================ -->
  <!-- Construct fpage - context = /PubmedArticleSet/PubmedArticle/MedlineCitation -->
  <xsl:template name="fpage">
    <xsl:param name="pagestring"/>
    <xsl:choose>
      <xsl:when test="contains($pagestring, ',')">
        <xsl:variable name="nospace">
          <xsl:call-template name="unify-whitespaces">
            <xsl:with-param name="str" select="$pagestring"/>
          </xsl:call-template>
        </xsl:variable>
        <fpage>
          <xsl:value-of select="substring-before($nospace,',')"/>
        </fpage>
        <!-- <lpage>
            <xsl:value-of select="substring-after($nospace,',')"/>
          </lpage> -->
      </xsl:when>
      <xsl:when test="contains($pagestring, ';')">
        <xsl:call-template name="get-first-page">
          <xsl:with-param name="str" select="substring-before($pagestring,';')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($pagestring, ':')">
        <xsl:call-template name="get-first-page">
          <xsl:with-param name="str" select="substring-before($pagestring,':')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($pagestring, ' ')">
        <xsl:call-template name="get-first-page">
          <xsl:with-param name="str" select="substring-before($pagestring,' ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($pagestring, '-')">
        <fpage>
          <xsl:value-of select="substring-before($pagestring,  '-')"/>
        </fpage>
      </xsl:when>
      <xsl:otherwise>
        <fpage>
          <xsl:value-of select="$pagestring"/>
        </fpage>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- ============================ -->
  <!-- Construct lpage - context = /PubmedArticleSet/PubmedArticle/MedlineCitation -->
  <xsl:template name="lpage">
    <xsl:param name="pagestring"/>
    <xsl:choose>
      <xsl:when test="contains($pagestring, ' ')">
        <xsl:call-template name="get-last-page">
          <xsl:with-param name="str">
            <xsl:call-template name="substring-after-last-space">
              <xsl:with-param name="str" select="$pagestring"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($pagestring, '-')">
        <lpage>
          <xsl:variable name="fpage">
            <xsl:value-of select="substring-before($pagestring,  '-')"/>
          </xsl:variable>
          <xsl:variable name="lpage">
            <xsl:value-of select="substring-after($pagestring,  '-')"/>
          </xsl:variable>
          <xsl:variable name="cap-pagestring" select="upper-case(concat(substring-before($pagestring,'-'),substring-after($pagestring,'-')))"/>
          <xsl:choose>
            <xsl:when test="translate($cap-pagestring,'IVXLCDM','') = ''">
              <!-- pages are roman numerals -->
              <xsl:value-of select="substring-after($pagestring,  '-')"/>
            </xsl:when>
            <xsl:when test="string-length($fpage) &gt; string-length($lpage)">
              <xsl:value-of select="concat(substring($fpage, 1, string-length($fpage)-string-length($lpage)), $lpage)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-after($pagestring,  '-')"/>
            </xsl:otherwise>
          </xsl:choose>
        </lpage>
      </xsl:when>
      <xsl:otherwise>
        <lpage><xsl:value-of select="$pagestring"/></lpage>
      </xsl:otherwise> 
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="get-elocid">
    <xsl:choose>
      <xsl:when test="count(MedlineCitation/Article/ELocationID) &gt; 1">
        <!-- there is more than one ELocationID -->
        <xsl:choose>
          <xsl:when test="MedlineCitation/Article/ELocationID[@EIdType='pii']">
            <elocation-id>
              <xsl:value-of select="MedlineCitation/Article/ELocationID[@EIdType='pii']"/>
            </elocation-id>
          </xsl:when>
          <xsl:when test="MedlineCitation/Article/ELocationID[@EIdType!='doi']">
            <elocation-id>
              <xsl:value-of select="MedlineCitation/Article/ELocationID[@EIdType!='doi']"/>
            </elocation-id>
          </xsl:when>
          <xsl:otherwise>
            <elocation-id>
              <xsl:value-of select="MedlineCitation/Article/ELocationID[1]"/>
            </elocation-id>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="count(MedlineCitation/Article/ELocationID) = 1">
        <elocation-id>
          <xsl:value-of select="MedlineCitation/Article/ELocationID"/>
        </elocation-id>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="relart">
    <xsl:apply-templates select="descendant::CommentsCorrections"/>
  </xsl:template>
  
  <xsl:template match="CommentsCorrections">
    <xsl:choose>
      <xsl:when test="@RefType">
        <xsl:call-template name="RELART">
          <xsl:with-param name="relart-type">
            <xsl:call-template name="get-relart-type">
              <xsl:with-param name="reftype" select="@RefType"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="get-relart-type">
    <xsl:param name="reftype"/>
    <xsl:choose>
      <xsl:when test="$reftype='CommentOn'">commentary-article</xsl:when>
      <xsl:when test="$reftype='CommentIn'">commentary</xsl:when>
      <xsl:when test="$reftype='ErratumIn'">correction-forward</xsl:when>
      <xsl:when test="$reftype='ErratumFor'">corrected-article</xsl:when>
      <xsl:when test="$reftype='PartialRetractionIn'">retraction-forward</xsl:when>
      <xsl:when test="$reftype='PartialRetractionOf'">retracted-article</xsl:when>
      <xsl:when test="$reftype='RepublishedFrom'">republished-article</xsl:when>
      <xsl:when test="$reftype='RepublishedIn'">republished-article</xsl:when>
      <xsl:when test="$reftype='RetractionOf'">retracted-article</xsl:when>
      <xsl:when test="$reftype='RetractionIn'">retraction-forward</xsl:when>
      <xsl:when test="$reftype='UpdateIn'">update</xsl:when>
      <xsl:when test="$reftype='UpdateOf'">updated-article</xsl:when>
      <xsl:when test="$reftype='SummaryForPatientsIn'">companion</xsl:when>
      <xsl:when test="$reftype='OriginalReportIn'">companion</xsl:when>
      <xsl:when test="$reftype='ReprintOf'">republished-article</xsl:when>
      <xsl:when test="$reftype='ReprintIn'">republished-article</xsl:when>
      <xsl:when test="$reftype='Cites'">cites</xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="CommentIn">
    
    <!-- Removed 1/20/06 LK: Process in NIHMS articles (param nihms)
      Other articles creating duplicate links because the relart-type can't be correctly
      identified in this direction. CommentOn element will build the correct forward and 
      backward links. -->
      <xsl:call-template name="RELART">
        <xsl:with-param name="relart-type" select="'commentary'"/>
      </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="CommentOn">
    
    <xsl:call-template name="RELART">
      <xsl:with-param name="relart-type" select="'commentary-article'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="ErratumFor">
    
    <xsl:call-template name="RELART">
      <xsl:with-param name="relart-type" select="'corrected-article'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="RepublishedFrom">
    
    <xsl:call-template name="RELART">
      <xsl:with-param name="relart-type" select="'republished-article'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="RetractionOf">
    
    <xsl:call-template name="RELART">
      <xsl:with-param name="relart-type" select="'retracted-article'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="OriginalReportIn | SummaryForPatientsIn">
    
    <xsl:call-template name="RELART">
      <xsl:with-param name="relart-type" select="'companion'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="ReprintOf">
    <xsl:call-template name="RELART">
      <xsl:with-param name="relart-type" select="'republished-article'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="RepublishedIn | ReprintIn">
    
    <!-- Removed 9/30, JB: so that we don't build so many incorrect links.-->
    <!-- Restored 8/4/05, LK, for NIHMS articles ONLY per Sergey Krasnov's request. Uses param nihms -->
      <xsl:call-template name="RELART">
        <xsl:with-param name="relart-type" select="'republication'"/>
      </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="RetractionIn">
    
    <!-- Removed 9/30, JB: so that we don't build so many incorrect links.-->
    <!-- Restored 8/4/05, LK, for NIHMS articles ONLY per Sergey Krasnov's request. Uses param nihms -->
      <xsl:call-template name="RELART">
        <xsl:with-param name="relart-type" select="'retraction-forward'"/>
      </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="ErratumIn">
    
    <!-- Removed 9/30, JB: so that we don't build so many incorrect links.-->
    <!-- Restored 8/4/05, LK, for NIHMS articles ONLY per Sergey Krasnov's request. Uses param nihms -->
      <xsl:call-template name="RELART">
        <xsl:with-param name="relart-type" select="'correction-forward'"/>
      </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="RELART">
    
    <xsl:param name="relart-type"/>
    <xsl:variable name="nlmta">
      <xsl:value-of select="substring-before(RefSource,'.')"/>
    </xsl:variable>
    <xsl:variable name="page">
      <xsl:choose>
        <xsl:when test="contains(substring-after(RefSource,':'),'-')">
          <xsl:value-of select="substring-before(substring-after(RefSource,':'),'-')"/>
        </xsl:when>
        <xsl:when test="contains(substring-after(RefSource,':'),';')">
          <xsl:value-of select="substring-before(substring-after(RefSource,':'),';')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring-after(RefSource,':')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$relart-type='cites'"/>
      <!-- don't process cites -->
      <xsl:when test="PMID">
        <related-article related-article-type="{$relart-type}" page="{$page}" id="{generate-id()}"
          xlink:href="{PMID}" ext-link-type="pubmed">
          <xsl:attribute name="vol">
            <!-- Separated out vol attribute b/c some RefSource has vol:Pg, others have vol(Pg) 
                            was vol="{substring-before(substring-after(RefSource,';'),'(')}" -->
            <xsl:choose>
              <xsl:when test="contains(substring-after(.,';'),'(')">
                <xsl:value-of select="substring-before(substring-after(.,';'),'(')"/>
              </xsl:when>
              <xsl:when test="contains(substring-after(.,';'),':')">
                <xsl:value-of select="substring-before(substring-after(.,';'),':')"/>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
<!--          <xsl:if test="$nlmta!=$domain/@nlm-ta">
            <xsl:attribute name="journal-id-type">nlm-ta</xsl:attribute>
            <xsl:attribute name="journal-id">
              <xsl:value-of select="$nlmta"/>
            </xsl:attribute>
          </xsl:if> -->   
          <xsl:value-of select="RefSource"/>
        </related-article>
      </xsl:when>
      <xsl:otherwise>
          <xsl:apply-templates select="RefSource">
            <xsl:with-param name="relart-type" select="$relart-type"/>
            <xsl:with-param name="page" select="$page"/>
          </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="RefSource">
    <!--nodepath node-->
    <xsl:param name="relart-type"/>
    <xsl:param name="page"/>
    <xsl:variable name="vol">
      <xsl:choose>
        <xsl:when test="contains(substring-after(.,';'),'(')">
          <xsl:value-of select="substring-before(substring-after(.,';'),'(')"/>
        </xsl:when>
        <xsl:when test="contains(substring-after(.,';'),':')">
          <xsl:value-of select="substring-before(substring-after(.,';'),':')"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="year" select="substring-before(substring-after(.,'. '),' ')"/>
<!--    <xsl:variable name="citation">
      <xsl:value-of select="//MedlineTA"/>
      <xsl:text>|</xsl:text>
      <xsl:value-of select="$year"/>
      <xsl:text>|</xsl:text>
      <xsl:value-of select="$vol"/>
      <xsl:text>|</xsl:text>
      <xsl:value-of select="$page"/>
      <xsl:text>||</xsl:text>
      <xsl:value-of select="generate-id()"/>
      <xsl:text>|</xsl:text>
    </xsl:variable>
-->   
    <related-article related-article-type="{$relart-type}" vol="{$vol}" page="{$page}" ext-link-type="pmc" id="{generate-id()}">
      <xsl:apply-templates/>
    </related-article>
  </xsl:template>
  
  
  
  <!-- ============================ -->
  <xsl:template match="Abstract">
    <abstract>
      <xsl:if test="../VernacularTitle">
        <xsl:attribute name="xml:lang" select="'eng'"/>
      </xsl:if>
      <xsl:if test="@Type">
        <xsl:attribute name="abstract-type" select="@Type"/>
        </xsl:if>
      <xsl:apply-templates select="AbstractText"/>
    </abstract>
  </xsl:template>
  
  <!-- ============================ -->
  <xsl:template match="OtherAbstract">
    <xsl:choose>
	 	<xsl:when test="AbstractText[1]='Abstract available from the publisher.'"/>
      <xsl:when test="@Language=/descendant::Language[1] or @Language=lower-case(/descendant::Language[1])">
        <abstract>
          <xsl:if test="@Type">
            <xsl:attribute name="abstract-type" select="@Type"/>
            </xsl:if>
          <xsl:apply-templates select="AbstractText"/>
        </abstract>
        </xsl:when>
      <xsl:otherwise>
        <trans-abstract>
          <xsl:apply-templates select="@Language"/>
          <xsl:if test="@Type">
            <xsl:attribute name="abstract-type" select="@Type"/>
              </xsl:if>
          <xsl:apply-templates select="AbstractText"/>
        </trans-abstract>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@xml:lang | @Language">
	 	<xsl:attribute name="xml:lang">
	 		<xsl:call-template name="get-lang">
				<xsl:with-param name="code" select="normalize-space()"/>
				</xsl:call-template>
			</xsl:attribute>
  	</xsl:template>
	
  <xsl:template match="AbstractText">
    <xsl:choose>
      <xsl:when test="@Label">
        <xsl:variable name="fchar" select="substring(@Label,1,1)"/>
        <sec>
          <title><xsl:value-of select="concat($fchar,lower-case(substring-after(@Label,$fchar)))"/></title>
          <p>
            <xsl:apply-templates/>
          </p>
        </sec>
      </xsl:when>
      <xsl:otherwise>
        <p>
          <xsl:apply-templates/>
        </p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="CollectiveName">
    <collab>
      <xsl:apply-templates/>
      <xsl:apply-templates select="/descendant::InvestigatorList"/>
    </collab>
    </xsl:template>

  <xsl:template match="CopyrightInformation">
    <permissions>
      <copyright-statement>
        <xsl:apply-templates/>
      </copyright-statement>
    </permissions>
    </xsl:template>

  <xsl:template name="write-languages">
    <kwd-group kwd-group-type="document-languages">
      <xsl:choose>
        <xsl:when test="self::PubmedArticle">
          <xsl:for-each select="MedlineCitation/Article/Language">
            <kwd><xsl:apply-templates/></kwd>
            </xsl:for-each>
          </xsl:when>
        <xsl:otherwise>
          <xsl:for-each-group select="descendant-or-self::node()/@xml:lang" group-by=".">
            <kwd><xsl:value-of select="."/></kwd>
            </xsl:for-each-group>
          </xsl:otherwise>  
        </xsl:choose>
    </kwd-group>
    </xsl:template>


  
  <xsl:template match="ChemicalList | MeshHeadingList | GeneSymbolList | PersonalNameSubjectList | DataBankList | SupplMeshList | KeywordList">
    <kwd-group kwd-group-type="{if (self::KeywordList and @Owner) then (@Owner) else (local-name())}">
      <xsl:apply-templates/>
    </kwd-group>
  </xsl:template> 
  
  <xsl:template name="write-space-flight-keywords">
    <kwd-group kwd-group-type="SpaceFlightMission">
      <xsl:for-each select="MedlineCitation/SpaceFlightMission">
        <kwd><xsl:apply-templates/></kwd>
        </xsl:for-each>
    </kwd-group>
    </xsl:template>

  <xsl:template match="Chemical">
    <compound-kwd>
      <xsl:apply-templates/>
    </compound-kwd>
  </xsl:template> 
  
  <xsl:template match="RegistryNumber | NameOfSubstance">
    <compound-kwd-part content-type="{local-name()}">
      <xsl:apply-templates/>
    </compound-kwd-part>
  </xsl:template> 

  <xsl:template match="MeshHeading">
    <xsl:choose>
      <xsl:when test="QualifierName">
        <nested-kwd>
          <xsl:apply-templates select="DescriptorName"/>
        </nested-kwd>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="DescriptorName"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> 
  
  <xsl:template match="DescriptorName | Keyword">
    <kwd content-type="{if (@MajorTopicYN='N') then 'not-major' else 'major'}">
      <xsl:apply-templates/>
    </kwd>
    <xsl:if test="following-sibling::QualifierName">
      <nested-kwd>
        <xsl:apply-templates select="following-sibling::QualifierName"/>
      </nested-kwd>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="QualifierName">
    <kwd content-type="{if (@MajorTopicYN='N') then 'not-major' else 'major'}">
      <xsl:apply-templates/>
    </kwd>
  </xsl:template>
  
  <xsl:template match="DataBank | AccessionNumberList">
    <nested-kwd content-type="{local-name()}">
      <xsl:apply-templates/>
    </nested-kwd> 
  </xsl:template>
  
  <xsl:template match="DataBankName | AccessionNumber">
    <kwd content-type="{local-name()}">
      <xsl:apply-templates/>
    </kwd>
  </xsl:template>
  
  <xsl:template match="SupplMeshName">
    <kwd content-type="{@Type}">
      <xsl:apply-templates/>
    </kwd>
  </xsl:template>
  
  
  <xsl:template match="GrantList">
    <funding-group>
      <xsl:apply-templates/>
    </funding-group>
  </xsl:template>
  
  <xsl:template match="Grant">
    <award-group>
      <funding-source country="{Country}">
        <xsl:value-of select="Agency"/>
      </funding-source>
      <award-id><xsl:value-of select="GrantID"/></award-id>
    </award-group>
  </xsl:template>
  
  
  <xsl:template match="CommentsCorrectionsList" mode="cited">
    <xsl:if test="descendant::CommentsCorrections[@RefType='Cites']">
      <notes notes-type="cited-articles">
        <ref-list>
          <xsl:apply-templates select="CommentsCorrections[@RefType='Cites']" mode="cited"/>
        </ref-list>
      </notes>  
      
    </xsl:if>
  </xsl:template>

  <xsl:template match="CommentsCorrections" mode="cited">
    <ref><mixed-citation>
      <named-content content-type="citation-string">
        <xsl:value-of select="RefSource"/>
      </named-content>
      <pub-id pub-id-type="pmid" specific-use="{concat('v',PMID/@Version)}">
        <xsl:value-of select="PMID"/>
      </pub-id>
    </mixed-citation></ref>
  </xsl:template>

  <xsl:template match="GeneSymbol">
    <kwd>
      <xsl:apply-templates/>
    </kwd>
  </xsl:template>
  
  <xsl:template match="PersonalNameSubject">
    <kwd>
      <xsl:apply-templates mode="pns"/>
    </kwd>
  </xsl:template>
  
  <xsl:template match="LastName | ForeName | Initials | Suffix" mode="pns">
    <named-content content-type="{local-name()}">
      <xsl:apply-templates/>
    </named-content>
  </xsl:template>

  <xsl:template match="CitationSubset">
      <custom-meta>
        <meta-name>CitationSubset</meta-name>
        <meta-value><xsl:apply-templates/></meta-value>
      </custom-meta>
    </xsl:template>

  <xsl:template match="GeneralNote">
    <notes notes-type="GeneralNote" specific-use="{concat('Owner:',@Owner)}">
      <p>
        <xsl:apply-templates/>
      </p>
    </notes>
  </xsl:template>


  <xsl:template match="OtherID">
    <object-id pub-id-type="{@Source}">
      <xsl:apply-templates/>
    </object-id>
    </xsl:template>








<!-- helper templates -->
  <xsl:template name="build-iso-date" >
    <xsl:param name="year"/>
    <xsl:param name="month"/>
    <xsl:param name="day"/>
    <xsl:param name="hour" select="0"/>
    <xsl:param name="minute"/>
    <xsl:param name="second"/>
    <xsl:value-of select="format-number($year,'0000')"/>
    <xsl:if test="$month"><xsl:value-of select="format-number($month,'00')"/>
    <xsl:if test="$day"><xsl:value-of select="format-number($day,'00')"/></xsl:if></xsl:if>
    <xsl:if test="$hour &gt; 0">
      <xsl:text>T</xsl:text>
      <xsl:value-of select="format-number($hour,'00')"/>
      <xsl:value-of select="format-number($minute,'00')"/>
      <xsl:value-of select="format-number($second,'00')"/>
    </xsl:if>
  </xsl:template>

  <xsl:function name="ncbi:get-initials">
    <xsl:param name="str"/>
    <xsl:variable name="STR" select="upper-case($str)"/>
    <xsl:variable name="spaces" select="string-length($str) - string-length(translate($str,' ',''))"/>
    <xsl:choose>
      <xsl:when test="$str != $STR">
        <xsl:value-of select="translate($str,concat($lowerLatin,'.,- '),'')"/>
	    </xsl:when>
      <xsl:when test="$spaces=0">
        <xsl:value-of select="substring($str,1,1)"/>
      </xsl:when>
      <xsl:when test="$spaces=1">
        <xsl:value-of select="substring($str,1,1)"/>
        <xsl:value-of select="substring(substring-after($str,' '),1,1)"/>
      </xsl:when>
      <xsl:when test="$spaces=2">
        <xsl:value-of select="substring($str,1,1)"/>
        <xsl:value-of select="substring(substring-after($str,' '),1,1)"/>
        <xsl:value-of select="substring(substring-after(substring-after($str,' '),' '),1,1)"/>
      </xsl:when>
      <xsl:when test="$spaces=3">
        <xsl:value-of select="substring($str,1,1)"/>
        <xsl:value-of select="substring(substring-after($str,' '),1,1)"/>
        <xsl:value-of select="substring(substring-after(substring-after($str,' '),' '),1,1)"/>
        <xsl:value-of select="substring(substring-after(substring-after(substring-after($str,' '),' '),' '),1,1)"/>
      </xsl:when>
    </xsl:choose>   
  </xsl:function>

  <!-- ==================================================================== -->
  <!-- TEMPLATE:  month-name-to-number
        NOTES:     Only test first 3 characters of name. That way we catch
                   a variety of abbreviations and typos. We will also match
                   some nonsense on occasion.
                   Additional cases can be added for other languages.
        PARAMS:    name     the month name to decode
                   nums     if true, numbers 1-12 are ok also.
        RETURN:    A number 1-12, or nil on failure.
     -->
  <!-- ==================================================================== -->
  <xsl:function name="ncbi:month-name-to-number">
    <xsl:param name="name"/>
    <xsl:variable name="nums" select="'1'"/>
    
    <xsl:variable name="UCname" select="upper-case(normalize-space(
      translate($name,'.',' ')))"/>
    
    <xsl:variable name="f3" select="if (substring($UCname,1,3) castable as xs:integer) 
      then (number(substring($UCname,1,3)))
      else (substring($UCname,1,3))"/>
    
    <xsl:choose>
      <xsl:when test="$nums and number($f3)>=1 and number($f3)&lt;=12
        and number($f3)=floor($f3)">
        <xsl:value-of select="number($f3)"/>
      </xsl:when>
      <xsl:when test="$f3 = 'JAN'">1</xsl:when>
      <xsl:when test="$f3 = 'FEB'">2</xsl:when>
      <xsl:when test="$f3 = 'MAR'">3</xsl:when>
      <xsl:when test="$f3 = 'APR'">4</xsl:when>
      <xsl:when test="$f3 = 'MAY'">5</xsl:when>
      <xsl:when test="$f3 = 'JUN'">6</xsl:when>
      <xsl:when test="$f3 = 'JUL'">7</xsl:when>
      <xsl:when test="$f3 = 'AUG'">8</xsl:when>
      <xsl:when test="$f3 = 'SEP'">9</xsl:when>
      <xsl:when test="$f3 = 'OCT'">10</xsl:when>
      <xsl:when test="$f3 = 'NOV'">11</xsl:when>
      <xsl:when test="$f3 = 'DEC'">12</xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:function>

  <!-- figures out fpage from a string - single page or range -->
  <xsl:template name="get-first-page">
    <xsl:param name="str"/>
    <xsl:choose>
      <xsl:when test="contains($str,'-')">
        <fpage>
          <xsl:value-of select="substring-before($str,'-')"/>
        </fpage>
      </xsl:when>
      <xsl:otherwise>
        <fpage>
          <xsl:value-of select="$str"/>
        </fpage>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- figures out lpagee from a string - single page or range -->
  <xsl:template name="get-last-page">
    <xsl:param name="str"/>
    <xsl:choose>
      <xsl:when test="contains($str,'-')">
        <lpage>
          <xsl:call-template name="last-page">
            <xsl:with-param name="fpage" select="substring-before($str,'-')"/>
            <xsl:with-param name="lpage" select="substring-after($str,'-')"/>
          </xsl:call-template>
        </lpage>
      </xsl:when>
      <xsl:otherwise>
        <lpage>
          <xsl:value-of select="$str"/>
        </lpage>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- Prepare lpage - which may need fpage -->
  <xsl:template name="last-page">
    <xsl:param name="fpage"/>
    <xsl:param name="lpage"/>
    <!--<xsl:message>[<xsl:value-of select="$fpage"/>|<xsl:value-of select="$lpage"/>]</xsl:message>  -->
    <xsl:choose>
      <!-- Return fpage if lpage is empty -->
      <xsl:when test="$lpage = ''">
        <xsl:value-of select="$fpage"/>
      </xsl:when>
      <!-- Return lpage as-is if it is not a number or if fpage is not a number-->
      <xsl:when test="not(number($lpage)) or not(number($fpage))">
        <xsl:value-of select="$lpage"/>
      </xsl:when>
      <!-- Return lpage as-is if it's not shorter than fpage -->
      <xsl:when test="string-length($lpage) >= string-length($fpage)">
        <xsl:value-of select="$lpage"/>
      </xsl:when>
      <!-- Return truncated fpage suffixed by lpage as in case fpage=1234, lpage=44 (1244) -->
      <xsl:when test="$lpage >= substring($fpage, string-length($fpage)-string-length($lpage)+1)">
        <xsl:value-of select="concat(substring($fpage, 1, string-length($fpage)-string-length($lpage)), $lpage)"/>
      </xsl:when>
      <!-- Return truncated fpage+1 suffixed by lpage as in case fpage=1238, lpage=4 (1244) -->
      <xsl:otherwise>
        <xsl:value-of select="concat(number(substring($fpage, 1, string-length($fpage) - string-length($lpage))) + 1, $lpage)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="unify-whitespaces">
    <xsl:param name="str"/>
    <xsl:value-of select="translate($str, 
      '&#x9;&#xA;&#xD;&#x20;','')"/>
  </xsl:template>        
  <!-- Outputs the substring after the last space in the input string -->
  <xsl:template name="substring-after-last-space">
    <xsl:param name="str"/>
    <xsl:if test="$str">
      <xsl:choose>
        <xsl:when test="contains($str,' ')">
          <xsl:call-template name="substring-after-last-space">
            <xsl:with-param name="str"
              select="substring-after($str,' ')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$str"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  

<xsl:template match="related-article">
  <related-article>
    <xsl:apply-templates select="@*"/>
    <xsl:choose>
      <xsl:when test="not(normalize-space)">
        <xsl:call-template name="build-relart-string"/>
        </xsl:when>
      <xsl:when test="@vol and @page and (not(contains(.,@vol)) or not(contains(.,@page)))">
        <xsl:call-template name="build-relart-string"/>
        </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
  </related-article>
  </xsl:template>
  

  <xsl:template name="build-relart-string">
    <!-- context node: related-article -->
    <xsl:variable name="jname" select="normalize-space(/article/front/journal-meta/journal-id[@journal-id-type='nlm-ta'])"/>
    <xsl:variable name="jid" select="normalize-space(@journal-id)"/>
    <xsl:choose>
      <xsl:when test="@journal-id and (@journal-id-type='nlm-ta' or @journal-id-type='iso-abbrev')">
        <xsl:value-of select="$jid"/>
        <xsl:choose>
          <xsl:when test="substring($jid,string-length($jid),1)='.'">
            <xsl:text> </xsl:text>
            </xsl:when>
          <xsl:otherwise>
            <xsl:text>. </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$jname"/>
        <xsl:choose>
          <xsl:when test="substring($jname,string-length($jname),1)='.'">
            <xsl:text> </xsl:text>
            </xsl:when>
          <xsl:otherwise>
            <xsl:text>. </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    <xsl:if test="normalize-space(@vol)">
      <xsl:value-of select="@vol"/>
      <xsl:text>:</xsl:text>
      </xsl:if>
    <xsl:if test="normalize-space(@page)">
      <xsl:value-of select="@page"/>
      </xsl:if>
    <xsl:if test="@vol or @page">
      <xsl:text>.</xsl:text>
      </xsl:if>
    </xsl:template>


  <xsl:template match="sup[parent::aff and not(preceding-sibling::*)]">
  	<label>
		<xsl:apply-templates/>
	</label>
	</xsl:template>


<!--DOI CLEANUP TEMPLATES -->
	<xsl:template name="clean-doi">
		<xsl:param name="str"/>
		<xsl:choose>
			<xsl:when test="contains($str, 'doi.org/')">
				<xsl:value-of select="substring-after($str, 'doi.org/')"/>				
			</xsl:when>
			<xsl:when test="contains($str, 'http://')">
				<xsl:value-of select="substring-after($str, 'http://')"/>				
			</xsl:when>
			<xsl:when test="contains($str,'DOI: ')">
				<xsl:value-of select="substring-after($str,'DOI: ')"/>
			</xsl:when>
			<xsl:when test="contains($str,'DOI:')">
				<xsl:value-of select="substring-after($str,'DOI:')"/>
			</xsl:when>
			<xsl:when test="contains($str,'doi: ')">
				<xsl:value-of select="substring-after($str,'doi: ')"/>
			</xsl:when>
			<xsl:when test="contains($str,'doi:')">
				<xsl:value-of select="substring-after($str,'doi:')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$str"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

   <!-- *********************************************************** -->
   <!-- Template: doi-check 
   
        Test takes in the value of the doi and tests it by
        calling another template. This test will probably only be 
        applied to the following:
           pub-id/@pub-id-type[.='doi'] 
           journal-id/@journal-id-type[.='doi']
           article-id/@pub-id-type[.='doi']
           related-article[@ext-link-type='doi']/@xlink:href
           issue-id[@pub-id-type = 'doi']
           ext-link[@ext-link-type = 'doi']/@xlink:href
           object-id[@pub-id-type = 'doi']
     -->
   <!-- *********************************************************** 
   <xsl:template name="doi-check">
   	<xsl:param name="value"/>
      
      <xsl:variable name="good-doi">
         <xsl:call-template name="doi-format-test">
            <xsl:with-param name="doi" select="$value"/>
         </xsl:call-template>
      </xsl:variable>
      
      <xsl:if test="$good-doi = 'false'">
         <xsl:call-template name="make-error">
            <xsl:with-param name="error-type">doi format check</xsl:with-param>
            <xsl:with-param name="description">
               <xsl:text>Malformed doi value: '</xsl:text>
               <xsl:value-of select="$value"/>
               <xsl:text>'</xsl:text>
            </xsl:with-param>
         </xsl:call-template>                                       
      </xsl:if>
   </xsl:template>
-->

   <!-- *********************************************************** -->
   <!-- Template: doi-format-test 

        Check the format of a doi and return true
        if well formed, false otherwise.
        
        Format is specified here:
        http://www.doi.org/handbook_2000/enumeration.html#2.2
     -->
   <!-- *********************************************************** -->
   <xsl:template name="doi-format-test">
      <xsl:param name="doi"/>
      
      <xsl:variable name="normalized-doi">
			<xsl:value-of  select="normalize-space($doi)"/>
			</xsl:variable>
		
	
      <!-- Format tests -->
      <xsl:choose>
         <!-- Cannot be empty -->
         <xsl:when test="not($normalized-doi)">
            <xsl:text>false</xsl:text>
         </xsl:when>
         
         <!-- No spaces allowed -->
         <xsl:when test="contains($normalized-doi, ' ')">
            <xsl:text>false</xsl:text>
         </xsl:when>
         
         <!-- Prefix must start with '10.' -->
         <xsl:when test="not(starts-with($normalized-doi, '10.'))">
            <xsl:text>false</xsl:text>
         </xsl:when>
         
         <!-- Must be something following the preamble in the prefix.
         In other words, cannot immediately follow the '10.' with a '/'-->
         <xsl:when test="substring($normalized-doi, 4,1) = '/'">
            <xsl:text>false</xsl:text>
         </xsl:when>
         
         <!-- '/' must separate prefix from the suffix -->
         <xsl:when test="not(contains(substring-after($normalized-doi, '10.'), '/'))">
            <xsl:text>false</xsl:text>
         </xsl:when>
         
         <!-- Must be content after the '/' to form the suffix -->
         <xsl:when test="not(substring-after($normalized-doi, '/'))">
            <xsl:text>false</xsl:text>
         </xsl:when>
         
         <!-- Must be OK!!-->
         <xsl:otherwise>
            <xsl:text>true</xsl:text>
         </xsl:otherwise>
      </xsl:choose>      
   </xsl:template>


<!-- **************************************************************** -->
<!--                 LANGUAGE CLEANUP TEMPLATES                       -->
<!-- **************************************************************** -->
	<xsl:template name="get-lang">
		<xsl:param name="code"/>
		<xsl:choose>
			<xsl:when test="lower-case($code)='eng' or lower-case($code)='en'">
				<xsl:text>eng</xsl:text>
				</xsl:when>
			<xsl:when test="string-length($code)=3 and $langs/l[@three=lower-case($code)]">
				<xsl:value-of select="lower-case($code)"/>
				</xsl:when>
			<xsl:when test="string-length($code)=2">
				<xsl:value-of select="if ($langs/l[@two=lower-case($code)]/@three) then ($langs/l[@two=lower-case($code)]/@three) else 'eng'"/>
				</xsl:when>
			<xsl:when test="contains($code,'-') and string-length(substring-before($code,'-'))=2">
				<xsl:value-of select="if ($langs/l[@two=lower-case(substring-before($code,'-'))]/@three) then ($langs/l[@two=lower-case(substring-before($code,'-'))]/@three) else 'eng'"/>
				</xsl:when>
			<xsl:when test="contains($code,'-') and string-length(substring-before($code,'-'))=3">
				<xsl:value-of select="if ($langs/l[@three=lower-case(substring-before($code,'-'))]) then (lower-case(substring-before($code,'-'))) else 'eng'"/>
				</xsl:when>
			<xsl:otherwise>
				<xsl:text>en</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:template>
		
	<!-- This variable is built from http://www.loc.gov/standards/iso639-2/php/code_list.php
			@three contains the values from ISO-639-2
			@two contains the values from ISO-639-1
			-->
	<xsl:variable name="langs">
		<l three="aar" two="aa"/>
		<l three="abk" two="ab"/>
		<l three="ace" two=""/>
		<l three="ach" two=""/>
		<l three="ada" two=""/>
		<l three="ady" two=""/>
		<l three="afa" two=""/>
		<l three="afh" two=""/>
		<l three="afr" two="af"/>
		<l three="ain" two=""/>
		<l three="aka" two="ak"/>
		<l three="akk" two=""/>
		<l three="alb" two=""/>
		<l three="ale" two=""/>
		<l three="alg" two=""/>
		<l three="alt" two=""/>
		<l three="amh" two="am"/>
		<l three="ang" two=""/>
		<l three="anp" two=""/>
		<l three="apa" two=""/>
		<l three="ara" two="ar"/>
		<l three="arc" two=""/>
		<l three="arg" two="an"/>
		<l three="arm" two=""/>
		<l three="arn" two=""/>
		<l three="arp" two=""/>
		<l three="art" two=""/>
		<l three="arw" two=""/>
		<l three="asm" two="as"/>
		<l three="ast" two=""/>
		<l three="ath" two=""/>
		<l three="aus" two=""/>
		<l three="ava" two="av"/>
		<l three="ave" two="ae"/>
		<l three="awa" two=""/>
		<l three="aym" two="ay"/>
		<l three="aze" two="az"/>
		<l three="bad" two=""/>
		<l three="bai" two=""/>
		<l three="bak" two="ba"/>
		<l three="bal" two=""/>
		<l three="bam" two="bm"/>
		<l three="ban" two=""/>
		<l three="baq" two=""/>
		<l three="bas" two=""/>
		<l three="bat" two=""/>
		<l three="bej" two=""/>
		<l three="bel" two="be"/>
		<l three="bem" two=""/>
		<l three="ben" two="bn"/>
		<l three="ber" two=""/>
		<l three="bho" two=""/>
		<l three="bih" two="bh"/>
		<l three="bik" two=""/>
		<l three="bin" two=""/>
		<l three="bis" two="bi"/>
		<l three="bla" two=""/>
		<l three="bnt" two=""/>
		<l three="bod" two="bo"/>
		<l three="bos" two="bs"/>
		<l three="bra" two=""/>
		<l three="bre" two="br"/>
		<l three="btk" two=""/>
		<l three="bua" two=""/>
		<l three="bug" two=""/>
		<l three="bul" two="bg"/>
		<l three="bur" two=""/>
		<l three="byn" two=""/>
		<l three="cad" two=""/>
		<l three="cai" two=""/>
		<l three="car" two=""/>
		<l three="cat" two="ca"/>
		<l three="cau" two=""/>
		<l three="ceb" two=""/>
		<l three="cel" two=""/>
		<l three="ces" two="cs"/>
		<l three="cha" two="ch"/>
		<l three="chb" two=""/>
		<l three="che" two="ce"/>
		<l three="chg" two=""/>
		<l three="chi" two=""/>
		<l three="chk" two=""/>
		<l three="chm" two=""/>
		<l three="chn" two=""/>
		<l three="cho" two=""/>
		<l three="chp" two=""/>
		<l three="chr" two=""/>
		<l three="chu" two="cu"/>
		<l three="chv" two="cv"/>
		<l three="chy" two=""/>
		<l three="cmc" two=""/>
		<l three="cop" two=""/>
		<l three="cor" two="kw"/>
		<l three="cos" two="co"/>
		<l three="cpe" two=""/>
		<l three="cpf" two=""/>
		<l three="cpp" two=""/>
		<l three="cre" two="cr"/>
		<l three="crh" two=""/>
		<l three="crp" two=""/>
		<l three="csb" two=""/>
		<l three="cus" two=""/>
		<l three="cym" two="cy"/>
		<l three="cze" two=""/>
		<l three="dak" two=""/>
		<l three="dan" two="da"/>
		<l three="dar" two=""/>
		<l three="day" two=""/>
		<l three="del" two=""/>
		<l three="den" two=""/>
		<l three="deu" two="de"/>
		<l three="dgr" two=""/>
		<l three="din" two=""/>
		<l three="div" two="dv"/>
		<l three="doi" two=""/>
		<l three="dra" two=""/>
		<l three="dsb" two=""/>
		<l three="dua" two=""/>
		<l three="dum" two=""/>
		<l three="dut" two=""/>
		<l three="dyu" two=""/>
		<l three="dzo" two="dz"/>
		<l three="efi" two=""/>
		<l three="egy" two=""/>
		<l three="eka" two=""/>
		<l three="ell" two="el"/>
		<l three="elx" two=""/>
		<l three="eng" two="en"/>
		<l three="enm" two=""/>
		<l three="epo" two="eo"/>
		<l three="est" two="et"/>
		<l three="eus" two="eu"/>
		<l three="ewe" two="ee"/>
		<l three="ewo" two=""/>
		<l three="fan" two=""/>
		<l three="fao" two="fo"/>
		<l three="fas" two="fa"/>
		<l three="fat" two=""/>
		<l three="fij" two="fj"/>
		<l three="fil" two=""/>
		<l three="fin" two="fi"/>
		<l three="fiu" two=""/>
		<l three="fon" two=""/>
		<l three="fra" two="fr"/>
		<l three="fre" two=""/>
		<l three="frm" two=""/>
		<l three="fro" two=""/>
		<l three="frr" two=""/>
		<l three="frs" two=""/>
		<l three="fry" two="fy"/>
		<l three="ful" two="ff"/>
		<l three="fur" two=""/>
		<l three="gaa" two=""/>
		<l three="gay" two=""/>
		<l three="gba" two=""/>
		<l three="gem" two=""/>
		<l three="geo" two=""/>
		<l three="ger" two=""/>
		<l three="gez" two=""/>
		<l three="gil" two=""/>
		<l three="gla" two="gd"/>
		<l three="gle" two="ga"/>
		<l three="glg" two="gl"/>
		<l three="glv" two="gv"/>
		<l three="gmh" two=""/>
		<l three="goh" two=""/>
		<l three="gon" two=""/>
		<l three="gor" two=""/>
		<l three="got" two=""/>
		<l three="grb" two=""/>
		<l three="grc" two=""/>
		<l three="gre" two=""/>
		<l three="grn" two="gn"/>
		<l three="gsw" two=""/>
		<l three="guj" two="gu"/>
		<l three="gwi" two=""/>
		<l three="hai" two=""/>
		<l three="hat" two="ht"/>
		<l three="hau" two="ha"/>
		<l three="haw" two=""/>
		<l three="heb" two="he"/>
		<l three="her" two="hz"/>
		<l three="hil" two=""/>
		<l three="him" two=""/>
		<l three="hin" two="hi"/>
		<l three="hit" two=""/>
		<l three="hmn" two=""/>
		<l three="hmo" two="ho"/>
		<l three="hrv" two="hr"/>
		<l three="hsb" two=""/>
		<l three="hun" two="hu"/>
		<l three="hup" two=""/>
		<l three="hye" two="hy"/>
		<l three="iba" two=""/>
		<l three="ibo" two="ig"/>
		<l three="ice" two=""/>
		<l three="ido" two="io"/>
		<l three="iii" two="ii"/>
		<l three="ijo" two=""/>
		<l three="iku" two="iu"/>
		<l three="ile" two="ie"/>
		<l three="ilo" two=""/>
		<l three="ina" two="ia"/>
		<l three="inc" two=""/>
		<l three="ind" two="id"/>
		<l three="ine" two=""/>
		<l three="inh" two=""/>
		<l three="ipk" two="ik"/>
		<l three="ira" two=""/>
		<l three="iro" two=""/>
		<l three="isl" two="is"/>
		<l three="ita" two="it"/>
		<l three="jav" two="jv"/>
		<l three="jbo" two=""/>
		<l three="jpn" two="ja"/>
		<l three="jpr" two=""/>
		<l three="jrb" two=""/>
		<l three="kaa" two=""/>
		<l three="kab" two=""/>
		<l three="kac" two=""/>
		<l three="kal" two="kl"/>
		<l three="kam" two=""/>
		<l three="kan" two="kn"/>
		<l three="kar" two=""/>
		<l three="kas" two="ks"/>
		<l three="kat" two="ka"/>
		<l three="kau" two="kr"/>
		<l three="kaw" two=""/>
		<l three="kaz" two="kk"/>
		<l three="kbd" two=""/>
		<l three="kha" two=""/>
		<l three="khi" two=""/>
		<l three="khm" two="km"/>
		<l three="kho" two=""/>
		<l three="kik" two="ki"/>
		<l three="kin" two="rw"/>
		<l three="kir" two="ky"/>
		<l three="kmb" two=""/>
		<l three="kok" two=""/>
		<l three="kom" two="kv"/>
		<l three="kon" two="kg"/>
		<l three="kor" two="ko"/>
		<l three="kos" two=""/>
		<l three="kpe" two=""/>
		<l three="krc" two=""/>
		<l three="krl" two=""/>
		<l three="kro" two=""/>
		<l three="kru" two=""/>
		<l three="kua" two="kj"/>
		<l three="kum" two=""/>
		<l three="kur" two="ku"/>
		<l three="kut" two=""/>
		<l three="lad" two=""/>
		<l three="lah" two=""/>
		<l three="lam" two=""/>
		<l three="lao" two="lo"/>
		<l three="lat" two="la"/>
		<l three="lav" two="lv"/>
		<l three="lez" two=""/>
		<l three="lim" two="li"/>
		<l three="lin" two="ln"/>
		<l three="lit" two="lt"/>
		<l three="lol" two=""/>
		<l three="loz" two=""/>
		<l three="ltz" two="lb"/>
		<l three="lua" two=""/>
		<l three="lub" two="lu"/>
		<l three="lug" two="lg"/>
		<l three="lui" two=""/>
		<l three="lun" two=""/>
		<l three="luo" two=""/>
		<l three="lus" two=""/>
		<l three="mac" two=""/>
		<l three="mad" two=""/>
		<l three="mag" two=""/>
		<l three="mah" two="mh"/>
		<l three="mai" two=""/>
		<l three="mak" two=""/>
		<l three="mal" two="ml"/>
		<l three="man" two=""/>
		<l three="mao" two=""/>
		<l three="map" two=""/>
		<l three="mar" two="mr"/>
		<l three="mas" two=""/>
		<l three="may" two=""/>
		<l three="mdf" two=""/>
		<l three="mdr" two=""/>
		<l three="men" two=""/>
		<l three="mga" two=""/>
		<l three="mic" two=""/>
		<l three="min" two=""/>
		<l three="mis" two=""/>
		<l three="mkd" two="mk"/>
		<l three="mkh" two=""/>
		<l three="mlg" two="mg"/>
		<l three="mlt" two="mt"/>
		<l three="mnc" two=""/>
		<l three="mni" two=""/>
		<l three="mno" two=""/>
		<l three="moh" two=""/>
		<l three="mon" two="mn"/>
		<l three="mos" two=""/>
		<l three="mri" two="mi"/>
		<l three="msa" two="ms"/>
		<l three="mul" two=""/>
		<l three="mun" two=""/>
		<l three="mus" two=""/>
		<l three="mwl" two=""/>
		<l three="mwr" two=""/>
		<l three="mya" two="my"/>
		<l three="myn" two=""/>
		<l three="myv" two=""/>
		<l three="nah" two=""/>
		<l three="nai" two=""/>
		<l three="nap" two=""/>
		<l three="nau" two="na"/>
		<l three="nav" two="nv"/>
		<l three="nbl" two="nr"/>
		<l three="nde" two="nd"/>
		<l three="ndo" two="ng"/>
		<l three="nds" two=""/>
		<l three="nep" two="ne"/>
		<l three="new" two=""/>
		<l three="nia" two=""/>
		<l three="nic" two=""/>
		<l three="niu" two=""/>
		<l three="nld" two="nl"/>
		<l three="nno" two="nn"/>
		<l three="nob" two="nb"/>
		<l three="nog" two=""/>
		<l three="non" two=""/>
		<l three="nor" two="no"/>
		<l three="nqo" two=""/>
		<l three="nso" two=""/>
		<l three="nub" two=""/>
		<l three="nwc" two=""/>
		<l three="nya" two="ny"/>
		<l three="nym" two=""/>
		<l three="nyn" two=""/>
		<l three="nyo" two=""/>
		<l three="nzi" two=""/>
		<l three="oci" two="oc"/>
		<l three="oji" two="oj"/>
		<l three="ori" two="or"/>
		<l three="orm" two="om"/>
		<l three="osa" two=""/>
		<l three="oss" two="os"/>
		<l three="ota" two=""/>
		<l three="oto" two=""/>
		<l three="paa" two=""/>
		<l three="pag" two=""/>
		<l three="pal" two=""/>
		<l three="pam" two=""/>
		<l three="pan" two="pa"/>
		<l three="pap" two=""/>
		<l three="pau" two=""/>
		<l three="peo" two=""/>
		<l three="per" two=""/>
		<l three="phi" two=""/>
		<l three="phn" two=""/>
		<l three="pli" two="pi"/>
		<l three="pol" two="pl"/>
		<l three="pon" two=""/>
		<l three="por" two="pt"/>
		<l three="pra" two=""/>
		<l three="pro" two=""/>
		<l three="pus" two="ps"/>
		<l three="qaa-qtz" two=""/>
		<l three="que" two="qu"/>
		<l three="raj" two=""/>
		<l three="rap" two=""/>
		<l three="rar" two=""/>
		<l three="roa" two=""/>
		<l three="roh" two="rm"/>
		<l three="rom" two=""/>
		<l three="ron" two="ro"/>
		<l three="rum" two=""/>
		<l three="run" two="rn"/>
		<l three="rup" two=""/>
		<l three="rus" two="ru"/>
		<l three="sad" two=""/>
		<l three="sag" two="sg"/>
		<l three="sah" two=""/>
		<l three="sai" two=""/>
		<l three="sal" two=""/>
		<l three="sam" two=""/>
		<l three="san" two="sa"/>
		<l three="sas" two=""/>
		<l three="sat" two=""/>
		<l three="scn" two=""/>
		<l three="sco" two=""/>
		<l three="sel" two=""/>
		<l three="sem" two=""/>
		<l three="sga" two=""/>
		<l three="sgn" two=""/>
		<l three="shn" two=""/>
		<l three="sid" two=""/>
		<l three="sin" two="si"/>
		<l three="sio" two=""/>
		<l three="sit" two=""/>
		<l three="sla" two=""/>
		<l three="slk" two="sk"/>
		<l three="slo" two=""/>
		<l three="slv" two="sl"/>
		<l three="sma" two=""/>
		<l three="sme" two="se"/>
		<l three="smi" two=""/>
		<l three="smj" two=""/>
		<l three="smn" two=""/>
		<l three="smo" two="sm"/>
		<l three="sms" two=""/>
		<l three="sna" two="sn"/>
		<l three="snd" two="sd"/>
		<l three="snk" two=""/>
		<l three="sog" two=""/>
		<l three="som" two="so"/>
		<l three="son" two=""/>
		<l three="sot" two="st"/>
		<l three="spa" two="es"/>
		<l three="sqi" two="sq"/>
		<l three="srd" two="sc"/>
		<l three="srn" two=""/>
		<l three="srp" two="sr"/>
		<l three="srr" two=""/>
		<l three="ssa" two=""/>
		<l three="ssw" two="ss"/>
		<l three="suk" two=""/>
		<l three="sun" two="su"/>
		<l three="sus" two=""/>
		<l three="sux" two=""/>
		<l three="swa" two="sw"/>
		<l three="swe" two="sv"/>
		<l three="syc" two=""/>
		<l three="syr" two=""/>
		<l three="tah" two="ty"/>
		<l three="tai" two=""/>
		<l three="tam" two="ta"/>
		<l three="tat" two="tt"/>
		<l three="tel" two="te"/>
		<l three="tem" two=""/>
		<l three="ter" two=""/>
		<l three="tet" two=""/>
		<l three="tgk" two="tg"/>
		<l three="tgl" two="tl"/>
		<l three="tha" two="th"/>
		<l three="tib" two=""/>
		<l three="tig" two=""/>
		<l three="tir" two="ti"/>
		<l three="tiv" two=""/>
		<l three="tkl" two=""/>
		<l three="tlh" two=""/>
		<l three="tli" two=""/>
		<l three="tmh" two=""/>
		<l three="tog" two=""/>
		<l three="ton" two="to"/>
		<l three="tpi" two=""/>
		<l three="tsi" two=""/>
		<l three="tsn" two="tn"/>
		<l three="tso" two="ts"/>
		<l three="tuk" two="tk"/>
		<l three="tum" two=""/>
		<l three="tup" two=""/>
		<l three="tur" two="tr"/>
		<l three="tut" two=""/>
		<l three="tvl" two=""/>
		<l three="twi" two="tw"/>
		<l three="tyv" two=""/>
		<l three="udm" two=""/>
		<l three="uga" two=""/>
		<l three="uig" two="ug"/>
		<l three="ukr" two="uk"/>
		<l three="umb" two=""/>
		<l three="und" two=""/>
		<l three="urd" two="ur"/>
		<l three="uzb" two="uz"/>
		<l three="vai" two=""/>
		<l three="ven" two="ve"/>
		<l three="vie" two="vi"/>
		<l three="vol" two="vo"/>
		<l three="vot" two=""/>
		<l three="wak" two=""/>
		<l three="wal" two=""/>
		<l three="war" two=""/>
		<l three="was" two=""/>
		<l three="wel" two=""/>
		<l three="wen" two=""/>
		<l three="wln" two="wa"/>
		<l three="wol" two="wo"/>
		<l three="xal" two=""/>
		<l three="xho" two="xh"/>
		<l three="yao" two=""/>
		<l three="yap" two=""/>
		<l three="yid" two="yi"/>
		<l three="yor" two="yo"/>
		<l three="ypk" two=""/>
		<l three="zap" two=""/>
		<l three="zbl" two=""/>
		<l three="zen" two=""/>
		<l three="zgh" two=""/>
		<l three="zha" two="za"/>
		<l three="zho" two="zh"/>
		<l three="znd" two=""/>
		<l three="zul" two="zu"/>
		<l three="zun" two=""/>
		<l three="zxx" two=""/>
		<l three="zza" two=""/>
		</xsl:variable>

<!-- **************************************************************** -->
<!--                 CHARACTER REPLACEMENT IN TEXT                    -->
<!-- **************************************************************** -->
<!--	<xsl:template match="text()">
		<xsl:choose>
			<xsl:when test="contains(.,'&#x2028;')">
				<xsl:call-template name="replace-char">
					<xsl:with-param name="str" select="."/>
					<xsl:with-param name="parent" select="name(parent::node())"/>
					</xsl:call-template>
				</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:template>
		
	<xsl:template name="replace-char">
		<xsl:param name="str"/>
		<xsl:param name="parent"/>
		<xsl:choose>
			<xsl:when test="contains(.,'&#x2028;')">
				<xsl:call-template name="replace-char">
					<xsl:with-param name="str" select="if ($parent='aff') then (replace($str,'&#x2028;',', ')) else (replace($str,'&#x2028;',' '))"/>
					<xsl:with-param name="parent" select="$parent"/>
					</xsl:call-template>
				</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$str"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:template>  -->

</xsl:stylesheet>

















