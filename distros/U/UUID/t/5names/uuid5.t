use strict;
use warnings;
use Test::More;
use MyNote;

use UUID qw(parse unparse generate_v5 uuid5);

ok 1, 'loaded';

my $name = 'www.example.com/my/data/set/url';

my ($ns_bin, $ns_str);
generate_v5($ns_bin, url => $name);
$ns_str = uuid5(url => $name);
note "namespace: $ns_str";

my $uu0 = uuid5($ns_bin, 'foo');
my $uu1 = uuid5($ns_bin, 'bar');
my $uu2 = uuid5($ns_bin, 'bam');

isnt $uu0, $uu1, 'unique 1';
isnt $uu0, $uu2, 'unique 2';
isnt $uu1, $uu2, 'unique 3';

my ($uu3, $uu4, $uu5);
{
    my ($bin3, $bin4, $bin5);
    generate_v5($bin3, $ns_str, 'foo'); unparse($bin3, $uu3);
    generate_v5($bin4, $ns_str, 'bar'); unparse($bin4, $uu4);
    generate_v5($bin5, $ns_str, 'bam'); unparse($bin5, $uu5);
}

isnt $uu3, $uu4, 'unique 4';
isnt $uu3, $uu5, 'unique 5';
isnt $uu4, $uu5, 'unique 6';

is $uu0, $uu3, 'same 1';
is $uu1, $uu4, 'same 2';
is $uu2, $uu5, 'same 3';

done_testing;
