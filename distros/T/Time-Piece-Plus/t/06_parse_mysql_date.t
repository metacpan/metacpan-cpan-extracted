use strict;
use warnings;
use 5.10.0;
use Test::More;

use Time::Piece::Plus;

my $sometime = "2011-11-15";
my $datetime_format = "%Y-%m-%d";
my $time = Time::Piece::Plus->strptime($sometime, $datetime_format);
my $localtime = localtime->strptime($sometime, $datetime_format);

subtest "now as localtime" => sub {
    my $now = localtime();
    my $parsed = Time::Piece::Plus->parse_mysql_date(str => $now->mysql_date, as_localtime => 1);
    isa_ok($parsed => 'Time::Piece::Plus', "returns Time::Piece::Plus instance");
    is($parsed->strftime($datetime_format) => $now->strftime($datetime_format), "correct parsed date");
};

subtest "now as gmtime" => sub {
    my $now = gmtime();
    my $parsed = Time::Piece::Plus->parse_mysql_date(str => $now->mysql_date, as_localtime => 0);
    isa_ok($parsed => 'Time::Piece::Plus', "returns Time::Piece::Plus instance");
    is($parsed->strftime($datetime_format) => $now->strftime($datetime_format), "correct parsed date");
};

subtest "as gmtime" => sub {
    my $parsed = Time::Piece::Plus->parse_mysql_date(str => $sometime, as_localtime => 0);
    isa_ok($parsed => 'Time::Piece::Plus', "returns Time::Piece::Plus instance");
    is($parsed->epoch => $time->epoch, "parsed correctly");
    is($parsed->strftime($datetime_format) => $sometime, "correct parsed date");
};

subtest "as localtime" => sub {
    my $parsed = Time::Piece::Plus->parse_mysql_date(str => $sometime, as_localtime => 1);
    isa_ok($parsed => 'Time::Piece::Plus', "returns Time::Piece::Plus instance");
    is($parsed->epoch => $localtime->epoch, "parsed correctly");
    is($parsed->strftime($datetime_format) => $sometime, "correct parsed date");
};

subtest "epoch minus date" => sub {
    my $somoday = "1969-12-31";
    my $parsed = Time::Piece::Plus->parse_mysql_date(str => $somoday, as_localtime => 0);
    isa_ok($parsed => 'Time::Piece::Plus', "parsed correctly");
    ok(($parsed->epoch == (-3600 * 24)), "correct parsed date");
};

done_testing();
