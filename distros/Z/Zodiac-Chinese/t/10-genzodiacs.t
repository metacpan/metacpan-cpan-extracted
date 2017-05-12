# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Zodiac-Chinese.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Zodiac::Chinese') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %tests = (
    '199001'    => 'yin earth snake',
    '200010'    => 'yang metal dragon',
    '200104'    => 'yin metal snake',
    '200309'    => 'yin water sheep',
    '196906'    => 'yin earth rooster',
);

foreach my $key (sort keys %tests) {
    $key =~ /(\d\d\d\d)(\d\d)/;
    my ($year, $month) = ($1, $2);
    is(Zodiac::Chinese::chinese_zodiac($year, $month), $tests{$key}, "Zodiac for $key");
}
done_testing();
