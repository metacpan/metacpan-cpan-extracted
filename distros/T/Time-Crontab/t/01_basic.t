use strict;
use Test::More;
use Time::Crontab;
use Time::Local;

is_deeply( Time::Crontab->new('* * * JAN *')->dump->{month}, [1]); 
is_deeply( Time::Crontab->new('* * * APR *')->dump->{month}, [4]); 
is_deeply( Time::Crontab->new('* * * * SUN')->dump->{day_of_week}, [0]); 
is_deeply( Time::Crontab->new('* * * * MON')->dump->{day_of_week}, [1]); 

ok( Time::Crontab->new('* * * * *')->match(time) );
ok( Time::Crontab->new('*/1 * * * *')->match(time) );

sub cron_ok {
    my ($cron, $min, $hour, $mday, $mon, $year) = @_;
    my $time = timelocal(0, $min, $hour, $mday, $mon-1, $year-1900);
    ok( Time::Crontab->new($cron)->match($time), "$cron not match " . localtime($time) );
}

sub cron_notok {
    my ($cron, $min, $hour, $mday, $mon, $year) = @_;
    my $time = timelocal(0, $min, $hour, $mday, $mon-1, $year-1900);
    ok( ! Time::Crontab->new($cron)->match($time), "$cron match " . localtime($time) );
}

cron_ok('  */5 * * * *', 0, 0, 26, 12, 2013);
cron_ok('  */5 *   * * *  ', 0, 0, 26, 12, 2013);
cron_notok('0 0 13 * 5', 0, 1, 6, 12, 2013);

cron_notok('0 0 * * 0', 0, 0, 13, 8, 2013); # 0==sun, but day is Tuesday 13th Aug 2013
cron_notok('0 0 * * 1', 0, 0, 13, 8, 2013); # 1==mon, but day is Tuesday 13th Aug 2013
cron_ok('0 0 * * 2', 0, 0, 13, 8, 2013); # 2==tue, but day is Tuesday 13th Aug 2013
cron_notok('0 0 * * 3', 0, 0, 13, 8, 2013); # 3==wed, but day is Tuesday 13th Aug 2013
cron_notok('0 0 * * 4', 0, 0, 13, 8, 2013); # 4==thu, but day is Tuesday 13th Aug 2013
cron_notok('0 0 * * 5', 0, 0, 13, 8, 2013); # 5==fri, but day is Tuesday 13th Aug 2013
cron_notok('0 0 * * 6', 0, 0, 13, 8, 2013); # 6==sat, but day is Tuesday 13th Aug 2013
cron_notok('0 0 * * 7', 0, 0, 13, 8, 2013); # 7==sun, but day is Tuesday 13th Aug 2013

cron_ok('0 0 13 8 7', 0, 0, 13, 8, 2013); # 7==sun, but day is Tuesday 13th Aug 2013 - special check!
cron_ok('0 0 13 8 2', 0, 0, 13, 8, 2013); # 2==tue, and day is Tuesday 13th Aug 2013 - special check!

cron_ok('0 0 13 * 5', 0, 0, 13, 1, 2013); # defined day and dow => day or dow
cron_ok('0 0 13 * 5', 0, 0, 6, 12, 2013); # defined day and dow => day or dow

cron_notok('0 0 13 * *',      0, 0,  12, 8, 2013); # 12th Aug still doesn't match 13th (not just because dow is any).
cron_ok(   '0 10 10,31 * 2',  0, 10, 10, 3, 2016); # 2016-03-10T10:00:00Z matches the 10th dom (but not the 2nd dow)

sub error_cron {
    my ($cron, $err_match) = @_;
    eval {
        Time::Crontab->new($cron);
    };
    like($@, $err_match, "error cron => $cron");
}

error_cron('',qr/incorrect/);
error_cron('* * *',qr/incorrect/);
error_cron('6*5 * * * *',qr/bad format minute/);
error_cron('65 * * * *',qr/bad range minute/);
error_cron('* * * * 9',qr/bad range day_of_week/);
error_cron('* * * JANb *',qr/bad format month/);
error_cron('* * * * THU-MON',qr/bad format day_of_week/);
error_cron('* * * * THU,MON',qr/bad format day_of_week/);

done_testing();
