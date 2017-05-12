#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';


use 5.010;

use lib ".";

use Test::Tester;
use Test::Regexp;
use t::Common;

sub init_data;

my @data   = init_data;


my $seen;
foreach my $data (@data) {
    my ($subject, $pattern, $match, $expected, $captures) = @$data;

    my $match_val = $match =~ /[ym1]/i;
    my $match_res;
    my ($premature, @results) = run_tests sub {
        $match_res = match subject       =>  $subject,
                           keep_pattern  =>  $pattern,
                           match         =>  $match_val,
                           captures      =>  $captures,
    };

    check results   => \@results,
          premature => $premature,
          expected  => $expected,
          match     => $match_val,
          match_res => $match_res,
          pattern   => $pattern,
          subject   => $subject,
          keep      =>  1,
    ;

    if ($match_res && ! $seen ++) {
        my ($premature, @results) = run_tests sub {
            $match_res = match subject         =>  $subject,
                               keep_pattern    =>  $pattern,
                               no_keep_message => 1,
                               match           =>  $match_val,
                               captures        =>  $captures,
        };

        check results   => \@results,
              premature => $premature,
              expected  => $expected,
              match     => $match_val,
              match_res => $match_res,
              pattern   => $pattern,
              subject   => $subject,
        ;
    }
}

#
# Data taken from 'meta state_flowers'
#

sub init_data {(
    # Match without captures.
    ['Rose',              qr {\w+},                    'y', 'PPPP', []],

    # Match with just numbered captures.
    ['Black Eyed Susan',  qr {(\w+)\s+(\w+)\s+(\w+)},  'y', 'PPPPPPP',
      [qw [Black Eyed Susan]]],

    # Match with just named captures.
    ['Sego Lily',         qr {(?<a>\w+)\s+(?<b>\w+)},  'y', 'PPPPPPPPPP',
      [[a => 'Sego'], [b => 'Lily']]],

    # Mix named and numbered captures.
    ['California Poppy',  qr {(?<state>\w+)\s+(\w+)},  'y', 'PPPPPPPP',
      [[state => 'California'], 'Poppy']],

    # Repeat named capture.
    ['Indian Paintbrush', qr {(?<s>\w+)\s+(?<s>\w+)},  'y', 'PPPPPPPPP',
      [[s => 'Indian'], [s => 'Paintbrush']]],

    #
    # Failures.
    #

    # No captures, but a result.
    ['Violet',            qr {\w+},                    'y', 'PPPFF',
      ['Violet']],

    # Capture, no result.
    ['Mayflower',         qr {(\w+)},                  'y', 'PPPF', []],

    # Capture, wrong result.
    ['Magnolia',          qr {(\w+)},                  'y', 'PPPFP',
      ['Violet']],

    # Named capture, numbered results.
    ['Hawaiian Hibiscus', qr {(?<a>\w+)\s+(?<b>\w+)},  'y', 'PPFPPP',
      [qw [Hawaiian Hibiscus]]],

    # Numbered capture, named results.
    ['Cherokee Rose',     qr {(\w+)\s+(\w+)},          'y', 'PPFFFFFPPP',
      [[a => 'Cherokee'], [b => 'Rose']]],

    # Wrong capture names.
    ['American Dogwood',  qr {(?<a>\w+)\s+(?<b>\w+)},  'y', 'PPFPFPPPPP',
      [[b => 'American'], [a => 'Dogwood']]],

    # Wrong order of captures.
    ['Mountain Laurel',   qr {(?<a>\w+)\s+(?<b>\w+)},  'y', 'PPPPPPPFFP',
      [[b => 'Laurel'], [a => 'Mountain']]],

    # Wrong order of captures - same name
    ['Yucca Flower',      qr {(?<a>\w+)\s+(?<a>\w+)},  'y', 'PPFFPPFFP',
      [[a => 'Flower'], [a => 'Yucca']]],

    # Too many numbered captures.
    ['Sagebrush',         qr {(\w+)},                  'y', 'PPPPFF',
      [qw [Sagebrush Violet]]],

    # Too many named captures.
    ['Apple Blossom',     qr {(?<a>\w+)\s+(?<a>\w+)},  'y', 'PPPPFFPPPFF',
      [[a => 'Apple'], [a => 'Blossom'], [a => 'Violet']]],

    # Not enough named captures.
    ['Wood Violet',       qr {(?<a>\w+)\s+(?<a>\w+)},  'y', 'PPPFPPF',
      [[a => 'Wood']]],

    # Incomplete match
    ['Forget Me Not',     qr {(?<a>\w+)\s+(?<b>\w+)},  'y', 'PFSSSSSSSS',
      [[a => 'Forget'], [b => 'Me']]],

    # Incomplete match
    ['Forget Me Not 2',   qr {(?<a>\w+)\s+(?<b>\w+)\s+(?<c>\w+)},
                                                       'y', 'PFSSSSSSSSSSS',
      [[a => 'Forget'], [b => 'Me'], [c => 'Not']]],
)}


__END__
