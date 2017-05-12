use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 2;

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

my $output = $x->output();

is_xml($output, $cmp, 'simple');

