use strict;
use warnings;
use Test::More;
use UUID ();


my $str = '00000000-0000-0000-0000-000000000000';
my $rc = UUID::parse($str,my $bin);
ok 1, 'parse null';

is $rc, 0, 'return ok';

my $bin2 = $bin;
$str = 'Peter is a moose.';
$rc = UUID::parse($str,$bin);
ok 1, 'parse bogus';
is $rc, -1, 'return ng';
is $str, 'Peter is a moose.', 'string unchanged';
is $bin, $bin2, 'binary unchanged';

done_testing;
