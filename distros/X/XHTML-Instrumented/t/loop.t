use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 5;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <ol id="list">
   <li id="dummy"><span id="text">Not text</span></li>
 </ol>
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

is_xml($output, $cmp, 'empty');

$output = $t->output(
    list => $t->loop(inclusive => 1),
);

is_xml($output, $cmp, 'empty inclusive');

$output = $t->output(
    list => $t->loop( headers => [ 'text' ], data => [['one'], ['two'], ['three']], default => 'empty'),
    text => $t->replace(text => 'jack'),
);

$cmp = <<DATA;
<div>
 <ol id="list">
   <li id="dummy.1"><span id="text.1">one</span></li>
   <li id="dummy.2"><span id="text.2">two</span></li>
   <li id="dummy.3"><span id="text.3">three</span></li>
 </ol>
</div>
DATA

is_xml($output, $cmp, 'one two three');

$output = $t->output(
    list => $t->loop( inclusive => 1, headers => [ 'text' ], data => [['one'], ['two'], ['three']], default => 'empty'),
    dummy => $t->replace(text => 'dummy'),
    text => $t->replace(text => 'bill'),
);

$cmp = <<DATA;
<div>
 <ol id="list.1">
   <li id="dummy.1"><span id="text.1">one</span></li>
 </ol>
 <ol id="list.2">
   <li id="dummy.2"><span id="text.2">two</span></li>
 </ol>
 <ol id="list.3">
   <li id="dummy.3"><span id="text.3">three</span></li>
 </ol>
</div>
DATA

is_xml($output, $cmp, 'one two three inclusive');

