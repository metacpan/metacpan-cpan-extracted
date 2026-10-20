#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Time::Keeper;
use Time::Keeper::Business;

# Japan's holidays from 2016, as the Cabinet Office lists them: the rules of
# the Act on National Holidays, the equinoxes by the formula the National
# Astronomical Observatory's announcements follow (good to 2099), the
# special dates of 2019 to 2021 as rules of one year, a Sunday holiday moved
# to the next day that is not one, and a day between two holidays made one.

sub vernal    { my $y = shift; int(20.8431 + 0.242194 * ($y - 1980) - int(($y - 1980) / 4)) }
sub autumnal  { my $y = shift; int(23.2488 + 0.242194 * ($y - 1980) - int(($y - 1980) / 4)) }

sub japan {
    my $R = 'Time::Keeper::Business::Rule';
    my $once = sub { my ($m, $d, $name, $year) = @_; $R->fixed(month => $m, day => $d, name => $name)->between(from => $year, to => $year) };
    my @rules = (
        $R->fixed(month => 1, day => 1, name => '元日'),
        $R->nth(month => 1, day_of_week => 1, n => 2, name => '成人の日'),
        $R->fixed(month => 2, day => 11, name => '建国記念の日'),
        $R->fixed(month => 12, day => 23, name => '天皇誕生日')->between(to => 2018),
        $R->fixed(month => 2, day => 23, name => '天皇誕生日')->between(from => 2020),
        $R->fixed(month => 3, day => 20, name => '春分の日')->only_if(sub { vernal($_[0]) == 20 }),
        $R->fixed(month => 3, day => 21, name => '春分の日')->only_if(sub { vernal($_[0]) == 21 }),
        $R->fixed(month => 4, day => 29, name => '昭和の日'),
        $R->fixed(month => 5, day => 3, name => '憲法記念日'),
        $R->fixed(month => 5, day => 4, name => 'みどりの日'),
        $R->fixed(month => 5, day => 5, name => 'こどもの日'),
        $R->nth(month => 7, day_of_week => 1, n => 3, name => '海の日')->except(years => [2020, 2021]),
        $R->fixed(month => 8, day => 11, name => '山の日')->except(years => [2020, 2021]),
        $R->nth(month => 9, day_of_week => 1, n => 3, name => '敬老の日'),
        $R->fixed(month => 9, day => 22, name => '秋分の日')->only_if(sub { autumnal($_[0]) == 22 }),
        $R->fixed(month => 9, day => 23, name => '秋分の日')->only_if(sub { autumnal($_[0]) == 23 }),
        $R->nth(month => 10, day_of_week => 1, n => 2, name => '体育の日')->between(to => 2018),
        $R->nth(month => 10, day_of_week => 1, n => 2, name => '体育の日（スポーツの日）')->between(from => 2019, to => 2019),
        $R->nth(month => 10, day_of_week => 1, n => 2, name => 'スポーツの日')->between(from => 2020)->except(years => [2020, 2021]),
        $R->fixed(month => 11, day => 3, name => '文化の日'),
        $R->fixed(month => 11, day => 23, name => '勤労感謝の日'),
        $once->(5, 1, '休日（祝日扱い）', 2019),
        $once->(10, 22, '休日（祝日扱い）', 2019),
        $once->(7, 23, '海の日', 2020), $once->(7, 24, 'スポーツの日', 2020), $once->(8, 10, '山の日', 2020),
        $once->(7, 22, '海の日', 2021), $once->(7, 23, 'スポーツの日', 2021), $once->(8, 8, '山の日', 2021),
    );
    return $R->set((map { $_->observed('next_business_day_if_sunday', keep => 1) } @rules),
                   $R->sandwiched(name => '休日'), name => '日本')->between(from => 2016);
}

unless (caller) {
    binmode STDOUT, ':encoding(UTF-8)';
    my $year = shift // Time::Keeper->today->year;
    my $b = Time::Keeper::Business->new(holidays => japan(), zone => 'Asia/Tokyo', name => '日本');
    print "$year\n";
    printf "  %s  %s  %s\n", $_->[0], $_->[0]->format('EEEE'), $_->[1] for $b->holidays(year => $year);
    my $day = Time::Keeper::Date->new(year => $year, month => 12, day => 20);
    print "the ten business days after $day:\n";
    printf "  %s  %s\n", $day = $b->next_business_day($day), $day->format('EEEE') for 1 .. 10;
}

1;
