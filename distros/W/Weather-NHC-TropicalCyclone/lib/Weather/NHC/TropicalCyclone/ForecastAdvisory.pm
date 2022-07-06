package Weather::NHC::TropicalCyclone::ForecastAdvisory;

use strict;
use warnings;
use Date::Calc;
use Getopt::Long;
use Util::H2O::More qw/baptise/;

sub new {
    my ( $pkg, %self ) = @_;

    # input_file and input_text are mutually exclusive via the contructor
    if ( not( exists $self{input_file} or exists $self{input_text} ) or ( exists $self{input_file} and exists $self{input_text} ) or not exists $self{output_file} ) {
        die qq{Constructor requires specifying the 'input_file' xor 'input_text', and 'output_file' parameters.\n};
    }
    my @fields = (qw/input_file input_text output_file as_atcf/);
    my $self = baptise -recurse, \%self, $pkg, @fields;
    return $self;
}

sub extract_and_save_atcf {
    my $self = shift;
    $self->extract_atcf;
    return $self->save_atcf;
}

sub save_atcf {
    my $self = shift;
    open( my $fh, q{>}, $self->output_file ) || die qq{Failed to open output ATCF file} . $self->output_file . qq{ : $!.\n};
    my $output_ref = $self->as_atcf;
    print $fh join( qq{\n}, @$output_ref );
    close $fh;
    return $self->output_file;
}

sub extract_atcf {
    my $self = shift;

    my @lines = ();

  ADVISORY_SOURCE:
    if ( $self->input_file ) {
        open( my $INPUT, q{<}, $self->input_file ) || die q{Failed to open forecast advisory file} . $self->input_file . qq{ for conversion to ATCF format: $!.\n};
        @lines = (<$INPUT>);
        close $INPUT;
    }
    elsif ( $self->input_text ) {
        @lines = split /\n/, $self->input_text;
    }

    my @output = ();    # accumulate content for $output, do write at the very end

    # parse rss reports from Nat'l Hurricane Center Atlantic Marine Forecast
    # Advisory.  NHC Mail (Atlantic Marine)
    # <mail-storm-atlan-marine@seahorse.nhc.noaa.gov> See:
    # http://www.nhc.noaa.gov/signup.shtml and select the following list: Atlantic
    # Marine (Forecast/Advisories and updates ONLY)

    # BASIN,CY,YYYYMMDDHH,TECHNUM,TECH,TAU,LatN/S,LonE/W,VMAX,MSLP,TY,RAD,WINDCODE,RAD1,RAD2,RAD3,RAD4,RADP,RRP,MRD,GUSTS,EYE,SUBREGION,MAXSEAS,INITIALS,DIR,SPEED,STORMNAME,DEPTH,SEAS,SEASCODE,SEAS1,SEAS2,SEAS3,SEAS4
    #
    #                                                                                                    1         1         1         1         1         1         1         1         1         1
    #          1         2         3         4         5         6         7         8         9         0         1         2         3         4         5         6         7         8         9
    #01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
    #AL, 01, 2009052912, 03, OFCL,   0, 393N,  649W,  30, 1006, TD,  34, NEQ,    0,    0,    0,    0,    0,    0,  40,  40,   0,    ,   0, TBK,  65,  17,           ,  , 12, NEQ,  60,  60,   0,   0
    my $template     = "_BASIN_, 01, 2009010100,   , OFCL,   0, 000N,  000W,  30,    0,   ,  34, NEQ,    0,    0,    0,    0,    0,    0,   0,  40,   0,    ,   0, TBK,  65,  17,           ,  , 12, NEQ,  60,  60,   0,   0";
    my %month_lookup = ( dummy => '00', JAN => '01', FEB => '02', MAR => '03', APR => '04', MAY => '05', JUN => '06', JUL => '07', AUG => '08', SEP => '09', OCT => '10', NOV => '11', DEC => '12' );

    # These are the data we are extracting
    my $pressure;
    my $storm_class = "";
    my $storm_name;
    my $storm_basin;
    my $storm_number;
    my $adv_num;
    my $storm_year;
    my $nowcast_year;
    my $forecast_year;
    my $nowcast_month;
    my $forecast_month;
    my $nowcast_day;
    my $forecast_day;
    my $nowcast_hour;
    my $forecast_hour;
    my $date_time;
    my $forecast_date_time;
    my $nowcast_date_time;
    my $nowcast_max_wind;
    my $forecast_max_wind;
    my $atcf_line = $template;
    my $lat;
    my $lon;
    my $vmax;
    my $gusts;    # in kt
    my $center_direction = 65;
    my $center_speed     = 17;

    my $body_ref = \@lines;
    my $cnt      = @{$body_ref};
    #
    my @match = ();

    # Get the NHC Number
    # NWS TPC/NATIONAL HURRICANE CENTER MIAMI FL   AL172005
    @match = grep /(?:AL|EP|CP|WP|IO|SH|LS)\d{2}\d{4}$/, @{$body_ref};
    if (@match) {
        if ( $match[0] =~ /(AL|EP|CP|WP|IO|SH|LS)(\d{2})(\d{4})$/ ) {
            $storm_basin  = $1;
            $storm_number = $2;
            $storm_year   = $3;
        }
        die qq{NO NHC NUMBER/YEAR\n} if not $storm_number or not $storm_year or not $storm_basin;
    }
    $atcf_line =~ s/_BASIN_/$storm_basin/;
    my $storm_number_str = sprintf( "%02d", $storm_number );
    substr( $atcf_line, 4, 2 ) = $storm_number_str;

    # Date format
    # 1500Z THU SEP 02 2004
    # July 18th TD 2. HAS CHANGED
    # NOTE NOTE NOW! 1500 UTC TUE JUL 18 2006
    if ( $storm_year > 2005 ) {
        @match = grep /^\d{4} .+ \d{4}$/, @{$body_ref};
    }
    else {
        @match = grep /^\d{4}Z .+ \d{4}$/, @{$body_ref};
    }
    #
    if (@match) {
        $date_time = $match[0];
        chomp $date_time;
        my @vals = split( ' ', $date_time );
        $nowcast_hour = substr( $vals[0], 0, 2 );
        if ( $storm_year > 2005 ) {
            $nowcast_year  = $vals[5];
            $nowcast_month = $month_lookup{ $vals[3] };
            $nowcast_day   = $vals[4];
        }
        else {
            $nowcast_year  = $vals[4];
            $nowcast_month = $month_lookup{ $vals[2] };
            $nowcast_day   = $vals[3];
        }
        $nowcast_date_time = $nowcast_year . $nowcast_month . $nowcast_day . $nowcast_hour;
        substr( $atcf_line, 8, 10 ) = sprintf( "%10d", $nowcast_date_time );
    }

    # advisory number does not appear in the ATCF format
    @match = grep /FORECAST.+ADVISORY NUMBER/, @{$body_ref};

    # HURRICANE FRANCES ADVISORY NUMBER  40
    # HURRICANE FRANCES FORECAST/ADVISORY NUMBER  37
    # HURRICANE FRANCES FORECAST/ADVISORY NUMBER  37...CORRECTED
    # HURRICANE FRANCES SPECIAL FORECAST/ADVISORY NUMBER  37
    if (@match) {
        if ( $match[0] =~ /^(.+)\s+FORECAST.+ADVISORY NUMBER\s+(\d{1,3})/ ) {
            $storm_name = $1;
            $adv_num    = $2;
            $storm_name =~ s/SPECIAL//;
        }
    }
    else {
        @match = grep /ADVISORY NUMBER/, @{$body_ref};
        if ( $match[0] =~ /^(.+)\s+ADVISORY NUMBER\s+(\d{1,3})/ ) {
            $storm_name = $1;
            $adv_num    = $2;
        }
    }
    my @tmp = split( ' ', $storm_name );
    if ( $tmp[0] eq 'HURRICANE' ) {
        $storm_class = $tmp[0];
        $storm_name  = $tmp[1];
    }
    elsif ( $tmp[0] eq 'POTENTIAL' ) {
        $storm_class = "$tmp[0] $tmp[1] $tmp[2]";
        $storm_name  = $tmp[3];
    }
    elsif ( $tmp[0] eq 'TROPICAL' or $tmp[0] eq 'SUBTROPICAL' or $tmp[0] eq 'REMNANTS' or $tmp[0] eq 'POST-TROPICAL' ) {

        # SUBTROPICAL is rare. see 2007 01
        $storm_class = "$tmp[0] $tmp[1]";
        $storm_name  = $tmp[2];
    }
    substr( $atcf_line, 148, 10 ) = sprintf( "%10s", $storm_name );
    my $adv_num_str     = sprintf( "%02d", $adv_num );
    my $adv_num_url_str = sprintf( "%03d", $adv_num );

    # HURRICANE CENTER LOCATED NEAR 23.4N  73.9W AT 02/1500Z
    # or
    #TROPICAL DEPRESSION DISSIPATING NEAR 29.0N  70.0W AT 24/2100Z
    # or
    # TROPICAL DEPRESSION CENTER LOCATED NEAR 11.2N  36.0W AT 25/0300Z
    @match = grep /(CENTER LOCATED|DISSIPATING) NEAR/, @{$body_ref};
    my $ns_hem = "N";
    my $ew_hem = "W";
    if (@match) {
        if ( $match[0] =~ /CENTER LOCATED NEAR\s+(\d{1,3}\.\d{1,2})([N|S])\s+(\d{1,3}\.\d{1,2})([E|W])\s+AT/ ) {
            $lat    = $1;
            $ns_hem = $2;
            $lon    = $3;
            $ew_hem = $4;
        }
        if ( $match[0] =~ /DISSIPATING NEAR\s+(\d{1,3}\.\d{1,2})([N|S])\s+(\d{1,3}\.\d{1,2})([E|W])\s+AT/ ) {
            $lat    = $1;
            $ns_hem = $2;
            $lon    = $3;
            $ew_hem = $4;
        }
    }

    my $nowcast_lat = sprintf( "%4d$ns_hem", $lat * 10 );
    my $nowcast_lon = sprintf( "%4d$ew_hem", $lon * 10 );
    substr( $atcf_line, 34, 5 ) = sprintf( "%5s", $nowcast_lat );
    substr( $atcf_line, 41, 5 ) = sprintf( "%5s", $nowcast_lon );

    #PRESENT MOVEMENT TOWARD THE NORTH-NORTHWEST OR 330 DEGREES AT   9 KT
    @match = grep /^PRESENT MOVEMENT TOWARD THE/, @{$body_ref};
    if (@match) {
        if ( $match[0] =~ /PRESENT MOVEMENT TOWARD THE.+OR\s+(\d{1,3})\s+DEGREES AT\s+(\d{1,2})\s+KT/ ) {
            $center_direction = $1;
            $center_speed     = $2;
        }
        substr( $atcf_line, 138, 4 ) = sprintf( "%4d", $center_direction );
        substr( $atcf_line, 143, 4 ) = sprintf( "%4d", $center_speed );
    }

    @match = grep /^ESTIMATED MINIMUM CENTRAL PRESSURE/, @{$body_ref};
    if (@match) {
        if ( $match[0] =~ /^ESTIMATED MINIMUM CENTRAL PRESSURE\s+(.+)\s+MB/ ) {
            $pressure = $1;
        }
    }
    substr( $atcf_line, 53, 4 ) = sprintf( "%4d", $pressure );

    #MAX SUSTAINED WINDS  25 KT WITH GUSTS TO  35 KT.
    #MAX SUSTAINED WINDS 125 KT WITH GUSTS TO 155 KT.

    @match = grep /^MAX SUSTAINED WINDS/, @{$body_ref};

    if (@match) {
        if ( $match[0] =~ /^MAX SUSTAINED WINDS\s+(\d{1,4}) KT WITH GUSTS TO\s+(\d{1,4})/ ) {
            $vmax  = $1;
            $gusts = $2;
        }
    }

    substr( $atcf_line, 47,  4 ) = sprintf( "%4d", $vmax );
    substr( $atcf_line, 113, 4 ) = sprintf( "%4d", $gusts );
    my $forecast_atcf_filename = lc($storm_name) . "_advisory_" . $adv_num_str . ".fst";
    #
    # collect nowcast wind radii, if any
    my $isotachs_found = 0;
    my @isotachs;
    for my $i ( 0 ... $#{$body_ref} ) {
        if ( @{$body_ref}[$i] =~ /^MAX SUSTAINED WINDS/ ) {

            #64 KT....... 45NE  30SE  20SW  30NW.
            #50 KT.......120NE  75SE  60SW  75NW.
            #34 KT.......175NE 120SE 120SW 120NW.
            $i++;
            while (1) {
                if ( @{$body_ref}[$i] =~ /^(\d{1,2}) KT\.{7}\s{0,}(\d{1,3})[N|S][E|W]\s+(\d{1,3})[N|S][E|W]\s+(\d{1,3})[N|S][E|W]\s+(\d{1,3})[N|S][E|W]/ ) {
                    $isotachs_found++;
                    my @wind_radii = ( $1, $2, $3, $4, $5 );
                    push @isotachs, @wind_radii;
                }
                else {
                    last;
                }
                $i++;
            }
            for ( my $j = $isotachs_found; $j > 0; $j-- ) {
                for ( my $k = 0; $k < 4; $k++ ) {
                    my $starting_pos = 72 + ( $k * 6 );
                    my $list_pos     = 1 + $k + ( 5 * ( $j - 1 ) );

                    # fill in wind radii
                    substr( $atcf_line, $starting_pos, 5 ) = sprintf( "%5d", $isotachs[$list_pos] );

                    # fill in isotach
                    substr( $atcf_line, 63, 3 ) = sprintf( "%3d", $isotachs[ 5 * ( $j - 1 ) ] );
                }
                push @output, $atcf_line;
            }
            unless ($isotachs_found) {
                push @output, $atcf_line;
            }
            last;
        }
    }

    # FORECAST tracks and points
    # FORECAST VALID 10/0000Z 21.5N  84.5W FORECASTs have a bizzare date format:
    # dd/hhmm  BUT near end of the month say 31/0000 the forecast dates switch to
    # 01/0000, 01/12000 so we need to check for this and increment the month.
    my $forecast_period = 0;
    $forecast_year  = $nowcast_year;
    $forecast_month = $nowcast_month;
    $forecast_day   = $nowcast_day;
    $forecast_hour  = $nowcast_hour;
    my $i = 0;
    while ( $i < $#{$body_ref} ) {
        if ( @{$body_ref}[$i] =~ /^(FORECAST|OUTLOOK) VALID/ ) {
            my $atcf_line = $template;
            $atcf_line =~ s/_BASIN_/$storm_basin/;

            # jgf20160105: fill in the storm number
            substr( $atcf_line, 4, 2 ) = $storm_number_str;

            # fill in the nowcast time
            substr( $atcf_line, 8, 10 ) = sprintf( "%10d", $nowcast_date_time );

            # fill in the storm name
            substr( $atcf_line, 148, 10 ) = sprintf( "%10s", $storm_name );
            my $line = @{$body_ref}[$i];
            chomp $line;

            # if the storm will dissipate, there is no more data to process
            if ( $line =~ /DISSIPATED/ ) {
                last;
            }
            if ( $line =~ /^(FORECAST|OUTLOOK) VALID\s+(\d{2})\/(\d{4})Z/ ) {
                $forecast_day  = $2;
                $forecast_hour = substr( $3, 0, 2 );
            }
            if ( $line =~ /Z\s+(\d{1,2}\.\d{1,2})([N|S])\s+(\d{1,2}\.\d{1,2})([E|W])/ ) {
                $lat    = $1;
                $ns_hem = $2;
                $lon    = $3;
                $ew_hem = $4;
            }
            my $forecast_lat = sprintf( "%4d$ns_hem", $lat * 10 );
            my $forecast_lon = sprintf( "%4d$ew_hem", $lon * 10 );
            substr( $atcf_line, 34, 5 ) = sprintf( "%5s", $forecast_lat );
            substr( $atcf_line, 41, 5 ) = sprintf( "%5s", $forecast_lon );

            # Get the next line
            # MAX WIND  30 KT...GUSTS  40 KT.
            $i++;
            $line = @{$body_ref}[$i];
            chomp $line;
            if ( $line =~ /^MAX WIND\s+(\d{1,4}) KT\.\.\.GUSTS\s+(\d{1,4}) KT\./ ) {
                $vmax  = $1;
                $gusts = $2;
            }
            substr( $atcf_line, 47,  4 ) = sprintf( "%4d", $vmax );
            substr( $atcf_line, 113, 4 ) = sprintf( "%4d", $gusts );
            $forecast_date_time = sprintf( "%04d%02d%02d%02d", $forecast_year, $forecast_month, $forecast_day, $forecast_hour );

            # check to see if we have crossed into the next month
            if ( $forecast_date_time < $nowcast_date_time ) {
                $forecast_month++;
                if ( $forecast_month > 12 ) {
                    $forecast_month = 1;
                }
            }

            # Determine the time in hours (forecast period) between the current
            # forecast and the nowcast time
            ( my $ddays, my $dhrs, my $dsec ) = Date::Calc::Delta_DHMS( $nowcast_year, $nowcast_month, $nowcast_day, $nowcast_hour, 0, 0, $forecast_year, $forecast_month, $forecast_day, $forecast_hour, 0, 0 );
            my $forecast_period = $ddays * 24 + $dhrs;
            substr( $atcf_line, 29, 4 ) = sprintf( "%4d", $forecast_period );

            # Get the next line and parse the isotachs
            $i++;
            ( $i, my $output_ref ) = _parseIotachs( $body_ref, $i, $atcf_line );
            push @output, @$output_ref;
        }
        $i++;
    }

    # save in instance's internal field
    $self->{as_atcf} = \@output;

    # return array reference for convenience
    return $self->as_atcf;
}

sub _parseIotachs {
    my ( $body_ref, $i, $atcf_line ) = @_;
    my $isotachs_found = 0;
    my @isotachs       = ();
    my @output         = ();
    while (1) {

        #64 KT... 45NE  30SE  20SW  30NW.
        if ( @{$body_ref}[$i] =~ /^(\d{1,2}) KT\.{3}\s{0,}(\d{1,3})[N|S][E|W]\s+(\d{1,3})[N|S][E|W]\s+(\d{1,3})[N|S][E|W]\s+(\d{1,3})[N|S][E|W]/ ) {
            $isotachs_found++;
            my @wind_radii = ( $1, $2, $3, $4, $5 );
            push @isotachs, @wind_radii;
        }
        else {
            last;
        }
        $i++;
    }
    for ( my $j = $isotachs_found; $j > 0; $j-- ) {
        for ( my $k = 0; $k < 4; $k++ ) {
            my $starting_pos = 72 + ( $k * 6 );
            my $list_pos     = 1 + $k + ( 5 * ( $j - 1 ) );

            # fill in wind radii
            substr( $atcf_line, $starting_pos, 5 ) = sprintf( "%5d", $isotachs[$list_pos] );

            # fill in isotach
            substr( $atcf_line, 63, 3 ) = sprintf( "%3d", $isotachs[ 5 * ( $j - 1 ) ] );
        }
        push @output, $atcf_line;
    }
    unless ($isotachs_found) {
        push @output, $atcf_line;
    }
    return ( $i, \@output );
}

1;

__END__

=head1 NAME

Weather::NHC::TropicalCyclone::ForecastAdvisory - provides handy extraction and
conversion functionality for use with the NHC forecast advisory text

=head1 SYNOPSIS

Below is a full example of fetching a JSON file from NHC and iterating over
each storm using C<Weather::NHC::TropicalCyclone>. The NHC forecast is fetched,
then it is this text that is converted in to the ATCF data format using this
module's C<save_as_atcf> method.

  use strict;
  use warnings;
  use Weather::NHC::TropicalCyclone ();
  use Weather::NHC::TropicalCyclone::Forecast ();
  
  my $nhc = Weather::NHC::TropicalCyclone->new;
  $nhc->fetch;
  my $storms_ref = $nhc->active_storms;
  foreach my $storm (@$storms_ref) {
      my ($text, $advNum, $local_file) = $storm->fetch_publicAdvisory($storm->id.q{.fst});
      my $imgs_ref = $storm->fetch_forecastGraphics_urls;
      if ( not $stormsAdvCache->{ $storm->id }->{$advNum} ) {

          my $new_advisory_file = sprintf( "%s.%s.fst.html", $advNum, $storm->id );
          rename $local_file, $new_advisory_file;

          my $new_advisory_atcf_file = sprintf( "%s.%s.fst", $advNum, $storm->id );
          my $fst_util = Weather::NHC::TropicalCyclone::Forecast->new( input_file => $new_advisory_file, output_file => $new_advisory_atcf_file);
          $fst_util->save_as_atcf;
     }
  }

=head1 DESCRIPTION

Parses text advisories from the National Hurricane Center and converts
them to ATCF forecast format for use within ADCIRC. It currently provides basic
functionality for converting the text advisories to a data file that is
generally useful. It doesn't provide a true object interface for advisories,
but if this is an approach that is useful it would be done in this module.

For more information on this format and others provided by the Automated Tropical
Cyclone Forecast System (ATCF), please visit
L<https://www.nrlmry.navy.mil/atcf_web/docs/database/new/database.html>.

=head1 METHODS

=over 3

=item C<new>

Constructor, accepts two named parameters: C<input_file> or C<input_text>
and C<output_file>. These define the initial file containing the NHC forecast
text and the file to which the ATCF format should be written.

Note: C<input_file> and C<input_file> are mutually exclusive. An exception will
be thrown from the C<new> constructor if both are provided.

=item C<as_atcf>

Internal field accessor, only useful after C<extract_atcf> has been called on the
instance.

=item C<extract_and_save_atcf>

Combines C<extract_atcf> and C<save_atcf> into a single, convenient method since this
will usually be what is wanted.

=item C<extract_atcf>

As long as C<input_file> has been defined and it is in the expected NCH forecast advisory
format, relevant data values will be extracted and return with each record contained
in an array refernce. Each element in this array reference corresponds to a distict
ATCF record.

=item C<input_file>

Accessor for the input file containing the NHC forecast advisory text if used
in the constructor..

=item C<input_text>

Accessor for the input text of the NHC forecast advisory if used in the constructor.

=item C<output_file>

Accessor for the output file that is written with the contents of C<as_atcf> when
C<save_atcf> or C<extract_and_save_atcf> is called.

=item C<save_atcf>

Saves contents returned by C<as_atcf> to the file specific by C<output>.

=item C<_parseIotachs>

Internal method that assists C<extract_atcf> in its parsing.

=back

=head1 AUTHOR

The core parsing code in this module was created by Jason Fleming for use
in the ADCIRC Surge Guidance System (ASGS). It is contained in the file,
C<nhc_advisory_bot.pl>, which is available in their github repository. This
module is presented simply as a wrapper around this functionality.

L<https://github.com/jasonfleming/asgs/blob/master/nhc_advisory_bot.pl>

=head1 LICENSE & COPYRIGHT

Copyright(C) 2009-2015: Jason Fleming

This file is part of the ADCIRC Surge Guidance System (ASGS).

The ASGS is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ASGS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the ASGS.  If not, see <http://www.gnu.org/licenses/>.
