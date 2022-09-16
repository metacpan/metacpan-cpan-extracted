# Weather::GHCN::Station.pm - class for Station metadata

=head1 NAME

Weather::GHCN::Station - class for Station metadata

=head1 VERSION

version v0.0.002

=head1 SYNOPSIS

    use Weather::GHCN::Station;
    
    my $stn_obj = Weather::GHCN::Station->new (
        id      => 'CA006105976',
        country => 'CA',
        state   => 'ON',
        active  => '1899-2022',
        lat     => '45.3833',
        long    => '-75.7167',
        elev    => 79,
        name    => 'OTTAWA CDA',
        gsn     => '',
    );

=head1 DESCRIPTION

The B<Weather::GHCN::Station> class is used to encapsulate the metadata for a 
station as obtained from the NOAA Global Historical Climatology 
Network data repository.  Data is sourced from the station list and 
the station inventory.

The module is primarily for use by Weather::GHCN::Fetch and Weather::GHCN::StationTable.

=cut

use v5.18;  # minimum for Object::Pad
use Object::Pad 0.66 qw( :experimental(init_expr) );

package Weather::GHCN::Station;
class   Weather::GHCN::Station;

our $VERSION = 'v0.0.002';

use Weather::GHCN::Common        qw( rng_new iso_date_time );
use Const::Fast;

const my $EMPTY  => q();    # empty string
const my $TAB    => qq(\t); # tab character
const my $TRUE   => 1;      # perl's usual TRUE
const my $FALSE  => not $TRUE; # a dual-var consisting of '' and 0

const my $NOAA_DATA  => 'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/';

# below this value is an error causing stn rejection
const my $ERR_THRESHOLD     => 50;

# attributes
field $id           :reader  :param;        # [0]
field $country      :reader  :param;        # [1]
field $state        :reader  :param;        # [2]
field $active       :mutator :param;        # [3]
field $lat          :reader  :param;        # [4]
field $long         :reader  :param;        # [5]
field $elev         :reader  :param;        # [6]
field $name         :reader  :param;        # [7]
field $gsn          :reader  :param;        # [8]
field $elems_href   :reader  { {} };        # [9]
field $idx          :mutator;               # [10]
field $note_nrs     :mutator { rng_new() }; # [11]

=head1 FIELD ACCESSORS

=over 4

=item id

Returns the Station id.

=item country

Returns the two-character GEC country code for the station.

=item state

Returns the two-character state code for US stations, or province code for
Canadian stations.

=item active

Returns the active range of the station.

=item lat

Returns the station latitude.

=item long

Returns the station longitude.

=item elev

Returns the station elevation.

=item name

Returns the station name.

=item gsn

Returns the boolean indicating whether this is a GSN station.

=item elems_href

Returns a hash reference for the measurements available from the
station daily data records.

=item idx

Returns an index number which is shared by stations that have the
same physical location; i.e. latitude and longitude.  When station
instrumentation is changed or there are other significant changes,
a new station id may be assigned.  This index enables you to group
together stations that represent the same spot but which may have
different active time periods.

=item note_nrs

Returns a number range string that represents notes which are errors
or warnings about the station.

=back

=cut
######################################################################
# Class (:common) methods
######################################################################

=head1 CLASS METHODS

=head2 new ()

Create a new Station object.


=head2 Headings ()

Column headings may be needed prior to creating any Station instances,
for example to print them before any data is loaded.  This Headings
class method is provided to handle that situation.  There is a
corresponding instance method.

If called in list context, a list is return;  in scalar context, a
list reference is returned.

=cut

method Headings :common {
    my @h = qw(StationId Country State Active Lat Long Elev Location Notes StnIdx Grid );
    return wantarray ? @h : \@h;
}

######################################################################
# Instance methods
######################################################################

=head1 INSTANCE METHODS

=head2 headings

See Headings in Class Methods.

=cut

method headings {
    my @h = Headings;
    return wantarray ? @h : \@h;
}

=head2 add_note ($note_id, $msg=undef, $verbose=$FALSE)

This method allows you to add numbered notes to each station object.
It is up to the caller to assign meaning to the numbers.  They are
stored in a range list (i.e. a Set::IntSpan::Fast object) so that
they can be printed compactly even if there a gaps in the number ranges.
For example, notes 1, 5 and 20 through 25 will print as 1,5,20-25.

The message argument is optional, but if you provide a message then
it will be display on STDERR if it is considered an error message.
The threshold is 50 (as established by the hard coded constant
$ERR_THRESHOLD).  Anything below that is considered an error.  Otherwise
it's considered a warning.

When the $VERBOSE argument is true, it causes warnings to also print
to STDERR.

=cut

method add_note ($note_id, $msg=undef, $verbose=$FALSE) {
    $note_nrs->add_from_string($note_id);

    return unless $msg;

    if ($note_id < $ERR_THRESHOLD) {
        say {*STDERR} '*E* ', $msg;
    } else {
        say {*STDERR} '*W* ', $msg if $verbose;
    }

    return;
}

=head2 row

Returns the station object as a list of field values.  The fields
are:

    $id, $country, $state, $active, $lat, $long, $elev, $name,
      $note_text, $idx, $grid>

The second last value, $idx is a unique serial index number provided
by GHCH::StationTable during load_stations().  Unless set by a consumer
of this module, its value will be B<undef>.

The last value, $grid, is a string derived by truncating $lat and
$long to 1 decimal place, converting them to N/S W/E format, and
concatenting them.  This results in a box that defines an area within
which there may be other nearby stations of interest.

If called in list context, a list is return;  in scalar context, a
list reference is returned.

=cut

method row {

    my $note_text = $note_nrs->cardinality ? '[' . $note_nrs->as_string . ']' : $EMPTY;

    my @row = (
        $id,
        $country,
        $state,
        $active,
        $lat,
        $long,
        $elev,
        $name,
        $note_text,
        $idx,
        $self->grid,
    );

    return wantarray ? @row : \@row;
}

=head2 coordinates

Returns the latitude and longitude coordinates of the station in
decimal format as a space-separated string.

=cut

method coordinates {
    # uncoverable branch true
    # uncoverable condition left
    # uncoverable condition right
    return $EMPTY unless $lat and $long;
    return sprintf '%f %f', $lat, $long;
}

=head2 description

Return lines of text which describe the station in attribute: value
format.

=cut

method description {
    # uncoverable branch true
    my $is_gsn = $gsn ? 'yes' : 'no';
    my $elems = join q( ), sort keys $elems_href->%*;

    # note: those the values are lined up here, they won't be when
    # imported into Google Earth
    my $text = <<~"_EOT_";
        Id:      $id
        Name:    $name
        Country: $country
        State:   $state
        Active:  $active
        Coord:   $lat $long
        Elev:    $elev
        Is GSN?  $is_gsn
        Metrics: $elems
        _EOT_

    return $text;
}

=head2 error_count

Returns a count of the number of errors that were flagged for this
station.  Errors generally make the station unsuitable for use.
Warnings are not included.

=cut

method error_count {
    my $err_count = grep { $_ < $ERR_THRESHOLD } $note_nrs->as_array;

    return $err_count;
}

=head2 grid

Returns the latitude and longitude to a single decimal place and using
cardinal (N/S E/W) notation.  This value can be used for grouping
together stations that are within a 1/10th degree grid and which
may be assumed to experience similar weather conditions.

=cut

method grid {
    my ($x, $y) = ($lat, $long);
    # uncoverable branch true
    my $xh = $x < 0 ? 'S' : 'N';
    # uncoverable branch false
    my $yh = $y < 0 ? 'W' : 'E';

    ## no critic [ProhibitMagicNumbers]
    # uncoverable branch true
    $x *= $x < 0 ? -1 : 1;
    # uncoverable branch false
    $y *= $y < 0 ? -1 : 1;

    my $grid = sprintf '%4.1f%s %4.1f%s', $x, $xh, $y, $yh;

    return $grid;
}

=head2 selected

Returns a boolean indicating whether the station was selected for
data loading.  Selected stations are those that meet the filtering
criteria (station id, station name, active range etc.) and that
are not flagged with errors.

=cut

method selected {
    # uncoverable branch true
    return $note_nrs->cardinality == 0 ? $TRUE : $FALSE;
}

=head2 url

Returns the URL for the station's daily data web page in the NOAA
GHCN data repository.

=cut

method url {
    return $NOAA_DATA . $id . '.dly';
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
