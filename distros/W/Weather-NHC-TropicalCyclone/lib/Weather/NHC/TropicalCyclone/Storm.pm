package Weather::NHC::TropicalCyclone::Storm;

use strict;
use warnings;

use HTTP::Tiny ();
use HTTP::Status qw/:constants/;
use Validate::Tiny    ();
use HTML::TreeBuilder ();

# specify accessors
use Object::Tiny qw/id binNumber name classification intensity pressure latitude longitude latitude_numberic movementDir movementSpeed lastUpdate publicAdvisory forecastAdvisory windSpeedProbabilities forecastDiscussion forecastGraphics forecastTrack windWatchesWarnings trackCone initialWindExtent forecastWindRadiiGIS bestTrackGIS earliestArrivalTimeTSWindsGIS mostLikelyTimeTSWindsGIS windSpeedProbabilitiesGIS kmzFile34kt kmzFile50kt kmzFile64kt stormSurgeWatchWarningGIS potentialStormSurgeFloodingGIS/;

our $DEFAULT_GRAPHICS_ROOT = q{https://www.nhc.noaa.gov/storm_graphics};
our $DEFAULT_BTK_ROOT      = q{https://ftp.nhc.noaa.gov/atcf/btk};
our $CLASSIFICATIONS       = {
    TD  => q{Tropical Depression},
    STD => q{Subtropical Depression},
    TS  => q{Tropical Storm},
    HU  => q{Hurricane},
    STS => q{Subtropical Storm},
    PTC => q{Post-tropical Cyclone / Remnants},
    TY  => q{Typhoon (we don't use this currently)},
    PC  => q{Potential Tropical Cyclone},
};

# constructor
sub new {
    my ( $pkg, $self ) = @_;

    my $v          = Validate::Tiny->new;
    my $validation = $v->check( $self, $pkg->_get_validation_rules );
    if ( not $v->success ) {
        die qq{Field validation errors found creating package instance for: } . join( q{, }, keys %{ $validation->error } ) . qq{\n};
    }

    return bless $self, $pkg;
}

sub _get_validation_rules {
    my $self = shift;
    return {
        fields => [qw/id binNumber name classification/],
        checks => [
            [qw/id binNumber name classification/] => Validate::Tiny::is_required(),
            classification                         => sub {
                my ( $value, $params ) = @_;

                # branch, if true indicates failed validation
                if ( not grep { /$value/ } ( keys %$CLASSIFICATIONS ) ) {
                    return q{Invalid classification, not defined in NHC specification.};
                }

                # indicates successful validation
                return undef;
            },
        ],
    };
}

sub _fetch_text_types {
    my $self = shift;

    # white list of resources and URL attributes they provide
    my $types = {
        text => [qw/publicAdvisory forecastAdvisory forecastDiscussion windSpeedProbabilities/],
    };

    return $types;
}

sub _fetch_data_types {
    my $self = shift;

    # white list of resources and URL attributes they provide
    my $types = {
        zipFile          => [qw/forecastTrack windWatchesWarnings trackCone initialWindExtent forecastWindRadiiGIS bestTrackGIS potentialStormSurgeFloodingGIS/],
        kmzFile          => [qw/forecastTrack windWatchesWarnings trackCone initialWindExtent forecastWindRadiiGIS bestTrackGIS earliestArrivalTimeTSWindsGIS mostLikelyTimeTSWindsGIS/],
        zipFile5km       => [qw/windSpeedProbabilitiesGIS/],
        zipFile0p5deg    => [qw/windSpeedProbabilitiesGIS/],
        kmzFile34kt      => [qw/windSpeedProbabilitiesGIS/],
        kmzFile50kt      => [qw/windSpeedProbabilitiesGIS/],
        kmzFile64kt      => [qw/windSpeedProbabilitiesGIS/],
        kmlFile          => [qw/stormSurgeWatchWarningGIS/],
        zipFileTidalMask => [qw/potentialStormSurgeFloodingGIS/],
    };

    return $types;
}

# get storm classification "real classification"
sub kind {
    my $self = shift;
    die qq{'classification' field not set\n} if not $self->classification;
    die qq{Unknown storm classification\n}   if not $CLASSIFICATIONS->{ $self->classification };
    return $CLASSIFICATIONS->{ $self->classification };
}

# determine basin based on binNumber
sub basin {
    my $self = shift;
    die qq{'binNumber' field not set\n} if not $self->binNumber;

    # allow for easy querying of "basin"
    my $BASINS = {
        atlantic => qr/^AT[1-5]$/i,
        pacific  => qr/^EP[1-5]$/i,
    };
    for my $basin ( keys %$BASINS ) {
        return $basin if $self->binNumber =~ $BASINS->{$basin};
    }
    return undef;
}

# attempts to get base graphics directory, then scrapes
# the index page for the files and returns an array reference
# of all image addresses for this storm
sub fetch_forecastGraphics_urls {
    my $self = shift;

    my $url = $self->forecastGraphics->{url};

    my $http = HTTP::Tiny->new;

    my $response = $http->get($url);

    my $html = $response->{content};

    $html =~ m/storm_graphics\/(.+)\/refresh/;
    my $prefix = $1;
    return [] if not $prefix;

    my $base = sprintf( qq{%s/%s}, $DEFAULT_GRAPHICS_ROOT, $prefix );
    $response = $http->get($base);

    $html = $response->{content};
    my $id   = uc $self->id;
    my @imgs = ( $html =~ m/href="($id.+\.png)"/g );
    @imgs = map { qq{$base/$_} } @imgs;

    return \@imgs;
}

# rolls up requesting url and extracting text inside of the <pre></pre>
# tag into one subroutine
sub _get_text {
    my ( $self, $resource, $local_file ) = @_;

    if ( not( $self->$resource->{advNum} or $self->$resource->{issuance} or $self->$resource->{url} ) ) {
        die qq{Resource must be one of: 'publicAdvisory', 'forecastAdvisory', or 'forecastDiscssion'\n};
    }

    my $url = $self->$resource->{url};

    my $http = HTTP::Tiny->new;

    my $response = $http->get($url);

    # extract actual advisory text from <pre></pre> and return just that text
    my $htb = HTML::TreeBuilder->new;
    $htb->parse( $response->{content} );

    my $pre = $htb->look_down( '_tag', 'pre' );

    if ($local_file) {
        open my $fh, q{>}, $local_file or die qq{Failed to open '$local_file' for writing: $!\n};
        print $fh $pre->as_text;
        close $fh;
    }

    return ( $pre->as_text, $self->$resource->{advNum}, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_publicAdvisory {
    my ( $self, $local_file ) = @_;
    return $self->_get_text( q{publicAdvisory}, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_forecastAdvisory {
    my ( $self, $local_file ) = @_;
    return $self->_get_text( q{forecastAdvisory}, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_forecastDiscussion {
    my ( $self, $local_file ) = @_;
    return $self->_get_text( q{forecastDiscussion}, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_windspeedProbabilities {
    my ( $self, $local_file ) = @_;
    return $self->_get_text( q{windSpeedProbabilities}, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_forecastTrack {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{forecastTrack}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_windWatchesWarnings {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{windWatchesWarnings}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_trackCone {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{trackCone}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_initialWindExtent {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{initialWindExtent}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_forecastWindRadiiGIS {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{forecastWindRadiiGIS}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_bestTrackGIS {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{bestTrackGIS}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_earliestArrivalTimeTSWindsGIS {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{earliestArrivalTimeTSWindsGIS}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_mostLikelyTimeTSWindsGIS {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{mostLikelyTimeTSWindsGIS}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_windSpeedProbabilitiesGIS {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{windSpeedProbabilitiesGIS}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_stormSurgeWatchWarningGIS {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{stormSurgeWatchWarningGIS}, $type, $local_file );
}

# optionally provide a local file name to save fetched file to
sub fetch_potentialStormSurgeFloodingGIS {
    my ( $self, $type, $local_file ) = @_;
    return $self->_get_file( q{potentialStormSurgeFloodingGIS}, $type, $local_file );
}

# rolls up requesting file, based on url associated with file key ("url" key is not specified)
sub _get_file {
    my ( $self, $resource, $urlKey, $local_file ) = @_;

    my $types = $self->_fetch_data_types;

    # make sure $urlKey is provided by the resource (defined in $types hash ref above)
    die qq{'$urlKey' is not a valid type provided by '$resource'.\n} if not grep { /$resource/ } ( @{ $types->{$urlKey} } );

    # check to make sure $resource is not 'null'
    return undef if ref $self->$resource ne q{HASH} or not $self->$resource->{$urlKey};

    my $url = $self->$resource->{$urlKey};

    # extract file name from URL if no $local_file is specified
    if ( not $local_file ) {

        # extract file name from the end of the URL
        $url =~ m/\/([a-zA-Z0-9_]+)\.([a-zA-Z]+)$/;
        $local_file = qq{$1.$2};
    }

    my $http = HTTP::Tiny->new;

    my $response = $http->mirror( $url, $local_file );

    if ( not $response->{success} ) {
        my $status = $response->{status} // q{Unknown};
        die qq{Download of $url failed. HTTP status: $status\n};
    }

    # bestTrackGIS resource doesn't provide "advNum" per specification
    return ( $local_file, $self->$resource->{advNum} // q{N/A} );
}

# auxillary methods to fetch the best track ".dat" file via NHC's FTP over HTTPS

sub fetch_best_track {
    my ( $self, $local_file ) = @_;

    my $btk_file = sprintf( "b%s.dat", $self->id );
    my $url = sprintf( "%s/%s", $DEFAULT_BTK_ROOT, $btk_file );

    $local_file //= $btk_file;

    my $http = HTTP::Tiny->new;

    my $response = $http->mirror( $url, $local_file );

    if ( not $response->{success} ) {
        my $status = $response->{status} // q{Unknown};
        die qq{Download of $url failed. HTTP status: $status\n};
    }

    # bestTrackGIS resource doesn't provide "advNum" per specification
    return $local_file;
}

1;

__END__

=head1 NAME

Weather::NHC::TropicalCyclone::Storm - Provides a convenient interface to individual storm sections
delivered inside of the NHC Tropical Cyclone JSON file. 

=head1 SYNOPSIS

   use strict;
   use warnings;
   use Weather::NHC::TropicalCyclone ();
   
   my $nhc = Weather::NHC::TropicalCyclone->new;
   $nhc->fetch;
   
   my $storms_ref = $nhc->active_storms;
   my $count = @$storms_ref;
   
   print qq{$count storms found\n};
   
   foreach my $storm (@$storms_ref) {
     print $storm->name . qq{\n};
     my ($text, $advNum, $local_file) = $storm->fetch_publicAdvisory($storm->id.q{.fst});
     print qq{$local_file saved for Advisory $advNum\n};
     rename $local_file, qq{$advNum.$local_file};
   }

=head1 DESCRIPTION

Given JSON returned by the NHC via C<https://www.nhc.noaa.gov/CurrentStorms.json>,
this module creates a covenient object for encapsulating each storm and fetching
the data associated with them.

=head1 METHODS

Each storm instances provides an accessor for each field. In addition to this, each
field that represents data (text extractible via C<.shtml> or a downloadable file)
also provides a C<fetch_*> method.

=head2 Text Extracted from C<.shtml>

Optional parameter naming a file to save the extracted text to.

Returns a list of 3 values: extracted text, advisory number, and local file (if optional
parameter is provided to the called method. 

Provided methods include:

=over 3

=item C<fetch_publicAdvisory>

=item C<fetch_forecastAdvisory>

=item C<fetch_forecastDiscussion>

=item C<fetch_windspeedProbabilities>

=item C<_get_text>

Internal method used by all of the fetch methods that extract text from the linked
C<.shtml> files.

=back

=head2 Directly Downloadable Files 

Optional parameter naming a file to save the extracted text to.

Returns a list of 2 values: name of saved local file and advisory (if provided).

Provided methods include:

=over 3

=item C<fetch_forecastTrack>

=item C<fetch_windWatchesWarnings>

=item C<fetch_trackCone>

=item C<fetch_initialWindExtent>

=item C<fetch_forecastWindRadiiGIS>

=item C<fetch_earliestArrivalTimeTSWindsGIS>

=item C<fetch_mostLikelyTimeTSWindsGIS>

=item C<fetch_windSpeedProbabilitiesGIS>

=item C<fetch_stormSurgeWatchWarningGIS>

=item C<fetch_potentialStormSurgeFloodingGIS>

=item C<fetch_bestTrackGIS>

Note: This resource doesn't provide an advisory. C<N/A> is returned in its place.

=item C<_get_file>

Internal method used by all of the fetch methods that downloads files.

=back

=head2 Auxillary Methods

=over 3

=item C<fetch_forecastGraphics_urls>

Uses the URL provided by the C<forecastGraphics> fields to determine the location
of the base graphics directory. The default index page returned by the web server
is scraped to get a fully resolved list of all graphics available for the storm.

Returns list of graphics URLs as an array reference. A method to download all of
the graphics is not provided at this time. But give the list of URLs, it's trivial
to write a loop to download any number of these images using C<HTTP::Tiny>'s
C<mirror> method. See C<perldoc HTTP::Tiny> for more information.

If the base directory for the image URLs can't be determined, this method returns
an empty array reference. It is up to the caller to determine that none were returned.

=item C<fetch_best_track>

Accepts an optional parameter that defines the local file to save this file as.

Attempts to fetch the best track C<.dat> file that. This URL is not provided directly
by the JSON file, but can be easily derived by using using C<$DEFAULT_BTK_ROOT> and
composing the filename using the C<id> accessor. This method combines this with a fetch
over HTTPS (using C<HTTP::Tiny>'s C<mirror> method). 

This method returns just the local file name.

=item C<kind>

Returns a C<Human meaningful> name for the kind of storm is represented by the
reference. Based on the specification, the following kinds are returned based
on the C<classification> value:

   NHC |     Meaningful Kind
   --- | -------------------------------------
   TD  | Tropical Depression
   STD | Subtropical Depression
   TS  | Tropical Storm
   HU  | Hurricane
   STS | Subtropical Storm
   PTC | Post-tropical Cyclone / Remnants
   TY  | Typhoon (we don't use this currently)
   PC  | Potential Tropical Cyclone


=back

=head1 ENVIRONMENT

Default ackage variables:

=over 3

=item C<$DEFAULT_GRAPHICS_ROOT>

defines the base URL used to determine the list of graphics available for the storm

=item C<$DEFAULT_BTK_ROOT>

defines the base URL used to fetch the best track C<.dat> file

=back

=head1 COPYRIGHT and LICENSE

This module is distributed under the same terms as Perl itself.
