package Wx::App::AnnualCal::MonthSizer;

use strict;
use warnings;

use Wx 0.990 qw(:sizer :textctrl);
use Wx::Grid;

use Date::Calc 6.3 qw(Day_of_Week Days_in_Month);

          ##################################################

sub new
  {
  my ($class, $param) = @_;

  my $year = $param->{year};

  my $months = [{'name' => 'JANUARY',   'len' => 31, 'days' => []},
                {'name' => 'FEBRUARY',  'len' => Days_in_Month($year,2), 'days' => []},
                {'name' => 'MARCH',     'len' => 31, 'days' => []},
                {'name' => 'APRIL',     'len' => 30, 'days' => []},
                {'name' => 'MAY',       'len' => 31, 'days' => []},
                {'name' => 'JUNE',      'len' => 30, 'days' => []},
                {'name' => 'JULY',      'len' => 31, 'days' => []},
                {'name' => 'AUGUST',    'len' => 31, 'days' => []},
                {'name' => 'SEPTEMBER', 'len' => 30, 'days' => []},
                {'name' => 'OCTOBER',   'len' => 31, 'days' => []},
                {'name' => 'NOVEMBER',  'len' => 30, 'days' => []},
                {'name' => 'DECEMBER',  'len' => 31, 'days' => []},
               ];

  for (my $i=0; $i<12; $i++)
    {
    my $col = Day_of_Week($year, $i+1, 1);
    $col %= 7;
    my $row = 1;
    for (my $j=1; $j<=$months->[$i]{len}; $j++)
      {
      $months->[$i]{days}->[$j] = {'row' => $row, 'col' => $col};
      if ($col == 6)
        {
        $col = 0;
        $row++;
        }
      else
        {
        $col++;
        }
      }
    }

  my $self = {'months' => $months, 'param' => $param};

  bless($self, $class);
  return($self);
  }

          ##################################################

sub getmonthsizer
  {
  my ($self, $ind) = @_;

  my $months = $self->{months};
  my $ref = $self->{param};
  my ($panel, $year, $fonts, $current, $day_names, $colors) =
     @{$ref}{qw(panel year fonts current day_names colors)};

  my $txt = Wx::TextCtrl->new($panel,
                              -1,
                              $months->[$ind]{name},
                              [-1,-1],
                              [-1,-1],
                              wxTE_CENTRE|wxTE_READONLY,
                             );
  $txt->SetFont($fonts->{ital});
  $txt->SetForegroundColour(Wx::Colour->new('green'));
  $txt->SetBackgroundColour(Wx::Colour->new('black'));

  my $grid = Wx::Grid->new($panel, -1, [-1,-1]);
  my ($nrow, $ncol) = (7,7);
  $grid->CreateGrid($nrow, $ncol);
  $grid->SetRowLabelSize(0);
  $grid->SetColLabelSize(0);
  $grid->SetGridLineColour(Wx::Colour->new('black'));
  $grid->SetDefaultCellBackgroundColour(Wx::Colour->new('black'));
  $grid->SetDefaultCellTextColour($colors->{'gold'});
  $grid->SetDefaultCellFont($fonts->{norm});
  $grid->SetDefaultCellAlignment(wxALIGN_CENTRE, wxALIGN_CENTRE);
  $grid->AutoSize();
  my $cell_wide = $grid->GetColSize(0) + 2;

  for (my $j=0; $j<$ncol; $j++)
    {
    $grid->SetColSize($j, $cell_wide);
    $grid->SetCellValue(0, $j, $day_names->[$j]);
    $grid->SetCellFont(0, $j, $fonts->{norm});
    };
  for (my $j=0; $j<$nrow; $j++)
    {
    $grid->SetCellTextColour($j, 0, Wx::Colour->new('cyan'));
    $grid->SetCellTextColour($j, $ncol-1, Wx::Colour->new('cyan'));
    }

  my $ndays = $months->[$ind]{len};
  $ref = $months->[$ind]{days};
  for (my $day=1; $day<=$ndays; $day++)
    {
    my $row = $ref->[$day]{row};
    my $col = $ref->[$day]{col};
    $grid->SetCellValue($row, $col, $day);
    }

  if ($year == $current->{year})
    {
    if (uc($current->{month}) eq $months->[$ind]{name})
      {
      my $row = $ref->[$current->{day}]{row};
      my $col = $ref->[$current->{day}]{col};
      $grid->SetCellTextColour($row, $col, Wx::Colour->new('black'));
      $grid->SetCellBackgroundColour($row, $col, $colors->{'gold'});
      $grid->SetCellFont($row, $col, $fonts->{emph});
      }
    }

  my $monthsizer = Wx::BoxSizer->new(wxVERTICAL);
  $monthsizer->Add($txt,              # text control
                   0,                 # vertically unstretchable
                   wxALIGN_CENTER,    # central alignment
                  );                    
  $monthsizer->Add($grid);            

  return($monthsizer);
  }

# * * *
#
#  Input for Dist::Zilla::Pod::Weaver plugin to create POD documentation.
#
# * * *

#ABSTRACT: a module in the AnnualCal distribution

1;

__END__
=pod

=head1 NAME

Wx::App::AnnualCal::MonthSizer - a module in the AnnualCal distribution

=head1 VERSION

version 0.92

=head1 SYNOPSIS

Package which generates and stores the required data for the display.

=head1 METHODS

=head2 new

Given the year to be displayed, which is passed as a value in a data
container, the constructor populates the container with additional
data describing the days of each month of the year.

=head2 getmonthsizer

Method which creates and returns the 'upper sizer' which displays the calendar
for the desired year (see L<Wx::App::AnnualCal/DESIGN>).

=head1 AUTHOR

Elliot Winston <exw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Elliot Winston.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

