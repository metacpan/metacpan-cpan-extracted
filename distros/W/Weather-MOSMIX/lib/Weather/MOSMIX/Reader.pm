package Weather::MOSMIX::Reader;
use strict;
use Moo 2;
use Archive::Zip;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use Scalar::Util 'weaken';
use Time::Piece;

use Archive::Zip;
use PerlIO::gzip;
use Weather::MOSMIX;
use Weather::MOSMIX::Writer;

=head1 NAME

Weather::MOSMIX::Read - Read MOSMIX weather forecast data

=head1 SYNOPSIS

This reads and parses  the XML from the compressed C<.kmz> file and writes it
to an SQLite database:

    my $w = Weather::MOSMIX::Writer->new(
        dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
    );
    my $r = Weather::MOSMIX::Reader->new(
        writer => $w,
    );

    for my $file (@files) {
        status("Importing $file\n");
        $r->read_zip( $file );
    };

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 C<< Weather::MOSMIX::Reader->new() >>

=cut

=head1 ACCESSORS

=head2 C<< twig >>

=cut

has 'twig' => (
    is => 'lazy',
    default => sub {
        my( $self ) = @_;
        weaken $self;
        require XML::Twig;
        XML::Twig->new(
            no_xxe => 1,
            keep_spaces => 1,
            twig_handlers => {

                # Set the expiry from the issue time
                'dwd:IssueTime' => sub { $self->handle_issuetime( $_[0], $_[1] ) },
                'kml:Placemark' => sub { $self->handle_place( $_[0], $_[1] ) },
            },
        )
    },
);

=head2 C<< expiry >>

=cut

# Ugly global attributes to store state while parsing:-/
has 'expiry' => (
    is => 'rw',
);

=head2 C<< issuetime >>

=cut

has 'issuetime' => (
    is => 'rw',
);

=head2 C<< writer >>

=cut

has 'writer' => (
    is => 'ro',
);

=head1 METHODS

=head2 C<< ->file_expiry >>

=cut

sub file_expiry( $self, $filename ) {
    if( $filename =~ m/MOSMIX_S_(20\d\d)(\d\d)(\d\d)(\d\d)_/) {
        my $d = $3 +1; # we'll hang onto the data for 24 hours
        "$1-$2-${d}T$4:00:00Z"
    };
}

=head2 C<< ->open_zip >>

    my $fh = $reader->open_zip(
        zip_name =>
        contained_name =>

Opens the first file from a C<.kmz> file and returns an unzipping filehandle
so the data can be streamed in. If no C<contained_name> is given, the first
file will be read.

=cut

sub open_zip( $self, %options ) {
    my $reader = Archive::Zip->new( $options{ zip_name } );

    my $stream;
    if( my $fn = $options{ contained_name }) {
        $stream = $reader->memberNamed( $fn )->fh;
    } else {
        my @members = $reader->members;
        $members[0]->rewindData();
        $stream = $members[0]->fh;
    };
    binmode $stream => ':gzip(none)';
    return $stream;
}

=head2 C<< ->read_zip >>

    $reader->read_zip( $kmzfile );

Opens the C<.kmz> file and parses the KML data in the first contained file.

=cut

# This could be in its own module?! IO::ReadZipContent ?
sub read_zip( $self, $filename, $expiry=$self->file_expiry($filename) ) {
    my $stream = $self->open_zip( zip_name => $filename );
    $self->parse_fh($stream, $expiry);
}

=head2 C<< ->parse_fh >>

    $reader->parse_fh( $xml_fh, expiry => '2020-02-15T14:00:00Z );

Parses the KML data streaming from the filehandle. The optional C<expiry>
option can be used to pass an expiry date.

=cut

sub parse_fh( $self, $fh, $expiry=undef ) {
    $self->writer->start;
    $self->expiry($expiry);
    $self->twig->parse($fh);
    $self->writer->commit;
}

sub handle_issuetime( $self, $twig, $issuetime ) {
    my $exp = $issuetime->text();
    $exp =~ s!\.000Z!!;
    my $issued = Time::Piece->strptime($exp,$Weather::MOSMIX::TIMESTAMP);
    $self->issuetime($issued.'Z');

    my $e = $issued->new();
    $issued = $issued->strftime($Weather::MOSMIX::TIMESTAMP);
    $self->issuetime($issued.'Z');

    $e += 24*60*60; # expire after 24 hours
    $e = $e->strftime($Weather::MOSMIX::TIMESTAMP).'Z';
    $self->expiry($e);
};

sub handle_place( $self, $twig, $place ) {
    my $description = $place->first_child_text('kml:description');

		my ($long,$lat,$el) = split /,/, $place->first_descendant('kml:coordinates')->text;

		# filter for
		#     "ww"  - significant weather
		#     "TTT" - temperature 2m above ground
		my @forecasts = (
		    grep { $_->{type} =~ /^(ww|TTT)$/ }
		    map {+{ type => $_->att('dwd:elementName'), values => $_->first_descendant('dwd:value')->text }}
		    map {; $_->descendants('dwd:Forecast') } $place->descendants('kml:ExtendedData') );
		for (@forecasts) {
			$_->{values} = [ map { $_ eq '-' ? undef : $_ } split /\s+/, $_->{values} ];
		};

		my %info = (
		    name        => scalar $place->first_child_text('kml:name'),
		    description => scalar  $place->first_child_text('kml:description'),
			longitude => $long,
			latitude  => $lat,
			elevation => $el,
			forecasts => \@forecasts,
            issuetime => $self->issuetime,
		);
		$self->writer->insert( $self->expiry, \%info );

        $place->purge;

    $twig->purge;
};

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/weather-mosmix>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Weather-MOSMIX>
or via mail to L<www-Weather-MOSMIX@rt.cpan.org|mailto:Weather-MOSMIX@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2019-2020 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
