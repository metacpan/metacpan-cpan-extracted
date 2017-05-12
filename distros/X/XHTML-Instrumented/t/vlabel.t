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
  <input name="test_1" id="asdf.1" value="testme"/>
 </form>
 <form name="myform" method="post">
  <label for="asdf.2" style="color: red;">label</label>
  <input name="test_2" id="asdf.2" value="checkme"/>
 </form>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $form = XHTML::Instrumented::Form->new();

$form->add_element(
    type => 'text',
    name => 'test_1',
    default => 'testme',
);

$form->add_element(
    type => 'text',
    name => 'test_2',
    required => 1,
    default => 'checkme',
);

my $e1 = $form->get_element('test_1');
my $e2 = $form->get_element('test_2');

#$form->add_params(
#    test_1 => [ '' ],
#    test_2 => [ '' ],
#);

$output = $x->output(
     myform => $form,
     submited => 1,
     loop => $x->loop(
        headers => ['asdf'],
        data => [ [ $e1 ], [ $e2 ] ],
     ),
);

is_xml($output, $cmp, 'select');

