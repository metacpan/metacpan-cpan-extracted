use strict;
use Test::More;

use Time::Piece::Plus;
use Time::Seconds;

subtest "from class method" => sub {
    my $string = Time::Piece::Plus->mysql_datetime;
    is($string => localtime->strftime("%Y-%m-%d %H:%M:%S"), "DATETIME string of now");
};

subtest "from instance method" => sub {
    my $sometime = "2011-11-25 02:30:33";
    my $time = localtime->strptime($sometime, "%Y-%m-%d %H:%M:%S");
    is($time->mysql_datetime => $sometime, "DATETIME string of sometime");
};


done_testing();
