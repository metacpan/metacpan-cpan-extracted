use v5.37.9;
use feature 'class';
no warnings 'experimental::class';

package Video::NRK::Cache::Ytdlp;  # Dist::Zilla doesn't know about class yet
$Video::NRK::Cache::Ytdlp::VERSION = '3.00';
class Video::NRK::Cache::Ytdlp :isa(Video::NRK::Cache::Store) {
# ABSTRACT: Store NRK Video on Demand cache using yt-dlp


use List::Util qw( min );


field @ytdlp_args = qw(
	--write-sub
	--all-subs
	--abort-on-unavailable-fragment
);

# :reader
method ytdlp_args () { @ytdlp_args }


our @FORMATS = qw(
	worst/worst*
	worst[height>240]/best/best*
	worst[height>320]/best/best*
	worst[height>480]/best/best*
	worst[height>640]/best/best*
	worst[height>960]/best/best*
	best/best*
);


method format () {
	my $format = $FORMATS[min( $self->quality, $#FORMATS )];
	return $format, '--format-sort', 'hasvid,ext,fps,res';
}


method download () {
	push @ytdlp_args, '--output', '' . $self->dir_mp4;
	push @ytdlp_args, '--format', $self->format();
	push @ytdlp_args, '--limit-rate', $self->rate . 'K' if $self->rate;
	$self->run_ytdlp;
}


method run_ytdlp () {
	$self->system( 'yt-dlp', $self->ytdlp_args, '--', $self->url );
}


}  # Work around perl5#20888 for v5.37.9 compatibility
1;
