use strict;
use warnings;
use Test::More;
use POSIX;
use Time::Local;
use Time::TZOffset qw/tzoffset/;

eval {
    POSIX::tzset;
    die q!tzset is implemented on this Cygwin. But Windows can't change tz inside script! if $^O eq 'cygwin';
    die q!tzset is implemented on this Windows. But Windows can't change tz inside script! if $^O eq 'MSWin32';
};
if ( $@ ) {
    plan skip_all => $@;
}

my @timezones = ( 
    ['Australia/Darwin','+0930','+0930','+0930','+0930'],
    ['Asia/Tokyo', '+0900','+0900','+0900','+0900'],
    ['UTC', '+0000','+0000','+0000','+0000'],
    ['Europe/London', '+0000','+0100','+0100','+0000'],
    ['Europe/Paris', '+0100','+0200','+0200','+0100'],
    ['America/New_York','-0500', '-0400', '-0400', '-0500'],
);

for my $timezones (@timezones) {
    my ($timezone, @tz) = @$timezones;
    local $ENV{TZ} = $timezone;
    POSIX::tzset;

    subtest "$timezone" => sub {
        my $i=0;
        for my $date ( ([10,1,2013], [10,5,2013], [15,8,2013], [15,11,2013]) ) {
            my ($day,$month,$year) = @$date;
            my $str = tzoffset(localtime(timelocal(0, 45, 12, $day, $month - 1, $year)));
            is $str, $tz[$i];
            $i++;
        }
    };

}

done_testing();

