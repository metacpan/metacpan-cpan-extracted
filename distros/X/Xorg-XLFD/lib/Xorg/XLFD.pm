package Xorg::XLFD;
use strict;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK);

  $VERSION = '0.128';

  @ISA = qw(Exporter);

  @EXPORT_OK = qw(get_xlfd);

};

sub get_xlfd {
  my $fam = shift; # fixed
  my %fonts;

  open(my $fh, '-|', 'xlsfonts') or croak("xlsfonts: $!\n");

  while(<$fh>) {
    chomp;
    $_ =~ s/^-//;
    my($foundary, $family, $weight, $slant, $set_width, $pixels, $tenths,
        $h_dpi, $v_dpi, $spacing, $avg_width, $charset)
      =  split(/--?/, $_);

    if( ($family =~ /^\d+$/m) or ($family eq '') ) {
      next;
    }

    push(@{$fonts{family}->{$family}->{weight}}, $weight)
      unless $weight ~~ @{$fonts{family}->{$family}->{weight}}; 

    push(@{$fonts{family}->{$family}->{width}}, $avg_width)
      unless $avg_width ~~ @{$fonts{family}->{$family}->{width}}; 

    push(@{$fonts{family}->{$family}->{vert_dpi}}, $v_dpi)
      unless $v_dpi ~~ @{$fonts{family}->{$family}->{vert_dpi}}; 

    push(@{$fonts{family}->{$family}->{horiz_dpi}}, $h_dpi)
      unless $h_dpi ~~ @{$fonts{family}->{$family}->{horiz_dpi}}; 

    push(@{$fonts{family}->{$family}->{tenths}}, $tenths)
      unless $tenths ~~ @{$fonts{family}->{$family}->{tenths}}; 

    push(@{$fonts{family}->{$family}->{spacing}}, $spacing)
      unless $spacing ~~ @{$fonts{family}->{$family}->{spacing}}; 

    push(@{$fonts{family}->{$family}->{slant}}, $slant)
      unless $slant ~~ @{$fonts{family}->{$family}->{slant}}; 

    push(@{$fonts{family}->{$family}->{'set width'}}, $set_width)
      unless $set_width ~~ @{$fonts{family}->{$family}->{'set width'}}; 

    push(@{$fonts{family}->{$family}->{pixels}}, $pixels)
      unless $pixels ~~ @{$fonts{family}->{$family}->{pixels}}; 

    push(@{$fonts{family}->{$family}->{charset}}, $charset)
      unless $charset ~~ @{$fonts{family}->{$family}->{charset}}; 

    push(@{$fonts{family}->{$family}->{foundary}}, $foundary)
      unless $foundary ~~ @{$fonts{family}->{$family}->{foundary}}; 

  }
  return (exists($fonts{family}{$fam}))
    ? $fonts{family}{$fam}
    : \%fonts
    ;
}


1;


__END__


=pod

=head1 NAME

Xorg::XLFD - X11 logical font description interface

=head1 SYNOPSIS

    use Xorg::XLFD qw(get_xlfd);

    my $desc = get_xlfd();         # all descriptions

    my $fixed = get_xlfd('fixed'); # description for the 'fixed' font

=head1 DESCRIPTION

X logical font description is a font standard used by the X Window System.
This module provides an interface for accessing these descriptions.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 get_xlfd()

B<get_xlfd()> takes one optional argument, a family name.
If no argument is provided, all available descriptions will be returned.

=head2 STRUCTURE

An example structure for the standard 'Fixed' font:

              fixed => {
                         charset => [
                                      "jisx0208.1983",
                                      "iso10646",
                                      "iso8859",
                                      "koi8",
                                      "jisx0201.1976",
                                      0,
                                      120,
                                      180
                                    ],
                         foundary => [
                                       "jis",
                                       "misc",
                                       "sony"
                                     ],
                         horiz_dpi => [
                                        75,
                                        100,
                                        0,
                                        120
                                      ],
                         pixels => [
                                     0,
                                     16,
                                     24,
                                     13,
                                     14,
                                     15,
                                     18,
                                     10,
                                     20,
                                     6,
                                     7,
                                     8,
                                     9,
                                     "ja",
                                     "ko",
                                     12
                                   ],
                         "set width" => [
                                          "normal",
                                          "semicondensed"
                                        ],
                         slant => [
                                    "r",
                                    "o"
                                  ],
                         spacing => [
                                      "c",
                                      100,
                                      75
                                    ],
                         tenths => [
                                     0,
                                     110,
                                     150,
                                     170,
                                     230,
                                     100,
                                     120,
                                     130,
                                     140,
                                     70,
                                     200,
                                     60,
                                     50,
                                     80,
                                     90,
                                     13,
                                     18
                                   ],
                         vert_dpi => [
                                       75,
                                       100
                                     ],
                         weight => [
                                     "medium",
                                     "bold"
                                   ],
                         width => [
                                    0,
                                    160,
                                    240,
                                    70,
                                    80,
                                    90,
                                    60,
                                    140,
                                    100,
                                    40,
                                    50,
                                    "c",
                                    120
                                  ]
                       },

=head1 XLFD SPECIFICATION

The XLFD is made up from 12/14 font properties as visualized below.

  -xos4-terminus-medium-r-normal--28-280-72-72-c-140-iso8859-1
   |     |        |    |   |     |   |   |  | |  |     |__________ charset
   |     |        |    |   |     |   |   |  | |  |________________ avg. width
   |     |        |    |   |     |   |   |  | |___________________ spacing
   |     |        |    |   |     |   |   |  |_____________________ vert. dpi
   |     |        |    |   |     |   |   |________________________ horiz. dpi
   |     |        |    |   |     |   |____________________________ 10th's of 1 pt
   |     |        |    |   |     |________________________________ pixels
   |     |        |    |   |______________________________________ set width
   |     |        |    |__________________________________________ slant
   |     |        |_______________________________________________ weight
   |     |________________________________________________________ family
   |______________________________________________________________ foundary


=head1 CAVEATS

We are relying on an external application for fetching the available font
descriptions. This is not good. We will look at the xlsfonts source code and try
to come up with a smarter way.

=head1 REPORTING BUGS

Report bugs on rt.cpan.org or to magnus@trapd00r.se

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2011 the B<Xorg::XLFD> L</AUTHOR> and L</CONTRIBUTORS> as listed
above.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
