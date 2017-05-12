use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 4;

require_ok( 'XHTML::Instrumented' );
require_ok( 'XHTML::Instrumented::Form' );

$data = <<DATA;
<div>
  <form name="myform" method="post">
    <textarea name="textarea">
      bob
    </textarea>
    <input type="text" name="text1" value="text1"/>
    <input type="text" name="text2" value="text2"/>
  </form>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $form = $x->get_form();
$form->add_element(type => 'textarea', name => 'textarea', value => 'This is text in a text area.' );
$form->add_element(type => 'text', name => 'text1', value => 'test text 1' );
$form->add_element(type => 'text', name => 'text2', value => 'test text 2' );
$form->add_element(type => 'hidden', name => 'a', value => ['a', 'b'] );
$form->add_element(type => 'hidden', name => 'b', value => 'b' );

my $output = $x->output(
     myform => $form,
);

my $cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <input name="b" type="hidden" value="b"/>
    <input name="a" type="hidden" value="b"/>
    <input name="a" type="hidden" value="a"/>
    <textarea name="textarea">
This is text in a text area.
    </textarea>
    <input type="text" name="text1" value="test text 1"/>
    <input type="text" name="text2" value="test text 2"/>
  </form>
</div>
DATA

is_xml($output, $cmp, 'select');

$cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <input name="b" type="hidden" value="b"/>
    <input name="a" type="hidden" value="b"/>
    <input name="a" type="hidden" value="a"/>
    <textarea name="textarea">
This is text in a text area.
    </textarea>
    <input type="text" name="text1" value="test text 1"/>
    <input type="text" name="text2" value="test text 2"/>
  </form>
</div>
DATA

$form->add_params(
    text1 => ['text1'],
);

is_xml($output, $cmp, 'select');


