use strict;
use warnings;

use Test::More tests=>3;
use Test::XML;

require_ok( 'XHTML::Instrumented' );
require_ok( 'XHTML::Instrumented::Form' );

my $data = <<DATA;
<div>
 <form name="myform">
  <input name="b" type="text"/>
 </form>
</div>
DATA

my $cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <input name="a" type="hidden" value="a"/>
    <input name="b" type="text" value="b"/>
  </form>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $form = XHTML::Instrumented::Form->new();
$form->add_element(type => 'hidden', name => 'a', value => 'a' );
$form->add_element(type => 'text', name => 'b', value => 'b' );

my $output = $x->output(
     myform => $form,
);

is_xml($output, $cmp, 'simple form');

