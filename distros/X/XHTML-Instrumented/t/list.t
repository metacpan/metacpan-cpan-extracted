use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div class="pBody">
 <ul id="learn_list">
  <li id="pt-lang"><a href="learn" id="nav_learn" name="nav_learn">English</a></li>
 </ul>
</div>
DATA

my $cmp = <<DATA;
<div class="pBody">
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    learn_list => $t->loop(),
);

is_xml($output, $cmp, 'not defined');

$output = $t->output(
    learn_list => $t->loop(
	headers => [ 'nav_learn' ],
        data => [
	    [ $t->replace(text => 'English' . ' (' . 123 . ')', args => { href => 'http://test/1' }) ],
	    [ $t->replace(text => 'French' . ' (' . 456 . ')', args => { href => 'http://test/2' }) ],
        ]
    ),
);

$cmp = <<DATA;
<div class="pBody">
 <ul id="learn_list">
  <li id="pt-lang.1"><a href="http://test/1" id="nav_learn.1" name="nav_learn">English (123)</a></li>
  <li id="pt-lang.2"><a href="http://test/2" id="nav_learn.2" name="nav_learn">French (456)</a></li>
 </ul>
</div>
DATA

is_xml($output, $cmp, 'defined');

