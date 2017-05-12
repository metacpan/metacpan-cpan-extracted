package WebService::RequestAPI::HTTPRequestAPI;
use strict;
use LWP::UserAgent;
use utf8;
use CGI::Util qw(escape unescape);
use base qw(WebService::RequestAPI::AbstractRequestAPI);
binmode STDOUT, ":utf8";

sub _request{
	my $self   = shift;
	my $method = shift;
	my $url    = shift;
	my $args   = shift;
	my $username   = shift;
	my $password   = shift;

	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0');
	my $req;
	if(uc($method) eq 'GET'){
		$req = HTTP::Request->new(GET => $url.'?'._create_url($args));
	}
	elsif(uc($method) eq 'POST'){
		$req = HTTP::Request->new(POST => $url);
		$req->content_type('application/x-www-form-urlencoded');
		$req->content(_create_url($args));
	}
	else{
		die "none method";
	}

	if($username and $password){
		$req->authorization_basic($username, $password);
	}

	$self->result($ua->request($req)->content);

	return $self;
}



sub _create_url{
	my $args = shift;
	my $url="";
	foreach my $key (keys %{$args}){
		$url .= $key."=".url_encode($args->{$key})."&";
	}
	return $url;
}

sub url_encode{
	my $URLencode=shift;
	return escape($URLencode);
}

sub url_decode{
	my $URLdecode=shift;
	$URLdecode=~    s/%([A-Fa-f\d]{2})/chr hex $1/eg; 
	return $URLdecode;
}

1; 
