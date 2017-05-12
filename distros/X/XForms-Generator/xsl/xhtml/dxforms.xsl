<!-- ==================================================================== -->
<!-- = Name: XForms XSLT converstion to HTML                            = -->
<!-- =                                                                  = -->
<!-- = Author: D. Hageman <dhageman@dracken.com>                        = -->
<!-- =                                                                  = -->
<!-- = Copyright: 2002 D. Hageman (Dracken Technologies)                = -->
<!-- =                                                                  = -->
<!-- = License: This program is free software; you can redistribute it  = -->
<!-- =          and/or modify it under the same terms as Perl itself.   = -->
<!-- =                                                                  = -->
<!-- = Credit: This stylesheet is based on a version created by Rick    = -->
<!-- =         Frankel included in the perl module distribution         = -->
<!-- =         XML::XForms::Generator.                                  = -->
<!-- ==================================================================== -->

<xsl:stylesheet version="1.0"
 				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:str="http://exslt.org/strings"
				xmlns:func="http://exslt.org/functions"
				xmlns:local="urn:local"
				xmlns:xforms="http://www.w3.org/2002/xforms/cr" 
				extension-element-prefixes="dyn str func">

<xsl:output method="html"
			indent="yes"
			omit-xml-declaration="yes"/>

<xsl:strip-space elements="*"/>

<xsl:param name="list-size" select='1'/>
<xsl:param name="input_size" select='25'/>
<xsl:param name='textarea-rows' select='5'/>
<xsl:param name='textarea-cols' select='25'/>
<xsl:param name='encode-instance-data'/>

<xsl:variable name='urlencoding' select='"application/x-www-urlencoded"'/>
<xsl:variable name='instance-nodename' select='"xforms:instance/*/"'/>
<xsl:template match='xforms:label|xforms:model'/>

<!-- and their attributes -->
<xsl:template match='@*'>
  <xsl:copy/>
</xsl:template>

<!-- the meat of the matter, outermost groups -->
<xsl:template match='xforms:group[not(ancestor::xforms:group)]'>
  <form>
    <xsl:for-each select='local:get-model()'>
      <xsl:attribute name='action'>
        <xsl:value-of select='xforms:submission/@action'/>
      </xsl:attribute>
      <xsl:attribute name='method'>
        <xsl:value-of select='xforms:submission/@method'/>
      </xsl:attribute>
      <xsl:attribute name='id'>
        <xsl:choose>
          <xsl:when test='@id'>
            <xsl:value-of select='@id'/>
          </xsl:when>
          <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:for-each>
      <xsl:attribute name='enctype'>
        <xsl:value-of select='local:get-encoding()'/>
      </xsl:attribute>
    <xsl:apply-templates/>
    <xsl:if test='$encode-instance-data and local:get-encoding() != $urlencoding'>
      <xsl:call-template name='encode-instance'/>
    </xsl:if>
  </form>
</xsl:template>

<xsl:template name='encode-instance'>
  <xsl:for-each select='local:get-model()'>
    <input name='_instance' type='hidden'>
      <xsl:attribute name='value'>
        <xsl:text>&lt;?xml version="1.0"?&gt;</xsl:text>
        <xsl:for-each select='xforms:instance'>
          <xsl:text>&lt;xforms:instance </xsl:text>
          <xsl:text>xmlns:xforms="http://www.w3.org/2002/01/xforms"</xsl:text>
          <xsl:value-of select='local:encoded-attributes()'/>
          <xsl:text>&gt;</xsl:text>
          <xsl:apply-templates mode='encode'/>
          <xsl:text>&lt;/xforms:instance&gt;</xsl:text>
        </xsl:for-each>
        </xsl:attribute>
    </input>
  </xsl:for-each>
</xsl:template>

<xsl:template match='*' mode='encode'>
  <xsl:value-of select='local:encoded-node()'/>
  <xsl:apply-templates mode='encode'/>
  <xsl:value-of select='local:encoded-node(true())'/>
</xsl:template>

<xsl:template match='text()' mode='encode'>
  <xsl:value-of select='.'/>
</xsl:template>

<!-- CONTROLS -->

<!-- xforms:input -->
<xsl:template match='xforms:input'>
  <xsl:param name='index'/>
  <xsl:call-template name='input'>
    <xsl:with-param name='index' select='$index'/>
    <xsl:with-param name='type' select='"text"'/>
  </xsl:call-template>
</xsl:template>

<!-- xforms:secret -->
<xsl:template match='xforms:secret'>
  <xsl:param name='index'/>
  <xsl:call-template name='input'>
    <xsl:with-param name='type' select='"password"'/>
  </xsl:call-template>
</xsl:template>

<xsl:template match='xforms:textarea'>
  <xsl:param name='index'/>
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <div>
      <xsl:call-template name='get-class-attribute'/>
      <xsl:call-template name='label'/>
      <span class='ui'>
        <textarea 
          name='{local:get-path($index,false())}'
          rows='{$textarea-rows}' cols='{$textarea-cols}'
          >
          <xsl:call-template name='common-attributes'/>
          <xsl:value-of select='local:get-instance-data($index,true())'/>
        </textarea>
      </span>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template match='xforms:output'>
  <xsl:param name='index'/>
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <xsl:variable name='data' select='local:get-instance-data($index)'/>
    <span class='output'>
      <xsl:value-of select='$data'/>
      <input type="hidden"  
        name='{local:get-path($index,false())}'
        value='{$data}'/>
    </span>
  </xsl:if>
</xsl:template>

<xsl:template match='xforms:upload'>
  <xsl:param name='index'/>
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <div>
      <xsl:call-template name='get-class-attribute'/>
      <xsl:call-template name='label'/>
      <span class='ui'>
        <input 
          name='{local:get-path($index,false())}'
          type='file' accept='{@media-type}'
          value='{local:get-instance-data($index)}'
          >
          <xsl:call-template name='common-attributes'/>
        </input>
      </span>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template match='xforms:range'/>

<!-- xforms: trigger -->
<xsl:template match="xforms:trigger">
  <xsl:param name='index'/>
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <trigger name='{local:get-path($index,false())}'>
      <xsl:if test='@class'>
        <xsl:attribute name='class'>
          <xsl:value-of select='@class'/>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select='normalize-space(xforms:label)'/>
    </trigger>
  </xsl:if>
</xsl:template>

<xsl:template match='xforms:submit'>
  <input type='submit' value='{local:label-text()}'>
    <xsl:call-template name='common-attributes'/>
  </input>
</xsl:template>

<xsl:template match='xforms:select'>
  <xsl:param name='index'/>
  <!-- open selection not supported -->
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <xsl:variable name='appearance' select='@appearance'/>
    <xsl:variable name='data' select='local:get-instance-data($index)'/>
	<xsl:variable name="name" select="local:get-path($index,false())"/>
    <div>
      <xsl:call-template name='get-class-attribute'/>
      <xsl:call-template name='label'/>
      <span class='ui'>
		<xsl:choose>
			<xsl:when test="$appearance = 'compact'">
				<select name="{$name}" multiple="multiple" size="3">
					<xsl:apply-templates>
						<xsl:with-param name="index" select="$index"/>
						<xsl:with-param name="data" select="$data"/>
					</xsl:apply-templates>
				</select>
			</xsl:when>
			<xsl:when test="$appearance = 'minimal'">
				<select name="{$name}" multiple="multiple" size="5">
					<xsl:apply-templates>
						<xsl:with-param name="index" select="$index"/>
						<xsl:with-param name="data" select="$data"/>
					</xsl:apply-templates>
				</select>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="xforms:item">
					<xsl:variable name="value" select="xforms:value"/>
					<input name="{$name}" type="checkbox" value="{$value}">
						<xsl:for-each select="str:tokenize($data)">
							<xsl:if test="$value = .">
								<xsl:attribute name="checked">checked</xsl:attribute>
							</xsl:if>
						</xsl:for-each>
					</input>
					<xsl:value-of select="xforms:label"/>
					<br/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
      </span>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template match='xforms:select1'>
  <xsl:param name='index'/>
  <!-- open selection not supported -->
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <xsl:variable name='appearance' select='@appearance'/>
    <xsl:variable name='data' select='local:get-instance-data($index)'/>
	<xsl:variable name="name" select="local:get-path($index,false())"/>
    <div>
      <xsl:call-template name='get-class-attribute'/>
      <xsl:call-template name='label'/>
      <span class='ui'>
        <xsl:choose>
			<xsl:when test="$appearance = 'compact'">
				<select name="{$name}" size="1">
					<xsl:apply-templates>
						<xsl:with-param name="index" select="$index"/>
						<xsl:with-param name="data" select="$data"/>
					</xsl:apply-templates>
				</select>
			</xsl:when>
			<xsl:when test="$appearance = 'minimal'">
				<select name="{$name}" size="5">
					<xsl:apply-templates>
						<xsl:with-param name="index" select="$index"/>
						<xsl:with-param name="data" select="$data"/>
					</xsl:apply-templates>
				</select>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="xforms:item">
					<xsl:variable name="value" select="xforms:value"/>
					<input name="{$name}" type="radio" value="{$value}">
						<xsl:for-each select="str:tokenize($data)">
							<xsl:if test="$value = .">
								<xsl:attribute name="checked">checked</xsl:attribute>
							</xsl:if>
						</xsl:for-each>
					</input>
					<xsl:value-of select="xforms:label"/>
					<br/>
				</xsl:for-each>
			</xsl:otherwise>
        </xsl:choose>
      </span>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template match='xforms:choices'>
  <optgroup label='{local:label-text()}'>
    <xsl:apply-templates>
      <xsl:with-param name='data' select='$data'/>
    </xsl:apply-templates>
  </optgroup>
</xsl:template>

<xsl:template name='_item'>
  <xsl:param name='value'/>
  <xsl:param name='label'/>
  <xsl:param name='data'/>
  <option value='{$value}'>
    <xsl:for-each select='str:tokenize($data)'>
      <xsl:if test='$value = .'>
        <xsl:attribute name='selected'>selected</xsl:attribute>
      </xsl:if>
    </xsl:for-each>
    <xsl:value-of select='$label'/>
  </option>
</xsl:template>

<xsl:template match='xforms:item'>
  <xsl:param name='data'/>
  <xsl:call-template name='_item'>
    <xsl:with-param name='value' select='xforms:value'/>
    <xsl:with-param name='label' select='xforms:label'/>
    <xsl:with-param name='data' select='$data'/>
  </xsl:call-template>
</xsl:template>

<xsl:template match='xforms:itemset'>
  <xsl:param name='index'/>
  <xsl:param name='data'/>
  <xsl:variable name='label' select='xforms:label/@ref'/>
  <xsl:variable name='value' select='xforms:value/@ref'/>
  <xsl:variable name='path' select='local:get-path($index,true())'/>
  <xsl:for-each select='local:get-model()'>
    <xsl:for-each select='dyn:evaluate($path)'>
      <xsl:call-template name='_item'>
        <xsl:with-param name='value' select='dyn:evaluate($value)'/>
        <xsl:with-param name='label' select='dyn:evaluate($label)'/>
        <xsl:with-param name='data' select='$data'/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:for-each>
</xsl:template>

<xsl:template match='xforms:group'>
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <xsl:choose>
      <xsl:when test='@class="no-display"'>
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <div class="ui">
          <xsl:call-template name='common-attributes'/>
          <span class='label_group'>
			<xsl:value-of select="xforms:label"/>
          </span>
          <xsl:apply-templates/>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:template>

<xsl:template match='xforms:repeat'>
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <div>
      <xsl:call-template name='get-class-attribute'/>
      <xsl:call-template name='label'/>
      <span class='ui'>
        <xsl:variable name='context' select='./*'/>
        <xsl:variable name='path' select='local:get-path(1,true())'/>
        <xsl:variable name='min'
          select='local:get-constraint("@minOccurs")'/>
        <xsl:variable name='max' 
          select='local:get-constraint("@maxOccurs")'/>
        <xsl:for-each select='local:get-model()'>
          <xsl:variable name='loop'>
            <xsl:call-template name='get-repeat'>
              <xsl:with-param name='path' select='$path'/>
              <xsl:with-param name='min' select='$min'/>
              <xsl:with-param name='max' select='$max'/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:for-each select='str:tokenize($loop)'>
            <div class='repeat'>
              <xsl:apply-templates select='$context'>
                <xsl:with-param name='index' select='normalize-space(.)'/>
              </xsl:apply-templates>
            </div>
          </xsl:for-each>
        </xsl:for-each>  
      </span>
    </div>
  </xsl:if>
</xsl:template>

<!-- functions and utility (called) templates -->
<func:function name="local:get-instance-data">
  <xsl:param name='index'/>
  <xsl:param name='no-normalize'/>
  <xsl:variable name='path'>
    <xsl:value-of select='local:get-path($index)'/>
  </xsl:variable>
  <func:result>
    <xsl:if test='$path !=""'>
      <xsl:for-each select='local:get-model()'>
        <xsl:variable name='data'>
          <xsl:choose>
            <xsl:when test='starts-with($path,$instance-nodename)'>
              <xsl:value-of select='dyn:evaluate(concat($path,"[1]"))'/>              
            </xsl:when>
            <xsl:otherwise>
              <!-- must be calculate -->
              <xsl:for-each select='./xforms:instance'>
                <xsl:value-of select='dyn:evaluate($path)'/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test='$no-normalize'>
            <xsl:value-of select='$data'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='normalize-space($data)'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:if>
  </func:result>
</func:function>

<func:function name='local:get-model'>
  <!-- Question: unclear in the spec: do child elements
       inherit their parents model?? For now, assume yes -->
  <xsl:param name='model' select='ancestor-or-self::xforms:*/@model'/>
  <xsl:choose>
    <xsl:when  test='$model'>
      <func:result select='//xforms:model[@id=$model]'/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select='//xforms:model[1]'/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name='local:get-path'>
  <xsl:param name='index'/>
  <xsl:param name='use-full-path' select='true()'/>
  <xsl:variable name='path'>
    <xsl:choose>
      <xsl:when test='@bind'>
        <xsl:variable name='id' select='@bind'/>
        <xsl:for-each select='local:get-model()'>
          <xsl:for-each select='descendant::xforms:bind[@id=$id]'>
            <xsl:choose>
              <xsl:when test='@calculate and $use-full-path'>
                <xsl:value-of select='@calculate'/>
              </xsl:when>
              <xsl:when test='@nodeset'>
                <xsl:value-of 
                  select='local:get-parent-path($index,@nodeset,$use-full-path)'/>
                <xsl:value-of select='@nodeset'/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of 
                  select='local:get-parent-path($index,@ref,$use-full-path)'/>
                <xsl:value-of select='@ref'/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test='@nodeset'>
        <xsl:value-of 
          select='local:get-parent-path($index,@nodeset,$use-full-path)'/>
        <xsl:value-of select='@nodeset'/>
      </xsl:when>
      <xsl:when test='@ref'>
        <xsl:value-of 
          select='local:get-parent-path($index,@ref,$use-full-path)'/>
        <xsl:value-of select='@ref'/>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>
  <func:result>
    <xsl:choose>
    <xsl:when 
      test='local:get-encoding() = $urlencoding and not($use-full-path)'>
      <xsl:value-of select='local:basename($path)'/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select='$path'/>
    </xsl:otherwise>
  </xsl:choose>
  </func:result>
</func:function>

<func:function name='local:get-parent-path'>
  <xsl:param name='index'/>
  <xsl:param name='rel-path'/>
  <xsl:param name='use-full-path'/>
  <func:result>
    <xsl:if test='$use-full-path'>
      <xsl:value-of select='$instance-nodename'/>
    </xsl:if>
    <xsl:if test='not(starts-with($rel-path,"/"))'>
      <!-- not absolute path -->
      <xsl:if test='$use-full-path'>
        <xsl:text>/</xsl:text>
      </xsl:if>
      <xsl:for-each select='ancestor::*[
                            @ref 
                            and local-name() != "select1"
                            and local-name() != "select"
                            ]|ancestor::xforms:repeat'>
        <xsl:choose>
          <xsl:when test='local-name()="repeat" and @bind'>
            <xsl:variable name='id' select='@bind'/>
            <xsl:for-each select='local:get-model()'>
              <xsl:value-of select='descendant::xforms:bind[@id=$id]/@nodeset'/>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test='@nodeset'>
            <xsl:value-of select='@nodeset'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='@ref'/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test='position()=last()'>
          <xsl:text>[</xsl:text>
          <xsl:choose>
            <xsl:when test='$index != ""'>
              <xsl:value-of select='$index'/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>1</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:text>/</xsl:text>
      </xsl:for-each>
    </xsl:if>
  </func:result>
</func:function>

<func:function name='local:get-encoding'>
  <func:result>
    <xsl:for-each select='local:get-model()'>
      <xsl:choose>
        <xsl:when test='xforms:submission/@encoding'>
          <xsl:value-of select='xforms:submission/@encoding'/>
        </xsl:when>
        <xsl:otherwise>multipart/form-data</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </func:result>
</func:function>

<func:function name='local:label-text'>
  <xsl:for-each select='./xforms:label'>
    <xsl:variable name='data' select='local:get-instance-data(1)'/>
    <func:result>
      <xsl:choose>
        <xsl:when test='$data !=""'>
          <xsl:value-of select='$data'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='normalize-space(.)'/>
        </xsl:otherwise>
      </xsl:choose>
    </func:result>
  </xsl:for-each>
</func:function>

<func:function name='local:basename'>
  <xsl:param name='path'/>
  <xsl:for-each select='str:tokenize($path,"/")'>
    <xsl:if test='position()=last()'>
      <func:result>
      <xsl:value-of select='.'/>
    </func:result>
    </xsl:if>
  </xsl:for-each>
</func:function>

<func:function name='local:dirname'>
  <xsl:param name='path'/>
  <xsl:variable name='parent'>
    <xsl:for-each select='str:tokenize($path,"/")'>
      <xsl:if test='position() != last()'>
        <xsl:value-of select='.'/>
        <xsl:value-of select='"/"'/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>
  <func:result>
    <xsl:value-of select='$parent'/>
</func:result>
</func:function>

<!-- named templates -->
<xsl:template name='common-attributes'>
  <xsl:if test='@class'>
    <xsl:attribute name='class'>
      <xsl:value-of select='@class'/>
    </xsl:attribute>
  </xsl:if>
  <xsl:if test='@accessKey'>
    <xsl:attribute name='accesskey'>
      <xsl:value-of select='@accessKey'/>
    </xsl:attribute>
  </xsl:if>
</xsl:template>

<xsl:template name='label'>
  <span class='label'>
    <xsl:value-of select='local:label-text()'/><br/>
  </span>
</xsl:template>

<xsl:template name='input'>
  <xsl:param name='type'/>
  <xsl:param name='index'/>
  <xsl:variable name='relevant' select='local:get-constraint("@relevant")'/>
  <xsl:if test='$relevant != "false"'>
    <div>
      <xsl:call-template name='get-class-attribute'/>
      <xsl:call-template name='label'/>
      <span class='ui'>
        <input 
          name='{local:get-path($index,false())}' 
          value='{local:get-instance-data($index)}'>
          <xsl:attribute name='type'>
            <xsl:value-of select='$type'/>
          </xsl:attribute>
		  <xsl:attribute name='size'>
		  	<xsl:value-of select='$input_size'/>
		  </xsl:attribute>
          <xsl:call-template name='common-attributes'/>
        </input>
      </span>
    </div>
  </xsl:if>
  <xsl:text>
  </xsl:text>
</xsl:template>

<xsl:template name='get-repeat'>
  <!-- must be called in model context -->
  <xsl:param name='path'/>
  <xsl:param name='min'/>
  <xsl:param name='max'/>

  <xsl:variable name='node-count' select='count(dyn:evaluate($path))'/>
  <xsl:variable name='parent' select='local:dirname($path)'/>
  <xsl:variable name='count'>
    <xsl:choose>
      <xsl:when test='$node-count &lt; $min'>
        <xsl:value-of select='$min'/>
      </xsl:when>
      <xsl:when test='$max = "unbounded"'>
        <xsl:value-of select='$node-count'/>
      </xsl:when>
      <xsl:when test='$node-count &gt; $max'>
        <xsl:value-of select='$max'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='$node-count'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:call-template name='_get-repeat'>
    <xsl:with-param name='value' select='""'/>
    <xsl:with-param name='i' select='1'/>
    <xsl:with-param name='count' select='$count'/>
  </xsl:call-template>
</xsl:template>

<func:function name='local:get-constraint'>
  <xsl:param name='attribute'/>
  <xsl:variable name ='id'>
    <!-- emacs is messing up, on indent of empty var here... -->
    <xsl:value-of select='@bind'/>
  </xsl:variable>
  <xsl:variable name='scalars'>
    <xsl:text>@type @maxOccurs @minOccurs</xsl:text>
  </xsl:variable>
  <func:result>
    <xsl:if test='$id != ""'>
        <xsl:variable name='value'>
          <xsl:for-each select='local:get-model()'>
            <xsl:for-each select='descendant::xforms:bind[@id=$id]'>
              <xsl:value-of select='dyn:evaluate($attribute)'/>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test='$value = ""'>
            <xsl:value-of 
              select='local:get-constraint-info($attribute,"default")'/>
          </xsl:when>
          <xsl:when test='contains($scalars,$attribute)'>
            <xsl:value-of select='$value'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select='local:get-model()'>
              <xsl:for-each select='xforms:instance'>
                <xsl:value-of select='dyn:evaluate($value)'/>
              </xsl:for-each>
            </xsl:for-each>
            <!-- not handled yet -->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
  </func:result>
</func:function>

<func:function name='local:get-constraint-info'>
  <xsl:param name='name'/>
  <xsl:param name='attribute'/>
  <xsl:variable name='scalars'>
    <xsl:text>@type @maxOccurs @minOccurs</xsl:text>
  </xsl:variable>
  
  <func:result>
    <xsl:choose>
      <xsl:when test='$attribute="scalar"'>
        <xsl:value-of select='contains($scalars,$name)'/>
      </xsl:when>
      <xsl:when test='$attribute="default"'>
        
        <xsl:choose>
          <xsl:when test='$name="@type"'>
            <xsl:text>string</xsl:text>
          </xsl:when>
          <xsl:when test='$name="@readOnly"'>
            <xsl:value-of select='false()'/>
          </xsl:when>
          <xsl:when test='$name="@required"'>
            <xsl:value-of select='false()'/>
          </xsl:when>
          <xsl:when test='$name="@relevant"'>
            <xsl:value-of select='true()'/>
          </xsl:when>
          <xsl:when test='$name="@isValid"'>
            <xsl:value-of select='true()'/>
          </xsl:when>
          <xsl:when test='$name="@maxOccurs"'>
            <xsl:text>unbounded</xsl:text>
          </xsl:when>
          <xsl:when test='$name="@minOccurs"'>
            <xsl:value-of select='0'/>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </func:result>
</func:function> 

<func:function name='local:encoded-node'>
  <xsl:param name='end'/>
  <func:result>
  <xsl:text>&lt;</xsl:text>
  <xsl:if test='$end'>
    <xsl:text>/</xsl:text>
  </xsl:if>
  <xsl:if test='namespace-uri()'>
    <xsl:value-of select='namespace-uri()'/>:
  </xsl:if>
  <xsl:value-of select='local-name()'/>
  <xsl:if test='not($end)'>
    <xsl:value-of select='local:encoded-attributes()'/>
  </xsl:if>
  <xsl:text>&gt;</xsl:text>
</func:result>
</func:function>

<func:function name='local:encoded-attributes'>
  <func:result>
    <xsl:for-each select='@*'>
      <xsl:text> </xsl:text>
      <xsl:value-of select='local-name()'/>
      <xsl:text>=</xsl:text>
      <xsl:text>"</xsl:text>
      <xsl:value-of select='.'/>
      <xsl:text>"</xsl:text>
    </xsl:for-each>
</func:result>
</func:function>

<xsl:template name='_get-repeat'>
  <xsl:param name='value'/>
  <xsl:param name='i'/>
  <xsl:param name='count'/>
  <xsl:choose>
    <xsl:when test='$i > $count'>
    <xsl:value-of select='$value'/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name='_get-repeat'>
        <xsl:with-param name='value' select='concat($value," ",$i)'/>
        <xsl:with-param name='i' select='$i+1'/>
        <xsl:with-param name='count' select='$count'/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name='get-class-attribute'>
  <xsl:param name='class' select='"ui"'/>
  <xsl:variable name='required' 
          select='local:get-constraint("@required")'/>
  <xsl:variable name='valid'
    select='local:get-constraint("@isValid")'/>

  <xsl:attribute name='class'>
    <xsl:value-of select='$class'/>
    <xsl:if test='$required = "true"'>
      <xsl:text> required</xsl:text>
    </xsl:if>
    <xsl:if test='$valid = "false"'>
      <xsl:text> invalid</xsl:text>
    </xsl:if>
  </xsl:attribute>
</xsl:template>

</xsl:stylesheet>
