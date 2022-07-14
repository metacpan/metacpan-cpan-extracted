use strict;
use warnings;
use Test::More;
use builtins::compat qw( :bool );

ok true;
ok !false;
ok is_bool(false);

my $var = 9;
ok !eval { main::created_as_number(9); 1 };

done_testing;
