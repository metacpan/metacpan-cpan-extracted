use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 1;

use XHTML::Instrumented;

my $data = <<DATA;
<div>
 <ol id="list">
   <li class=":even"><span id="text.e">Even</span></li>
   <li class=":odd"><span id="text.o">Odd</span></li>
 </ol>
</div>
DATA

my $cmp = <<DATA;
<div>
 <ol id="list">
   <li class=":odd"><span id="text.o.1">one</span></li>
   <li class=":even"><span id="text.e.2">two</span></li>
   <li class=":odd"><span id="text.o.3">three</span></li>
 </ol>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    list => $t->loop( headers => [ 'text' ], data => [['one'], ['two'], ['three']], default => 'empty'),
);

is_xml($output, $cmp, 'even and odd');

