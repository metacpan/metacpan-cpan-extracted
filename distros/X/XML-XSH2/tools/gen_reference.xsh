#!xsh
# -*- cperl -*-

$WARNINGS = 0;
catalog "/etc/xml/catalog";
$db_stylesheet = "http://docbook.sourceforge.net/release/xsl/current/html/docbook.xsl";

if { $xsh_grammar_file eq "" } $xsh_grammar_file="src/xsh_grammar.xml";
if { $db_stylesheet eq "" } {
  #  weired things happen in XML::LibXML/LibXSLT with new stylesheets!
  $db_stylesheet = { (split(/\n/,`locate html/docbook.xsl`))[0] };
  echo "Using DocBook XML stylesheet: " $db_stylesheet;
}
if { $db_stylesheet eq "" } {
  echo "Cannot find docbook.xsl stylesheets! Exiting."
  exit 1;
}
if { $html_stylesheet eq "" } $html_stylesheet="style.css";

quiet;
load-ext-dtd 1;
parser-completes-attributes 1;
parser_expands_xinclude 1;
xpath-extensions;
validation 1;

echo "Compiling ${db_stylesheet}";
$db_xslt := xslt --compile $db_stylesheet;

echo "Parsing ${$xsh_grammar_file}";
$X := open $xsh_grammar_file;
echo "Done.";

echo "creating directory doc/frames";
system mkdir -p doc/frames;

validation 0;
indent 1;

$dbg = 1;
def dbg $s {
  $dbg = $dbg+1;
  echo "debug" $dbg $s;
}

def transform_section $s {
  my $s_id = string($s/@id);
  #  echo $s_id;

  map :i { s/^[ \t]+//; s/\n[ \t]+/\n/g; } $s//code/descendant::text();

  foreach ($s//code/descendant::tab) {
    insert text "${(times(@count,'  '))}" replace .;
  }
  rename 'programlisting' $s//code;
  rename 'orderedlist' $s//enumerate;
  foreach $s/descendant::typeref {
    my $sl := insert element "simplelist type='inline'" before .;
    foreach split("\\s",@types) {
      foreach ($X/recdescent-xml/rules/rule[@type=current()]) {
	insert chunk
	  (concat("<member>",if(@id,concat("<xref linkend='",@id,"'/>"),@name),"</member>")) into $sl;
      }
    }
    rm .;
  }

  foreach $s//xref {
    my $l=string(@linkend);
    my $obj = id2($X,$l); # find linkend in the original document
    for $obj $c = string(if(self::section,title,if(@name,@name,@id))); # get label
    if ($obj/ancestor::section) { # we have a parent section
      # is it the same section?
      my $r_id = $obj/ancestor::section[last()]/@id;
      if ($r_id != $s_id) {
	# assume we are in a different section,
	# convert to an ulink
	add chunk "<ulink url='s_${r_id}.html#${l}'>${c}</ulink>" replace .;
      }
    } else {
      add chunk "<ulink url='s_${l}.html'>${c}</ulink>" replace .;
    }
  };
  foreach $s//link {
    rename 'ulink' .;
    add attribute "url=${(@linkend)}" replace @linkend;
    map { "s_".$_.".html" } @url;
  }
  undef $H;

  my $i=0;
  foreach ($s//simplesect[not(@id)] | $s//example[not(@id)]) {
    add attribute { "id=gen-".sprintf("%03d",$i++) } into .;
  }

  #echo "saving doc/frames/s_${s_id}.xml";
  save --file "doc/frames/s_${s_id}.xml" $s;
  #echo "transforming to HTML";
  $H := xslt --precompiled {$db_xslt} {$s} html.stylesheet='${html_stylesheet}';
  #echo "done.";
  #  $H := xslt $db_stylesheet $s html.stylesheet='${html_stylesheet}';
  xadd attribute "target=_self" into $H//*[name()='a'];
  # move content of <a name="">..</a> out, so that it does not behave
  # as a link in browsers
  foreach $H//*[name()='a' and not(@href)] {
    xmove ./node() after .;
  }
  #echo "saving doc/frames/s_${s_id}.html";
  save --format 'html' --file "doc/frames/s_${s_id}.html" $H;
  close $H;
}

echo 'index';
$toc_template=<<"EOF";
<html>
  <head>
    <title>Table of contents</title>
    <link href='${html_stylesheet}' rel='stylesheet'/>
  </head>
  <body>
    <h2>XSH2 Reference</h2>
    <font color='#000090' size='-2'>
      <a href='t_syntax.html' target='mainIndex'>Syntax</a><br/>
      <a href='t_command.html' target='mainIndex'>Commands</a><br/>
      <a href='t_argtype.html' target='mainIndex'>Argument Types</a><br/>
      <a href='t_function.html' target='mainIndex'>XPath Functions</a><br/>
    </font>
    <hr/>
    <small></small>
  </body>
</html>
EOF

$I := new <<"EOF";
<html>
  <head>
    <title>XSH2 Reference</title>
    <link href='${html_stylesheet}' rel='stylesheet'/>
  </head>
  <frameset cols='250,*'>
     <frame name='mainIndex' src='t_syntax.html'/>
     <frame name='mainWindow' src='s_intro.html'/>
     <noframes>
       <body>
         <p>XSH2 Reference - XSH2 is an XML Editing Shell</p>
         <small>Your browser must support frames to display this
         page correctly!</small>
       </body>
     </noframes>
  </frameset>
</html>
EOF

save --format html --file 'doc/frames/index.html' $I;
close $I;

echo 'sections';
$S := new "<section id='intro'><title>Getting Started</title></section>";
$section=$S//section;
xcopy $X/recdescent-xml/doc/description/node() into $section;
call transform_section $section;

close $S;


# SYNTAX TOC
$T := new $toc_template;
for $T/html/body/font/a[contains(@href,'syntax')] {
  echo 'sec';
  add chunk "<u><b/></u>" before .;
  move . into preceding-sibling::u/b;
}
add chunk "<a href='s_intro.html' target='mainWindow'>Getting started</a><br/>"
  into $T/html/body/small;

foreach $X/recdescent-xml/doc/section {
  $id=string(@id);
  echo $id;
  add chunk "<a href='s_${id}.html' target='mainWindow'>${(title)}</a><br/>"
    into $T/html/body/small;
  for (.) { # avoid selecting $S
    $S := new "<section id='${id}'/>";
    $section=$S/section;
  }
  xcopy ./node() into $section;

  $rules=$X/recdescent-xml/rules/rule[documentation[id(@sections)[@id=$id]]];
  if ($rules) {
    add chunk "<simplesect role='related'>
                 <title>Related Topics</title>
                 <variablelist/>
               </simplesect>" into $section;
  }
  foreach &{ sort :k(@name|@id) $rules } {
    add chunk "<varlistentry>
      <term><xref linkend='${(./@id)}'/></term>
      <listitem></listitem>
    </varlistentry>" into $section/simplesect[last()]/variablelist;
    xcopy ./documentation/shortdesc/node()
      into $section/simplesect[last()]/variablelist/varlistentry[last()]/listitem;
  }
  call transform_section $section;
}

save --format html --file "doc/frames/t_syntax.html" $T;
close $T;

# Commands, TYPES AND FUNCTIONS
foreach $part in { qw(command type function list) } {
  echo $part;
  $T := new $toc_template;

  for $T/html/body/font/a[contains(@href,$part)] {
    add chunk "<u><b/></u>" before .;
    move . into preceding-sibling::u/b;
  }
  if ($part='type') $part='argtype';
  $rules := sort :k lc(documentation/title|@name|@id) $X//rule[@type=$part];
  foreach { $rules } {
    my $ref=string(@id);
    echo "rule: ${ref}";
    $S := new "<section id='${ref}'/>";
    cd id2($X,$ref);
    $section=$S/section;

    # TITLE
    if (./documentation/title) {
      xcopy ./documentation/title into $section;
    } else {
      add chunk "<title>${(@name)}</title>" into $section;
    }
    map :i { s/\s+argument\s+type//i; $_=lcfirst if lc(lcfirst($_)) eq lcfirst} $section/title/text();
    for $section/title {
      add chunk "<a href='s_${ref}.html' target='mainWindow'>${(.)}</a><br/>"
	into $T/html/body/small;
    }
    if ($part='argtype') { $t = 'argument type' } else { $t=$part }
    insert text {" $t"} into $section/title;
    #USAGE
    if (./documentation/usage) {
      add chunk "<simplesect role='usage'><title>Usage</title></simplesect>" into $section;
      foreach (./documentation/usage) {
	add element para into $section/simplesect[last()];
      }
      copy ./documentation/usage into $section/simplesect[last()]/para;
      rename literal $section/simplesect[last()]/para/usage;
    }

    #ALIASES
    if (./aliases/alias) {
      add chunk "<simplesect role='aliases'><title>Aliases</title><para><literal> </literal></para></simplesect>" into $section;
      foreach (./aliases/alias) {
	copy ./@name append $section/simplesect[last()]/para/literal/text()[last()];
	if (following-sibling::alias) {
	  add text ", " append $section/simplesect[last()]/para/literal/text()[last()];;
	}
      }
    }

    #DESCRIPTION
    if (./documentation/description) {
      add chunk "<simplesect role='description'><title>Description</title></simplesect>" into $section;
      xcopy ./documentation/description/node() into $section/simplesect[last()];
    }

    #SEE ALSO
    if (./documentation/see-also/ruleref) {
      add chunk "<simplesect role='seealso'><title>See Also</title><para/></simplesect>" into $section;
      foreach (./documentation/see-also/ruleref) {
	add element "<xref linkend='${(@ref)}'/>" into $section/simplesect[last()]/para;
	if (following-sibling::ruleref) {
	  add text ", " into $section/simplesect[last()]/para;
	}
      }
    }
    #SECTIONS
    if (./documentation/@sections) {
      add chunk "<simplesect><title>Sections</title><para/></simplesect>" into $section;
      $s=string(./documentation/@sections);
      foreach my $name in { split /\s+/, $s } {
	add chunk "<xref linkend='${name}'/>"
	  into $section/simplesect[last()]/para;
      };
      foreach $section/simplesect[last()]/para/xref {
	if (following-sibling::xref) {
	  add text ", " after . ;
	}
      }
    }
    call transform_section $section;
    close $S;
  }
  echo "writing doc/frames/t_${part}.html";
  save --format HTML --file "doc/frames/t_${part}.html" $T;
  close $T;
};
