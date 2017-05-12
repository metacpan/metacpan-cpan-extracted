
use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<'DATA';
<div>
 <span><b><i id="bob">This is bob</i></b><b>.</b></span>
 <span><b><i>two</i></b><b>.</b></span>
</div>
DATA

my $cmp = <<'DATA';
<div>
 <span><b><i id="bob">Bob</i></b><b>.</b></span>
 <span><b><i>two</i></b><b>.</b></span>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $x->output(
    bob => 'Bob',
);

is_xml($output, $cmp, 'simple');

$data = <<'DATA';
<div>
 <span><b><i id="bob.adsf">This is bob.adsf</i></b><b>.</b></span>
 <span><b><i>three</i></b><b>.</b></span>
</div>
DATA

$cmp = <<'DATA';
<div>
 <span><b><i id="bob.adsf">Bob</i></b><b>.</b></span>
 <span><b><i>three</i></b><b>.</b></span>
</div>
DATA

$x = XHTML::Instrumented->new(name => \$data, type => '');

$output = $x->output(
    bob => 'Bob',
);

is_xml($output, $cmp, 'simple');

