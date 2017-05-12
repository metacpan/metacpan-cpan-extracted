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
  <input type="text" name="test" id="asdf" value="bob"/>
 </form>
</div>
DATA

$cmp = <<DATA;
<div id="loop">
 <form method="post" name="one">
  <label for="asdf.1">label</label>
  <input type="text" name="test" id="asdf.1" value="testone"/>
 </form>
 <form method="post" name="two">
  <label for="asdf.2">label</label>
  <input type="text" name="test" id="asdf.2" value="testtwo"/>
 </form>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $form1 = XHTML::Instrumented::Form->new( name => 'one');
my $form2 = XHTML::Instrumented::Form->new( name => 'two');

$form1->add_element(
    type => 'text',
    name => 'test',
    value => 'testone',
);
$form2->add_element(
    type => 'text',
    name => 'test',
    value => 'testtwo',
);

$output = $x->output(
     loop => $x->loop(
        headers => ['a', 'myform'],
        data => [
 	  ['a', $form1 ],
	  ['b', $form2 ]],
     ),
);

is_xml($output, $cmp, 'select');

