# Weather::GHCN::StationTable.pm - class for collecting station objects and weather data

## no critic (Documentation::RequirePodAtEnd)

=head1 NAME

Weather::GHCN::StationTable - collect station objects and weather data

=head1 VERSION

version v0.0.003

=head1 SYNOPSIS

  use Weather::GHCN::StationTable;

  my $ghcn = Weather::GHCN::StationTable->new;

  my ($opt, @errors) = $ghcn->set_options(
    user_options => {
        country     => 'US',
        state       => 'NY',
        location    => 'New York',
        report      => 'yearly',
    },
  );
  die @errors if @errors;

  $ghcn->load_stations;

  # generate a list of the stations that were selected
  say $ghcn->get_stations( kept => 1 );

  if ($opt->report) {
      say $ghcn->get_header;

      $ghcn->load_data();
      $ghcn->summarize_data;

      say $ghcn->get_summary_data;
      say $ghcn->get_footer;
  }


=head1 DESCRIPTION

The B<Weather::GHCN::StationTable> module provides a class that is used to
fetch stations information from the NOAA Global Historical Climatology
Network database, along with temperature and/or precipitation records
from the daily historical records.

For a more comprehensive example than the above Synopsis, see the
section EXAMPLE PROGRAM.

Caveat emptor: incompatible interface changes may occur on releases
prior to v1.00.000.  (See VERSIONING and COMPATIBILITY.)

The module is primarily for use by modules Weather::GHCN::Fetch.

=cut

use v5.18;  # minimum for Object::Pad
use Object::Pad 0.66 qw( :experimental(init_expr) );

package Weather::GHCN::StationTable;
class   Weather::GHCN::StationTable;

our $VERSION = 'v0.0.003';

## no critic [References::ProhibitDoubleSigils]

# directly used by this module
use Carp                qw( carp croak );
use Const::Fast;
use Weather::GHCN::Common        qw( :all );
use Weather::GHCN::TimingStats;
use HTML::Entities;
#use Hash::Wrap          {-lvalue => 1, -defined => 1, -as => '_wrap_hash' };

# included so consumers of this module don't have to include these
use Cache::FileCache;
use Devel::Size;
use File::HomeDir;
use File::Spec;
use FindBin;
use Weather::GHCN::CountryCodes;
use Weather::GHCN::Measures;
use Weather::GHCN::Options;
use Weather::GHCN::Station;
use GIS::Distance;
use Try::Tiny;
use URI::Fetch;

const my $EMPTY  => q();    # empty string
const my $SPACE  => q( );   # space character
const my $DASH   => q(-);   # dash character
const my $TAB    => qq(\t); # tab character
const my $NL     => qq(\n); # perl platform-universal newline
const my $TRUE   => 1;      # perl's usual TRUE
const my $FALSE  => not $TRUE; # a dual-var consisting of '' and 0

const my $CONFIG_FILE => '$HOME/.ghcn_fetch.yaml';

const my %MMM_TO_MM => (
    Jan=>1, Feb=>2, Mar=>3, Apr=>4, May=>5, Jun=>6,
    Jul=>7, Aug=>8, Sep=>9, Oct=>10, Nov=>11, Dec=>12,
);

const my $GHCN_DATA          => 'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/';
const my $GHCN_STN_LIST_URL  => 'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt';
const my $GHCN_STN_INVEN_URL => 'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-inventory.txt';

const my $STN_ID_RE     => qr{ [[:upper:]]{2} [[:alnum:]\_\-]{9} }xms;
const my $STN_LIST_RE   => qr{ \A $STN_ID_RE ( [,] $STN_ID_RE )+ \Z }xms;

# station errors (rejected)
const my $ERR_FETCH         => 1;
const my $ERR_METRICS       => 2;
const my $ERR_NOT_ACTIVE    => 3;
const my $ERR_RANGE_FULL    => 4;
const my $ERR_NOT_PARTIAL   => 5;
const my $ERR_NOACTIVE      => 6;
const my $ERR_INSUFF        => 7;
const my $ERR_NOT_GSN       => 8;
const my $ERR_NO_GIS        => 9;

# station warnings (not rejected)
const my $WARN_MISS_YA      => 51;
const my $WARN_MISS_YF      => 52;
const my $WARN_MISS_MO      => 53;
const my $WARN_MISS_DY      => 54;
const my $WARN_ANOM         => 55;

my %NoteMsg = (  ## no critic [ProhibitMagicNumbers]
    1 => q|*E* unable to fetch data from URL|,
    2 => q|*E* station doesn't have any of the required measurements|,
    3 => q|*E* station active range isn't a subset of the -active range|,
    4 => q|*E* station active range doesn't fully intersect -range|,
    5 => q|*E* station active range doesn't partially intersect -active|,
    6 => q|*E* option -range or -active specified but station has no active range in the inventory|,
    7 => q|*E* insufficient data to meet quality threshold|,
    8 => q|*E* not a GSN station|,
    9 => q|*E* -gps specified but station is without GIS coordinates|,

    51 => q|*W* station missing data in years of the active range|,
    52 => q|*W* station missing data in years of the filter range|,
    53 => q|*W* station missing one or more entire months of data in a year|,
    54 => q|*W* station missing one or more days of data in a year|,
    55 => q|*W* station has insufficient baseline years - anomalies not calculated|,
);

# Global lexical option object, created by new()
my $Opt;

# private fields that are intialized by set_options()
field $_ghcn_opt_obj;                # [0] Weather::GHCN::Options object providing filtering and other options
field $_stnid_filter     { {} };     # [1] hashref of station id's to be loaded, or empty hash
field $_return_list      { $FALSE }; # [2] return method results as tsv if true, a list if false

# private fields that are intialized by load()
field $_cache;                       # [3] Cache::FileCache object
field $_measures_obj;                # [4] Measures object

# private fields that are intialized by get_header()
field $_measure_begin_idx {0};       # [5] column index where measures will go in the output

# private fields that are intialized by new() i.e. automatically or within sub BUILD
field %_hstats;                      # [6] Hash for capturing data field hash statistics
field $_tstats;                      # [7] TimingStats object (or undef)

# data fields
field %_station;                     # [8]  loaded station objects, key station_id
field $_aggregate_href   { {} } ;    # [9]  hashref of aggregated (summarized0 daily data
field $_flag_cnts_href   { {} } ;    # [10] hashref of flag counts
field $_daily_href       { {} } ;    # [11] hashref of most recent daily data loaded
field $_baseline_href    { {} } ;    # [12] hashref of baseline data

# readable fields that are populated set_options
field $opt_obj              :reader; # [13] $ghcn_opt_obj->opt_obj (a Hash::Wrap of $ghcn_opt_obj->opt_href)
field $opt_href             :reader; # [14] $ghcn_opt_obj->opt_href
field $config_file          :reader; # [15]
field $config_href          :reader; # [16] hash reference containing cache and alias options

# other fields with read methods
field $stn_count            :reader;         # [17]
field $stn_selected_count   :reader;         # [18]
field $stn_filtered_count   :reader;         # [19]
field $missing_href         :reader  { {} }; # [20]

=head1 FIELD ACCESSORS

=over 4

=item opt_obj

Returns a reference to the Options object created by set_options.

=item opt_href

Returns a reference to a hash of the Options created by set_options.

=item config_file

Returns the name of the configuration file, if one was passed to
set_options.

=item config_href

Returns a reference to a hash containing the configuration options
set by set_options (if any).

=item stn_count

Returns a count of the total number of stations found in the station
list.

=item stn_selected_count

Returns a count of the number of stations that were selected for
processng.

=item stn_filtered_count

Returns a count of the number of stations that were selected for
processing, excluding those rejected due to errors or other criteria.

=item missing_href

Returns a hash of the missing months and days for the selected
data.

=back

=cut

=head1 METHODS

=head2 new ()

Create a new StationTable object.

=cut

BUILD {
    %_hstats = ();
    $_tstats = Weather::GHCN::TimingStats->new();
}

=head2 export_kml( list => 0 )

Output the coordinates of the station collection as a KML file, for
import into Google Earth as placemarks.  The active range of each
station will be included as timespans so that you can view the
placemarks across time.

=over 4

=item argument: list

If the argument list contains the 'list' keyword and a true value,
then export_kml will return a string with the kml output as lines of
text rather than writing it to the file specified by the kml option.

=item option: kml <filespec>

Write the kml output to the file designated by <filespec>.  If <filespec>
is an empty string, no file is written.

=item option: color <str>

A color name, one of blue, green, azure, purple, red, white or yellow.
Only the first character is recognized, so 'b' and 'bob' both result
in blue.  All colors are given an opacity of 50 (the range is 00 to ff).

=back

=cut

method export_kml ( %arg ) {
    my $return_list = $arg{list} // $_return_list;
    my $filespec = $Opt->kml;

    my $kml_color = _get_kml_color( $Opt->color );
    my @output;

    push @output, '<?xml version="1.0" encoding="UTF-8"?>';
    push @output, '<kml xmlns="http://www.opengps.net/kml/2.2">';
    push @output, '<Document>';
    push @output, '  <Style id="mypin">';
    push @output, '  <IconStyle>';
    push @output, '  <color>' . $kml_color . '</color>';
    push @output, '  <Icon>';
    # push @output, '    <href>http://maps.google.com/mapfiles/kml/pushpin/' . $color . '-pushpin.png</href>';
    push @output, '    <href>http://maps.google.com/mapfiles/kml/shapes/donut.png</href>';
    push @output, '  </Icon>';
    push @output, '  </IconStyle>';
    push @output, '  </Style>';

    foreach my $stn ( values %_station ) {
        next if $stn->error_count;
        # TODO:  use ->sets to get a list of spans and use the first span instead of splitting run_list
        my ($start, $end) = split m{ [-] }xms, $stn->active;

        my $desc = $stn->description();

        push @output,         '  <Placemark>';
        push @output,         '    <styleUrl>#mypin</styleUrl>';
        push @output, sprintf '    <name>%s</name>', encode_entities($stn->name);
        push @output, sprintf '    <description>%s</description>', encode_entities($desc);
        push @output,         '    <TimeSpan>';
        push @output, sprintf '      <begin>%s-01-01T00:00:00Z</begin>', $start;
        push @output, sprintf '        <end>%s-12-31T23:59:59Z</end>', $end;
        push @output,         '    </TimeSpan>';
        push @output, sprintf '    <Point><coordinates>%f, %f, %f</coordinates></Point>', $stn->long, $stn->lat, $stn->elev;
        push @output,         '  </Placemark>';
    }

    push @output, '</Document>';
    push @output, '</kml>';

    if ($filespec) {
        # uncoverable branch true
        # uncoverable branch false
        open my $fh, '>', $filespec
            or croak "*E* unable to open $filespec for write\n";
        say {$fh} join $NL, @output;
        # uncoverable branch true
        # uncoverable branch false
        close $fh or croak "*E* unable to close kml output\n";;
    }

    return $return_list ? @output : tsv(\@output);
}

=head2 flag_counts ()

The load_stations() and load_data() methods may reject a station or a
particular data entry due to quality or other issues.  These
decisions are kept in a hash field, and a reference to that hash is
returned by this method.  The caller can then report the values.

=cut

method flag_counts () {
    return $_flag_cnts_href;
}

=head2 get_flag_statistics ( list => 0, no_header => 0 )

Gets a header row and summary table of data points that were kept and rejected, along
with counts of QFLAGS (quality flags).  Returns tab-separated
text, or a list if the list argument is true.  A heading line
is provided unless no_header is true.

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=item argument: no_header => <bool>

If the arguments include the 'no_header' keyword and a true value,
then the return value will not include a header line.  Default is
false.

=back

=cut

method get_flag_statistics ( %args ) {
    my $return_list = $args{list} // $_return_list;

    my @output;

    # print summary of data points kept and rejected, with qflag counts
    push @output, ['Values', 'Kept', 'Rejected', 'Flags']
        unless $args{no_header};
    foreach my $elem ( sort keys $_flag_cnts_href->%* ) {
        next if $elem =~ m{ [[:lower:]] }xms;
        next if $elem =~ m{ \A A_ }xms;
        my $flag_info = _qflags_as_string( $_flag_cnts_href->{$elem}->{QFLAGS} );

        push @output, [
            $elem,
            ( $_flag_cnts_href->{$elem}->{KEPT}     // 0 ),
            ( $_flag_cnts_href->{$elem}->{REJECTED} // 0 ),
            $flag_info,
        ];
    }

    return $return_list ? @output : tsv(\@output);
}

=head2 get_footer( list => 0 )

Get a footing section with explanatory notes about the output data
produced by detail and summary reports.

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=back

=cut

method get_footer ( %args ) {
    my $return_list = $args{list} // $_return_list;

    my @output;

    push @output, 'Notes:';
    push @output, '  1. Data is obtained from the GHCN GHCN repository, specifically:';
    push @output, $TAB . $GHCN_STN_LIST_URL;
    push @output, $TAB . $GHCN_STN_INVEN_URL;
    push @output, $TAB . $GHCN_DATA;
    push @output, '  2. Temperatures are in Celsius, precipitation in mm and snowfall/depth in cm.';
    push @output, '  3. TAVG is a daily average computed at each station; Tavg is the average of TMAX and TMIN.';
    push @output, '  4. Data is averaged at the daily level across multiple stations.';
    push @output, '  5. Data is summarized at the monthly or yearly level using different rules depending on the measure:';
    push @output, $TAB . '- TMAX is aggregated by max(); TMIN is aggregated by min().';
    push @output, $TAB . '- TAVG and Tavg are aggregated by average().';
    push @output, $TAB . '- PRCP and SNOW are aggregated by sum().';
    push @output, $TAB . '- SNWD is aggregated by max().';
    push @output, '  6. Decades begin on Jan 1 in calendar years ending in zero.';
    push @output, '  7. Seasonal decades/year/quarters begin Dec 1 of the previous calendar year.';

    return $return_list ? @output : tsv(\@output);
}

=head2 get_hash_stats ( list => 0, no_header => 0 )

Gets the hash sizes collected during the execution of StationTable
methods, notably load_stations and load_data, as tab-separated
lines of text.

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=item argument: no_header => <bool>

If the arguments include the 'no_header' keyword and a true value,
then the return value will not include a header line.  Default is
false.

=back

=cut

method get_hash_stats ( %args ) {
    my $return_list = $args{list} // $_return_list;

    my @output;

    my @keys = sort keys %_hstats;

    if ( @keys and not $args{no_header} ) {
        push @output, [ 'Hash sizes:' ];
        push @output, [ qw(Hash Subject Iteration Size) ];
    }

    foreach my $hash ( sort @keys ) {
        foreach my $subject ( sort keys $_hstats{$hash}->%* ) {
            foreach my $iter ( sort keys $_hstats{$hash}->{$subject}->%* ) {
                my $sz = commify( $_hstats{$hash}->{$subject}->{$iter} );
                push @output, [ $hash, $subject, $iter, $sz ];
            }
        }
    }

    return $return_list ? @output : tsv(\@output);
}

=head2 get_header ( list => 0 )

The weather data obtained by the laod_data() method is essentially a
table.  Which columns are returned depends on various options.  For
example, if report => monthly is given, then the key columns will be
year and month -- no day.  If the precip option is given, then
extra columns are included for precipitation values.

This variabiliy makes it difficult for a consumer of these modules
to emit a heading that matches the underlying columns.  The purpose of
this method is to return a set of column headings that will match
the data.  The value returned is a tab-separated string.

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=back

=cut

method get_header ( %args ) {
    my $return_list = $args{list} // $_return_list;

    # if this is a summary report, then alter the measure column labels
    if ( not $Opt->report eq 'id' ) {
        foreach my $label ($_measures_obj->measures) {
            $label =~ s{ \A TMAX }{TMAX max}xms;
            $label =~ s{ \A TMIN }{TMIN min}xms;

            $label =~ s{ \A TAVG }{TAVG avg}xms;
            $label =~ s{ \A Tavg }{Tavg avg}xms;

            $label =~ s{ \A PRCP }{PRCP sum}xms;
            $label =~ s{ \A SNOW }{SNOW sum}xms;

            $label =~ s{ \A SNWD }{SNWD max}xms;

            $label =~ s{ \A A_ (\w+) }{$1 anom}xms;
        }
    }

    my $includes_month =
        $Opt->report eq 'id'    ||
        $Opt->report eq 'daily' ||
        $Opt->report eq 'monthly';


    # generate and print the header row
    my @output;
    push @output, 'Year';
    push @output, 'Month'      if $includes_month;
    push @output, 'Day'        if $Opt->report eq 'id' or $Opt->report eq 'daily';
    push @output, 'Decade';
    push @output, 'S_Decade'   if $includes_month;
    push @output, 'S_Year'     if $includes_month;
    push @output, 'S_Qtr'      if $includes_month;

    $_measure_begin_idx = @output;
    push @output, $_measures_obj->measures;

    push @output, 'QFLAGS'     if $Opt->report eq 'id';
    push @output, 'StationId'  if $Opt->report eq 'id';
    push @output, 'Location'   if $Opt->report eq 'id';
    push @output, 'StnIdx'     if $Opt->report eq 'id';
    push @output, 'Grid'       if $Opt->report eq 'id';

    return $return_list ? @output : join $TAB, @output;
}

=head2 get_missing_data_ranges( list => 0, no_header => 0 )

Gets a list, by station id and year, of any months or day ranges
when data was found to be missing.  Missing data can lead to incorrect
interpretation and can cause a station to be rejected if the percent
of found data does not meet the -quality threshold (normally 90%).

Returns a heading line followed by lines of tab-separated strings.

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list of lists (stations containing years) is returned rather than
tab-separated lines of text.  Defaults to false.

=item argument: no_header => <bool>

If the arguments include the 'no_header' keyword and a true value,
then the return value will not include a header line.  Default is
false.

=item option: report <daily|monthly|yearly|id>

Determines the number and content of heading values.

=back

=cut

method get_missing_data_ranges ( %args ) {
    my $return_list = $args{list} // $_return_list;

    my @output;

    push @output, ['Missing year, months and days by station id and year (for selected stations):']
        unless $args{no_header};

    foreach my $stnid ( sort keys $missing_href->%* ) {
        my $stnobj = $_station{$stnid};
        next if $stnobj->error_count > 0;
        my $yyyy_href = $missing_href->{$stnid};

        foreach my $yyyy ( sort keys $yyyy_href->%* ) {
            my $values_href = $yyyy_href->{$yyyy};
            foreach my $v ( keys $values_href->%* ) {
                push @output, [ $stnid, $yyyy, $v ];
            }
        }
    }

    return $return_list ? @output : tsv(\@output);
}

=head2 datarow_as_hash ( $row_aref )

This is a convenience method that may be used to convert table rows
returned by the row_sub callback subroutine of load_data from a perl
list into a hash.  It automatically calls get_header to get the
headers for the table data.  When you pass it a reference to a data
row (obtained vis the row_sub callback routine given to load_data)
it combines the elements of the data row list with the column headings
and returns a hash.

=cut

method datarow_as_hash ( $row_aref ) {
    my @header = $self->get_header( list => 1 );
    my %h;

    @h{@header} = $row_aref->@*;

    return %h;
}

=head2 get_missing_rows( list => 0 )

In support of a -nogaps option, to generate detail output that does
not have any gaps due to missing data, this method gets a list of
rows for the months and days that had missing data for a given
station id in a given year.

Returns lines of tab-separated strings.

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=item option: nogaps

Emits extra rows after the detail data rows to make up for missing
months or days.  This is primarily so that if the data is charted
by date, then the x-axis will have all the dates from start to finish.
Otherwise, the chart and any trends that are projected on it will
be distorted by the missing data.

=back

=cut

method get_missing_rows ( %args ) {
    my $return_list = $args{list} // $_return_list;

    my @output;

    my %loc;
    map { $loc{$_} = $_station{$_}->name } keys %_station;

    foreach my $stnid ( sort keys $missing_href->%* ) {
        my $yyyy_href = $missing_href->{$stnid};
        foreach my $yyyy ( sort keys $yyyy_href->%* ) {
            my $values_href = $yyyy_href->{$yyyy};
            foreach my $v ( keys $values_href->%* ) {
                my ($months_aref, $mmdd_aref) = _parse_missing_text($v);
                foreach my $mm ( $months_aref->@* ) {
                    my $ndays = _days_in_month($yyyy, $mm);
                    foreach my $day (1..$ndays) {
                        push @output, [ $yyyy, $mm, $day, ($EMPTY) x 8, $stnid, $loc{$stnid} ];
                    }
                }
                foreach my $mmdd_aref ( $mmdd_aref->@* ) {
                    my ($mm,$dd) = $mmdd_aref->@*;
                    push @output, [ $yyyy, $mm, $dd, ($EMPTY) x 8, $stnid, $loc{$stnid} ];
                }
            }
        }
    }

    return $return_list ? @output : tsv(\@output);
}

=head2 get_options ( list => 0, no_header => 0 )

Get text which shows the options that were in effect for this
processing run, in a Getopt style.  Includes a heading and a
footing with explanatory notes.  If argument 'list' is true, returns
the lines as a list.  Line [1] contains the options string.

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=item argument: no_header => <bool>

If the arguments include the 'no_header' keyword and a true value,
then the return value will not include a header line or the explanatory
footing notes.  Default is false.

=back

=cut

method get_options ( %args ) {
    my $return_list = $args{list} // $_return_list;

    my @output;

    push @output, 'Options:'
        unless $args{no_header};

    push @output, $TAB . $_ghcn_opt_obj->options_as_string;

    if ( not $args{no_header} ) {
        push @output, $EMPTY;
        push @output, $TAB . 'Note that quality is a percentage; radius in km';
        push @output, $TAB . 'Note that nonetwork values mean the following:';
        push @output, $TAB . ' -1 refresh the cache if last page not refreshed this year';
        push @output, $TAB . '  0 always check for a fresher copy of the page';
        push @output, $TAB . '  1 do not contact the server, just use what is cached';
    }

    return $return_list ? @output : tsv(\@output);
}

=head2 get_stations ( list => 0, kept => 1, no_header => 0 )

Return lines of text with tab-separated columns describing each of
the stations for stations that were found to meet the filtering
criteria specified in the user options.

=over 4

=item argument: kept => <bool>

If the argument kept => 0 is specified, and load_data has already
been invoked, then the stations which were rejected due to quality flags
or missing data will be returned.  If kept => 1 is specified, then
the stations that were kept will be returned.

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=item argument: no_header => <bool>

If the arguments include the 'no_header' keyword and a true value,
then the return value will not include a header line.  Default is
false.

=back

=cut

method get_stations ( %args ) {
    my $return_list = $args{list} // $_return_list;
    my $kept = $args{kept};
    my $no_header = $args{no_header};

    my @output;

    # no stations, so just return empty
    return $return_list ? @output : tsv(\@output)
        if $self->stn_filtered_count == 0;

    push @output, scalar Weather::GHCN::Station::Headings
        unless $no_header;

    my $ii = 0;
    foreach my $id ( sort keys %_station ) {
        my $stn = $_station{$id};
        $ii++;
        if (not defined $kept
            or $kept and $stn->error_count == 0
            or not $kept and $stn->error_count > 0)
        {
            push @output, scalar $stn->row;
        }
    }

    croak '*E* get_stations called before load_stations'
        if $ii == 0;

    return $return_list ? @output : tsv(\@output);
}

=head2 get_station_note_list ()

Return a list consisting of tab-separated code/description pairs that
rejected stations were flagged with; i.e. the reasons for their
rejection.

=cut

# TODO: consider removing this as it is no longer used anywere
method get_station_note_list () {
    my @stn_notes;

    my $notes_nrs = rng_new();

    foreach my $id ( sort keys %_station ) {
        my $stn = $_station{$id};
        # combine all the notes
        $notes_nrs->add( $stn->note_nrs->as_array );
    }

    if ( not $notes_nrs->is_empty ) {
        foreach my $note_code ($notes_nrs->as_array) {
            push @stn_notes, join $TAB, $note_code, $NoteMsg{$note_code};
        }
    }

    return @stn_notes;
}

=head2 get_summary_data ( list => 0 )

Gets a list of summarized the temperature or precipitation data
by day, month or year depending on the report option.

Returns undef if the report option is 'id'.

The actual columns that are returned is dictated by the report option
and by the tavg and precip options provided when the object was
instantiated by new().

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=item option: report <daily|monthly|yearly>

Determines the level of summarization.

=item option: range <rangelist>

If the range option is provided, the output rows are restricted to
those years that are within the specified range(s).

=back

=cut

method get_summary_data ( %args ) {
    my $return_list = $args{list} // $_return_list;

    # when an 'id' report is requested, we generate detail data only
    # so there is no summary data to print
    return if $Opt->report eq 'id';

    my @output;

    # build hash of measure names and indices so measures can be
    # inserted into the correct columns
    my %measure_idx;
    my $ii = 0;
    foreach my $m ( $_measures_obj->measures ) {
        $measure_idx{$m} = $_measure_begin_idx + $ii++;
    }

    my $opt_range_nrs = rng_new($Opt->range);

    # generate and print the data rows
    foreach my $key ( sort keys $_aggregate_href->%* ) {
        my ($year, $month, $day) = unpack 'A4 A2 A2', $key;

        next if $Opt->range and not $opt_range_nrs->contains($year);

        my $row = $_aggregate_href->{$key};

        my @row;
        push @row, $year;
        push @row, $month   if $Opt->report eq 'daily' or $Opt->report eq 'monthly';
        push @row, $day     if $Opt->report eq 'daily';
        push @row, int($year / 10) * 10;        ## no critic [ProhibitMagicNumbers]
        if ( not $Opt->report eq 'yearly' ) {
            push @row, _seasonal_decade($year, $month);
            push @row, _seasonal_year($year, $month);
            push @row, _seasonal_qtr($year, $month);
        }

        foreach my $elem ( $_measures_obj->measures ) {
            my $sum = $row->{$elem}->[0];
            my $cnt = $row->{$elem}->[1];
            $row[ $measure_idx{$elem} ] = $cnt ? sprintf '%.2f', ($sum // 0) / $cnt : $EMPTY;
        }

        push @output, \@row;
    }

    return $return_list ? @output : tsv(\@output);
}


=head2 get_timing_stats ( list => 0 )

Get a list of the timers, with durations and notes, in alphabetical
order by timer label.

=over 4

=item argument: list => <bool>

If the arguments include the 'list' keyword and a true value, then a
list is returned rather than tab-separated lines of text.  Defaults
to false.

=back

=cut

method get_timing_stats ( %args ) {
    my $return_list = $args{list} // $_return_list;

    my @output;

    foreach my $k ( $_tstats->get_timers() ) {
        my $note = $_tstats->get_note($k) // $EMPTY;
        ## no critic [ProhibitMagicNumbers]
        my $dur = sprintf '%.1f', $_tstats->get_duration($k)  * 1000.0;
        my $label = $k . $SPACE . $note;
        push @output, $args{rows_as_tsv}
                ? [ $dur, $label ]
                : join $TAB, $dur, $label;
    }

    return $return_list ? @output : tsv(\@output);
}

=head2 has_missing_data ()

Returns true if any missing data was detected amongst the stations
that were processed.  The calling script can use this to decide
whether to issue a warning to the user.  A list of missing data
specifics can be sent to the output by calling method
get_missing_data_ranges.

=cut

method has_missing_data () {
    my $keycount = ( keys $missing_href->%* );
    return $keycount ? $TRUE : $FALSE;
}

=head2 load_data ( progress_sub => undef, row_sub => sub { say @_ } )

Load the daily weather data for each of the stations that are were
loaded into the collection.  Print the data if option report id is
given.  Otherwise cache the data so it can be aggregated at a later
step.

=over 4

=item argument: progress_sub => undef

As fetching and parsing each daily data page can take some time, an
optional callback hook is provided so the caller can emit a
progress message before each station's data is loaded; e.g.
progress => sub{ say {STDERR} @_ }.

=item argument: row_sub => sub { say @_ }

Optional callback hook to allow the caller to provide their own
subroutine for printing (or collecting in a list, or both) the
row-level station data that is fetched when the report option is 'id'.
Defaults to printing via the 'say' operator.

=item option: report <id|daily|monthly|yearly>

When report id is specified, the weather data for each station is
printed immediately (via the row_sub callback hook).

For all other report options, the data is fetched from each station
and kept in a cache so that it can be aggregated by invoking
summarize_data(). The row_sub hook is not invoked.

=back

=cut

method load_data ( %args ) {
    my $progress_callback = $args{progress_sub};
    my $row_callback = $args{row_sub};

    my @station_objs =
        sort { $a->id cmp $b->id }
            grep { $_->error_count == 0 } values %_station;

    my $stn_count = @station_objs;

    my $ii = 0;
    foreach my $stn ( @station_objs ) {
        my $daily_url = $GHCN_DATA . $stn->id . '.dly';
        my $content = $self->_fetch_url($daily_url, $_cache, 'URI::Fetch_daily');

        if ($progress_callback) {
            no strict 'refs';  ## no critic [ProhibitNoStrict]
            my $msg = sprintf 'processing station %d/%d %s %s', ++$ii, $stn_count, $stn->id, $stn->name;;
            $progress_callback->($msg);
        }

        if (not $content) {
            $stn->add_note($ERR_FETCH, $stn->id . $TAB . 'fetch daily URL failed');
            next;
        }

        my $insufficient_quality = $self->_load_daily_data($stn, $content);

        if ( $Opt->report eq 'id' ) {
            $self->_print_detail_data( $_measure_begin_idx, $stn, $row_callback );
        } else {
            $self->_aggregate_station_data($stn)
                unless $insufficient_quality;
        }

        $self->_clear_daily_data();

        $self->_capture_data_hash_stats($stn->id, $ii);
    }

    return;
}

=head2 load_stations ()

Read the GHCN stations list and the stations inventory list and create
a hash of Station objects, keyed on station id, filtered according
to the options provided in set_options().

Returns a hash of Weather::GHCN::Station objects, keyed on station id.

=over 4

=item option: country <str>

Selects only those stations that match the 2-digit GEC (formerly
FIPS) country code or that uniquely match the name or partial name
given in <str>.

=item option: state <code>

Selects only those stations that match a US state or Canadian provinc
code.

=item option: location <str>

Selects only those stations with a name that matches the specified
pattern, which can be either a station id, or a comma-separated
list of station id's, or a regex.  If a regex, then it is anchored
on the left and whitespace is NOT ignored.

=item option: gps <latitude,longitude>

This option selects stations within a certain radius of the designated
latitude and longitude, expressed as positive and negative numbers
(not using N, S, W, E designators).

=item option: radius <int>

In conjunction the gps options, determines the radius in kilometers
for the search area.  Defaults to 25 km.

=item option: gsn

Select only GCOS Surface Network stations, which  is a baseline
network comprising a subset of about 1000 stations chosen mainly to
give a fairly uniform spatial coverage from places where there is a
good length and quality of data record.  See
L<https://www.ncdc.noaa.gov/gosic/global-climate-observing-system-gcos/g
cos-surface-network-gsn-program-overview>

=back

=cut

method load_stations () {

    # get the caching configuration and use it to create a cache for URI::Fetch
    # if no cache config, then $_cache will be undef and fetches will be uncached
    if ($config_href and $config_href->{'cache'} ) {
        my $cache_opt = $config_href->{'cache'};
        my $namespace = $cache_opt->{'namespace'} // 'ghcn';
        my $root = $cache_opt->{'root'};
        my $root_abs = File::Spec->rel2abs( $root, $FindBin::Bin );

        $_cache = Cache::FileCache->new(
            {
              cache_root => $root_abs,
              namespace  => $namespace,
            }
        );
    }

    my $stations_content = $self->_fetch_url( $GHCN_STN_LIST_URL, $_cache, 'URI::Fetch_stn');

    if ( $stations_content =~ m{<title>(.*?)</title>}xms ) {
        croak '*E* unable to fetch data from ' . $GHCN_STN_LIST_URL . ': ' . $1;
    }

    ## no critic [InputOutput::RequireBriefOpen]
    open my $stn_fh, '<', \$stations_content
        or croak '*E* unable to open stations_content string';

    $_tstats->start('Parse_stn');

    my %stnidx;
    my $gps = GIS::Distance->new;

    # Scan the station table
    # - filtering on country, state, location and GIS distance according to options
    while ( my $line = <$stn_fh> ) {
        $stn_count++;

        # |---  0---|--- 10---|--- 20---|--- 30---|--- 40---|--- 50---|--- 60---
        # |123456789|123456789|123456789|123456789|123456789|123456789|123456789
        # (stationid).(latitu).(longitu).(elev).st.--name-----------------------
        # ACW00011604  17.1167  -61.7833   10.1    ST JOHNS COOLIDGE FLD

        ## no critic [ProhibitMagicNumbers]
        my $id = substr $line, 0, 11;

        next if $_stnid_filter->%* and not $_stnid_filter->{$id};

        my $lat   = 0 + substr $line, 12, 8;    # coerce to number
        my $long  = 0 + substr $line, 21, 9;    # coerce to number
        my $elev  = 0 + substr $line, 31, 6;    # coerce to number
        my $state =     substr $line, 38, 2;
        my $name  =     substr $line, 41, 30;
        my $gsn_flag  = substr $line, 72, 3;
        # my $hcr_crn_flag  = substr $line, 76, 3;
        # my $wmo_id        = substr $line, 80, 5;

        my $country = substr $id, 0, 2;
        $name =~ s{ \s+ \Z }{}xms;

        ## use critic [ProhibitMagicNumbers]

        ## no critic [RequireExtendedFormatting]
        my $opt_country = $Opt->country;
        next if $Opt->country and $country !~ m{\A$opt_country}msi;

        my $opt_state = $Opt->state;
        next if $Opt->state and $state !~ m{\A$opt_state}msi;

        ## use critic [RequireExtendedFormatting]
        next if $Opt->location and not _match_location($id, $name, $Opt->location);

        if ( $Opt->gps ) {
            my ($opt_lat, $opt_long) = split m{[,;\s]}xms, $Opt->gps;
            my $distance = $gps->distance($opt_lat, $opt_long, $lat, $long);
            next if $distance->kilometers > $Opt->radius;
        }

        my $gsn = $gsn_flag eq 'GSN' ? 'GSN' : $EMPTY;

        next if $Opt->gsn and not $gsn;

        $_station{$id} = Weather::GHCN::Station->new(
            id      => $id,
            country => $country,
            state   => $state,
            active  => $EMPTY,
            lat     => $lat,
            long    => $long,
            elev    => $elev,
            name    => $name,
            gsn     => $gsn
        );

        $stnidx{$_station{$id}->coordinates}++;
    }
    close $stn_fh or croak '*E* unable to close stations_content string';

    $_tstats->stop('Parse_stn');

    $stn_selected_count = keys %_station;

    # assign a unique index to each station with matching coordinates
    my $ii = 0;
    foreach my $coord (sort keys %stnidx) {
        $stnidx{$coord} = ++$ii;
    }

    foreach my $stnid ( sort keys %_station ) {
        my $stn = $_station{$stnid};
        $stn->idx = $stnidx{$stn->coordinates};
    }

    $stn_filtered_count = $self->_load_station_inventories();

    return \%_station;
}

=head2 ($opt, @errors) = set_options ( %args )

Set various options for this StationTable instance.  These options
will affect the processing and output by subsequent method calls.

Returns an Option object and a list of errors.  It is advised you
check @errors after calling set_options cease processing; e.g.
I<die @errors if @errors>.

You may want to set up a file-scoped lexical variable to hold the
options object.  That way it is accessible throughout your code.
The typical calling pattern would look like this:

    my $Opt;  # a file-scope lexical

    sub run (@ARGV) {
        my $ghcn = Weather::GHCN::StationTable->new;

        my @errors;
        ($Opt, @errors) = set_options(...);
        die @errors if @errors;
        ...
}

=over 4

=item user_options => \%user_options

This optional argument provides a reference to a hash
that contains a set of options that will control the filtering,
processing and output of the GHCN modules.  This hash is typically
created by the caller using Getopt::Long.

The options provided can be any subset of the supported options.  Any
option not provided will be added with an appropriate default value.
The resulting combined option collection will be available as both as
hash reference in the instance, and as a Hash::Wrap object reference
in the instance via methods.

If empty or undef, a list of all stations in the GHCN database will
be generated, so it's best to at least provide some country or
station id filtering, and absolutely necessary in order to produce
other output such as daily or monthly weather data (by specifying
-report).

See USER OPTIONS for a list of the options available.

=item config_file => $config_filespec

This optional argument specifies a file which will be used to set
the configuration options.  The file must contain YAML specifications
that describe the hash structure defined in section CONFIGURATION
OPTIONS.

This option is an alternative to config_options.  (If both options
are specifed, then config_options  will take precedence.)

If config_filespec is an empty string, then the filespec will default
to $HOME\.ghcn_fetch.yaml (%UserProfile% on Windows).

If config_filespec is undef, then an empty configuration will be
used; i.e. there will be no cache and no aliases.

=item config_options => \%config_options

This optional argument is a reference to a hash containing
configuration options as described in section CONFIGURATION OPTION.
Alternatively, config_file can be used to specify a file containing
the configuation specification in YAML format.

=item stnid_filter => \%stnid_filter

This optional argument should be a reference to a hash whose keys are
the specific station id's which are to be fetched and processed.
When this is used, many filtering options via %opt will be overridden
(e.g. -country).

=item timing_stats => $TimingStats_obj

This optional argument should point to a TimingStats object that was
created by the caller and will be used to collect timing statistics.

=item hash_stats => \%hash_stats

This optional argument should be a reference to a hash that was
created by the caller and will be used to collect performance and
memory statistics.

=item return_list => <bool>

By default, get methods return a tab-separated string of results.
If return_list is set to true, then these methods will return a
list (or list of lists).

=back

=cut

method set_options (%arg) {
    my $user_options;
    my $config_options;

    my %valid;

    if ( $arg{'user_options'} ) {
        $valid{'user_options'}++;
        $_ghcn_opt_obj //= Weather::GHCN::Options->new();
        $user_options = $arg{'user_options'};
        # combine user-specified options with the defaults
        ($opt_href, $opt_obj) = $_ghcn_opt_obj->combine_options($user_options);
        # update the combined options hash in the Options object
        $_ghcn_opt_obj->opt_href = $opt_href;
        # update the combined options object in the Options object
        $_ghcn_opt_obj->opt_obj = $opt_obj;
        # save the combined option object in a file-scoped lexical for use throughout this code
        $Opt = $opt_obj;
    }

    if ( $arg{'config_file'} ) {
        $valid{'config_file'}++;
        $config_file = $arg{'config_file'};
        $config_href = _get_config_options($config_file);
        # update the config options hash in the Options object
        $_ghcn_opt_obj->config_href = $config_href;
    }

    if ( $arg{'config_options'} ) {
        $valid{'config_options'}++;
        carp '*W* set_options: config_options override config_file'
            if $valid{'config_file'};
        $_ghcn_opt_obj //= Weather::GHCN::Options->new();
        $config_options = $arg{'config_options'};
        $config_href    = $arg{'config_options'};
        # update the config options hash in the Options object
        $_ghcn_opt_obj->config_href = $config_href;

    }

    if ( $arg{'stnid_filter'} ) {
        $valid{'stnid_filter'}++;
        $_stnid_filter   = $arg{'stnid_filter'} // {};
    }

    if ( $arg{'return_list'} ) {
        $valid{'return_list'}++;
        $_return_list = $arg{'return_list'};
    }

    foreach my $kw (keys %arg) {
        croak '*E* set_options unrecognized argument: ' . $kw
            unless exists $valid{$kw};
    }

    $_measures_obj = Weather::GHCN::Measures->new($opt_href)
        if $user_options;

    my @errors = $_ghcn_opt_obj->validate();

    return ($opt_obj, @errors);
}

=head2 summarize_data ()

Aggregate the daily weather data for the stations that were loaded,
according to the report option.

=over 4

=item option: report => 'daily|monthly|yearly'

When the report option is 'id', no summarization is needed and the
method immediately returns undef.

=back


=cut

method summarize_data () {

    # when an 'id' report is requested, we generate detail data only
    # so there is no need to summarize data.
    return if $Opt->report eq 'id';

    # We'll be replacing $_aggregate_href with this hash after we're
    # done, but we can't loop over $_aggregate_href and be changing
    # it within the loop.  Hence the need for another hash.
    my %summary;

    $_tstats->start('Summarize_data');

    while ( my ($k,$href) = each $_aggregate_href->%* ) {
        ## no critic [ProhibitMagicNumbers]
        my $year    = substr $k, 0, 4;
        my $month   = substr $k, 4, 2;
        my $day     = substr $k, 6, 2;
        ## use critic [ProhibitMagicNumbers]

        my $key = $year;
        $key .= $month  if $Opt->report eq 'monthly' or $Opt->report eq 'daily';
        $key .= $day    if $Opt->report eq 'daily';

        foreach my $elem ( keys $href->%* ) {
            my $a = $_aggregate_href->{$k}->{$elem};

            my $v = _ddivide( $a->[0], $a->[1] );

            my $s = $summary{$key}{$elem} //= [undef, undef];

            if ($elem eq 'TMIN') {
                # for TMIN we keep the minimum value
                $s->[0] = _dmin($s->[0], $v);
                $s->[1] = 1.0;
            }
            elsif ( $elem eq 'TMAX' or $elem eq 'SNWD' ) {
                # For TMAX SNOW SNWD PRCP we keep the maximum value
                $s->[0] = _dmax($s->[0], $v);
                $s->[1] = 1.0;
            }
            elsif ( $elem eq 'PRCP' or $elem eq 'SNOW' ) {
                # for PRCP and SNOW, sum and use a count of 1 so we sum across time
                $s->[0] = _dsum($s->[0], $v);
                $s->[1] = 1.0;
            }
            else {
                # for TAVG and Tavg and the anomaly values we keep the sum and count,
                # so we can calculate an average of them across time
                $s->[0] = _dsum($s->[0], $v);
                $s->[1] = _dcount($s->[1], $v);
            }
        }
    }

    $_tstats->stop('Summarize_data', _memsize(\%summary, $Opt->performance));

    $_aggregate_href = \%summary;

    return;
}

=head2 tstats ()

Provides access to the TimingStats object so the caller can start
and stop script-level timers.

=cut

method tstats () {
    return $_tstats;
}

=head2 DOES

Defined by Object::Pad.  Included for POD::Coverage.

=head2 META

Defined by Object::Pad.  Included for POD::Coverage.

=cut

#---------------------------------------------------------------------
# Private Methods
#---------------------------------------------------------------------

method _aggregate_station_data ($stn) {

    $_tstats->start('Aggregate_station_data');


    while ( my ($yyyymmdd,$href) = each $_daily_href->%* ) {
        while ( my ($elem,$v) = each $href->%* ) {
            # autovivify the slot, initialize the array, and get a reference to the
            # slot to avoid the overhead of multiple key lookups later
            my $slot_href = $_aggregate_href->{$yyyymmdd}->{$elem} //= [undef, undef];

            # We accumulate into two array elements.  The first contains
            # the sum and the second the count so we can compute avg = sum/count.
            # _dsum and _dcount return the second arg if the first arg is undef
            # otherwise, _dsum returns the sum of the two args and _dcount returns the
            # value of the first arg incremented by 1
            $slot_href->[0] = _dsum($slot_href->[0], $v);
            $slot_href->[1] = _dcount($slot_href->[1], $v);
        }
    }

    $_tstats->stop('Aggregate_station_data', _memsize($_aggregate_href, $Opt->performance));

    return;
}

method _capture_data_hash_stats ($subject, $iter) {

    $_hstats{'aggregate'}{$subject}{$iter} = Devel::Size::total_size( $_aggregate_href );
    $_hstats{'flag_cnts'}{$subject}{$iter} = Devel::Size::total_size( $_flag_cnts_href );
    $_hstats{'daily'}{$subject}{$iter} = Devel::Size::total_size( $_daily_href );
    $_hstats{'baseline'}{$subject}{$iter} = Devel::Size::total_size( $_baseline_href );

    return;
}

method _clear_daily_data () {

    $_daily_href = { };

    return;
}

method _compute_anomalies () {

    $_tstats->start('Compute_anomalies');

    while ( my ($k,$href) = each $_daily_href->%* ) {
        my ($year,$month,$day) = unpack 'A4 A2 A2', $k;

        my $base_href = $_baseline_href->{ $month . $day };

        foreach my $elem ( keys $href->%* ) {
            next if not exists $base_href->{$elem};
            $href->{'A_' . $elem} = $href->{$elem} - $base_href->{$elem};
        }
    }

    $_tstats->stop('Compute_anomalies');

    return;
}

method _compute_baseline ($stn, $baseline) {

    $_tstats->start('Compute_baseline');

    my $baseline_nrs = rng_new($baseline);

    my %baseline_data;

    my $gap_nrs = rng_new( $baseline_nrs->as_string );

    while ( my ($k,$href) = each $_daily_href->%* ) {
        my ($year,$month,$day) = unpack 'A4 A2 A2', $k;

        next unless $baseline_nrs->contains($year);

        $gap_nrs->remove($year) if $baseline_nrs->contains($year);

        while ( my ($elem,$v) = each $href->%* ) {
            $baseline_data{ $month . $day }->{$elem}->[0] += $v // 0;
            $baseline_data{ $month . $day }->{$elem}->[1] ++;
        }
    }

    if ($gap_nrs->cardinality > 0) {
        my $msg = sprintf "%s\tanomalies not calculated\tmissing %d years from the baseline (%s)",
            $stn->id, $gap_nrs->cardinality, $gap_nrs->as_string;
        $stn->add_note($WARN_ANOM, $msg);
        $_baseline_href = { };
        return;
    }

    while ( my ($md,$elem_href) = each %baseline_data ) {
        while ( my ($elem, $aref) = each $elem_href->%* ) {
            my ($sum, $count) = $aref->@*;
            $baseline_data{$md}->{$elem} = $sum / $count;
        }
    }

    $_baseline_href = \%baseline_data;

    $_tstats->stop('Compute_baseline');

    return;
}

method _compute_mean_and_counts ($stn) {

    $_tstats->start('Compute_mean');

    # In this subroutine we loop through the daily min and max values that
    # were captured from the daily page and replace them with the calculated
    # mean.  We replace in order to save on the memory and performance overhead
    # of creating a new hash table.  Because the daily page has separate rows for
    # max and min, we have to scan the entire page in order to collect the max and
    # min for each day.  It's possible there may be a day with one or both entries
    # missing, in which case we undef the corresponding entry since it's impossible
    # to calculate the mean in that case.

    while ( my ($yyyymmdd, $href) = each $_daily_href->%* ) {

        my $max = $href->{TMAX};
        my $min = $href->{TMIN};

        if (defined $max and defined $min) {
            $href->{Tavg} = ($max + $min) / 2.0;
        }
    }

    $_tstats->stop('Compute_mean');

    return;
}

method _compute_quality ($stn, $context_msg, $day_count, $range, $quality) {

    $_tstats->start('Compute_quality');

    my $expected_days = 0;
    my $insufficient_quality = 0;

    map { $expected_days += _days_in_year($_) } rng_new($range)->as_array();

    ## no critic [ProhibitMagicNumbers]
    my $data_quality = int(($day_count / $expected_days) * 1000 + 0.5) / 10.0;

    if ( $data_quality < $quality ) {
        my $msg = sprintf "%s\tinsufficient data\tstation only has %d days in %s and needs %d (%0.1f%% < %d%%)",
            $stn->id, $day_count, $context_msg, $expected_days, $data_quality, $quality;
        $stn->add_note($ERR_INSUFF, $msg);
        $insufficient_quality++;
    }

    $_tstats->stop('Compute_quality');

    return $insufficient_quality;
}

method _fetch_url ($url, $cache, $timer_label=$EMPTY) {

    $_tstats->start($timer_label) if $timer_label;

    # $cache is a Cache::FileCache object.  URI::Fetch will use this
    # object to designate the location of its page cache.

    # NoNetwork == 0:
    #   If a page is in the cache, the origin HTTP server is always checked for
    #   a fresher copy

    # NoNetwork == 1:
    #   The origin HTTP is never contacted, regardless of the page being in
    #   cache or not. If the page is missing from cache, the fetch method will
    #   return undef. If the page is in cache, that page will be returned, no
    #   matter how old it is.

    # NoNetwork > 1:
    #   The origin HTTP server is not contacted if the page is in cache and the
    #   cached page was inserted in the last N seconds.
    #   If the cached copy is older than N seconds, a normal HTTP request (full
    #   or cache check) is done.

    # NoNetwork is set to the value of -nonetwork (when it was provided)
    #   If the -nonetwork option is not given, then NoNetwork is set to the number
    #   of seconds in the current year.

    my $nonetwork = $Opt->nonetwork;

    croak '*E* set_options must include cache options if the nonetwork option is > 0'
        if $nonetwork > 0 and not $cache;

    if ( !$Opt->defined('nonetwork') || $Opt->nonetwork < 0 ) {
        ## no critic [ProhibitMagicNumbers]
        my @t = localtime;
        # set nonetwork to the number of seconds this year
        # $t[7] is the day of the year (0..364/365)
        $nonetwork = $t[7] * 24 * 60*60;
    }


    my %fetch_opt = ( NoNetwork => $nonetwork );

    $fetch_opt{Cache} = $cache if $cache;

    my $res = URI::Fetch->fetch( $url, %fetch_opt )
                or croak '*E* unable to fetch data from ' . $url . ': ' .
                         ( URI::Fetch->errstr // 'unknown error' ). "\n";

    $_tstats->stop($timer_label) if $timer_label;

    my $content = $res->is_success ? $res->content : $EMPTY;

    return $content;
}

method _filter_stations ($stations_href) {
    $_tstats->start('Filter_stn');

    my $opt_range_nrs  = rng_new( $Opt->range );
    my $opt_active_nrs = rng_new( $Opt->active );

    foreach my $stn (values $stations_href->%*) {
        my $stn_active_nrs = rng_new( $stn->active );

        ##debug '=== station ', $stn->id, ' ', $stn->name;

        $stn->add_note($ERR_METRICS)
            if not $stn->elems_href->%*;

        $stn->add_note($ERR_RANGE_FULL)
            if $Opt->range and not $opt_range_nrs->subset($stn_active_nrs);

        $stn->add_note($ERR_NO_GIS)
            if $Opt->gps and $stn->coordinates eq $EMPTY;

        $stn->add_note($ERR_NOACTIVE)
            if $Opt->active and not $stn->active;

        if ($stn->active) {
            if ($Opt->partial) {
                my $s = $opt_active_nrs->intersection($stn_active_nrs);

                $stn->add_note($ERR_NOT_PARTIAL)
                    if $Opt->active and $s->is_empty;
            } else {
                $stn->add_note($ERR_NOT_ACTIVE)
                    if $Opt->active and not $opt_active_nrs->subset($stn_active_nrs);
            }

        } else {
            $stn->add_note($ERR_NOACTIVE)
                if $Opt->range;
        }
    }

    $_tstats->stop('Filter_stn');

    my $count = grep { $_->error_count == 0 } values $stations_href->%*;

    return $count;
}

method _initialize_flag_cnts () {

    # initialize KEPT flags for all metrics, so all get printed
    foreach my $elem ( $_measures_obj->measures ) {
        $_flag_cnts_href->{$elem}->{KEPT} //= 0;
    }

    return;
}

method _load_daily_data ($stn, $stn_content) {

    my %gaps;
    my %baseline_days;

    my $opt_range_nrs    = rng_new($Opt->range);
    my $opt_baseline_nrs = rng_new($Opt->baseline);
    my $opt_fmonth_nrs   = rng_new($Opt->fmonth);
    my $opt_fday_nrs     = rng_new($Opt->fday);

    $self->_initialize_flag_cnts();

    ## no critic [ProhibitMagicNumbers]

    $_tstats->start('Load_daily_data');

    ## no critic [InputOutput::RequireBriefOpen]
    open my $stn_fh, '<', \$stn_content
        or croak '*E* unable to open station daily content';

    while ( my $line = <$stn_fh> ) {

        # |---  0---|--- 10---|--- 20---|--- 30---|--- 40---|--- 50---|
        # |123456789|123456789|123456789|123456789|123456789|123456789|
        # iiiiiiiiiiiyyyymmeeee(dddddd)(dddddd)(dddddd)(dddddd)(dddddd) ...
        # CA006105976188911TMAX   39  C  122  C  144  C   83  C   28  C ...

        my $id      =     substr $line,  0, 11;
        my $year    = 0 + substr $line, 11,  4; # coerce to number
        my $month   = 0 + substr $line, 15,  2; # coerce to number
        my $element =     substr $line, 17,  4;
        my $data    =     substr $line, 21    ;

        next unless $element =~ $_measures_obj->re;

        next if $Opt->fmonth and not $opt_fmonth_nrs->contains($month);

        my $need_baseline = $Opt->anomalies and $opt_baseline_nrs->contains($year);
        if ( $Opt->range ) {
            next unless $opt_range_nrs->contains($year)
                     or $need_baseline;
        }

        foreach my $ii ( 0 .. 30 ) {
            my $day = $ii + 1;

            next if $Opt->fday and not $opt_fday_nrs->contains($day);

            # |---  0---|--- 10---|--- 20---|--- 30---|--- 40---|--- 50
            # |123456789|123456789|123456789|123456789|123456789|123456
            #    39  C  122  C  144  C   83  C   28  C   67  C   89  C ...
            my $daily = substr $data, $ii * 8, 8;

            my $value = 0 + substr $daily, 0, 5;
            # my $mflag = substr $daily, 5, 1;
            my $qflag = substr $daily, 6, 1;
            # my $sflag = substr $daily, 7, 1;

            $qflag =~ s{ \s+ \Z }{}xms;

            my $key = sprintf '%04d%02d%02d', $year, $month, $day;

            # keep track of all baseline days
            $baseline_days{$key}++
                if $need_baseline;

            # skip over values that have quality flags
            if ( $qflag ne $EMPTY ) {
                $_flag_cnts_href->{$element}->{QFLAGS}->{$qflag}++;
                $_flag_cnts_href->{$element}->{REJECTED}++;
                $_daily_href->{$key}->{QFLAGS}->{$element}->{$qflag}++;
                next;
            }

            # skip missing values
            next if $value == -9999;

            $_flag_cnts_href->{$element}->{KEPT}++;

            if ( $element =~ m{ \A ( TMAX | TMIN | TAVG | SNOW | SNWD | PRCP ) \Z }xms ) {
                # values are stored in 10th of a unit, so we divide by 10 to scale them to get:
                # - temperatures in °C
                # - PRCP in mm
                # - SNOW and SNWD in cm
                $_daily_href->{$key}->{$element} = $value / 10.0 if $value;
                $gaps{$year}->{$month} //= pack 'b30', 0;
                vec( $gaps{$year}->{$month}, $ii, 1) = 1;
            }
        }
    }
    close $stn_fh or croak '*E* unable to close';

    $_tstats->stop('Load_daily_data');

    # warn about missing years, months or days
    $self->_report_gaps( $stn, \%gaps );

    my $insufficient_quality = 0;

    # determine whether there's sufficient data within the -range, based on the -quality threshold
    if ( $Opt->range ) {
        my $day_count = keys $_daily_href->%*;
        $insufficient_quality += $self->_compute_quality( $stn, 'range', $day_count, $Opt->range, $Opt->quality );
    }

    # determine whether there's sufficient data within the -baseline, based on the -quality threshold
    if ( $Opt->anomalies ) {
        my $day_count = keys %baseline_days;
        $insufficient_quality += $self->_compute_quality( $stn, 'baseline', $day_count, $Opt->baseline, $Opt->quality );
    }

    $self->_compute_mean_and_counts( $stn );

    if ($Opt->anomalies and $insufficient_quality == 0) {
        $self->_compute_baseline( $stn, $Opt->baseline );
        $self->_compute_anomalies();
    }

    return $insufficient_quality;
}

method _load_station_inventories () {

    my $inv_content = $self->_fetch_url($GHCN_STN_INVEN_URL, $_cache, 'URI::Fetch_inv');

    # Now scan the station inventory list, to get the active range for each station
    # - note there are multiple records, one for each element and active range combo

    $_tstats->start('Parse_inv');

    ## no critic [InputOutput::RequireBriefOpen]
    open my $inv_fh, '<', \$inv_content
        or croak '*E* unable to open inventory content';

    while (my $inv = <$inv_fh>) {
        # |---  0---|--- 10---|--- 20---|--- 30---|--- 40---
        # |123456789|123456789|123456789|123456789|123456789
        # (stationid)....................elem.from.(to)
        # ACW00011604  17.1167  -61.7833 TMAX 1949 1949

        ## no critic [ProhibitMagicNumbers]
        my $id          = substr $inv, 0, 11;
        # my $lat       = substr $inc, 12, 8;
        # my $long      = substr $inc, 21, 9;
        my $elem        = substr $inv, 31, 4;
        my $firstyear   = substr $inv, 36, 4;
        my $lastyear    = substr $inv, 41, 4;
        ## use critic [ProhibitMagicNumbers]

        # in case the inventory list contains a station id that isn't in
        # the station list, we'll skip it
        next if not exists $_station{$id};

        next unless $elem =~ $_measures_obj->re;

        my $stn = $_station{$id};

        # combine the inventory active range set with the station active range
        $stn->active = rng_new( $stn->active, $firstyear . $DASH . $lastyear )->as_string();

        $stn->elems_href->{$elem}++
            if $elem =~ $_measures_obj->re;
    }
    close $inv_fh or croak;

    $_tstats->stop('Parse_inv');

    my $count = $self->_filter_stations(\%_station);

    return $count;
}

# TODO: consider ways to let the caller decide on how to output the result

method _print_detail_data ($measure_begin_idx, $stn, $row_sub) {

    return if not defined $row_sub;

    $_tstats->start('Printing');

    # build has of measure names and indices so measures can be
    # inserted into the correct columns
    my %measure_idx;
    my $ii = 0;
    foreach my $m ( $_measures_obj->measures ) {
        $measure_idx{$m} = $measure_begin_idx + $ii++;
    }

    my $opt_range_nrs = rng_new($Opt->range);

    # generate and print the data rows
    foreach my $key ( sort keys $_daily_href->%* ) {
        my ($year, $month, $day) = unpack 'A4 A2 A2', $key;
        my $flags = $EMPTY;

        next unless ( $Opt->range ? $opt_range_nrs->contains($year) : $TRUE );

        my $row = $_daily_href->{$key};

        $flags = _qflags_as_string( $row->{QFLAGS} )
            if exists $row->{QFLAGS};

        my @row;
        push @row, $year;
        push @row, $month;
        push @row, $day;
        push @row, int($year / 10) * 10;            ## no critic [ProhibitMagicNumbers]
        push @row, _seasonal_decade($year, $month);
        push @row, _seasonal_year($year, $month);
        push @row, _seasonal_qtr($year, $month);
        foreach my $elem ( $_measures_obj->measures ) {
            $row[ $measure_idx{$elem} ] = sprintf '%.2f', $row->{$elem}
                if defined $row->{$elem};
            $row[ $measure_idx{$elem} ] //= $EMPTY;
        }
        push @row, $flags;
        push @row, $stn->id;
        push @row, $stn->name;
        push @row, $stn->idx;
        push @row, $stn->grid;

        $row_sub->( \@row );
    }

    $_tstats->stop('Printing');

    return;
}

method _report_gaps ($stn, $gaps_href) {

    $_tstats->start('Report_gaps');

    my @years = sort keys $gaps_href->%*;

    if ( $Opt->active ) {
        my $active_nrs = rng_new( $Opt->active );
        my $years_nrs = rng_new( @years );
        my $gap_nrs = $active_nrs->diff( $years_nrs );
        if ($gap_nrs->cardinality) {
            my $msg = sprintf "%s\tmissing data in the active range\tyears %s", $stn->id, $gap_nrs->as_string;
            $stn->add_note($WARN_MISS_YA, $msg, $Opt->verbose);
            my $iter = $gap_nrs->iterate_runs();
            while (my ( $from, $to ) = $iter->()) {
                foreach my $yyyy ($from .. $to) {
                    $missing_href->{$stn->id}{$yyyy}{$EMPTY}++;
                }
            }
        }
    }

    my $opt_range_nrs    = rng_new($Opt->range);
    my $opt_baseline_nrs = rng_new($Opt->baseline);

    if ( $Opt->range ) {
        my $years_nrs = rng_new( @years );
        my $gap_nrs = $opt_range_nrs->diff( $years_nrs );
        if ($gap_nrs->cardinality) {
            my $msg = sprintf "%s\tmissing data in the filter range\tyears %s", $stn->id, $gap_nrs->as_string;
            $stn->add_note($WARN_MISS_YF, $msg, $Opt->verbose);
            my $iter = $gap_nrs->iterate_runs();
            while (my ( $from, $to ) = $iter->()) {
                foreach my $yyyy ($from .. $to) {
                    $missing_href->{$stn->id}{$yyyy}{$EMPTY}++;
                }
            }
        }
    }

    my ($this_yyyy, $this_mm) = _today();

    foreach my $yyyy ( @years ) {
        # don't report gaps for years that aren't within -range (or -baseline if -anomalies)
        next if $Opt->range and
              ( $opt_range_nrs and not $opt_range_nrs->contains($yyyy)
              or
                $Opt->anomalies and not $opt_baseline_nrs->contains($yyyy) );

        ## no critic [ProhibitMagicNumbers]
        my $end_month = $yyyy == $this_yyyy
            ? $this_mm
            : 12;

        my $month_gap_nrs = $Opt->fmonth
            ? rng_new( $Opt->fmonth )
            : rng_new( 1 .. $end_month );

        my @months = sort {$a<=>$b} keys $gaps_href->{$yyyy}->%*;

        $month_gap_nrs->remove( @months );

        if ($month_gap_nrs->cardinality) {
            my $gap_months = join $SPACE, _month_names($month_gap_nrs->as_array);
            my $msg = sprintf "%s\tmissing data: year %d months %s", $stn->id, $yyyy, $gap_months;
            $stn->add_note($WARN_MISS_MO, $msg, $Opt->verbose);
            $missing_href->{$stn->id}{$yyyy}{$gap_months}++;
        }

        my $opt_fday_nrs   = rng_new($Opt->fday);
        my $opt_fmonth_nrs = rng_new($Opt->fmonth);

        ## no critic [ProhibitMagicNumbers]
        my $gap_text = $EMPTY;
        foreach my $mm ( 1 .. $end_month ) {
            # skip months that don't match -fmonth when -fmonth was given
            next if $Opt->fmonth and not $opt_fmonth_nrs->contains($mm);

            my $day_vec = $gaps_href->{$yyyy}->{$mm};

            next if not $day_vec;

            my @days_with_data;
            my $mdays = _days_in_month($yyyy,$mm);

            foreach my $day ( 1..31 ) {
                # skip days that don't match -fday when -fday was given
                next if $Opt->fday and not $opt_fday_nrs->contains($day);

                next if $day > $mdays;

                push @days_with_data, $day
                    if vec($day_vec, $day - 1, 1) == 1;
            }

            my $days_in_month_nrs = $Opt->fday
                ? $opt_fday_nrs
                : rng_new( 1 .. $mdays );

            my $days_nrs = rng_new( @days_with_data );

            my $day_gap_nrs = $days_in_month_nrs->diff($days_nrs);

            $gap_text .= $SPACE . _month_names($mm) . '[' . $day_gap_nrs->as_string . ']'
                unless $day_gap_nrs->is_empty;
        }

        if ( $gap_text !~ m{\A \s* \Z}xms ) {
            my $msg = sprintf "%s\tmissing data: %d days %s", $stn->id, $yyyy, $gap_text;
            $stn->add_note($WARN_MISS_DY, $msg, $Opt->verbose);
            $gap_text =~ s{\A \s+ }{}xms;
            $missing_href->{$stn->id}{$yyyy}{$gap_text}++;
        }
    }

    $_tstats->stop('Report_gaps');

    return;
}

#----------------------------------------------------------------------
# Configuration Helper functions
#----------------------------------------------------------------------

sub _get_config_options ($config_file=$EMPTY) {

    #debug# use DDP;
    #debug# use Log::Dispatch;
    #debug# my $log = Log::Dispatch->new(
    #debug#     outputs => [
    #debug#         [ 'File',   min_level => 'debug', filename => 'c:/sandbox/log.log' ],
    #debug#         [ 'Screen', min_level => 'debug' ],
    #debug#         
    #debug#     ]
    #debug# );

    my $config_href = {};
    
    # passing undef will result in an empty config
    return $config_href if not defined $config_file;

    #debug# use FindBin;
    #debug# open my $fh, '>>', 'c:/sandbox/log.log' or die;
    #debug# $log->debug( 'program ' . $0                                   );
    #debug# $log->debug( 'caller ' . join(' | ', caller)                   );
    #debug# $log->debug( 'received config_file:           ' . $config_file );

    my $config_filespec = $config_file eq $EMPTY
                        ? _get_default_config_filespec()
                        : $config_file
                        ;

    my $yaml_struct;
    my $msg = $EMPTY;

    # uncoverable branch false
    if (-e $config_filespec) {
        # uncoverable branch false
        try {
            $yaml_struct = YAML::Tiny->read($config_filespec);
        } catch {
            $msg = '*W* no cache or aliases: failed reading YAML in ' . $config_filespec;
            carp $msg;
        }
    } else {
        return $config_href;
    }

    $config_href = $yaml_struct->[0]
        if $yaml_struct;

    #debug# $log->( 'yaml_struct length = ' . length $yaml_struct );
    #debug# $log->( "\n" );
    #debug# $log->( 'config_filespec:                ' . $config_filespec );
    #debug# $log->( 'carp ' . $msg );
    #debug# $log->( 'FindBin::Bin                    ' . $FindBin::Bin );
    #debug# $log->( "\n");
    #debug# $log->( 'config_href ' . np($config_href) );
    #debug# $log->( "\n" );
    #debug# $log->( "================" );
    #debug# $log->( "\n" );
    #debug# close $fh;

    return $config_href;
}

sub _get_default_config_filespec () {

    # an EMPTY arg will default to $HOME/.ghcn_fetch.yaml
    my $config_file ||= $CONFIG_FILE;

    my $homedir = File::HomeDir->my_home;
    #debug# say {$fh} 'homedir:                        ', $homedir;
    
    my $config_filespec = File::Spec->canonpath($config_file);
    #debug# say {$fh} 'config_filespec (canon):        ', $config_filespec;

    $config_filespec =~ s{ \A \$HOME }{$homedir}xms;
    #debug# say {$fh} 'config_filespec (s/$HOME/):     ', $config_filespec;

    if ( not File::Spec->file_name_is_absolute($config_filespec) ) {
        $config_filespec = File::Spec->catfile( $homedir, $config_filespec );       
        #debug# say {$fh} 'config_filespec wasnt absolute: ', $config_filespec;
    }
    
    return $config_filespec;
}

#----------------------------------------------------------------------
# -kml Helper Functions
#----------------------------------------------------------------------

# TODO: allow any KML hex colour code, format <opacity%><red><green><blue>

sub _get_kml_color ($color_opt) {

    # From https://developers.google.com/kml/documentation/kmlreference#colorstyle

    # Color and opacity (alpha) values are expressed in hexadecimal notation.
    # The range of values for any one color is 0 to 255 (00 to ff). For
    # alpha, 00 is fully transparent and ff is fully opaque. The order of
    # expression is aabbggrr, where:
    #
    #    aa=alpha (00 to ff)
    #    bb=blue (00 to ff)
    #    gg=green (00 to ff)
    #    rr=red (00 to ff).
    #
    # For example, if you want to apply a blue color with 50 percent opacity
    #  to an overlay, you would specify the following:
    #    <color>7fff0000</color>,
    #  where alpha=0x7f, blue=0xff, green=0x00, and red=0x00.

    my %kml_colors = (
        b => [ 'blue',  'ff780000' ],
        g => [ 'grn',   'ff147800' ],
        a => [ 'ltblu', 'ffF06414' ], # 'a' for azure
        p => [ 'purple','ff780078' ],
        r => [ 'red',   'ff1400FF' ],
        w => [ 'wht',   'ffFFFFFF' ],
        y => [ 'ylw',   'ff14F0FF' ],
    );

    # just use the first character of whatever string we're given
    my $c = substr $color_opt, 0, 1;

    return unless $kml_colors{$c};

    return $kml_colors{$c}->[1];
}

#----------------------------------------------------------------------
# -location Helper Functions
#----------------------------------------------------------------------

# Match -location <pattern> to the station id or name provided in the call.
# If the pattern looks like a station id (e.g. 'CA006105887') then it matches
# to the stn_id parameter; if it looks like a comma-separated list of station
# id's, it returns success if any of them match the stn_id parameter.  Otherwise,
# it matches the <pattern> to the start of the stn_name parameter.
sub _match_location ($stn_id, $stn_name, $pattern) {

    my $result = $FALSE;

    if ($pattern =~ m{ \A $STN_ID_RE \Z }xms) {
        $result = $stn_id eq $pattern;
    }
    elsif ($pattern =~ m{ \A $STN_ID_RE ( [,] $STN_ID_RE )+ \Z }xms) {
        my @patterns = split m{ [,] }xms, $pattern;
        my $multi_pattern = '\A(' . join(q(|), @patterns) . ')\Z';

        $result = $stn_id =~ $multi_pattern;
    }
    else {
        ## no critic [RequireExtendedFormatting]
        $result = $stn_name =~ m{\A$pattern}msi;
    }

    return $result;
}

#----------------------------------------------------------------------
# -nogaps Helper Functions
#----------------------------------------------------------------------

# parse the missing values text, which looks like this:
#   month names:   Jan Feb Mar Apr May Jun Jul Aug Sep Oct
#   or day ranges: May[2] Oct[3,11] Nov[1] Dec[2,5]

sub _parse_missing_text ( $s ) {
    my @months;
    my @mmdd;
    my @f = split m{ \s }xms, $s;

    my $mmm_re    = qr{ [A-Z][a-z][a-z] }xms;
    my $nbr_rng   = qr{ \d+ ( [-] \d+)? }xms;
    my $rng_list  = qr{ $nbr_rng (, $nbr_rng)* }xms;

    foreach my $tok (@f) {
        if ( $tok =~ m{ \A $mmm_re \Z }xms ) {
            push @months, $MMM_TO_MM{$tok};
        }
        if ( $tok =~ m{ \A ($mmm_re) \[ ($rng_list) \] \Z }xms ) {
            my $mm = $MMM_TO_MM{$1};
            my @days = rng_new($2)->as_array;
            foreach my $day (@days) {
                push @mmdd, [$mm, $day];
            }
        }
    }
    return \@months, \@mmdd;
}

#----------------------------------------------------------------------
# Misc Functions
#----------------------------------------------------------------------

# format qflags like this:  I:1, N:9, S:4
sub _qflags_as_string ( $qflags_href ) {
    return $EMPTY if not $qflags_href;

    my @r;
    foreach my $qflag ( sort keys $qflags_href->%* ) {
        push @r, sprintf '%s:%d', $qflag, $qflags_href->{$qflag};
    }

    return join ', ', @r;
}
#----------------------------------------------------------------------
# Undef-safe Functions
#----------------------------------------------------------------------

# defined max - return the maximum of the two arguments,
#   or the defined argument if one of the arguments is undef
sub _dmax ($x, $y) {

    return if not defined $x and not defined $y;
    return $y if not defined $x;
    return $x if not defined $y;

    return $x > $y ? $x : $y;
}

# defined min - return the minimum of the two arguments,
#   or the defined argument if one of the arguments is undef
sub _dmin ($x, $y) {

    return if not defined $x and not defined $y;
    return $y if not defined $x;
    return $x if not defined $y;

    return $x < $y ? $x : $y;
}

# defined sum - return the sum of the two arguments,
#   or the defined argument if one of the arguments is undef
sub _dsum ($x, $y) {

    return if not defined $x and not defined $y;
    return $y if not defined $x;
    return $x if not defined $y;

    return $x + $y;
}

# defined count - increment the value of the first argument by 1,
#   or return it unchanged if the second argument is undef
sub _dcount ($x, $y) {

    return $x if not defined $y;

    return defined $x ? $x + 1 : 1;
}

# defined divide - returns undef if either argument is undef
#   or if the denominator is zero
sub _ddivide ($x, $y) {

    return if not defined $x;
    return if not defined $y;
    return if not $y;

    return $x / $y;
}

#----------------------------------------------------------------------
# Date and Time Helper Functions
#----------------------------------------------------------------------

sub _days_in_month ($year, $month) {

    # coerce to numbers
    $year += 0;
    $month += 0;

    ## no critic [ProhibitMagicNumbers]
    my @mdays = (0, 31,28,31,30,31,30,31,31,30,31,30,31);

    if ($month == 2) {
        return $mdays[$month] + _is_leap_year($year);
    }

    return $mdays[$month];
}

sub _days_in_year ($year) {

    $year += 0; # coerce to number

    ## no critic [ProhibitMagicNumbers]
    return 365 + _is_leap_year($year);
}

sub _is_leap_year ($year) {

    $year += 0; # coerce to number

    ## no critic [ProhibitMagicNumbers]
    return 0 if $year % 4;
    return 1 if $year % 100;
    return 0 if $year % 400;
    return 1;
}

sub _month_names (@mm) {

    my @mnames = qw(xxx Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    my @result = ();
    return (@result) unless @mm;

    ## no critic [ProhibitMagicNumbers]
    foreach my $mm (@mm) {
        if ($mm !~ m{ \A \d\d? \Z }xms) {
            push @result, '???';
        }
        elsif ($mm > 0 and $mm < 13) {
            push @result, $mnames[$mm];
        }
        else {
            push @result, '???';
        }
    }

    return wantarray ? @result : shift @result;
}

sub _now () {

    my @_now = localtime time;

    return wantarray
        ? iso_date_time(@_now)
        : scalar iso_date_time(@_now)
        ;
}

sub _today () {

    my @ymdhms = _now();

    return wantarray
        ? @ymdhms[0..2]
        : sprintf '%4d-%02d-%02d', @ymdhms[0..2];
}

# Seasonal decades are based on seasonal years.
# However, decades are deemed to begin when the seasonal
# year ends in 9.  For example, seasonal decade 2010 begins
# Dec 1 2009 and continues through Nov 30, 2019.
sub _seasonal_decade ($year, $month) {
    ## no critic [ProhibitMagicNumbers]
    $year += 1 if $month == 12;
    return int($year / 10) * 10;
}

# Seasonal quarter Q1 begins Dec 1 and ends Feb 28/29
# For example, 2017 Q1 includes Dec 2017, Jan 2018 and Feb 2018.
sub _seasonal_qtr ($year, $month) {
    my @seasonal_quarter = qw( Q0 Q1 Q1 Q2 Q2 Q2 Q3 Q3 Q3 Q4 Q4 Q4 Q1 );

    return $seasonal_quarter[$month];
}

# Seasonal years begin Dec 1 and continue through end of November
# the following year.  For example, Dec 15 2017 is in Q1 2017;
# Jan 15 2018 is in Q1 2017 (not 2018!!!); Nov 15 2018 is in Q4 2017.
# This is consistent with definition used by weatherstats.ca.
sub _seasonal_year ($year, $month) {
    ## no critic [ProhibitMagicNumbers]
    $year -= 1 unless $month == 12;
    return $year;
}

#----------------------------------------------------------------------
# Performance Helper Functions
#----------------------------------------------------------------------

# calculate the total size of a hash or other structure
sub _memsize ( $ref, $opt_performance ) {
    return $EMPTY unless $opt_performance;
    return sprintf ' [%s]', commify( Devel::Size::total_size( $ref ) );
}

=head1 EXAMPLE PROGRAM

  use Weather::GHCN::StationTable;

  my $ghcn = Weather::GHCN::StationTable->new;

  my ($opt, @errors) = $ghcn->set_options(
    user_options => {
        country     => 'US',
        state       => 'NY',
        location    => 'New York',
        active      => '2000-2022',
        report      => 'yearly',
        nonetwork   => -1,      # refresh cache if stale this year
    },
    config_options => {
        cache => {
            root => 'c:/ghcn_cache',
            namespace => 'ghcn',
        },
    },
  );

  die @errors if @errors;

  $ghcn->load_stations;

  my @rows;
  if ($opt->report) {
      say $ghcn->get_header;

      # this also prints detailed station data if $opt->report eq 'id'
      $ghcn->load_data(
        # set a callback routine for printing progress messages
        progress_sub => sub { say {*STDERR} @_ },
        # set a callback routine for capturing data rows when report => 'id'
        row_sub      => sub { push @rows, $_[0] },
      );

      # these only do something when $opt->report ne 'id'
      $ghcn->summarize_data;
      say $ghcn->get_summary_data;

      say '';
      say $ghcn->get_footer;

      say '';
      say $ghcn->get_flag_statistics;
  }

  # print data rows collected by row_sub callback (when report => 'id')
  foreach my $row_aref (@rows) {
      say join "\t", $row_aref->@*;
  }

  say '';
  say $ghcn->get_stations( kept => 1 );

  say '';
  say 'Stations that failed to meet range or quality criteria:';
  say $ghcn->get_stations( kept => 0, no_header => 1 );

  if ( $ghcn->has_missing_data ) {
      warn '*W* some data was missing for the stations and date range processed' . $NL;
      say '';
      say $ghcn->get_missing_data_ranges;
  }

  say $ghcn->get_options;

  say $ghcn->get_timing_stats;

  say $ghcn->get_hash_stats;

  $ghcn->export_kml if $opt->kml;

=head1 CONFIGURATION OPTIONS

StationTable supports two kinds of options:  user and configuration.
The main difference between the two is that configuration options
are more suited to persistence; i.e. you'll most likely put them
in a file that is used at every execution of StationTable.

=head2 Cache

Cache options are used internally by StationTable when it calls
URI::Fetch to get pages of data from the GHCN web respository.

=over 4

=item root

This defines a path to a folder which will be used to cache web
pages.  See the nonetwork user option for ways to control caching.

=item namespace

This defines the subfolder of root within which the cache files will
reside.

=back

=head2 Aliases

Aliases are a convenience feature that allow you to define mnemonic
shortcuts for specific stations.  GHCN station id's (like CA006106000)
are difficult to remember and type, as can GHCN station names.
Frequently-used station id's can be given easier alias names that
can be use in the -location option for precise and reliable data
retrieval.

The entries within the aliases hash are simply keyword/value pairs
that represent the mnemonic alias name and the station id (or id's)
that are to be retrieved when that alias is used in -location.

=head2 YAML Example

This is what the YAML content for a typical configuation file would
look like:

    ---
    cache:
        root: C:/ghcn_cache_new
        namespace: ghcn_new

    aliases:
        yow: CA006106000,CA006106001    # Ottawa airport
        cda: CA006105976,CA006105978    # Ottawa (CDA and CDA RCS)

=head2 Hash Example

Here's what the typical config file would look like as a perl hash
structure:

    config_options => {
        cache => {
            root        => 'C:/ghcn_cache_new',
            namespace   => 'ghcn_new',
        }
        aliases => {
            yow => 'CA006106000,CA006106001',    # Ottawa airport
            cda => 'CA006105976,CA006105978',    # Ottawa (CDA and CDA RCS)
        }
    }

=head1 USER OPTIONS

See B<ghcn_fetch.pl -help> for a list of all user options in Getopts::Long
format.  Simply translate to a hash key/value pair.  For example,
B<-report id> becomes B<report => 'id'>.

=head1 VERSIONING and COMPATIBILITY

The version number scheme used for this module consists of a 3-part
dot-delimited string such as v0.22.365.  This format was chosen for
compatibility with Dist::Zilla version support, so that all modules
in GHCN will get the same version number upon release.  See also
L<https://metacpan.org/pod/version>.

The first digit of the string is a major release numbers.  With the
exception of v0 release, which should be considered experimental
pre-production versions, the interface is intended to be upward
compatible within a set of releases sharing the same major release
number.  If an incompatible change becomes necessary, the major
release number will be incremented.

The other two strings are essentially the date of the release, in
the format YY.DDD where YY is the year of the century and DDD is the
day number within the year.

=head1 AUTHOR

Gary Puckering (jgpuckering@rogers.com)

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Gary Puckering

=cut

1;
