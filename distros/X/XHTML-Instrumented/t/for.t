use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );
require_ok( 'XHTML::Instrumented::Form' );

my ($output, $cmp);

my $data = <<DATA;
<div id="loop">
 <form name="myform">
  <label for="asdf">label</label>
  <input name="test" id="asdf"/>
 </form>
</div>
DATA

$cmp = <<DATA;
<div id="loop">
 <form name="myform" method="post">
  <label for="asdf.1">label</label>
  <input name="test" id="asdf.1" value="testme"/>
 </form>
 <form name="myform" method="post">
  <label for="asdf.2">label</label>
  <input name="test" id="asdf.2" value="testme"/>
 </form>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $form = XHTML::Instrumented::Form->new();

$form->add_element(
    type => 'text',
    name => 'test',
    value => 'testme',
);

$output = $x->output(
     myform => $form,
     loop => $x->loop(
        headers => ['a'],
        data => [['a'], ['b']],
     ),
);

is_xml($output, $cmp, 'select');
