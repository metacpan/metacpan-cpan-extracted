# Weather::GHCN::Measure.pm - class for creating a list of weather measures based on ghcn_fetch options -tavg and -precip

## no critic (Documentation::RequirePodAtEnd)

=head1 NAME

Weather::GHCN::Measures - provide a list of meteorological metrics to be obtained from GHCN daily data

=head1 VERSION

version v0.0.008

=head1 SYNOPSIS

  use Weather::GHCN::Measures;

  my $opt_href => {
    location => 'New York',
    country => 'US',
  };

  my $mobj = Weather::GHCN::Measures->new( $opt_href );

  say join ' ', $mobj->measures->@*;

  if ( 'TMAX' =~ $mobj->re ) {
      say 'TMAX is available';
  }


=head1 DESCRIPTION

The B<Weather::GHCN::Measures> module provides a class that is used to encapsulate
the set of meteorological measures that the GHCN module consumer wants
to obtain from NOAA GHCN data.  By default, the object returned by
instantiating this class will include TMAX (maximum daily temperature)
and TMIN (minimum daily temperature) as required metrics.  It will also
include Tavg, which is derived by averaging TMAX and TMIN.

To include other metrics, notably TAVG (which is computed by the
weather station instrumentation), and precipitation metrics (PRCP, SNOW
and SNWD) see the new() method documentation.

The module is primarily for use by module Weather::GHCN::StationTable.

=cut

# these are needed because perlcritic fails to detect that Object::Pad handles these things
## no critic [ValuesAndExpressions::ProhibitVersionStrings]
## no critic [TestingAndDebugging::RequireUseWarnings]

use v5.18;  # minimum for Object::Pad
use Object::Pad 0.66 qw( :experimental(init_expr) );


package Weather::GHCN::Measures;
class   Weather::GHCN::Measures;

our $VERSION = 'v0.0.008';

use Const::Fast;

=head1 METHODS

=head2 new( [$opt_href] )

Create a new Measures object.

Other GHCN modules will use the measures determined by instantiating
this object to get those data measurements from the GHCN daily data.

The optional argument passed to new() is expected to be a reference
to a hash which contains kw/value pairs such as would be gathered by
the consumer of GHCN modules when it calls Getopt::Long with an
options list that includes:

    qw( tavg precip anomalies )

If the key 'tavg' is present and has a true value, then the TAVG
measure is included.

If the key 'precip' is present and has a true value, then the PRCP,
SNOW and SNWD (Snow Days) measures are included.

If the key 'anomalies' is found and has a true values, then additional
columns are added in order to provide a place for temperature
anomalies to be report.

=cut

field @measures :reader;
field $re       :reader;

=head1 FIELD ACCESSORS

=head2 measures

Returns a list of the measures applicable to the options provided
in the constructor.

=head2 re

Returns a regular expression object that can be used to validate
measure names by pattern matching.  Any measure name matching this
B<re> is valid for the options given in the object constructor.

=head2 new( $opt_href )

Creates a new Measures object, using the options in the argument,
which must be a Weather::GHCN::Options object.

=cut

BUILD {
    my ($opt_href) = @_;

    $opt_href //= {};

    my %opt = ( $opt_href->%* );

    @measures =  qw( TMAX TMIN Tavg );

    push @measures, qw( TAVG )                      if $opt{tavg};
    push @measures, qw( PRCP SNOW SNWD )            if $opt{precip};

    if ( $opt{anomalies} ) {
        push @measures, qw( A_TMAX A_TMIN A_Tavg);
        push @measures, qw( A_TAVG )                if $opt{tavg};
        push @measures, qw( A_PRCP A_SNOW A_SNWD )  if $opt{precip};
    }

    my $m_re = join q(|), @measures;
    $re = qr{ \A $m_re \Z }xms;
}


=head2 DOES

Defined by Object::Pad.  Included for POD::Coverage.

=head2 META

Defined by Object::Pad.  Included for POD::Coverage.

=head1 AUTHOR

Gary Puckering (jgpuckering@rogers.com)

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Gary Puckering

=cut

1;
