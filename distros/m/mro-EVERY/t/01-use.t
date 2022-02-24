use v5.22;

use Test::More;

use Symbol  qw( qualify_to_ref );

my $madness = 'mro::EVERY';
my $method  = 'import';

use_ok $madness; 
can_ok $madness, $method;

done_testing;
