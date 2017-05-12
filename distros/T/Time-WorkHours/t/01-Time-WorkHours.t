#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 24;
use Test::LectroTest::Compat;
use Test::LectroTest::Generator qw(:common);
use Data::Dumper 'Dumper';

use FindBin qw($Bin);
use lib "$Bin/../lib";

BEGIN {
    use_ok( 'Time::WorkHours' ) or exit;
}

our $trials = 100;

exit main();

sub main {
    my $wh = Time::WorkHours->new(
        work_interval_start => '17h',
        work_interval       => '6h',
    );
    
    isa_ok($wh, 'Time::WorkHours');
    can_ok($wh, 'shift_to_work_time');
    
    is($wh->work_interval_start_minute, 17*60, 'start minutes calculation');
    is($wh->work_interval_minutes, 6*60, 'interval minutes calculation');

    check_work_start_end();
    check_within();
    check_shift_to_work_time();
    return 0;
}

sub check_shift_to_work_time {
    diag 'work hours from 17:00 for 6h';
    my $wh = Time::WorkHours->new(
        work_interval_start => '17h',
        work_interval       => '6h',
    );
    my $now = random_datetime(
        'day'    => 5,
        'hour'   => 22,
        'minute' => 59,
    );
    my $shifted_now = $wh->shift_to_work_time($now);
    is_deeply(
        {
            'day'    => $shifted_now->day,
            'hour'   => $shifted_now->hour,
            'minute' => $shifted_now->minute,
        },
        {
            'day'    => 5,
            'hour'   => 22,
            'minute' => 59,
        },
        'last minute of the interval should have no shift ('.$now.')'
    );
    $now = random_datetime(
        'day'    => 5,
        'hour'   => 23,
        'minute' => 00,
    );
    $shifted_now = $wh->shift_to_work_time($now);
    is_deeply(
        {
            'day'    => $shifted_now->day,
            'hour'   => $shifted_now->hour,
            'minute' => $shifted_now->minute,
        },
        {
            'day'    => 6,
            'hour'   => 17,
            'minute' => 00,
        },
        'first minute of the interval should have shift to the beginning of the next interval ('.$now.' to '.$shifted_now.')'
    );
    
    diag 'work hours now from 22:00 for 4h';
    $wh = Time::WorkHours->new(
        work_interval_start => '22h',
        work_interval       => '4h',
    );
    $now = random_datetime(
        'day'    => 5,
        'hour'   => 14,
        'minute' => 00,
    );
    $shifted_now = $wh->shift_to_work_time($now);
    is_deeply(
        {
            'day'    => $shifted_now->day,
            'hour'   => $shifted_now->hour,
            'minute' => $shifted_now->minute,
        },
        {
            'day'    => 6,
            'hour'   => 00,
            'minute' => 00,
        },
        'middle of the interval day to the middle of the interval ('.$now.' to '.$shifted_now.')'
    );

    my $random_shift_lectro;
    $random_shift_lectro = Property {
        ##[ hour <- Int( range => [0, 23], sized => 0), minute <- Int( range => [0, 59]), start <- Int( range => [0, 23], sized => 0), interval <- Int( range => [1, 23*60+59], sized => 0) ]##
        
        my $wh = Time::WorkHours->new(
            work_interval_start => $start.'h',
            work_interval       => $interval,
        );
        my $random_datetime = random_datetime(
            'hour'   => $hour,
            'minute' => $minute,
        );
        my $shifted_now = $wh->shift_to_work_time($random_datetime);
        my $duration = $shifted_now->delta_ms($now);
        
        # should be shifted to work hours and no further than 24h
        $wh->within($shifted_now) && ($duration->minutes < 24*60);
    }, name => 'random datetime shift' ;
    holds( $random_shift_lectro, trials => $trials  );
}

sub check_work_start_end {    
    diag 'work hours from 17:00 for 6h';
    my $wh = Time::WorkHours->new(
        work_interval_start => '17h',
        work_interval       => '6h',
    );
    my $now = random_datetime(
        'day'    => 5,
        'hour'   => 16,
        'minute' => 25,
    );

    my $work_start = $wh->work_start($now);
    
    is_deeply(
        {
            'day'    => $work_start->day,
            'hour'   => $work_start->hour,
            'minute' => $work_start->minute,
        },
        {
            'day'    => 5,
            'hour'   => 17,
            'minute' => 0,
        },
        'check work_start ('.$now.')'
    );
    
    my $work_end = $wh->work_end($now);
    is_deeply(
        {
            'day'    => $work_end->day,
            'hour'   => $work_end->hour,
            'minute' => $work_end->minute,
        },
        {
            'day'    => 5,
            'hour'   => 23,
            'minute' => 0,
        },
        'check work_end'
    );
        
    my $work_start_end = Property {
        ##[ ]##
        lectrotest_work_start_end(
            'start'    => Int( range => [0, 24*60-1])->generate,
            'interval' => Int( range => [0, 24*60-1])->generate,
            'now'      => random_datetime(),
        );
    }, name => 'random test work_start & work_end' ;
    holds( $work_start_end, trials => $trials );

    diag 'work hours now from 22:00 for 4h';
    $wh = Time::WorkHours->new(
        work_interval_start => '22h',
        work_interval       => '4h',
    );
    
    $now = random_datetime(
        'day'    => 6,
        'hour'   => 01,
        'minute' => 30,
    );

    $work_start = $wh->work_start($now);
    is_deeply(
        {
            'day'    => $work_start->day,
            'hour'   => $work_start->hour,
            'minute' => $work_start->minute,
        },
        {
            'day'    => 5,
            'hour'   => 22,
            'minute' => 0,
        },
        'check work_start when date within the work hours (start: '.$work_start.' for: '.$now.')'
    );
    
    # check next_work_start within work hours
    my $next_work_start;
    $next_work_start = $wh->next_work_start($now);
    is_deeply(
        {
            'day'    => $next_work_start->day,
            'hour'   => $next_work_start->hour,
            'minute' => $next_work_start->minute,
        },
        {
            'day'    => 6,
            'hour'   => 22,
            'minute' => 0,
        },
        'check next_work_start when date within the work hours (start: '
            .$next_work_start
            .' for: '
            .$now.')'
    );

    $now = random_datetime(
        'day'    => 6,
        'hour'   => 02,
        'minute' => 30,
    );
    $next_work_start = $wh->next_work_start($now);
    is_deeply(
        {
            'day'    => $next_work_start->day,
            'hour'   => $next_work_start->hour,
            'minute' => $next_work_start->minute,
        },
        {
            'day'    => 6,
            'hour'   => 22,
            'minute' => 0,
        },
        'check next_work_start when date outside the work hours (start: '
            .$next_work_start
            .' for: '
            .$now.')'
    );
}

sub check_within {    
    my $wh = Time::WorkHours->new(
        work_interval_start => '17h',
        work_interval       => '6h',
    );
    my $now = random_datetime(
        'hour'   => 16,
        'minute' => 25,
    );
    
    my $random_within;
    $random_within = random_datetime(
        'hour'    => 17,
        'minutes' => 00,
    );
    ok(
        $wh->within($random_within),
        '17:00 within work hours ('.$random_within.')',
    );

    $random_within = random_datetime(
        'hour'    => 22,
        'minute'  => 59,
        'seconds' => 59,
    );
    ok(
        $wh->within($random_within),
        '22:59 within work hours ('.$random_within.')',
    );

    $random_within = random_datetime(
        'hour'   => 16,
        'minute' => 59,
    );
    ok(
        !$wh->within($random_within),
        '16:59 outside work hours ('.$random_within.')',
    );

    $random_within = random_datetime(
        'hour'    => 23,
        'minute'  => 00,
        'seconds' => 00,
    );
    ok(
        !$wh->within($random_within),
        '23:00 outside work hours ('.$random_within.')',
    );
    
    my $random_within_lectro;
    $random_within_lectro = Property {
        ##[ hour <- Int( range => [17, 22], sized => 0), minute <- Int( range => [0, 59]) ]##
        $random_within = random_datetime(
            'hour'   => $hour,
            'minute' => $minute,
        );
        $wh->within($random_within);
    }, name => 'random within' ;
    holds( $random_within_lectro, trials => $trials  );

    $random_within_lectro = Property {
        ##[ hour <- Int( range => [0, 23], sized => 0), minute <- Int( range => [0, 59]) ]##
        $tcon->retry() if (($hour >= 17) and ($hour <=22));
        $random_within = random_datetime(
            'hour'   => $hour,
            'minute' => $minute,
        );
        !$wh->within($random_within);
    }, name => 'random outside' ;
    holds( $random_within_lectro, trials => $trials  );


    # change the range to overlap noon
    diag 'work hours now from 22:00 for 4h';
    $wh = Time::WorkHours->new(
        work_interval_start => '22h',
        work_interval       => '4h',
    );

    $random_within = random_datetime(
        'hour'    => 01,
        'minute'  => 00,
        'seconds' => 00,
    );
    ok(
        $wh->within($random_within),
        '01:00 within work hours ('.$random_within.') '.$wh->work_start.' '.$wh->work_end,
    );
    
    $random_within_lectro = Property {
        ##[ hour <- Int( range => [0, 23], sized => 0), minute <- Int( range => [0, 59]) ]##
        $tcon->retry()
            if (($hour < 22) and ($hour >= 2));
        $random_within = random_datetime(
            'hour'   => $hour,
            'minute' => $minute,
        );
        $wh->within($random_within);
    }, name => 'random within 2x' ;
    holds( $random_within_lectro, trials => $trials  );

    $random_within_lectro = Property {
        ##[ hour <- Int( range => [0, 23], sized => 0), minute <- Int( range => [0, 59]) ]##
        $tcon->retry()
            if not (($hour < 22) and ($hour >= 2));
        $random_within = random_datetime(
            'hour'   => $hour,
            'minute' => $minute,
        );
        !$wh->within($random_within);
    }, name => 'random outside 2x' ;
    holds( $random_within_lectro, trials => $trials  );

    return 0;
}

sub datetime_props {
    my $date          = shift;
    my $ignore_second = shift;
    
    return (
        'year'   => $date->year,
        'month'  => $date->month,
        'day'    => $date->day,
        'hour'   => $date->hour,
        'minute' => $date->minute,
        'second' => ($ignore_second ? 0 : $date->second),
    );
}

sub lectrotest_work_start_end {
    my %args = @_;
    
    my $start    = $args{'start'};
    my $interval = $args{'interval'};
    my $now      = $args{'now'};
    
    my $start_string    = sprintf '%2d:%02d', int($start / 60), ($start % 60);
    my $interval_string = sprintf '%2d:%02d', int($interval / 60), ($interval % 60);
    
    my $wh = Time::WorkHours->new(
        work_interval_start => $start,
        work_interval       => $interval,
    );
    
    my $work_start = $wh->work_start($now);
    my $got      = {
        'hour'   => $work_start->hour,
        'minute' => $work_start->minute,
    };
    my $expected = {
        'hour'   => int($start / 60),
        'minute' => $start % 60,
    };
    if (not Test::More::_deep_check($got, $expected)) {
        diag Dumper {
            'got'      => $got,
            'expected' => $expected,
            'what'     => 'work_start()',
            'start'    => $start_string,
            'interval' => $interval_string,
        };
        return 0
    }
    
    my $work_end = $wh->work_end($now);
    $got      = {
        'hour'   => $work_end->hour,
        'minute' => $work_end->minute,
    };
    my $expected_work_end = $wh->work_start($now)->add('minutes' => $interval);
    $expected = {
        'hour'   => $expected_work_end->hour,
        'minute' => $expected_work_end->minute,
    };
    if (not Test::More::_deep_check($got, $expected)) {
        diag Dumper {
            'got'      => $got,
            'expected' => $expected,
            'what'     => 'work_end()',
            'start'    => $start_string,
            'interval' => $interval_string,
        };
        return 0
    }
    
    return 1;
}

sub random_datetime {
    my %args = @_;
    
    return DateTime->new(
        'year'   => (defined $args{'year'}   ? $args{'year'}   : Int( range => [0, 3000])->generate),
        'month'  => (defined $args{'month'}  ? $args{'month'}  : Int( range => [1, 12], sized=>0)->generate),
        'day'    => (defined $args{'day'}    ? $args{'day'}    : Int( range => [1, 20], sized=>0)->generate),   # hmm
        'hour'   => (defined $args{'hour'}   ? $args{'hour'}   : Int( range => [0, 23])->generate),
        'minute' => (defined $args{'minute'} ? $args{'minute'} : Int( range => [0, 59])->generate),
        'second' => (defined $args{'second'} ? $args{'second'} : Int( range => [0, 59])->generate),
    );
}
