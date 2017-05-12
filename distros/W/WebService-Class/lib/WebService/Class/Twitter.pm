package WebService::Class::Twitter;
use warnings;
use strict;
use base qw(WebService::Class::AbstractHTTPRequestClass);
__PACKAGE__->base_url('http://twitter.com/');

sub init{
	my $self = shift;
	$self->SUPER::init(@_);
	$self->urls({
		'public_timeline'=> $self->base_url."statuses/public_timeline.xml",
		'friend_timeline'=> $self->base_url."statuses/friends_timeline.xml",
		'user_timeline'  => $self->base_url."statuses/user_timeline.xml",
		'show_status'    => $self->base_url."statuses/show/%s.xml",
		'update_status'  => $self->base_url."statuses/update.xml",
		'destroy_status' => $self->base_url."statuses/destroy/%s.xml",
		'replies'        => $self->base_url."statuses/replies.xml",
		'friends'        => $self->base_url."statuses/friends.xml",
		'followers'      => $self->base_url."statuses/followers.xml",
		'featured'       => $self->base_url."statuses/featured.xml",
		'show_users'     => $self->base_url."users/show/%s.xml",
	});
}

sub public_timeline{
	my $self = shift;
	return $self->request_api()->request('GET',$self->urls->{'public_timeline'},{},$self->username,$self->password)->parse_xml();
}

sub friend_timeline{
	my $self = shift;
	return $self->request_api()->request('GET',$self->urls->{'friend_timeline'},{},$self->username,$self->password)->parse_xml();
}

sub user_timeline{
	my $self = shift;
	return $self->request_api()->request('GET',$self->urls->{'user_timeline'},{},$self->username,$self->password)->parse_xml();
}

sub friends{
	my $self = shift;
	return $self->request_api()->request('GET',$self->urls->{'friends'},{},$self->username,$self->password)->parse_xml();
}

sub replies{
	my $self = shift;
	return $self->request_api()->request('GET',$self->urls->{'replies'},{},$self->username,$self->password)->parse_xml();
}

sub followers{
	my $self = shift;
	return $self->request_api()->request('GET',$self->urls->{'followers'},{},$self->username,$self->password)->parse_xml();
}


sub featured{
	my $self = shift;
	return $self->request_api()->request('GET',$self->urls->{'featured'},{},$self->username,$self->password)->parse_xml();
}


sub show_users{
	my $self = shift;
	my $id   = shift;
	return $self->request_api()->request('POST',sprintf($self->urls->{'show_users'},$id),{},$self->username,$self->password)->parse_xml();
}



sub show_status{
	my $self = shift;
	my $id   = shift;
	return $self->request_api()->request('POST',sprintf($self->urls->{'show_status'},$id),{},$self->username,$self->password)->parse_xml();
}

sub update_status{
	my $self = shift;
	my $status = shift;
	return $self->request_api()->request('POST',$self->urls->{'update_status'},{'status'=>$status},$self->username,$self->password)->parse_xml();
}

sub destroy_status{
	my $self = shift;
	my $id   = shift;
	return $self->request_api()->request('POST',sprintf($self->urls->{'destroy_status'},$id),{},$self->username,$self->password)->parse_xml();
}

1; 
