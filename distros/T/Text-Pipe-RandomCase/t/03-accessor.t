use strict;
use warnings;
use Test::More tests => 4;
use Text::Pipe;

my $pipe = Text::Pipe->new('RandomCase', 
	force_one => 1,
	probability => 10,
);

is($pipe->force_one(),1,'checking force_one after construction via paramter');
is($pipe->probability(),10,'checking probability after construction via paramter');

$pipe = Text::Pipe->new('RandomCase');

is($pipe->force_one(),undef,'checking force_one after construction without paramter');
is($pipe->probability(),undef,'checking probability after construction without paramter');
