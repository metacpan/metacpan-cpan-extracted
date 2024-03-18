use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ();


# duplicate failing test 23 from the old test

my ($bin, $bin1, $bin2);

$bin = 'bogus value';
is UUID::is_null( $bin ), 0, 'old 21'; # != the null uuid, right?

$bin = '1234567890123456';
is UUID::is_null( $bin ), 0, 'old 22'; # still not null

#-------------------------------------------------------------------> last seen here dumps core below

# make sure compare operands sane
UUID::generate( $bin1 );
$bin2 = 'x';
is abs(UUID::compare( $bin1, $bin2 )), 1, 'old 23';
is abs(UUID::compare( $bin2, $bin1 )), 1, 'old 24';
$bin2 = 'some silly ridiculously long string that couldnt possibly be a uuid';
is abs(UUID::compare( $bin1, $bin2 )), 1, 'old 25';
is abs(UUID::compare( $bin2, $bin1 )), 1, 'old 26';

done_testing;
