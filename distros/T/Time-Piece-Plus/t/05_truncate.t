use strict;
use Test::More;

use Time::Piece::Plus;

my $sometime = "2011-11-26 01:15:20";
my $datetime_format = "%Y-%m-%d %H:%M:%S";
my $time = Time::Piece::Plus->strptime($sometime, $datetime_format);

subtest "truncate to minute" => sub {
    my $truncated = $time->truncate(to => 'minute');
    is($truncated->second => 0, "seconds are truncated");
    is($truncated->strftime($datetime_format) => "2011-11-26 01:15:00", "correct truncated date");
};

subtest "truncate to hour" => sub {
    my $truncated = $time->truncate(to => 'hour');
    is($truncated->second => 0, "seconds are truncated");
    is($truncated->minute => 0, "minutes are truncated");
    is($truncated->strftime($datetime_format) => "2011-11-26 01:00:00", "correct truncated date");
};

subtest "truncate to day" => sub {
    my $truncated = $time->truncate(to => 'day');
    is($truncated->second => 0, "seconds are truncated");
    is($truncated->minute => 0, "minutes are truncated");
    is($truncated->hour   => 0, "hours are truncated");
    is($truncated->strftime($datetime_format) => "2011-11-26 00:00:00", "correct truncated date");
};

subtest "truncate to month" => sub {
    my $truncated = $time->truncate(to => 'month');
    is($truncated->second => 0, "seconds are truncated");
    is($truncated->minute => 0, "minutes are truncated");
    is($truncated->hour   => 0, "hours are truncated");
    is($truncated->mday   => 1, "days are truncated");
    is($truncated->strftime($datetime_format) => "2011-11-01 00:00:00", "correct truncated date");
};

subtest "truncate to year" => sub {
    my $truncated = $time->truncate(to => 'year');
    is($truncated->second => 0, "seconds are truncated");
    is($truncated->minute => 0, "minutes are truncated");
    is($truncated->hour   => 0, "hours are truncated");
    is($truncated->mday   => 1, "days are truncated");
    is($truncated->mon    => 1, "months are truncated");
    is($truncated->strftime($datetime_format) => "2011-01-01 00:00:00", "correct truncated date");
};

done_testing();
