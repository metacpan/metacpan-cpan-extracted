use strict;

use Test::More;
use File::Basename;
use Time::Strptime::Format;
use DateTime::TimeZone;

my %EXPECT = (
    # TODO: testing on mocked timezone defintiions
    # (map {
    #     $_ => [
    #         ['1949-04-03 23:59:59', '-654768001 32400'],
    #         ['1949-04-03 01:00:00', '-654768000 36000'],
    #         ['1949-09-10 00:59:59', '-640947601 36000'],
    #         ['1949-09-10 01:00:00', '-640944000 32400'],
    #         ['2015-12-31 16:08:18', '1451545698 32400'],
    #     ],
    # } qw!JST-9 Asia/Tokyo!),
    (map {
        $_ => [
            ['2014-03-30 01:59:59', '1396141199 3600'],
            ['2014-03-30 03:00:00', '1396141200 7200'],
            ['2014-10-26 01:59:59', '1414281599 7200'],
            ['2014-10-26 02:00:00', '1414285200 3600'],
        ],
    } qw!CET Europe/Paris!),
);

my $inc = join ' ', map { "-I\"$_\"" } @INC;
my $dir = dirname(__FILE__);

my %found;
for my $tz (keys %EXPECT) {
    $found{$tz}++ if eval { DateTime::TimeZone->new(name => $tz); 1 };
}

plan skip_all => 'Missing tzdata on this system' unless %found;
plan tests => 1 + keys %found;

my $shell_quote = $^O eq 'MSWin32' ? '"' : "'";
subtest 'detect offset from date time string' => sub {
    is `$^X $inc $dir/strptime.pl ${shell_quote}%Y-%m-%d %H:%M:%S %z${shell_quote} ${shell_quote}2014-01-01 01:23:45 -0900${shell_quote}`, "1388571825 -32400";
    is `$^X $inc $dir/strptime.pl ${shell_quote}%Y-%m-%d %H:%M:%S %z${shell_quote} ${shell_quote}2014-01-01 01:23:45 +0900${shell_quote}`, "1388507025 32400";
};

for my $tz (keys %found) {
    subtest $tz => sub {
        for my $params (@{ $EXPECT{$tz} }) {
            my ($dt, $expected) = @$params;
            subtest $dt => sub {
                subtest 'detect time_zone from option' => sub {
                    my ($result) = join ' ', Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S' => { time_zone => $tz })->parse($dt);
                    is $result, $expected;
                };

                subtest 'detect time_zone from env' => sub {
                    local $ENV{TZ} = $tz;
                    is `$^X $inc $dir/strptime.pl ${shell_quote}%Y-%m-%d %H:%M:%S${shell_quote} ${shell_quote}$dt${shell_quote}`, $expected;
                };

                subtest 'detect time_zone from date time string' => sub {
                    local $ENV{TZ} = 'GMT';
                    my ($result) = join ' ', Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S %Z', { time_zone => 'GMT' })->parse("$dt $tz");
                    is $result, $expected;
                    is `$^X $inc $dir/strptime.pl ${shell_quote}%Y-%m-%d %H:%M:%S %Z${shell_quote} ${shell_quote}$dt $tz${shell_quote}`, $expected;
                };
            };
        }
    };
}
