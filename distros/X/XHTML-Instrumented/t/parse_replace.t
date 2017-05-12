use Test::More;
use Test::Exception;

use Data::Dumper;

plan tests => 8;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div class=":replace :replace" id="bob">
 <span id="one">two</span>
 <span id="two">one</span>
 <span id="three">three</span>
</div>
DATA

throws_ok {
    my $t = XHTML::Instrumented->new(
	name => \$data,
	type => '',
    );
} qr/Only one replace per tag/, 'multiple names';

$data = <<DATA;
<div class=":replace" id="the_id">
 <span id="one">two</span>
 <span id="two">one</span>
 <span id="three">three</span>
</div>
DATA

throws_ok {
    my $t = XHTML::Instrumented->new(
	name => \$data,
	type => 'xx',
	path => 't',
	replace_name => 'bob',
    );
} qr|File not found: t/bob|, 'replace_name';

my $t;
lives_ok {
    $t = XHTML::Instrumented->new(
	name => \$data,
	type => '',
	replace_name => 'parse_replace',
	path => 't',
    );
} 'replace_name';

$data = <<DATA;
<div class=":replace.parse_replace" id="the_id">
 <span id="one">two</span>
 <span id="two">one</span>
 <span id="three">three</span>
</div>
DATA

lives_ok {
    $t = XHTML::Instrumented->new(
	name => \$data,
	type => '',
	path => 't',
    );
} 'replace.name';


is($t->output(), <<EOP, 'replaced');
<div id="the_id">
This is the replaced text.
</div>
EOP

$data = <<DATA;
<div class=":replace.parse_replace" id="not_the_id">
 <span id="one">two</span>
 <span id="two">one</span>
 <span id="three">three</span>
</div>
DATA

throws_ok {
    $t = XHTML::Instrumented->new(
	name => \$data,
	type => '',
	path => 't',
    );
} qr|Replacement not found|, 'replace_name';

ok(unlink "t/parse_replace.cxi", 'cxi file not created');
