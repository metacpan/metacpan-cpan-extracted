package Tinder::API;
use LWP::UserAgent;
use HTTP::Request::Common qw{ POST };
use HTTP::Headers;
use Data::Dumper qw(Dumper);
use WWW::Mechanize;
=head1 NAME

B<Tinder::API> - Unofficial internal Tinder's API calls.

=head1 SYNOPSIS

	C<< my $API= new Tinder::API('facebookAuthToken',"Id"); >>

=head1 DESCRIPTION

This module was orginally the first Perl library to interract with Tinder app. As you may know, Tinder uses a series of non encrypted API calls in order to make the client-server possible. Those calls are greatly documented in -L<https://gist.github.com/rtt/10403467> repo. You can use Fiddler , install the trust certificate on your mobile device and use your Fiddler sniffer as a proxy for all traffic. Then you will get more or less the same pattern as the repo above. 
In the current library, I aim to provide an easy access to the calls.
Please note that you will need a FaceBook Authentication Token for Tinder::API to work!
You can get it by going on -L<https://www.facebook.com/dialog/oauth?client_id=464891386855067&redirect_uri=https://www.facebook.com/connect/login_success.html&scope=basic_info,email,public_profile,user_about_me,user_activities,user_birthday,user_education_history,user_friends,user_interests,user_likes,user_location,user_photos,user_relationship_details&response_type=token>. 

=head2 Methods

=over 12

=item C<new>

Returns a new Tinder::API object

=over 12

=item C<_facebookAuthToken>

The FaceBook Authentication Token for Tinder app. Check in the description on how to get it.

=item C<_Id>

A Facebook Id associated with the token.

=back

=item C<auth>

Takes a facebookAuthToken and a corresponding Id and returns a tinder X-Auth-Token.
C<< my XAUTHTOKEN=$API->auth() >>
Please note that this is an internal method and is already called in the constructor B<new>.

=item C<relocate>

Takes two coordinates (lat,long) and updates your coordinates on Tinder;
C<< $API->relocate(0.00000,0.00000) >>
B<NOTE> Sometimes Tinder spits out I<Not significant change> for your location. This means in most cases that you have to feed it a pair with more distance to the old coordinates.

=item C<getRecs>

Returns a list of recommendations from Tinder;
C<< my $response=$API->getRecs(); >>

=item C<getUser>

Takes a TinderId of a user (valid) and returns all information about him/her;
C<< my $reponse=$API->getUser($id); >>

=item C<sendMessage>

Takes a TinderId of a user (valid) and the body of a message, and sends the message to the give TinderId;
C<< $API->sendMessage($id,$message); >>

=item C<getUpdates>

Returns a list of Tinder updates;
C<< my $reponse=$API->getUpdates(); >>

=item C<likeOrPass>

Takes a TinderId of a user (valid) and a decision (like or pass him/her).
C<< $API->likeOrPass($id,$decision); >>

=item C<getFbToken>

Returns the current Facebook token being used;
C<< my $token=$API->getFbToken(); >>

=item C<getId>

Returns the current Facebook id being used;
C<< my $id=$API->getId(); >>

=back

=head1 LICENSE

Distributed according to GNU GPL and CPAN Terms and Conditions.
You may re-use and publish the code, but you have to mention the original AUTHOR and CPAN repo.
You may NOT sell this module.

=head1 AUTHOR

ArtificialBreeze - L<http://github.com/ArtificialBreeze> -L<https://metacpan.org/author/ArtificialBreeze>

=head1 SEE ALSO

L<perlpod>, L<perlpodspec>

=cut
sub new
{
	my $class =shift;
	my $self=
	{
		_Token => shift,
		_Id => shift,
	};
	my $object=bless $self,$class;
	$object->auth($self->{_Token});
	return $object;
}
	my $ua=new LWP::UserAgent(ssl_opts => { verify_hostname => 1 });
	my $auth_headers = HTTP::Headers->new(
	'Accept-Language'=> 'en;q=1, ru;q=0.9',
	'Accept-Encoding'=> 'gzip, deflate',
	'User-Agent'=> 'Tinder/4.1.4 (iPhone; iOS 8.0; Scale/2.00)',
	'os_version'=> '800000',
	'Accept'=> '*/*',
	'platform'=> 'ios',
	'Content-Type'=> 'application/json; charset=utf-8',
	'Connection'=> 'keep-alive',
	'Proxy-Connection'=> 'keep-alive',
	'Content-Length'=> '329',
	'app-version'=> '218',
	);
	$ua->default_headers($auth_headers);
sub auth()
{
	my $self = shift;
	my $Token = $self->{_Token};
	my $Id = $self->{_Id};
	my $url='https://api.gotinder.com/auth';
	my $request = POST( $url, [ 'facebook_token' => $Token, 'facebook_id' => $Id ,'locale'=>'en' ] );
	my @json=split /:/, $ua->request($request)->as_string();
	for(my $i=0;$i< scalar(@json);$i++)
	{
		if ($json[$i] =~ /token/)
		{
			 $self->{_TinderToken}=$1 if $json[$i+1] =~ /"(.+?)"/;
			last;
		}
	}
	my $req_headers = HTTP::Headers->new(
	'X-Auth-Token' => $self->{_TinderToken},
	'Accept-Language'=> 'en;q=1, ru;q=0.9',
	'Accept-Encoding'=> 'gzip, deflate',
	'User-Agent'=> 'Tinder/4.1.4 (iPhone; iOS 8.0; Scale/2.00)',
	'os_version'=> '800000',
	'Accept'=> '*/*',
	'platform'=> 'ios',
	'Content-Type'=> 'application/json; charset=utf-8',
	'Connection'=> 'keep-alive',
	'Proxy-Connection'=> 'keep-alive',
	'Content-Length'=> '329',
	'app-version'=> '218',
	);
	$ua->default_headers($req_headers);
	return 0;
}
sub relocate()
{
	my $self=shift;
	my $lat=shift;
	my $lon=shift;
	my $TinderToken=$self->{_TinderToken};
	my $url='https://api.gotinder.com/user/ping';
	my $request = POST( $url, [ "lat" => $lat, "lon" => $lon] );
	return $ua->request($request)->as_string();
}
sub getRecs()
{
	my $self=shift;
	my $lat=shift;
	my $lon=shift;
	my $url='https://api.gotinder.com/user/recs';
	return $ua->get($url)->as_string();
}
sub getUser()
{
	my $self=shift;
	my $userId=shift;
	my $url='https://api.gotinder.com/user/'.$userId;
	return $ua->get($url)->as_string();
}
sub sendMessage()
{
	my $self=shift;
	my $targetId=shift;
	my $message=shift;
	my $url="https://api.gotinder.com/user/matches/$targetId";
	my $request = POST( $url, [ "message" => $message] );
	return $ua->request($request)->as_string();
}	
sub getUpdates()
{
	my $self=shift;
	my $url='https://api.gotinder.com/updates';
	return $ua->get($url)->as_string();
}
sub likeOrPass()
{
	my $self=shift;
	my $targetId=shift;
	my $decision=shift;
	my $url="https://api.gotinder.com/$decision/$targetId";
	return $ua->get($url)->as_string();
}
sub getFbToken()
{
	my $self=shift;
	return $self->{_Token};
}
sub getId()
{
	my $self=shift;
	return $self->{_Id};
}
1;