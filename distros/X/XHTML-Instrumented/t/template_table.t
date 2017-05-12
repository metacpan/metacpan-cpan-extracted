use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 6;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <table id="list">
  <tr>
   <td>
<span id="x">abcd</span>
   </td>
  </tr>
 </table></div>
DATA

my $cmp = <<DATA;
<div>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');
my $output = $x->output(
    list => $x->loop(),
);

is_xml($output, $cmp, 'empty');

$output = $x->output(
    list => $x->loop(inclusive => 1),
);

$cmp = <<DATA;
<div>
</div>
DATA

is_xml($output, $cmp, 'empty inclusive');

$output = $x->output(
    list => $x->loop(inclusive => 0, headers => ['x'], data => [['single']]),
);

$cmp = <<DATA;
<div>
 <table id="list">
  <tr>
   <td>
<span id="x.1">single</span>
   </td>
  </tr>
 </table></div>
DATA

is_xml($output, $cmp, 'single');

$output = $x->output(
    list => $x->loop(inclusive => 1, headers => ['x'], data => [['single']]),
);

$cmp = <<DATA;
<div>
 <table id="list.1">
  <tr>
   <td>
<span id="x.1">single</span>
   </td>
  </tr>
 </table>
</div>
DATA

is_xml($output, $cmp, 'single inclusive');



$output = $x->output(
    list => $x->loop(inclusive => 0, headers => ['x'], data => [['test'], ['test2']]),
);

$cmp = <<DATA;
<div>
 <table id="list.1">
  <tr>
   <td>
<span id="x.1">test</span>
   </td>
  </tr>
 </table>
 <table id="list.2">
  <tr>
   <td>
<span id="x.2">test2</span>
   </td>
  </tr>
 </table>
 </div>
DATA

$output = $x->output(
    list => $x->loop(inclusive => 1, headers => ['x'], data => [['test'], ['test2']]),
);

is_xml($output, $cmp, 'inclusive list');

