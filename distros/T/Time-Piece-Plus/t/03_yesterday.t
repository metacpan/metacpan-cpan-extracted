use strict;
use Test::More;

use Time::Piece::Plus;
use Time::Seconds;

subtest "from class method" => sub {
    my $now = localtime();
    my $one_day_ago = $now - ONE_DAY;
    my $yesterday = Time::Piece::Plus->yesterday;
    is($yesterday->strftime("%Y%m%d") => $one_day_ago->strftime("%Y%m%d"), "yesterday method returns yesterday");
    is($yesterday->strftime("%H%M%S") => "000000", "yesterday method truncate times");
};

subtest "from instance method" => sub {
    my $sometime = "2011-11-25 15:00:02";
    my $time = localtime(Time::Piece::Plus->strptime($sometime, "%Y-%m-%d %H:%M:%S"));
    my $one_day_ago = $time - ONE_DAY;
    my $yesterday = $time->yesterday;
    is($yesterday->strftime("%Y%m%d") => $one_day_ago->strftime("%Y%m%d"), "yesterday method returns yesterday");
    is($yesterday->strftime("%H%M%S") => "000000", "yesterday method truncate times");
};


done_testing();
