use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 4;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <div id="test.eq:0">
test 0
 </div>
 <div id="test.eq:1">
test 1
 </div>
 <div id="test.eq:2">
test 2
 </div>
</div>
DATA

my $cmp = <<DATA;
<div>
 <div id="test.eq:0">
test 0
 </div>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    list => $t->loop(),
    test => 0,
);

is_xml($output, $cmp, 'test 0');

$cmp = <<DATA;
<div>
 <div id="test.eq:1">
test 1
 </div>
</div>
DATA

$t = XHTML::Instrumented->new(name => \$data, type => '');

$output = $t->output(
    list => $t->loop(),
    test => 1,
);

is_xml($output, $cmp, 'test 1');

$cmp = <<DATA;
<div>
</div>
DATA

$t = XHTML::Instrumented->new(name => \$data, type => '');

$output = $t->output(
    list => $t->loop(),
    test => 3,
);

is_xml($output, $cmp, 'test 3');

