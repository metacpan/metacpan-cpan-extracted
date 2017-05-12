package Wrangler::Wx::StatusBar;

use strict;
use warnings;

use Wx qw(wxID_ANY wxSB_FLAT wxST_SIZEGRIP);
use base qw(Wx::StatusBar);
# use Wx::Event qw(EVT_PAINT);

sub new {
	my ($self,$parent) = @_;

	$self = $self->SUPER::new($parent, wxID_ANY, wxST_SIZEGRIP | wxSB_FLAT );

	## register event listeners
	Wrangler::PubSub::subscribe('dir.activated', sub {
		$self->SetStatusText("$_[0] entered", 0);
	}, __PACKAGE__);
	Wrangler::PubSub::subscribe('file.activated', sub {
		$self->SetStatusText("$_[0] activated", 0);
	}, __PACKAGE__);
	Wrangler::PubSub::subscribe('selection.changed', sub {
		my $item = $_[0] == 1 ? 'item' : 'items';
		my $etcetera = '';
		my ($cntImages,$cntAudio,$cntVideo);
		if($_[0] > 1 && ref($_[1])){
			for(@{$_[1]}){
				next unless $_->{'MIME::mediaType'};
				$cntImages++ if $_->{'MIME::mediaType'} eq 'image';
				$cntAudio++ if $_->{'MIME::mediaType'} eq 'audio';
				$cntVideo++ if $_->{'MIME::mediaType'} eq 'video';
			}
			$etcetera .= ', '.$cntImages.' images' if $cntImages;
			$etcetera .= ', '.$cntAudio.' audio-files' if $cntAudio;
			$etcetera .= ', '.$cntVideo.' videos' if $cntVideo;
		}
		$self->SetStatusText("$_[0] $item selected".$etcetera, 0);
	}, __PACKAGE__);
	Wrangler::PubSub::subscribe('status.update', sub {
		$self->SetStatusText($_[0], 0);
	}, __PACKAGE__);

#	EVT_PAINT($self, sub { 
		$self->SetStatusStyles(0,wxSB_FLAT);	# does not work: flat-style is not settable on construction
#	});

	return $self;
}

sub Destroy {
	my $self = shift;

	Wrangler::PubSub::unsubscribe_owner(__PACKAGE__);

	$self->SUPER::Destroy();
}

1;
