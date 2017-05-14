#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

use File::Basename;
use Test::More;
use Date::Calc qw(Day_of_Week Month_to_Text);
use Wx qw(:font);

use lib qw(../lib);
use Wx::App::AnnualCal::MonthSizer;

my $param = init();

while (my $row = <DATA>)
  {
  my ($year, $month, $day) = split(/\s+/x, $row);
  $param->{'year'} = $year;
  my $ms = Wx::App::AnnualCal::MonthSizer->new($param);
  isa_ok($ms, 'Wx::App::AnnualCal::MonthSizer', '$ms');
  my $months = $ms->{months};
  isa_ok($months, 'ARRAY', '$months');
  my $col = $months->[$month-1]->{days}->[$day]->{col};
  my $weekday = Day_of_Week($year,$month,$day) % 7;
  my $name = Month_to_Text($month);
  is($col, $weekday, "correct data storage for $name $day, $year");
  }

    ##############################################

sub init
  {
  my $frame = Wx::Frame->new(undef,        # parent window
                             -1,           # default id value
                             "",           # no title
                            );
  isa_ok($frame, 'Wx::Frame', '$frame');
  my $panel = Wx::Panel->new($frame);
  isa_ok($panel, 'Wx::Panel', '$panel');
  my $fonts = {'norm' => Wx::Font->new(9, wxFONTFAMILY_MODERN,
                           wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL),
               'ital' => Wx::Font->new(9, wxFONTFAMILY_MODERN,
                           wxFONTSTYLE_ITALIC, wxFONTWEIGHT_BOLD),
               'emph' => Wx::Font->new(10, wxFONTFAMILY_MODERN,
                           wxFONTSTYLE_ITALIC, wxFONTWEIGHT_BOLD),
              };
  my $colors = {'gold' => Wx::Colour->new(255,215,0)};
  return {'panel' => $panel, 'colors' => $colors, 'fonts' => $fonts};
  }

done_testing();

__DATA__
1942 8 1
2000 7 1
2014 1 5
