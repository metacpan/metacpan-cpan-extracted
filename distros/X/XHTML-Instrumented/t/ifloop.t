use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <div id="lista.if">
  <span id="spanned">spaned</span>
  <ol id="lista.ex">
    <li id="dummy"><span id="text0">Not text</span></li>
  </ol>
 </div>
 <div id="listb.if">
  <ol>
    <li id="listb.in"><span id="text1">Not text</span></li>
  </ol>
 </div>
</div>
DATA

my $cmp = <<DATA;
<div>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    lista => $t->loop( headers => [ 'x' ],
       data => [],
    ),
    listb => $t->loop(),
);

is_xml($output, $cmp, 'empty');

$cmp = <<DATA;
<div>
 <div id="lista.if">
  <span id="spanned">spaned</span>
  <ol id="lista.ex">
    <li id="dummy.1"><span id="text0.1">text1</span></li>
    <li id="dummy.2"><span id="text0.2">text2</span></li>
  </ol>
 </div>
 <div id="listb.if">
  <ol>
    <li id="listb.in.1"><span id="text1.1">text1</span></li><li id="listb.in.2"><span id="text1.2">text2</span></li>
  </ol>
 </div>
</div>
DATA

$output = $t->output(
    lista => $t->loop(
        headers => ['text0'],
	data => [
	   [ 'text1' ],
	   [ 'text2' ],
	]
    ),
    listb => $t->loop(
        headers => ['text1'],
	data => [
	   [ 'text1' ],
	   [ 'text2' ],
	]
    ),
);

is_xml($output, $cmp, 'full');


