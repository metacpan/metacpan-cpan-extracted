use strict;
use warnings;
use 5.10.0;
use Test::More;

use Time::Piece::Plus;

my $sometime = "2011-11-26 23:01:10";
my $datetime_format = "%Y-%m-%d %H:%M:%S";
my $time = Time::Piece::Plus->strptime($sometime, $datetime_format);
my $localtime = localtime->strptime($sometime, $datetime_format);

subtest "now as gmtime" => sub {
    my $now    = gmtime();
    my $parsed = Time::Piece::Plus->parse_mysql_datetime(str => $now->mysql_datetime, as_localtime => 0);
    isa_ok($parsed => 'Time::Piece::Plus', "returns Time::Piece::Plus instance");
    is($parsed->epoch => $now->epoch, "parsed correctly");
    is($parsed->strftime($datetime_format) => $now->strftime($datetime_format), "correct parsed datetime");
};

subtest "now as localtime" => sub {
    my $now    = localtime();
    my $parsed = Time::Piece::Plus->parse_mysql_datetime(str => $now->mysql_datetime, as_localtime => 1);
    isa_ok($parsed => 'Time::Piece::Plus', "returns Time::Piece::Plus instance");
    is($parsed->epoch => $now->epoch, "parsed correctly");
    is($parsed->strftime($datetime_format) => $now->strftime($datetime_format), "correct parsed datetime");
};

subtest "as gmtime" => sub {
    my $parsed = Time::Piece::Plus->parse_mysql_datetime(str => $sometime, as_localtime => 0);
    isa_ok($parsed => 'Time::Piece::Plus', "returns Time::Piece::Plus instance");
    is($parsed->epoch => $time->epoch, "parsed correctly");
    is($parsed->strftime($datetime_format) => $sometime, "correct parsed datetime");
};

subtest "as localtime" => sub {
    my $parsed = Time::Piece::Plus->parse_mysql_datetime(str => $sometime, as_localtime => 1);
    isa_ok($parsed => 'Time::Piece::Plus', "returns Time::Piece::Plus instance");
    is($parsed->epoch => $localtime->epoch, "parsed correctly");
    is($parsed->strftime($datetime_format) => $sometime, "correct parsed datetime");
};

subtest "epoch minus datetime" => sub {
    my $somoday = "1969-12-31 23:59:59";
    my $parsed = Time::Piece::Plus->parse_mysql_datetime(str => $somoday, as_localtime => 0);
    isa_ok($parsed => 'Time::Piece::Plus', "parsed correctly");
    ok(($parsed->epoch == -1), "correct parsed datetime");
};

done_testing();
