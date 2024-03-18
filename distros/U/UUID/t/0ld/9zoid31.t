use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ();


# sane compare (direct from old test, but annotated)
#
# in response to:
#
#t/9old_test.t       (Wstat: 139 Tests: 31 Failed: 0)
#  Non-zero wait status: 139
#  Parse errors: Bad plan.  You planned 40 tests but ran 31.
#
# from:
#   osname=freebsd, osvers=13.1-release-p3, archname=amd64-freebsd
#   uname='freebsd smoker-10.smoker 13.1-release-p3 freebsd 13.1-release-p3 generic amd64 '
#
# see 0db72d2e-8c72-11ee-a6e5-eb18438e9ed8
#
#---- ALSO ----
#t/9old_test.t       (Wstat: 139 (Signal: SEGV, dumped core) Tests: 31 Failed: 0)
#  Non-zero wait status: 139
#  Parse errors: Bad plan.  You planned 40 tests but ran 31.
#
#   osname=freebsd, osvers=13.1-release-p3, archname=amd64-freebsd
#   uname='freebsd smoker-10.smoker 13.1-release-p3 freebsd 13.1-release-p3 generic amd64 '
#
# see 6faded94-8c6b-11ee-ad03-84a447702ea9

my ($uuid, $bin1, $bin2, $tmp1, $tmp2);
$uuid=1;
UUID::generate( $uuid ); # this is wrong. dont want to fix it though.
ok 1, 'sane gen';
$bin2 = '1234567890123456';
ok 1, 'sane set';
$tmp1 = UUID::compare( $bin1, $bin2 );   #<----------------------------------- segv
ok 1, 'sane compare 1';
$tmp2 = UUID::compare( $bin2, $bin1 );
ok 1, 'sane compare 2';
$tmp2 = -UUID::compare( $bin2, $bin1 );
is $tmp1, $tmp2, 'negated compare';      #<----------------------------------- last one complete';
is UUID::compare( $bin1, $bin2 ), -UUID::compare( $bin2, $bin1 ), 'dual compare';
$bin2 = $bin1;
ok 1, 'insane set';

#was marked TODO
is UUID::compare( $bin1, $bin2 ), 0, 'insane compare';

UUID::unparse($bin1,$tmp1);
UUID::unparse($bin2,$tmp2);
note 'UUID 1 : ', $tmp1;
note 'UUID 2 : ', $tmp2;


done_testing;
