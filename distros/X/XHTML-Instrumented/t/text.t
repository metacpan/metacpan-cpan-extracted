use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 2;

require_ok( 'XHTML::Instrumented' );

$data = <<DATA;
<div>
  <form name="myform" method="post">
    <input name="name" value=""/>
  </form>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

$cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <input name="name" value="default"/>
  </form>
</div>
DATA

$form = $t->get_form();
$form->add_element(type => 'text', name => 'name', value => 'default');

$output = $t->output( myform => $form );

#diag($output);

is_xml($output, $cmp, 'text params');

