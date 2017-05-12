#!xsh
# -*- cperl -*-

if ("$xsh_grammar_file" = "") $xsh_grammar_file="src/xsh_grammar.xml";
if ("$db_stylesheet" = "") {
  # weired things happen in XML::LibXML/LibXSLT with new stylesheets!
#  $db_stylesheet="http://docbook.sourceforge.net/release/xsl/current/html/docbook.xsl";

  perl { ($db_stylesheet)=split(/\n/,`locate html/docbook.xsl`); };
  echo "Using DocBook XML stylesheet: $db_stylesheet"
}
if ("$db_stylesheet" = "") {
  echo "Cannot find docbook.xsl stylesheets! Exiting."
  exit 1;
}
if ("$html_stylesheet"="") $html_stylesheet="style.css";

quiet;
load-ext-dtd 1;
validation 1;
parser-completes-attributes 1;

open X = $xsh_grammar_file;

validation 0;
indent 1;

def transform_section {
  map { s/^[ \t]+//; s/\n[ \t]+/\n/g; } %section//code/descendant::text();
  foreach %section//code/descendant::tab {
    perl { $ws='  ' x count('string(@count)'); };
    insert text $ws instead of .;
  }
  map { $_='programlisting' } %section//code;
  foreach %section//xref {
    $linkend=string(@linkend);
    foreach X:(id("$linkend")) {
      if (name()='section') {
	$content=string(title);
      } else {
	if (@name) {
	  $content=string(@name);
	} else {
	  $content="$linkend";
	}
      }
    }
    add chunk "<ulink url='s_$linkend.html'>$content</ulink>" replace .;
  };
  foreach %section//link {
    map { $_='ulink' } .;
    add attribute url=${{string(@linkend)}} replace @linkend;
    map { $_="s_".$_.".html" } @url;
  }
  xslt S $db_stylesheet H params html.stylesheet="'$html_stylesheet'";
  clone H=H;
  xadd attribute target=_self into H://*[name()='a'];
  # move content of <a name="">..</a> out, so that it does not behave
  # as a link in browsers
  foreach H://*[name()='a' and not(@href)] {
    xmove ./node() after .;
  }
  for %section/@id {
    save_HTML H "doc/frames/s_${{string(.)}}.html";
    saveas S "doc/frames/s_${{string(.)}}.xml";
  }
  close H;
}

$toc_template="<html>
  <head>
    <title>Table of contents</title>
    <link href='$html_stylesheet' rel='stylesheet'/>
  </head>
  <body>
    <h2>XSH Reference</h2>
    <font color='#000090' size='-2'>
      <a href='t_syntax.html' target='mainIndex'>Syntax</a><br/>
      <a href='t_command.html' target='mainIndex'>Commands</a><br/>
      <a href='t_argtype.html' target='mainIndex'>Argument types</a><br/>
    </font>
    <hr/>
    <small></small>
  </body>
</html>";

new I "<html>
  <head>
    <title>XSH Reference</title>
    <link href='$html_stylesheet' rel='stylesheet'/>
  </head>
  <frameset cols='250,*'>
     <frame name='mainIndex' src='t_syntax.html'/>
     <frame name='mainWindow' src='s_intro.html'/>
     <noframes>
       <body>
         <p>XSH Reference - XSH is an XML Editing Shell</p>
         <small>Your browser must support frames to display this
         page correctly!</small>
       </body>
     </noframes>
  </frameset>
</html>";
save_HTML I 'doc/frames/index.html';
close I;

new S "<section id='intro'><title>Getting Started</title></section>";
%section=S://section;
xcopy X:/recdescent-xml/doc/description/node() into %section;
call transform_section;
close S;

# SYNTAX TOC
new T $toc_template;
for T:(/html/body/font/a[contains(@href,'syntax')]) {
  add chunk "<u><b/></u>" before .;
  move . into preceding-sibling::u/b;
}
add chunk "<a href='s_intro.html' target='mainWindow'>Getting started</a><br/>"
  into T:/html/body/small;

foreach X:/recdescent-xml/doc/section {
  $id=string(@id);
  add chunk "<a href='s_${id}.html' target='mainWindow'>${{string(title)}}</a><br/>"
    into T:/html/body/small;
  for (.) { # avoid selecting S:/
    new S "<section id='${id}'/>";
    %section=S:section;
  }
  xcopy ./node() into %section;

  %rules=X:(/recdescent-xml/rules/rule[documentation[id(@sections)[@id='$id']]]);
  if %rules[@type='command'] { $c='Commands' } else { $c='' }
  if %rules[@type='argtype'] { $a='Argument Types' } else { $a='' }
  if ('$c' != '' and '$a' != '') { $t='$a and $c' } else { $t='$a$c' }
  if ('$a$c' != '')
    add chunk "<simplesect>
                 <title>Related $t</title>
                 <variablelist/>
               </simplesect>" into %section;
  sort (@name|@id) { $a cmp $b } %rules;
  foreach %rules {
    add chunk "<varlistentry>
      <term><xref linkend='${{string(./@id)}}'/></term>
      <listitem></listitem>
    </varlistentry>" into %section/simplesect[last()]/variablelist;
    xcopy ./documentation/shortdesc/node()
      into %section/simplesect[last()]/variablelist/varlistentry[last()]/listitem;
  }
  call transform_section;
}

save_HTML T "doc/frames/t_syntax.html";
close T;

# COMMANDS AND TYPES
foreach { qw(command type) } {
  new T $toc_template;

  for T:(/html/body/font/a[contains(@href,'$__')]) {
    add chunk "<u><b/></u>" before .;
    move . into preceding-sibling::u/b;
  }
  if ('$__'='type') $__='argtype';
  %rules=X:(//rule[@type='$__']);
  sort (documentation/title|@name|@id) { lc($a) cmp lc($b) } %rules;
  foreach %rules {
    $ref=string(@id);
    new S "<section id='$ref'/>";
    cd X:id('$ref');
    %section=S:section;

    # TITLE
    if (./documentation/title) {
      xcopy ./documentation/title into %section;
    } else {
      add chunk "<title>${{string(@name)}}</title>" into %section;
    }
    map { s/\s+argument\s+type//i; $_=lcfirst } %section/title/text();
    for %section/title {
      add chunk "<a href='s_${ref}.html' target='mainWindow'>${{string(.)}}</a><br/>"
	into T:/html/body/small;
    }
    if ('$__'='argtype') { $t = 'argument type' }
    else { $t = 'command' }
    insert text " $t" into %section/title;
    #USAGE
    if (./documentation/usage) {
      add chunk "<simplesect><title>Usage</title></simplesect>" into %section;
      foreach (./documentation/usage) {
	add element para into %section/simplesect[last()];
      }
      copy ./documentation/usage into %section/simplesect[last()]/para;
      map { $_='literal' } %section/simplesect[last()]/para/usage;
    }

    #ALIASES
    if (./aliases/alias) {
      add chunk "<simplesect><title>Aliases</title><para><literal> </literal></para></simplesect>" into %section;
      foreach (./aliases/alias) {
	copy ./@name append %section/simplesect[last()]/para/literal/text()[last()];
	if (following-sibling::alias) {
	  add text ", " append %section/simplesect[last()]/para/literal/text()[last()];;
	}
      }
    }

    #DESCRIPTION
    if (./documentation/description) {
      add chunk "<simplesect><title>Description</title></simplesect>" into %section;
      xcopy ./documentation/description/node() into %section/simplesect[last()];
    }

    #SEE ALSO
    if (./documentation/see-also/ruleref) {
      add chunk "<simplesect><title>See Also</title><para/></simplesect>" into %section;
      foreach (./documentation/see-also/ruleref) {
	add element "<xref linkend='${{string(@ref)}}'/>" into %section/simplesect[last()]/para;
	if (following-sibling::ruleref) {
	  add text ", " into %section/simplesect[last()]/para;
	}
      }
    }
    #SECTIONS
    if (./documentation/@sections) {
      add chunk "<simplesect><title>Sections</title><para/></simplesect>" into %section;
      $s=string(./documentation/@sections);
      foreach { split /\s+/, $s } {
	add chunk "<xref linkend='$__'/>"
	  into %section/simplesect[last()]/para;
      };
      foreach %section/simplesect[last()]/para/xref {
	if (following-sibling::xref) {
	  add text ", " after . ;
	}
      }
    }
    call transform_section;
    close S;
  }
  save_HTML T "doc/frames/t_${__}.html";
  close T;
};
