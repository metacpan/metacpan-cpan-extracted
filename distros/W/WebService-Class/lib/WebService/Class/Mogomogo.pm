package WebService::Class::Mogomogo;
use warnings;
use strict;
use base qw(WebService::Class::Twitter);
__PACKAGE__->base_url("http://api.mogo2.jp/");

sub init{
	my $self = shift;
	$self->SUPER::init(@_);
	$self->urls({
		'public_timeline'=>$self->base_url."statuses/public_timeline.xml",
		'friend_timeline'=>$self->base_url."statuses/friends_timeline.xml",
		'user_timeline'=>$self->base_url."statuses/user_timeline.xml",
		'show_status'=>$self->base_url."statuses/show/%s.xml",
		'update_status'=>$self->base_url."statuses/update.xml",
		'destroy_status'=>$self->base_url."statuses/destroy/%s.xml",
		'replies'=>$self->base_url."statuses/replies.xml",
		'friends'=>$self->base_url."statuses/friends.xml",
		'followers'=>$self->base_url."statuses/followers.xml",
		'featured'=>$self->base_url."statuses/featured.xml",
		'show_users'=>$self->base_url."users/show/%s.xml",
	});
}







1;
