use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 4;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <span id="bob">This is a test</span>
</div>
DATA

my $cmp = <<DATA;
<div>
 <span id="bob">This is a test</span>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $x->output(
    bob => $x->replace(),
);

is_xml($output, $cmp);

$cmp = <<DATA;
<div>
 <span id="bob" test="test">good</span>
</div>
DATA

$output = $x->output(
    bob => $x->replace( text => 'good', args => {test => 'test'} ),
);

is_xml($output, $cmp);

$cmp = <<DATA;
<div>
 <span id="bob" test="test">This is a test</span>
</div>
DATA

$output = $x->output(
    bob => $x->args(test => 'test'),
);

is_xml($output, $cmp);

