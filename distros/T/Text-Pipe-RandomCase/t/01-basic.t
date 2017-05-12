use strict;
use warnings;
use Test::More tests => 4;
use Text::Pipe;

my ($input,$output,$counter);


ok ( my $pipe = Text::Pipe->new('RandomCase'), 'creating pipe');

ok ( $pipe->probability(1), 'settings probability') ;
is ( $pipe->probability(),1, 'getting probability') ;

$input = "foobar";

ok( $pipe->filter($input) !~ /[a-z]/, 'string has no lower case characters with frequency 1');
