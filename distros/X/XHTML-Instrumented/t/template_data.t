use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 5;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <table>
  <tbody id="list">
   <tr>
    <td class=":data">
     <span id="x.1">left</span>
    </td>
    <td>
     <span id="x.2">right</span>
    </td>
   </tr>
  </tbody>
 </table>
</div>
DATA

my $cmp = <<DATA;
<div>
<table>
</table>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $x->output(
    list => $x->loop(),
);

is_xml($output, $cmp);

$output = $x->output(
    list => $x->loop(inclusive => 1),
);

is_xml($output, $cmp);

$output = $x->output(
    list => $x->loop( headers => [ 'x' ], data => [['one'], ['two'], ['three'], ['four'], ['five']], default => 'empty'),
);

$cmp = <<DATA;
<div>
 <table>
  <tbody id="list">
   <tr>
    <td class=":data">
     <span id="x.1.1">one</span>
    </td>
    <td>
     <span id="x.2.2">two</span>
    </td>
   </tr>
   <tr>
    <td class=":data">
     <span id="x.1.3">three</span>
    </td>
    <td>
     <span id="x.2.4">four</span>
    </td>
   </tr>
   <tr>
    <td class=":data">
     <span id="x.1.5">five</span>
    </td>
    <td>
     <span id="x.2.6">empty</span>
    </td>
   </tr>
  </tbody>
 </table>
</div>
DATA

{
    is_xml($output, $cmp);
}

$output = $x->output(
    list => $x->loop( headers => [ 'x' ], data => [['one'], ['two'], ['three'], ['four'], ['five']]),
);

$cmp = <<DATA;
<div>
 <table>
  <tbody id="list">
   <tr>
    <td class=":data">
     <span id="x.1.1">one</span>
    </td>
    <td>
     <span id="x.2.2">two</span>
    </td>
   </tr>
   <tr>
    <td class=":data">
     <span id="x.1.3">three</span>
    </td>
    <td>
     <span id="x.2.4">four</span>
    </td>
   </tr>
   <tr>
    <td class=":data">
     <span id="x.1.5">five</span>
    </td>
    <td>
     <span id="x.2.6">N/A</span>
    </td>
   </tr>
  </tbody>
 </table>
</div>
DATA

{
    is_xml($output, $cmp);
}

