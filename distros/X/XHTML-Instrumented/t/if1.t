use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 2;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <table>
  <tbody id="list">
   <tr>
    <td>
     a
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

is_xml($output, $cmp, 'empty loop');

