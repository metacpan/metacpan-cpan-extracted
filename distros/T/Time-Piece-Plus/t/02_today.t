use strict;
use Test::More;

use Time::Piece::Plus;
use Time::Seconds;

subtest "from class method" => sub {
    my $now = localtime();
    my $today = Time::Piece::Plus->today;
    is($today->strftime("%Y%m%d") => $now->strftime("%Y%m%d"), "today method returns today");
    is($today->strftime("%H%M%S") => "000000", "today method truncate times");
};

subtest "from instance method" => sub {
    my $sometime = "2011-11-25 15:00:02";
    my $time = localtime(Time::Piece::Plus->strptime($sometime, "%Y-%m-%d %H:%M:%S"));
    my $today = $time->today;
    is($today->strftime("%Y%m%d") => $time->strftime("%Y%m%d"), "today method returns today");
    is($today->strftime("%H%M%S") => "000000", "today method truncate times");
};


done_testing();
