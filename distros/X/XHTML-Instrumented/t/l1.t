use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <ul id="list">
  <li id="item">x</li>
 </ul>
</div>
DATA

my $cmp = <<DATA;
<div>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    list => $t->loop(),
);

is_xml($output, $cmp, 'not defined');

$output = $t->output(
    list => $t->loop(
	headers => [ 'item' ],
        data => [
	    [ $t->replace(text => 'one') ],
	    [ $t->replace(text => 'two' ) ],
        ]
    ),
);

$cmp = <<DATA;
<div>
 <ul id="list">
  <li id="item.1">one</li>
  <li id="item.2">two</li>
 </ul>
</div>
DATA

is_xml($output, $cmp, 'defined');

