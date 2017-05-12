use Test::More;
use Test::XML;

use Test::Warn;

use Data::Dumper;

plan tests => 5;

require_ok( 'XHTML::Instrumented' );
require_ok( 'XHTML::Instrumented::Form' );

$data = <<DATA;
<div>
  <a name="bob">bob</a>
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
$form->add_element(type => 'textarea', name => 'textarea');
$form->add_element(type => 'text', name => 'text1');
$form->add_element(type => 'text', name => 'text2');
$form->add_element(type => 'hidden', name => 'a');
$form->add_element(type => 'hidden', name => 'b');

my $output;

warnings_are {
    $output = $x->output(
	 myform => $form,
    );
} ['need value for a', 'need value for b'], 'Not a form';

my $cmp = <<DATA;
<div>
  <a name="bob">bob</a>
  <form name="myform" method="post">
    <textarea name="textarea">
    </textarea>
    <input type="text" name="text1" value=""/>
    <input type="text" name="text2" value=""/>
  </form>
</div>
DATA

is_xml($output, $cmp, 'select');

$form->add_params(
    a => [ 'a', 'b' ],
    b => [ 'c' ],
    text1 => [],
    text2 => [ 'test text 2' ],
    textarea => [],
);

$output = $x->output(
     myform => $form,
);

$cmp = <<DATA;
<div>
  <a name="bob">bob</a>
  <form name="myform" method="post">
    <input name="b" type="hidden" value="c"/>
    <input name="a" type="hidden" value="b"/>
    <input name="a" type="hidden" value="a"/>
    <textarea name="textarea">
    </textarea>
    <input type="text" name="text1" value=""/>
    <input type="text" name="text2" value="test text 2"/>
  </form>
</div>
DATA

is_xml($output, $cmp, 'params');

