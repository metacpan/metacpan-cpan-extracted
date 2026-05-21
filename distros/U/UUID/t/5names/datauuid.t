use strict;
use warnings;

BEGIN {
    my $has_du = eval 'require Data::UUID';
    unless ($has_du) {
        print "1..0 # SKIP no Data::UUID\n";
        exit 0;
    }
    Data::UUID->import(qw(NameSpace_DNS));
}

use MyTest;

use UUID qw(parse uuid3);

ok 1, 'loaded';

my $NAME = 'www.example.com';

my $ug = Data::UUID->new;
my $du3 = lc $ug->create_from_name_str(NameSpace_DNS, $NAME);

# compare
my $uu3 = uuid3(dns => $NAME);
note "Data::UUID  => $du3";
note "UUID::uuid3 => $uu3";
is $uu3, $du3, 'uuids match';

done_testing;
