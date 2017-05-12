use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 2;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <span id="one">one</span>
 <span id="two">two</span>
 <span id="three">three</span>
</div>
DATA

my $cmp = <<DATA;
<div>
 <span id="one">one</span>
 two
 <span id="three">three</span>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    two => $t->replace(remove_tag => 1),
);

is_xml($output, $cmp, 'remove_tag');

