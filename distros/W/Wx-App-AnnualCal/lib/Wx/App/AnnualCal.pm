package Wx::App::AnnualCal;

use strict;
use warnings;

use Wx 0.990 qw(:frame);
use base qw(Wx::App);

use lib qw(../../../lib);
use Wx::App::AnnualCal::MyFrame;

my $VERSION = 0.92;

          ##################################################

sub OnInit
  {
  my $frame = Wx::App::AnnualCal::MyFrame->new
    (
     undef,                                 # parent window
     -1,                                    # default id value
     'Annual Calendar',                     # title
     [-1,-1],                               # default position
     [-1,-1],                               # default size
     wxDEFAULT_FRAME_STYLE,                 # frame style
    );                                   
  $frame->build();                          # creates calendar
  $frame->Center(wxBOTH);                   # center frame on screen
  $frame->Show(1);                          # displays calendar

  return(1);
  }

# * * *
#
#  Input for Dist::Zilla::Pod::Weaver plugin to create POD documentation.
#
# * * *

#ABSTRACT: the main module of the AnnualCal distribution


1;


__END__
=pod

=head1 NAME

Wx::App::AnnualCal - the main module of the AnnualCal distribution

=head1 VERSION

version 0.92

=head1 SYNOPSIS

Main module for AnnualCal, a GUI application programmed in wxPerl,
displaying an annual calendar for the year input by the user.

=head1 METHODS

=head2 OnInit

The entry point to a wxPerl program, analagous to 'main' in a C program.

=head1 DESIGN

The design of the GUI is moderately complex, utilizing BoxSizer, Grid,
GridSizer, TxtCtrl, and Button widgets.

The name of each month is inserted into a TxtCtrl, and the days of each
month are inserted into a 7x7 GridSizer, the first row of which is reserved
for the weekday names.
Each of these 12 pairs of widgets is then inserted into a vertical BoxSizer,
the TxtCtrl added prior to the GridSizer, creating a set of 12 widgets
containing all the data needed to display a year.  The next step is to insert 
this collection into a single 3x4 Grid, in the correct order; a GridSizer
is not used here because today's date is highlighted, when it is displayed.

A horizontal BoxSizer is used to contain the interactive
Buttons for changing the year, and a TxtCtrl to display the current year.

Finally, a vertical BoxSizer is created which contains the Grid on top, and
the horizontal BoxSizer on the bottom.  The motivation for this design is
that only the 'upper sizer' has to be replaced when the user changes the
year; the 'bottom sizer' is essentially static, except for updating
the TexCtrl to display the new year.

=head1 AUTHOR

Elliot Winston <exw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Elliot Winston.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

