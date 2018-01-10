use 5.008001;
use warnings;
use strict;
use utf8;
use Test::More;
use Test::Exception;

use Test::Mock::Time;


my $t = time;
my $loc = localtime;
my @loc = localtime;
my $gmt = gmtime;
my @gmt = gmtime;

cmp_ok $t, '>', 1455000000, 'time looks like current actual time';
is scalar gmtime(1455000000), 'Tue Feb  9 06:40:00 2016', 'gmtime with param';
like $loc, qr/\d\d:\d\d:\d\d/ms, 'scalar localtime looks like time';
like $gmt, qr/\d\d:\d\d:\d\d/ms, 'scalar gmtime looks like time';
is 0+@loc, 9, 'localtime returns 9 values';
is 0+@gmt, 9, 'gmttime returns 9 values';

is time(), $t, 'time()';
cmp_ok CORE::time(), '>=', $t, 'CORE::time() looks like time()';
select undef,undef,undef,1.1;
cmp_ok CORE::time(), '>', $t, 'CORE::time() is increased';
cmp_ok CORE::localtime(), 'ne', $loc, 'CORE::localtime() is changed';
is time, $t, 'time is same after real 1.1 second delay';
is time(), $t, 'time() is same';
is scalar localtime, $loc, 'localtime is same';
is scalar gmtime, $gmt, 'gmtime is same';

throws_ok { sleep -1.5 } qr/sleep with negative value is not supported/;
throws_ok { sleep -1 } qr/sleep with negative value is not supported/;
is sleep -0.5, 0, 'sleep -0.5';
is time, $t, 'time is same after sleep -0.5';
is sleep 0, 0, 'sleep 0';
is time, $t, 'time is same after sleep 0';
is sleep 0.5, 0, 'sleep 0.5';
is time, $t, 'time is same after sleep 0.5';
is sleep 1, 1, 'sleep 1';
is time, $t+=1, 'time is increased by 1';
is sleep 1.5, 1, 'sleep 1.5';
is time, $t+=1, 'time is increased by 1';
is sleep 1000, 1000, 'sleep 1000';
is time, $t+=1000, 'time is increased by 1000';
cmp_ok localtime, 'ne', $loc, 'localtime is changed';
cmp_ok gmtime, 'ne', $gmt, 'gmtime is changed';

ff(0.5);
is time, $t, 'time is same after ff(0.5)';
ff(0.5);
is time, $t+=1, 'time is increased by 1 after ff(0.5)';
ff(1000);
is time, $t+=1000, 'time is increased by 1000 after ff(1000)';


done_testing();
