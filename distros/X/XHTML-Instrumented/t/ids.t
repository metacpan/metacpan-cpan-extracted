use Test::More;
use Test::XML;
use Test::Warn;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<'DATA';
<div>
 <span id="bob">test1</span>
 <span id="bob">test1</span>
</div>
DATA

my $cmp = <<'DATA';
<div>
 <span id="bob">Bob</span>
 <span id="bob">Bob</span>
</div>
DATA

my $x;
warning_is {
    $x = XHTML::Instrumented->new(name => \$data, type => '');
} 'Duplicate id: bob', 'duplicate id';

$output = $x->output(
    bob => $x->replace(text => 'Bob'),
);

is_xml($output, $cmp, 'simple');

