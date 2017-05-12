use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok 'Text::Microformat' }
open IN, 't/hcard1.html';
local $/;
my $html = <IN>;
my $uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
	is($thing->fn->[0]->Value, 'John Doe');
	is($thing->Get('fn'), 'John Doe');
	is($thing->Get('adr.post-office-box'), 'Box 1234');
	is($thing->Get('adr.type'), 'work');
	is($thing->Get('geo.latitude'), '37.77');
	is($thing->Get('email.type'), undef);
}
