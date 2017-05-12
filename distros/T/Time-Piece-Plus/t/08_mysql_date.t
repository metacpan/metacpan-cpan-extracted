use strict;
use Test::More;

use Time::Piece::Plus;
use Time::Seconds;

subtest "from class method" => sub {
    my $string = Time::Piece::Plus->mysql_date;
    is($string => localtime->strftime("%Y-%m-%d"), "DATE string of now");
};

subtest "from instance method" => sub {
    my $someday = "2011-11-25";
    my $time = localtime->strptime($someday, "%Y-%m-%d");
    is($time->mysql_date => $someday, "DATE string of someday");
};


done_testing();
