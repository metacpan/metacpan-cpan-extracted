use strict;

use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 2;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <div id="row">
   <span id="junk">junk</span>
   <span id="text">one</span>
   <span id="column">
     <span id="cdata">one</span>
   </span>
 </div>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    row => $t->loop(  inclusive => 1,
                      headers => [ 'text', 'column' ], 
		      data => [
		          ['text one', $t->loop( headers => ['cdata'], data => [['one one'], ['one two']] )], 
		          ['text two', $t->loop( headers => ['cdata'], data => [['two one'], ['two two']] )], 
		      ]
		   ),
);

my $cmp = <<DATA;
<div>
  <div id="row.1">
    <span id="junk.1">junk</span>
    <span id="text.1">text one</span>
    <span id="column.1">
      <span id="cdata.1.1">one one</span>
      <span id="cdata.1.2">one two</span>
    </span>
  </div>
 <div id="row.2">
    <span id="junk.2">junk</span>
    <span id="text.2">text two</span>
    <span id="column.2">
      <span id="cdata.2.1">two one</span>
      <span id="cdata.2.2">two two</span>
    </span>
  </div>
</div>
DATA

is_xml($output, $cmp, 'loop in loop');

