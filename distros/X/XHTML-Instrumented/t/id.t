use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <span id="one">one</span>
 <span id="two">two</span>
</div>
DATA

my $cmp = <<DATA;
<div>
 <span id="one">one</span>
 <span id="two">two</span>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $x->output(
);

is_xml($output, $cmp, 'no control');

$output = $x->output(
    one => $x->replace(text => 'ein'),
);

$cmp = <<DATA;
<div>
 <span id="one">ein</span>
 <span id="two">two</span>
</div>
DATA

is_xml($output, $cmp, 'ein');

