use strict;
use warnings;
use Test::More;
use XML::Overlay;
plan tests => 1;

my $o_source = qq!
<Overlay>
  <target xpath="/child::foo">
    <action type="setAttribute" attribute="att">bar</action>
    <action type="insertBefore">
      <spam />
    </action>
    <action type="removeAttribute" attribute="meh" />
  </target>
  <target xpath="//spam">
    <action type="insertAfter">
      <meh1 />
      <meh2 />
    </action>
    <action type="delete" />
  </target>
</Overlay>!;

my $o_tree = XML::Overlay->new(xml => $o_source);

my $d_source = qq!
<blub>
  <foo meh="3" />
  <bar>
    <spam bleem="3" />
  </bar>
</blub>!;

my $d_tree = Class::XML->new(xml => $d_source);

$o_tree->process($d_tree);

is("${d_tree}", qq!<blub>
  
      <spam />
    <foo att="bar" />
  <bar>
    
      <meh1 />
      <meh2 />
    
  </bar>
</blub>!, "Transforms applied ok");
