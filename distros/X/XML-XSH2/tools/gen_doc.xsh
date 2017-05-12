#!xsh
# -*- cperl -*-

$xsh_grammar_file ||= "src/xsh_grammar.xml";

quiet;
load-ext-dtd 1;
validation 1;
parser-completes-attributes 1;
xpath-extensions;

$x := open $xsh_grammar_file;

load-ext-dtd 0;
validation 0;

$d := create <<EOF;
<!DOCTYPE article PUBLIC "-//OASIS//DTD DocBook XML V4.3//EN" 
  "http://www.oasis-open.org/docbook/xml/4.3/docbookx.dtd">
<article>
  <title>XSH2 Reference</title>
  <section id="intro">
    <title>XSH2 Language</title>
  </section>
  <section id="cmd">
    <title>Command Reference</title>
  </section>
  <section id="type">
    <title>Type Reference</title>
  </section>
  <section id="function">
    <title>XPath Extension Function Reference</title>
  </section>
</article>
EOF

xcopy $x/recdescent-xml/doc/description/node() into $d/article/section[@id='intro'];
xcopy $x/recdescent-xml/doc/section into $d/article/section[@id='intro'];


foreach $d/article/section[@id='intro']/section {
  my $id=@id;
  my $rules=$x/recdescent-xml/rules/rule[documentation[id(@sections)[@id=$id]]];
  echo "section: ${id}, rules: " count($rules);

  if $rules[@type='command' or @type='argtype' or @type='function']
    add chunk <<EOF append .;
<section>
  <title>Related topics</title>
  <para>
    <variablelist/>
  </para>
 </section>
EOF

  my $varlist=./section[last()]/para/variablelist;
  foreach &{ sort :k (@name|@id) $rules} {
    add chunk <<"EOF" into $varlist;
    <varlistentry>
      <term><xref linkend='${(./@id)}'/></term>
      <listitem><para/></listitem>
    </varlistentry>
EOF
  for ./documentation/shortdesc/node() xcopy . into $varlist/varlistentry[last()]/listitem/para;
  }
}

foreach my $__ in { qw(cmd type function) } {
  print "FILLING: ${__}"; print "";
  my $sec=$d/article/section[@id=$__];
  if ($__='type') $__='argtype';
  if ($__='cmd') $__='command';
  my $type := sort :k (@name|documentation/title)[1] $x//rule[@type=$__];
  foreach {$type} {
    cd xsh:id2($x,@id);
    # TITLE
    copy xsh:new-element('section','id',@id,'role',$__) into $sec;
    my $section=$sec/section[last()];
    if (./documentation/title) {
      xcopy ./documentation/title into $section;
    } else {
      add chunk concat("<title>",string(@name),"</title>") into $section;
    }
    map :i { s/\s+argument\s+type//i; $_=lcfirst } $section/title/text();

    #USAGE
    if (./documentation/usage) {
      my $us :=
	add chunk "<simplesect role='usage'><title>Usage</title><para></para></simplesect>"
	into $section;
      xcopy ./documentation/usage into $us/para;
      rename 'literal' $us/para/usage;
    }

    #ALIASES
    if (./aliases/alias) {
      my $us :=
	add chunk <<CHUNK into $section;
 <simplesect role='aliases'>
   <title>Aliases</title>
   <para><literal> </literal></para>
 </simplesect>
CHUNK
      foreach (./aliases/alias) {
	copy ./@name append $us/para/literal/text()[last()];
	if (following-sibling::alias) {
	  add text ", " append $us/para/literal/text()[last()];
	}
      }
    }

    #DESCRIPTION
    if (./documentation/description) {
      my $us :=
	add chunk "<simplesect role='description'><title>Description</title></simplesect>"
	  into $section;
      xcopy ./documentation/description/node() into $us;
    }

    #SEE ALSO
    if (./documentation/see-also/ruleref) {
      my $us :=
	add chunk "<simplesect role='seealso'><title>See Also</title><para/></simplesect>"
	  into $section;
      foreach (./documentation/see-also/ruleref) {
	copy xsh:new-element('xref','linkend',string(@ref)) into $us/para;
	if (following-sibling::ruleref) add text ", " into $us/para;
      }
    }
  }
};

map :i { s/^[ \t]+//; s/\n[ \t]+/\n/g; } $d//code/descendant::text();
foreach $d//tab {
  insert text {"  " x literal('@count')} replace .;
}
rename 'programlisting' $d//code;
rename 'orderedlist' $d//enumerate;

foreach $d/descendant::typeref {
  my $sl := insert element "simplelist type='inline'" before .;
  foreach xsh:split("\\s",@types) {
    foreach ($x/recdescent-xml/rules/rule[@type=current()]) {
      insert chunk
	(concat("<member>",if(@id,concat("<xref linkend='",@id,"'/>"),@name),"</member>")) into $sl;
    }
  }
  rm .;
}


foreach $d//xref {
  rename 'link' .;
  my $target = xsh:id2($x,@linkend);
  if ($target/@name or $target/@id) {
    insert text xsh:if($target/@name,
		       $target/@name,
		       $target/@id) into .;
  } else {
    if ($target) {
      die "Cannot find target ${(@linkend)}";
    } else {
      die "Cannot create label for  target ${(serialize($target))}";
    }
  }
};

foreach $d//variablelist {
  my $termlength= xsh:max(
    xsh:map(varlistentry/term,'string-length(normalize-space(.))')
  );
  copy xsh:new-attribute('termlength',$termlength) into .;
}

indent 1;
rename 'informalexample' //example[not(title)]; # for validity sake
for { 1..5 } {
  rename { 'sect'.$__ } //section[not(ancestor::section)]; # for validity sake
}
save --file 'doc/xsh_reference.xml' $d;
