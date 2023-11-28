use v5.37.9;
use feature 'class';
no warnings 'experimental::class';
use open qw( :utf8 :std );

package Video::NRK::Cache::Store;  # Dist::Zilla doesn't know about class yet
$Video::NRK::Cache::Store::VERSION = '3.01';
class Video::NRK::Cache::Store;
# ABSTRACT: Store NRK Video on Demand cache on disk (abstract base class)


use Carp qw( croak );
use Cwd qw( cwd );
use Path::Tiny qw( path );
use List::Util qw( max );


our $RATE = 1600;  # kilo-bytes per second
our $NICE = 1;
our $DRY_RUN = 0;


field $program_id :param;
field $url        :param;
field $meta_title :param = $program_id;
field $meta_desc  :param = '';
field $options    :param = {};

field $dir;
field $file;
field $dir_mp4;
field %dir_sub;
field $nice = $NICE;
field $quality = 3;

# :reader
method program_id () { $program_id }
method url        () { $url }
method meta_title () { $meta_title }
method meta_desc  () { $meta_desc }
method options    () { $options }

method dir     () { $dir }
method file    () { $file }
method dir_mp4 () { $dir_mp4 }
method dir_sub () { %dir_sub }
method nice    () { $nice }
method quality () { $quality }


ADJUST {
	$quality = $options->{quality} if defined $options->{quality};
	$nice = $options->{nice} if defined $options->{nice};
	
	$dir = path(cwd)->child("$meta_title");
	$file = path(cwd)->child("$meta_title.mp4");
	$dir_mp4 = $dir->child("$program_id.mp4");
	$dir_sub{nb_ttv} = $dir->child("$program_id.nb-ttv.vtt");
	$dir_sub{nb_nor} = $dir->child("$program_id.nb-nor.vtt");
	$dir_sub{nn_ttv} = $dir->child("$program_id.nn-ttv.vtt");
	$dir_sub{nn_nor} = $dir->child("$program_id.nn-nor.vtt");
}


method create () {
	$self->prep;
	$self->download;
	$self->ffmpeg;
	$self->post;
}


method rate () {
	return unless $nice;
	return max 1, int $RATE / 2 ** ($nice - 1);
}


method prep () {
	croak "File exists: $file" if $file->exists;
	$dir->mkpath;
}


method ffmpeg () {
	my @codecs = (
		'-c:v' => $options->{vcodec} ? split ' ', $options->{vcodec} : 'copy',
		'-c:a' => $options->{acodec} ? split ' ', $options->{acodec} : 'copy',
	);
	croak "acodec/vcodec must have uneven number of items" if @codecs & 1;  # won't catch the mess if both are wrong
	my $dir_sub = $dir_sub{nb_ttv}->exists ? $dir_sub{nb_ttv} :
		$dir_sub{nn_ttv}->exists ? $dir_sub{nn_ttv} :
		$dir_sub{nb_nor}->exists ? $dir_sub{nb_nor} :
		$dir_sub{nn_nor}->exists ? $dir_sub{nn_nor} :
		undef;
	if ($dir_sub) {
		@codecs = (
			-f => 'srt', -i => "$dir_sub",
			qw( -map 0:0 -map 0:1 -map 1:0 ), @codecs, qw( -c:s mov_text ),
		);
		# https://trac.ffmpeg.org/wiki/Map
	}
	$self->system( 'ffmpeg',
		-i => "$dir_mp4",
		@codecs,
		-metadata => "description=$meta_desc",
		-metadata => "comment=$url",
		-metadata => "copyright=NRK",
		-metadata => "episode_id=$program_id",
		"$file",
	);
}


method post () {
	$dir->remove_tree;
}


method system ($cmd, @args) {
	say join " ", $cmd, @args;
	system $cmd, @args unless $DRY_RUN;
	$self->_ipc_error_check($!, $?, $cmd);
}


method _ipc_error_check ($os_err, $code, $cmd) {
	utf8::decode $os_err;
	croak "$cmd failed to execute: $os_err" if $code == -1;
	croak "$cmd died with signal " . ($code & 0x7f) if $code & 0x7f;
	croak "$cmd exited with status " . ($code >> 8) if $code;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Video::NRK::Cache::Store - Store NRK Video on Demand cache on disk (abstract base class)

=head1 VERSION

version 3.01

=head1 SYNOPSIS

 $store = Video::NRK::Cache::Ytdlp->new(
   program_id => 'DVFJ64001010',
   url        => 'https://tv.nrk.no/program/DVFJ64001010',
   meta_title => 'Flåmsbana',
   meta_desc  => 'Bli med frå høgfjell til fjord.',
   options    => { quality => 4, nice => 3 },
 );
 $store->create;

=head1 DESCRIPTION

Abstract base class for the different video cache storage
implementations.

Your subclass B<must> implement the L</"download"> method,
which is not provided by this base class.

This distribution provides the following concrete subclasses:

=over

=item Video::NRK::Cache::Ytdl

Uses YouTube-dl for downloading. The C<youtube-dl> binary must
exist on your PATH.

=item Video::NRK::Cache::Ytdlp

Uses YT-dlp for downloading. The C<yt-dlp> binary must exist
on your PATH.

=back

=head1 PARAMETERS

When constructing a L<Video::NRK::Cache::Store> object,
C<new()> accepts the following parameters:

=over

=item meta_desc

A description of the NRK video to cache. Used as meta data.
Defaults to an empty string. Optional.

=item meta_title

The title of the NRK video to cache. Used as file and directory name
for the cache store. By default, the program ID is used. Optional.

=item options

Hash ref with options for the cache. See L</"OPTIONS">. Optional.

=item program_id

The NRK program ID of the NRK video to cache. Used primarily for
naming and as meta data. B<Required.>

=item url

The URL of the NRK video to cache. B<Required.>

=back

=head1 METHODS

L<Video::NRK::Cache::Store> provides accessors for all parameters
listed above. Additionally, it provides the following methods:

=over

=item create

 $store->create;

Create the offline NRK cache store. This is a convenience method,
exactly equivalent to the following sequence:

 $store->prep;
 $store->download;
 $store->ffmpeg;
 $store->post;

=item dir

 $path = $store->dir;

Return the location of the cache store directory as a L<Path::Tiny>
object.

=item dir_mp4

 $path = $store->dir_mp4;

Return the (temporary) location of the video cache file inside the
cache store directory as a L<Path::Tiny> object.

=item dir_sub

 %path_hash = $store->dir_sub;

Return the (temporary) location of the video subtitle cache files
inside the cache store directory as a hash of L<Path::Tiny> objects.
Has entries for the keys C<nb_ttv>, C<nb_nor>, C<nn_ttv>, C<nn_nor>.
Each of these files may or may not actually exist, depending on the
subtitles offered for the particular video.

=item download

 $store->download;

Download video data and subtitles into the cache store directory.

I<This method is not implemented in this class. Subclasses are
expected to provide it.>

=item ffmpeg

 $store->ffmpeg;

Use FFmpeg for post-processing. In particular, subtitles and meta
data need to be added to the target cache file.

=item file

 $path = $store->file;

Return the location of the target cache file as a L<Path::Tiny>
object.

=item nice

 $nice = $store->nice;

Return the value of the C<nice> option. See L</"OPTIONS">.

=item post

 $store->post;

Ensure any necessary cleanup steps have been taken. In particular,
the cache store directory should be removed (but the target cache
file preserved).

=item prep

 $store->prep;

Ensure all necessary preparations for downloading video data into
the cache have been taken. In particular, the target cache file
must not exist and the cache store directory must have been created.

=item quality

 $quality = $store->quality;

Return the value of the C<quality> option. See L</"OPTIONS">.

=item rate

 $kbyte_per_sec = $store->rate;

Return the suggested maximum transfer rate in kilobytes per second,
based on the value of the C<nice> option.

=item system

 $store->system( $cmd, @args );

Equivalent to L<perlfunc/"system">, but additionally prints a
summary of the system call to stdout and checks for errors.

=back

=head1 OPTIONS

L<Video::NRK::Cache::Store> accepts the following options, which
are to be provided as hash entries to the C<options> parameter:

=over

=item nice

The C<nice> option is an integer describing bandwidth reduction.
Increasing this value may reduce the bandwidth used by the program.
The value C<0> means no bandwidth limitation. The value C<1> is the
default and limits bandwidth to S<1600 kB/s>.

Reducing the bandwidth may be useful when the caching is done on a
good network connection for later viewing, where it prevents the
overuse of network and server resources. It may also be useful on
a bad network connection to keep the remaining bandwidth available
for other purposes.

=item quality

The C<quality> option is an integer describing the format of the
AV content to store in the cache. Usually the AV quality for NRK
content ranges S<< from C<0> to C<5>. >>

If this option is not given, by default quality C<3> is preferred
when available, otherwise the highest numerical value available is
chosen. AV content at quality C<3> means "540p" or "qHD" resolution,
which is similar to Standard Definition TV (though typically encoded
at higher quality than standard TV). It may sound old-fashioned,
but it saves valuable bandwidth, and for a lot of TV programs,
this quality is actually plenty fine.

=back

=head1 LIMITATIONS

The code deciding the output filename seems fairly brittle and
should probably be overhauled. In particular, a suitable output file
name should ideally start with the numeric season/episode code if
available and continue with the name of the program (if this is a TV
episode with a name of its own, the show name should be excluded).
It should perhaps always end with the program ID (although this
may be redundant, given that the ID is also in the meta data).
Spaces should be used for separation on macOS, hyphens otherwise.
These considerations are currently unimplemented.

This software's OOP API is new and still evolving. Additionally,
this software uses L<perlclass>, which is an experimental feature.
The class structure and API will likely be redesigned in future,
once the implementation of L<Corinna|https://github.com/Ovid/Cor>
in Perl is more complete.

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
