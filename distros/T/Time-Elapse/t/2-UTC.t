#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 2 ;

local $ENV{TZ} = 'UTC';

use POSIX;

my $test1 =  POSIX::strftime("%H:%M:%S, %A, %B %m %Y", gmtime(0));

my $test2 =  POSIX::strftime("%H:%M:%S, %A, %B %m %Y", localtime(0));

ok( $test1 eq $test2, "$test1 / $test2");

my $test3 = join('', gmtime(0));

my $test4 = join('', localtime(0));

ok( $test3 == $test4, "$test3 / $test4");

