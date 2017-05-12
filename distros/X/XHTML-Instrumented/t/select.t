use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <form name="myform">
  <select name="select">
   <option>select</option>
   <option>not a</option>
   <option>not b</option>
   <option>not c</option>
  </select>
 </form>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');
my $form = $t->get_form();
$form->add_element(
    type => 'select',
    name => 'select',
    data => [
        { text => 'A', disabled => 1 },
	{ text => 'B', selected => 1 },
	{ text => 'C' } 
    ] 
);

my $cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <select name="select">
      <option disabled="disabled" value="A">A</option>
      <option selected="selected" value="B">B</option>
      <option value="C">C</option>
    </select>
  </form>
</div>
DATA

my $output = $t->output(
     myform => $form,
);

is_xml($output, $cmp, 'select I');

$t = XHTML::Instrumented->new(name => \$data, type => '');
$form = $t->get_form();
my $s =
$form->add_element(
    type => 'select',
    name => 'select',
    value => 'C',
    data => [
        { text => 'A', disabled => 1 },
	{ text => 'B' },
	{ text => 'C' } 
    ] 
);

$cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <select name="select">
      <option disabled="disabled" value="A">A</option>
      <option value="B">B</option>
      <option value="C" selected="selected">C</option>
    </select>
  </form>
</div>
DATA

$output = $t->output(
     myform => $form,
);

is_xml($output, $cmp, 'select II');

__END__

