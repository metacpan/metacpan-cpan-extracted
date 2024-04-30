#
# v5 should be all dupes.
#
use strict;
use warnings;
use Test::More;
use MyNote;
BEGIN { use_ok 'UUID' }

my $n = 100;
my %seen = ();

for (1 .. $n) {
    my ($bin, $str);
    UUID::generate_v5($bin, dns => 'www.example.com');
    UUID::unparse($bin, $str);
    note $str;
    #ok !exists($seen{$str});
    $seen{$str} = 1;
}

is scalar(keys %seen), 1, 'all dupes';

done_testing;
