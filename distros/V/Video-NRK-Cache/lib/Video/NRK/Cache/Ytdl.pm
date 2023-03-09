use v5.37.9;
use feature 'class';
no warnings 'experimental::class';

package Video::NRK::Cache::Ytdl;  # Dist::Zilla doesn't know about class yet
$Video::NRK::Cache::Ytdl::VERSION = '3.00';
class Video::NRK::Cache::Ytdl :isa(Video::NRK::Cache::Store) {
# ABSTRACT: Store NRK Video on Demand cache using youtube-dl


use List::Util qw( min );


field @ytdl_args = qw(
	--write-sub
	--all-subs
	--abort-on-unavailable-fragment
);

# :reader
method ytdl_args () { @ytdl_args }


our @FORMATS = qw(
	worst[ext=mp4][fps<40][height>30]/worst[ext=mp4][fps<40]/worst/worstaudio
	worst[ext=mp4][fps<40][height>240]/best[ext=mp4][fps<40]/best/bestaudio
	worst[ext=mp4][fps<40][height>320]/best[ext=mp4][fps<40]/best/bestaudio
	worst[ext=mp4][fps<40][height>480]/best[ext=mp4][fps<40]/best/bestaudio
	worst[ext=mp4][fps<40][height>640]/best[ext=mp4][fps<40]/best/bestaudio
	worst[ext=mp4][fps<40][height>960]/best[ext=mp4][fps<40]/best/bestaudio
	best[ext=mp4][fps<40]/best/bestaudio
);


method format () {
	return $FORMATS[min( $self->quality, $#FORMATS )];
}


method download () {
	push @ytdl_args, '--output', $self->dir_mp4;
	push @ytdl_args, '--format', $self->format();
	push @ytdl_args, '--limit-rate', $self->rate . 'k' if $self->rate;
	$self->run_ytdlp;
}


method run_ytdlp () {
	$self->system( 'youtube-dl', $self->url, $self->ytdl_args );
}


}  # Work around perl5#20888 for v5.37.9 compatibility
1;
