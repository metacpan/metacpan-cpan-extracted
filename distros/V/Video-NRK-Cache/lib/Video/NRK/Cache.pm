use v5.37.9;
use feature 'class';
no warnings 'experimental::class';

package Video::NRK::Cache;  # Dist::Zilla doesn't know about class yet
$Video::NRK::Cache::VERSION = '3.00';
class Video::NRK::Cache;
# ABSTRACT: Cache NRK Video on Demand broadcasts for offline viewing


use Carp qw( croak );
use HTTP::Tiny ();
use JSON::PP qw( decode_json );

use Video::NRK::Cache::ProgramId;
use Video::NRK::Cache::Ytdlp;


my $version = $Video::NRK::Cache::VERSION ? "/$Video::NRK::Cache::VERSION" : " (DEV)";
our %UA_CONFIG = ( agent => "nrkcache$version ", verify_SSL => 1 );


field $program_id;
field $url         :param;
field $psapi_base  :param //= undef;
field $meta        :param ||= {};
field $options     :param ||= {};
field $store_class :param //= 'Video::NRK::Cache::Ytdlp';
field $store;
field $ua = HTTP::Tiny->new( %UA_CONFIG );

# :reader
method program_id () { $program_id }
method url        () { $url }
method store      () { $store }


ADJUST {
	my $prf = Video::NRK::Cache::ProgramId->new(
		ua => $ua,
		parse => $url,
		psapi_base => $psapi_base,
	);
	$program_id = $prf->id or die;
	$psapi_base = $prf->psapi_base;
	$self->get_metadata() unless defined $meta->{title} && defined $meta->{desc};
	
	$store = $store_class->new(
		program_id => $program_id,
		url        => $url = $prf->url,
		meta_title => $meta->{title},
		meta_desc  => $meta->{desc},
		options    => $options,
	);
}


method get_json ($endpoint) {
	my $json_url = "$psapi_base$endpoint" =~ s/\{id\}/$program_id/r;
	my $res = $ua->get($json_url, {headers => { Accept => 'application/json' }});
	my $error = $res->{status} == 599 ? ": $res->{content}" : "";
	croak "HTTP error $res->{status} $res->{reason} on $res->{url}$error" unless $res->{success};
	return decode_json $res->{content};
}


method get_metadata () {
	my $json = $self->get_json("/playback/metadata/program/{id}");
	
	my $title = $json->{preplay}{titles}{title} // '';
	if (my $subtitle = $json->{preplay}{titles}{subtitle}) {
		$title .= " $subtitle" if length $subtitle < 30;
		# The "subtitle" sometimes contains the full-length description,
		# which we don't want in the file name.
	}
	$title =~ s/$/-$program_id/ unless $title =~ m/$program_id$/;
	$meta->{title} //= $title;
	
	my $description = $json->{preplay}{description} // '';
	$description .= " ($program_id)";
	$meta->{desc} //= $description;
	
	return $meta;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Video::NRK::Cache - Cache NRK Video on Demand broadcasts for offline viewing

=head1 VERSION

version 3.00

=head1 SYNOPSIS

 my $cache = Video::NRK::Cache->new( url => 'DVFJ64001010' );
 say "Creating cache from URL: ", $cache->url;
 $cache->store->create;
 
 Video::NRK::Cache->new(
   url => 'https://tv.nrk.no/program/DVFJ64001010',
   options => { nice => 3, quality => 2 },
   store_class => 'Video::NRK::Cache::Ytdl',
 )->store->create;

=head1 DESCRIPTION

The Video-on-Demand programs of the Norwegian Broadcasting
Corporation (NRK) can be difficult to watch over a slow or unstable
network connection. This script creates a local cache of such video
programs in an MPEG-4 container, enabling users to watch without
interruptions.

For network transport, this class by default uses YT-dlp.
Norwegian subtitles and metadata are retrieved from NRK as well.
The data is muxed into a single MP4 file using FFmpeg.

=head1 PREREQUISITES

=over

=item FFmpeg

This software expects the FFmpeg executable to be available on your PATH as C<ffmpeg>. See L<ffmpeg.org|https://ffmpeg.org/> and L<Alien::ffmpeg>.

=item YT-dlp

This software by default expects the YT-dlp executable to be available on your PATH as C<yt-dlp>. Alternatives are optionally supported. See L</"store_class"> and L<github.com/yt-dlp|https://github.com/yt-dlp/yt-dlp#readme>.

=back

=head1 PARAMETERS

When constructing a L<Video::NRK::Cache> object,
C<new()> accepts the following parameters:

=over

=item meta

Meta data to be used for the cache. A hash ref with the entries
C<title> and/or C<desc>. If not provided as parameter, this is
determined automatically using NRK's PSAPI. Optional.

=item options

Options for the cache. A hash ref with the entries C<nice> and/or
C<quality>. See L<Video::NRK::Cache::Store/"OPTIONS">. Optional.

=item psapi_base

The base URL of NRK's Programspiller API. By default, this
software uses the fixed value C<https://psapi.nrk.no> or tries
to determine the base URL from NRK's web site. Optional.

=item store_class

Name of the class that implements storing the video in the cache.
By default, C<Video::NRK::Cache::Ytdlp> is used. Another subclass
of L<Video::NRK::Cache::Store> may be named here. Optional.

=item url

The URL of the NRK video to cache. Also accepts a NRK program ID.
B<Required.>

=back

=head1 METHODS

L<Video::NRK::Cache> provides the following methods:

=over

=item get_json

 $hashref = $cache->get_json( $endpoint );

Query NRK's PSAPI for the endpoint provided and return the decoded
result. If the string C<{id}> is present in C<$endpoint>, it will
be replaced with the NRK program ID.

=item get_metadata

 $cache->get_metadata;

Determine the meta data to be used for storing the cached video
using NRK's PSAPI.

=item program_id

 $program_id = $cache->program_id;

Return the NRK program ID of the video being cached, as a string.

=item store

 $cache->store;

Return the L<Video::NRK::Cache::Store> object.

=item url

 $url = $cache->url;

Return the URL of the NRK video being cached.

=back

=head1 LIMITATIONS

The caching of multiple videos at the same time is currently
unsupported.

This software's OOP API is new and still evolving. Additionally,
this software uses L<perlclass>, which is an experimental feature.
The class structure and API will likely be redesigned in future,
once the implementation of L<Corinna|https://github.com/Ovid/Cor>
in Perl is more complete.

=head1 SEE ALSO

L<https://psapi.nrk.no/documentation/redoc/programsider-tv/>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

Arne Johannessen has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
