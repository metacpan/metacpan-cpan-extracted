use Test::More;
use Test::XML;
use Test::Warn;

plan tests => 2;

require_ok( 'XHTML::Instrumented' );

my $data = <<'DATA';
<div>
 <span id="bob">test1
</div>
DATA

my $cmp = <<'DATA';
<div>
 <span id="bob">Bob</span>
 <span id="bob">Bob</span>
</div>
DATA

my $x =
eval {
    XHTML::Instrumented->new(name => \$data, type => '');
};
if ($@) {
    pass('died');
} else {
    fail('died');
}

