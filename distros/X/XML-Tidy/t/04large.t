use Test;
BEGIN { plan tests => 15 }
use XML::Tidy;
my $tobj; ok(1);
sub diff { # test for difference between mem XPath obj && disk XML file
  my $tidy = shift() || return(0);
  my $tstd = shift();   return(0) unless(defined($tstd) && $tstd);
  my($root)= $tidy->findnodes('/');
  my $xdat = qq(<?xml version="1.0" encoding="utf-8"?>\n);
  $xdat .= $_->toString() for($root->getChildNodes());
  # split root PI's && comments with newlines again
  $xdat =~ s/\?><\?/\?>\n<\?/g;
  $xdat =~ s/\?><!--/\?>\n<!--/g;
  $xdat =~ s/--></-->\n</g;
  $xdat =~ s/><!--/>\n<!--/g;
  $tstd =~ s/\?><\?/\?>\n<\?/g;
  $tstd =~ s/\?><!--/\?>\n<!--/g;
  $tstd =~ s/--></-->\n</g;
  $tstd =~ s/><!--/>\n<!--/g;
  if($xdat eq $tstd) { return(1); } # 1 == files same
  else               {
    my @xdat = split(/\n/, $xdat);
    my @tstd = split(/\n/, $tstd);
    for(my $indx = 0; $indx < @xdat; $indx++) {
      if($xdat[$indx] ne $tstd[$indx]) {
        print "indx:" .       $indx  . "\n" .
              "xdat:" . $xdat[$indx] . "\n" .
              "tstd:" . $tstd[$indx] . "\n";
        if     ($xdat[$indx + 1] eq $tstd[$indx]) {
          splice(@xdat, $indx);
        } elsif($tstd[$indx + 1] eq $xdat[$indx]) {
          splice(@tstd, $indx);
        }
      }
    }
    return(0);
  } # 0 == files diff
}

my $tst2 = q|<?xml version="1.0" encoding="utf-8"?>
<?sample0 processing-instruction="this"?>
<?sample1 processing-instruction="that"?>
<!-- Comment0 outside root element -->
<!-- Comment1 outside root element -->
<grammar xmlns="http://relaxng.org/ns/structure/1.0" xmlns:x="http://www.w3.org/1999/xhtml" ns="http://www.w3.org/2002/06/xhtml2">
  <!-- Comment0 inside root element -->
  <!-- Comment1 inside root element -->
  <x:h1>RELAX NG schema for XHTML 2.0</x:h1>
  <x:pre>
Copyright (C)2003-2004 W3C(R) (MIT, ERCIM, Keio), All Rights Reserved.

Editor:   Masayasu Ishikawa mimasa@w3.org
Revision: $Id: xhtml2.rng,v 1.34 2004/07/21 10:33:05 mimasa Exp $

Permission to use, copy, modify and distribute this RELAX NG schema
for XHTML 2.0 and its accompanying documentation for any purpose and
without fee is hereby granted in perpetuity, provided that the above
copyright notice and this paragraph appear in all copies. The copyright
holders make no representation about the suitability of this RELAX NG
schema for any purpose.

It is provided "as is" without expressed or implied warranty.
For details, please refer to the W3C software license at:
    <x:a href="http://www.w3.org/Consortium/Legal/copyright-software">http://www.w3.org/Consortium/Legal/copyright-software</x:a>
  </x:pre>
  <div>
    <x:h2>XHTML 2.0 modules</x:h2>
    <x:h3>Attribute Collections Module</x:h3>
    <include href="xhtml-attribs-2.rng" />
    <x:h3>Document Module</x:h3>
    <include href="xhtml-document-2.rng" />
    <x:h3>Structural Module</x:h3>
    <include href="xhtml-structural-2.rng" />
    <x:h3>Text Module</x:h3>
    <include href="xhtml-text-2.rng" />
    <x:h3>Hypertext Module</x:h3>
    <include href="xhtml-hypertext-2.rng" />
    <x:h3>List Module</x:h3>
    <include href="xhtml-list-2.rng" />
    <x:h3>Metainformation Module</x:h3>
    <include href="xhtml-meta-2.rng" />
    <x:h3>Object Module</x:h3>
    <include href="xhtml-object-2.rng" />
    <x:h3>Scripting Module</x:h3>
    <include href="xhtml-script-2.rng" />
    <x:h3>Style Attribute Module</x:h3>
    <include href="xhtml-inlstyle-2.rng" />
    <x:h3>Style Sheet Module</x:h3>
    <include href="xhtml-style-2.rng" />
    <x:h3>Tables Module</x:h3>
    <include href="xhtml-table-2.rng" />
    <x:h3>Support Modules</x:h3>
    <x:h4>Datatypes Module</x:h4>
    <include href="xhtml-datatypes-2.rng" />
    <x:h4>Events Module</x:h4>
    <include href="xhtml-events-2.rng" />
    <x:h4>Param Module</x:h4>
    <include href="xhtml-param-2.rng" />
    <x:h4>Caption Module</x:h4>
    <include href="xhtml-caption-2.rng" />
  </div>
  <div>
    <x:h2>XML Events module</x:h2>
    <include href="xml-events-1.rng" />
  </div>
  <div>
    <x:h2>Ruby module</x:h2>
    <include href="full-ruby-1.rng">
      <define name="Inline.class">
        <notAllowed />
      </define>
      <define name="NoRuby.content">
        <ref name="Text.model" />
      </define>
    </include>
    <define name="Inline.model">
      <notAllowed />
    </define>
    <define name="Text.class" combine="choice">
      <ref name="ruby" />
    </define>
  </div>
  <div>
    <x:h2>XForms module</x:h2>
    <x:p>To-Do: work out integration of XForms</x:p>
    <!--include href="xforms-11.rng"/-->
  </div>
  <div>
    <x:h2>XML Schema instance module</x:h2>
    <include href="XMLSchema-instance.rng" />
  </div>
</grammar>|;
my $tstI = q|<?xml version="1.0" encoding="utf-8"?>
<?sample0 processing-instruction="this"?>
<?sample1 processing-instruction="that"?>
<!-- Comment0 outside root element -->
<!-- Comment1 outside root element -->
<grammar xmlns="http://relaxng.org/ns/structure/1.0" xmlns:x="http://www.w3.org/1999/xhtml" ns="http://www.w3.org/2002/06/xhtml2">
  <!-- Comment0 inside root element -->
  <!-- Comment1 inside root element -->
  <x:h1>RELAX NG schema for XHTML 2.0</x:h1>
  <x:pre>
Copyright (C)2003-2004 W3C(R) (MIT, ERCIM, Keio), All Rights Reserved.

Editor:   Masayasu Ishikawa mimasa@w3.org
Revision: $Id: xhtml2.rng,v 1.34 2004/07/21 10:33:05 mimasa Exp $

Permission to use, copy, modify and distribute this RELAX NG schema
for XHTML 2.0 and its accompanying documentation for any purpose and
without fee is hereby granted in perpetuity, provided that the above
copyright notice and this paragraph appear in all copies. The copyright
holders make no representation about the suitability of this RELAX NG
schema for any purpose.

It is provided "as is" without expressed or implied warranty.
For details, please refer to the W3C software license at:
    <x:a href="http://www.w3.org/Consortium/Legal/copyright-software">http://www.w3.org/Consortium/Legal/copyright-software</x:a>
  </x:pre>
  <div>
    <x:h2>XHTML 2.0 modules</x:h2>
    <x:h3>Attribute Collections Module</x:h3>
    <include href="xhtml-attribs-2.rng" />
    <x:h3>Document Module</x:h3>
    <include href="xhtml-document-2.rng" />
    <x:h3>Structural Module</x:h3>
    <include href="xhtml-structural-2.rng" />
    <x:h3>Text Module</x:h3>
    <include href="xhtml-text-2.rng" />
    <x:h3>Hypertext Module</x:h3>
    <include href="xhtml-hypertext-2.rng" />
    <x:h3>List Module</x:h3>
    <include href="xhtml-list-2.rng" />
    <x:h3>Metainformation Module</x:h3>
    <include href="xhtml-meta-2.rng" />
    <x:h3>Object Module</x:h3>
    <include href="xhtml-object-2.rng" />
    <x:h3>Scripting Module</x:h3>
    <include href="xhtml-script-2.rng" />
    <x:h3>Style Attribute Module</x:h3>
    <include href="xhtml-inlstyle-2.rng" />
    <x:h3>Style Sheet Module</x:h3>
    <include href="xhtml-style-2.rng" />
    <x:h3>Tables Module</x:h3>
    <include href="xhtml-table-2.rng" />
    <x:h3>Support Modules</x:h3>
    <x:h4>Datatypes Module</x:h4>
    <include href="xhtml-datatypes-2.rng" />
    <x:h4>Events Module</x:h4>
    <include href="xhtml-events-2.rng" />
    <x:h4>Param Module</x:h4>
    <include href="xhtml-param-2.rng" />
    <x:h4>Caption Module</x:h4>
    <include href="xhtml-caption-2.rng" />
  </div>
  <div>
    <x:h2>XML Events module</x:h2>
    <include href="xml-events-1.rng" />
  </div>
  <div>
    <x:h2>Ruby module</x:h2>
    <include href="full-ruby-1.rng">
      <define name="Inline.class">
        <notAllowed />
      </define>
      <define name="NoRuby.content">
        <ref name="Text.model" />
      </define>
    </include>
    <define name="Inline.model">
      <notAllowed />
    </define>
    <define name="Text.class" combine="choice">
      <ref name="ruby" />
    </define>
  </div>
  <div>
    <x:h2>XForms module</x:h2>
    <x:p>To-Do: work out integration of XForms</x:p>
    <!--include href="xforms-11.rng"/-->
  </div>
  <div>
    <x:h2>XML Schema instance module</x:h2>
    <include href="XMLSchema-instance.rng" />
  </div>
</grammar>|;
my $tstJ = q|<?xml version="1.0" encoding="utf-8"?>
<?sample0 processing-instruction="this"?>
<?sample1 processing-instruction="that"?>
<!-- Comment0 outside root element -->
<!-- Comment1 outside root element -->
<grammar xmlns="http://relaxng.org/ns/structure/1.0" xmlns:x="http://www.w3.org/1999/xhtml" ns="http://www.w3.org/2002/06/xhtml2"><!-- Comment0 inside root element --><!-- Comment1 inside root element --><x:h1>RELAX NG schema for XHTML 2.0</x:h1><x:pre>
Copyright (C)2003-2004 W3C(R) (MIT, ERCIM, Keio), All Rights Reserved.

Editor:   Masayasu Ishikawa mimasa@w3.org
Revision: $Id: xhtml2.rng,v 1.34 2004/07/21 10:33:05 mimasa Exp $

Permission to use, copy, modify and distribute this RELAX NG schema
for XHTML 2.0 and its accompanying documentation for any purpose and
without fee is hereby granted in perpetuity, provided that the above
copyright notice and this paragraph appear in all copies. The copyright
holders make no representation about the suitability of this RELAX NG
schema for any purpose.

It is provided "as is" without expressed or implied warranty.
For details, please refer to the W3C software license at:
    <x:a href="http://www.w3.org/Consortium/Legal/copyright-software">http://www.w3.org/Consortium/Legal/copyright-software</x:a></x:pre><div><x:h2>XHTML 2.0 modules</x:h2><x:h3>Attribute Collections Module</x:h3><include href="xhtml-attribs-2.rng" /><x:h3>Document Module</x:h3><include href="xhtml-document-2.rng" /><x:h3>Structural Module</x:h3><include href="xhtml-structural-2.rng" /><x:h3>Text Module</x:h3><include href="xhtml-text-2.rng" /><x:h3>Hypertext Module</x:h3><include href="xhtml-hypertext-2.rng" /><x:h3>List Module</x:h3><include href="xhtml-list-2.rng" /><x:h3>Metainformation Module</x:h3><include href="xhtml-meta-2.rng" /><x:h3>Object Module</x:h3><include href="xhtml-object-2.rng" /><x:h3>Scripting Module</x:h3><include href="xhtml-script-2.rng" /><x:h3>Style Attribute Module</x:h3><include href="xhtml-inlstyle-2.rng" /><x:h3>Style Sheet Module</x:h3><include href="xhtml-style-2.rng" /><x:h3>Tables Module</x:h3><include href="xhtml-table-2.rng" /><x:h3>Support Modules</x:h3><x:h4>Datatypes Module</x:h4><include href="xhtml-datatypes-2.rng" /><x:h4>Events Module</x:h4><include href="xhtml-events-2.rng" /><x:h4>Param Module</x:h4><include href="xhtml-param-2.rng" /><x:h4>Caption Module</x:h4><include href="xhtml-caption-2.rng" /></div><div><x:h2>XML Events module</x:h2><include href="xml-events-1.rng" /></div><div><x:h2>Ruby module</x:h2><include href="full-ruby-1.rng"><define name="Inline.class"><notAllowed /></define><define name="NoRuby.content"><ref name="Text.model" /></define></include><define name="Inline.model"><notAllowed /></define><define name="Text.class" combine="choice"><ref name="ruby" /></define></div><div><x:h2>XForms module</x:h2><x:p>To-Do: work out integration of XForms</x:p><!--include href="xforms-11.rng"/--></div><div><x:h2>XML Schema instance module</x:h2><include href="XMLSchema-instance.rng" /></div></grammar>|;
my $tstK = q|<?xml version="1.0" encoding="utf-8"?>
<?sample0 processing-instruction="this"?>
<?sample1 processing-instruction="that"?>
<!-- Comment0 outside root element -->
<!-- Comment1 outside root element -->
<grammar xmlns="http://relaxng.org/ns/structure/1.0" xmlns:x="http://www.w3.org/1999/xhtml" ns="http://www.w3.org/2002/06/xhtml2">
  <!-- Comment0 inside root element -->
  <!-- Comment1 inside root element -->
  <x:h1>RELAX NG schema for XHTML 2.0</x:h1>
  <x:pre>
Copyright (C)2003-2004 W3C(R) (MIT, ERCIM, Keio), All Rights Reserved.

Editor:   Masayasu Ishikawa mimasa@w3.org
Revision: $Id: xhtml2.rng,v 1.34 2004/07/21 10:33:05 mimasa Exp $

Permission to use, copy, modify and distribute this RELAX NG schema
for XHTML 2.0 and its accompanying documentation for any purpose and
without fee is hereby granted in perpetuity, provided that the above
copyright notice and this paragraph appear in all copies. The copyright
holders make no representation about the suitability of this RELAX NG
schema for any purpose.

It is provided "as is" without expressed or implied warranty.
For details, please refer to the W3C software license at:
    <x:a href="http://www.w3.org/Consortium/Legal/copyright-software">http://www.w3.org/Consortium/Legal/copyright-software</x:a>
  </x:pre>
  <div>
    <x:h2>XHTML 2.0 modules</x:h2>
    <x:h3>Attribute Collections Module</x:h3>
    <include href="xhtml-attribs-2.rng" />
    <x:h3>Document Module</x:h3>
    <include href="xhtml-document-2.rng" />
    <x:h3>Structural Module</x:h3>
    <include href="xhtml-structural-2.rng" />
    <x:h3>Text Module</x:h3>
    <include href="xhtml-text-2.rng" />
    <x:h3>Hypertext Module</x:h3>
    <include href="xhtml-hypertext-2.rng" />
    <x:h3>List Module</x:h3>
    <include href="xhtml-list-2.rng" />
    <x:h3>Metainformation Module</x:h3>
    <include href="xhtml-meta-2.rng" />
    <x:h3>Object Module</x:h3>
    <include href="xhtml-object-2.rng" />
    <x:h3>Scripting Module</x:h3>
    <include href="xhtml-script-2.rng" />
    <x:h3>Style Attribute Module</x:h3>
    <include href="xhtml-inlstyle-2.rng" />
    <x:h3>Style Sheet Module</x:h3>
    <include href="xhtml-style-2.rng" />
    <x:h3>Tables Module</x:h3>
    <include href="xhtml-table-2.rng" />
    <x:h3>Support Modules</x:h3>
    <x:h4>Datatypes Module</x:h4>
    <include href="xhtml-datatypes-2.rng" />
    <x:h4>Events Module</x:h4>
    <include href="xhtml-events-2.rng" />
    <x:h4>Param Module</x:h4>
    <include href="xhtml-param-2.rng" />
    <x:h4>Caption Module</x:h4>
    <include href="xhtml-caption-2.rng" />
  </div>
  <div>
    <x:h2>XML Events module</x:h2>
    <include href="xml-events-1.rng" />
  </div>
  <div>
    <x:h2>Ruby module</x:h2>
    <include href="full-ruby-1.rng">
      <define name="Inline.class">
        <notAllowed />
      </define>
      <define name="NoRuby.content">
        <ref name="Text.model" />
      </define>
    </include>
    <define name="Inline.model">
      <notAllowed />
    </define>
    <define name="Text.class" combine="choice">
      <ref name="ruby" />
    </define>
  </div>
  <div>
    <x:h2>XForms module</x:h2>
    <x:p>To-Do: work out integration of XForms</x:p>
    <!--include href="xforms-11.rng"/-->
  </div>
  <div>
    <x:h2>XML Schema instance module</x:h2>
    <include href="XMLSchema-instance.rng" />
  </div>
</grammar>|;
my $tstL = q|<?xml version="1.0" encoding="utf-8"?>
<?sample0 processing-instruction="this"?>
<?sample1 processing-instruction="that"?>
<!-- Comment0 outside root element -->
<!-- Comment1 outside root element -->
<grammar xmlns="http://relaxng.org/ns/structure/1.0" xmlns:x="http://www.w3.org/1999/xhtml" ns="http://www.w3.org/2002/06/xhtml2">
	<!-- Comment0 inside root element -->
	<!-- Comment1 inside root element -->
	<x:h1>RELAX NG schema for XHTML 2.0</x:h1>
	<x:pre>
Copyright (C)2003-2004 W3C(R) (MIT, ERCIM, Keio), All Rights Reserved.

Editor:   Masayasu Ishikawa mimasa@w3.org
Revision: $Id: xhtml2.rng,v 1.34 2004/07/21 10:33:05 mimasa Exp $

Permission to use, copy, modify and distribute this RELAX NG schema
for XHTML 2.0 and its accompanying documentation for any purpose and
without fee is hereby granted in perpetuity, provided that the above
copyright notice and this paragraph appear in all copies. The copyright
holders make no representation about the suitability of this RELAX NG
schema for any purpose.

It is provided "as is" without expressed or implied warranty.
For details, please refer to the W3C software license at:
    <x:a href="http://www.w3.org/Consortium/Legal/copyright-software">http://www.w3.org/Consortium/Legal/copyright-software</x:a>
	</x:pre>
	<div>
		<x:h2>XHTML 2.0 modules</x:h2>
		<x:h3>Attribute Collections Module</x:h3>
		<include href="xhtml-attribs-2.rng" />
		<x:h3>Document Module</x:h3>
		<include href="xhtml-document-2.rng" />
		<x:h3>Structural Module</x:h3>
		<include href="xhtml-structural-2.rng" />
		<x:h3>Text Module</x:h3>
		<include href="xhtml-text-2.rng" />
		<x:h3>Hypertext Module</x:h3>
		<include href="xhtml-hypertext-2.rng" />
		<x:h3>List Module</x:h3>
		<include href="xhtml-list-2.rng" />
		<x:h3>Metainformation Module</x:h3>
		<include href="xhtml-meta-2.rng" />
		<x:h3>Object Module</x:h3>
		<include href="xhtml-object-2.rng" />
		<x:h3>Scripting Module</x:h3>
		<include href="xhtml-script-2.rng" />
		<x:h3>Style Attribute Module</x:h3>
		<include href="xhtml-inlstyle-2.rng" />
		<x:h3>Style Sheet Module</x:h3>
		<include href="xhtml-style-2.rng" />
		<x:h3>Tables Module</x:h3>
		<include href="xhtml-table-2.rng" />
		<x:h3>Support Modules</x:h3>
		<x:h4>Datatypes Module</x:h4>
		<include href="xhtml-datatypes-2.rng" />
		<x:h4>Events Module</x:h4>
		<include href="xhtml-events-2.rng" />
		<x:h4>Param Module</x:h4>
		<include href="xhtml-param-2.rng" />
		<x:h4>Caption Module</x:h4>
		<include href="xhtml-caption-2.rng" />
	</div>
	<div>
		<x:h2>XML Events module</x:h2>
		<include href="xml-events-1.rng" />
	</div>
	<div>
		<x:h2>Ruby module</x:h2>
		<include href="full-ruby-1.rng">
			<define name="Inline.class">
				<notAllowed />
			</define>
			<define name="NoRuby.content">
				<ref name="Text.model" />
			</define>
		</include>
		<define name="Inline.model">
			<notAllowed />
		</define>
		<define name="Text.class" combine="choice">
			<ref name="ruby" />
		</define>
	</div>
	<div>
		<x:h2>XForms module</x:h2>
		<x:p>To-Do: work out integration of XForms</x:p>
		<!--include href="xforms-11.rng"/-->
	</div>
	<div>
		<x:h2>XML Schema instance module</x:h2>
		<include href="XMLSchema-instance.rng" />
	</div>
</grammar>|;
           $tobj = XML::Tidy->new($tst2) ;
ok(defined($tobj                       ));
ok(        $tobj->get_xml(),      $tst2 );
ok(   diff($tobj,                 $tst2));
ok(        $tobj->get_xml(),      $tst2 );
           $tobj->reload();
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tst2));
ok(defined($tobj                       ));
#k(        $tobj->get_xml(),      $tstI );
ok(   diff($tobj,                 $tstI));
           $tobj->strip();
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tstJ));
           $tobj->tidy();
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tstK));
           $tobj->tidy("\t");
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tstL));
