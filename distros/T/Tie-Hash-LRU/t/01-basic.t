
use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN { 
    use_ok('Tie::Hash::LRU') 
};

my $tied = tie my %h, 'Tie::Hash::LRU', 3;

ok $tied;
is ref $tied, 'Tie::Hash::LRU';

# these tests were taken from Cache::LRU

ok $h{'a'} = 1;
is $h{'a'}, 1;

ok $h{'b'} = 2;
is $h{'a'}, 1;
is $h{'b'}, 2;

ok $h{'c'} = 3;
is $h{'a'}, 1;
is $h{'b'}, 2;
is $h{'c'}, 3;

my $keep;
is +($keep = $h{'a'}), 1; # the order is now a => c => b
ok $h{'d'} = 5;
is $h{'a'}, 1;
ok !defined $h{'b'};
is $h{'c'}, 3;
is $h{'d'}, 5; # the order is now d => c => a

ok $h{'e'} = 6;
ok !defined $h{'a'};
ok !defined $h{'b'};
is $h{'c'}, 3;
is $h{'d'}, 5;
is $h{'e'}, 6;

ok delete $h{'d'};
is $h{'c'}, 3;
ok !defined $h{'d'};
is $h{'e'}, 6;


