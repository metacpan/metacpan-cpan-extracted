package WebService::GData::YouTube::Feed::Playlist;
use base WebService::GData::YouTube::Feed::Video;
our $VERSION  = 0.01_01;


	sub position {
		my $this = shift;
		if(@_>=2){
			$this->{_feed}->{'yt$position'}->{'$t'}=$_[1];	
			return;
		}
		return $this->{_feed}->{'yt$position'}->{'$t'};
	}

1;