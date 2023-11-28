use v5.37.9;
use feature 'class';
no warnings 'experimental::class';

package Video::NRK::Cache::Ytdl;  # Dist::Zilla doesn't know about class yet
$Video::NRK::Cache::Ytdl::VERSION = '3.01';
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
	worst[ext=mp4][fps<40][height>30]/worstvideo[ext=mp4][fps<40][height>30]+worstaudio/worst[ext=mp4][fps<40]/worst/worstvideo+worstaudio/worstaudio
	worst[ext=mp4][fps<40][height>240]/worstvideo[ext=mp4][fps<40][height>240]+bestaudio/best[ext=mp4][fps<40]/best/bestvideo+bestaudio/bestaudio
	worst[ext=mp4][fps<40][height>320]/worstvideo[ext=mp4][fps<40][height>320]+bestaudio/best[ext=mp4][fps<40]/best/bestvideo+bestaudio/bestaudio
	worst[ext=mp4][fps<40][height>480]/worstvideo[ext=mp4][fps<40][height>480]+bestaudio/best[ext=mp4][fps<40]/best/bestvideo+bestaudio/bestaudio
	worst[ext=mp4][fps<40][height>640]/worstvideo[ext=mp4][fps<40][height>640]+bestaudio/best[ext=mp4][fps<40]/best/bestvideo+bestaudio/bestaudio
	worst[ext=mp4][fps<40][height>960]/worstvideo[ext=mp4][fps<40][height>960]+bestaudio/best[ext=mp4][fps<40]/best/bestvideo+bestaudio/bestaudio
	best[ext=mp4][fps<40]/bestvideo[ext=mp4][fps<40]+bestaudio/best/bestvideo+bestaudio/bestaudio
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
