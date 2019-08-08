use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

plan skip_all => 'set TEST_FULL=1 to enable real test coverage' unless $ENV{TEST_FULL};

use_system_zones();

my @dias;
# check past - unavailable, OS's timelocal cannot work with these dates
# check transitions
push @dias, [86399, "1910-01-01 00:00:00", "1970-01-01 00:00:00"];
push @dias, [3599, "1980-01-01 00:00:00", "1986-01-01 00:00:00"];
push @dias, [3599, "2000-01-01 00:00:00", "2006-01-01 00:00:00"];
push @dias, [3599, "2006-01-01 00:00:00", "2011-01-01 00:00:00"];
# check near future
push @dias, [3599, "2016-01-01 00:00:00", "2022-01-01 10:00:00"];
# check far future
push @dias, [3599, "2060-01-01 00:00:00", "2066-01-01 10:00:00"];

# Europe/Moscow disabled - OS has a lot of bugs with non-standart transitions which occur in Moscow 
test_zone($_) for qw# America/New_York Australia/Melbourne #;

sub test_zone {
    $ENV{TZ} = shift;
    tzset();
    POSIX::tzset();
    
    foreach my $dia (@dias) {
        my ($step, $from, $till) = @$dia;
        ok(MyTest::test_timelocal($step, epoch_from($from), epoch_from($till)));
    }
    
    # random check - RAND_FLAG, DIA (1910+[0-DIA]), ITERS COUNT
    ok(MyTest::test_timelocal(0, 200, 400000));
    
    for (my $i = 0; $i < 1000; $i++) {
        my @date1 = (int(rand 1800)-900, int(rand 1800)-900, int(rand 240)-120, int(rand 200)-100, int(rand 120)-60, 1913 + int(rand 200));
        my @date2 = @date1;
        $date2[5] -= 1900;
        
        my $r1 = timelocal(@date1);
        my $r2 = systimelocal(@date2);
        
        $r1 = timelocal(@date1, 1) if $r1 != $r2; # if ambiguity, OS may return unpredicted results. Lets handle that.
        
        is($r1, $r2, "date(@date1) $ENV{TZ}");
    }
}

done_testing();
