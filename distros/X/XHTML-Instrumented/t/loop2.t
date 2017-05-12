use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 6;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <ol id="list">
   <li id="dummy"><span id="text">Not text</span></li><span id="bob">x</span>
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
    text => $t->replace(text => 'jack'),
    bob => $t->replace(text => 'bob data'),
);

$cmp = <<DATA;
<div>
 <ol id="list">
   <li id="dummy"><span id="text">jack</span></li><span id="bob">bob data</span>
 </ol>
</div>
DATA

is_xml($output, $cmp, 'one two three');

$output = $t->output(
    list => $t->loop( headers => [ 'text' ], data => [['one'], ['two'], ['three']], default => 'empty'),
    dummy => $t->replace(text => 'dummy'),
    text => $t->replace(text => 'bill'),
);

$cmp = <<DATA;
<div>
 <ol id="list">
  <li id="dummy.1"><span id="text.1">one</span></li><span id="bob.1">x</span>
  <li id="dummy.2"><span id="text.2">two</span></li><span id="bob.2">x</span>
  <li id="dummy.3"><span id="text.3">three</span></li><span id="bob.3">x</span>
 </ol>
</div>
DATA

is_xml($output, $cmp, 'list overload');

$output = $t->output(
    list => $t->loop( headers => [ 'text' ], data => [['one'], ['two'], ['three']], default => 'empty'),
    dummy => $t->replace(text => 'dummy'),
    text => $t->replace(text => 'bill'),
    bob => $t->replace(text => 'bob data'),
);

$cmp = <<DATA;
<div>
 <ol id="list">
  <li id="dummy.1"><span id="text.1">one</span></li><span id="bob.1">x</span>
  <li id="dummy.2"><span id="text.2">two</span></li><span id="bob.2">x</span>
  <li id="dummy.3"><span id="text.3">three</span></li><span id="bob.3">x</span>
 </ol>
</div>
DATA

is_xml($output, $cmp, 'list overload bob defined');

