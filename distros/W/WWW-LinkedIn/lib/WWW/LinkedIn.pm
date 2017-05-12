
package WWW::LinkedIn;

use strict;
use warnings 'all';
use Carp 'confess';
use Net::OAuth;
use LWP::UserAgent;
use HTTP::Request::Common;
use Digest::MD5 'md5_hex';
use Digest::HMAC_SHA1;
use MIME::Base64;

our $VERSION = '0.004';


sub new
{
  my ($class, %args) = @_;
  
  foreach(qw( consumer_key consumer_secret ))
  {
    confess "Required param '$_' was not provided"
      unless $args{$_};
  }# end foreach()
  
  return bless \%args, $class;
}# end new()

sub consumer_key        { shift->{consumer_key} }
sub consumer_secret     { shift->{consumer_secret} }
sub access_token        { @_ > 1 ? $_[0]->{access_token} = $_[1] : $_[0]->{access_token} }
sub access_token_secret { @_ > 1 ? $_[0]->{access_token_secret} = $_[1] : $_[0]->{access_token_secret} }


sub get_request_token
{
  my ($s, %args) = @_;

  foreach(qw( callback ))
  {
    confess "Required param '$_' was not provided"
      unless $args{$_};
  }# end foreach()
  
  $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

  my $nonce = md5_hex(time() * rand());
  my $timestamp = time();
  my $request = Net::OAuth->request("request token")->new(
    consumer_key      => $s->consumer_key,
    consumer_secret   => $s->consumer_secret,
    request_url       => 'https://api.linkedin.com/uas/oauth/requestToken',
    request_method    => 'POST',
    signature_method  => 'HMAC-SHA1',
    timestamp         => $timestamp,
    nonce             => $nonce,
    callback          => $args{callback},
  );
  $request->sign;
  my $res = LWP::UserAgent->new()->request(POST $request->to_url);
  my ($token) = $res->content =~ m{token\=([^&]+)}
    or confess "LinkedIn's API did not return a request token.  Instead, it returned this:\n" . $res->as_string;
  my ($token_secret) = $res->content =~ m{oauth_token_secret\=([^&]+)}
    or confess "LinkedIn's API did not return a request token secret.  Instead, it returned this:\n" . $res->as_string;
  
  return {
    token   => $token,
    secret  => $token_secret,
    url     => "https://www.linkedin.com/uas/oauth/authorize?oauth_token=$token",
  };
}# end get_request_token()


sub get_access_token
{
  my ($s, %args) = @_;
  
  foreach(qw( request_token request_token_secret verifier ))
  {
    confess "Required param '$_' was not provided"
      unless $args{$_};
  }# end foreach()

  $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
  my $nonce = md5_hex(time() * rand());
  my $timestamp = time();
  my $request = Net::OAuth->request("access token")->new(
    consumer_key      => $s->consumer_key,
    consumer_secret   => $s->consumer_secret,
    request_method    => 'POST',
    signature_method  => 'HMAC-SHA1',
    timestamp         => $timestamp,
    nonce             => $nonce,
    request_url       => 'https://api.linkedin.com/uas/oauth/accessToken',
    token             => $args{request_token},
    token_secret      => $args{request_token_secret},
    verifier          => $args{verifier},
  );
  $request->sign;
  my $req = POST 'https://api.linkedin.com/uas/oauth/accessToken';
  $req->header( Authorization => $request->to_authorization_header );
  my $res = LWP::UserAgent->new->request( $req );
  my ($access_token) = $res->content =~ m{oauth_token\=([^&]+)};
  my ($access_token_secret) = $res->content =~ m{oauth_token_secret\=([^&]+)};
  
  return {
    token   => $access_token,
    secret  =>  $access_token_secret,
  };
}# end get_access_token()


sub request
{
  my ($s, %args) = @_;
  
  foreach(qw( request_url ))
  {
    confess "Required param '$_' was not provided"
      unless $args{$_};
  }# end foreach()
  foreach(qw( access_token access_token_secret ))
  {
    confess "Required param '$_' not provided and not set manually"
      unless $args{$_} || exists $s->{$_};
  }# end foreach()

  $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
  my $nonce = md5_hex(time() * rand());
  my $timestamp = time();
  my $request = Net::OAuth->request("protected resource")->new(
    signature_method  => 'HMAC-SHA1',
    timestamp         => $timestamp,
    nonce             => $nonce,
    consumer_key      => $s->consumer_key,
    consumer_secret   => $s->consumer_secret,
    token             => $args{access_token} || $s->access_token,
    token_secret      => $args{access_token_secret} || $s->access_token_secret,
    request_method    => 'GET',
    request_url       => $args{request_url},
  );
  $request->sign;
  my $req = GET $args{request_url};
  $req->header( Authorization => $request->to_authorization_header );
  my $res = LWP::UserAgent->new->request( $req );  
  return $res->content;
}# end request()

1;# return true:

=pod

=head1 NAME

WWW::LinkedIn - Simple interface to the LinkedIn OAuth API

=head1 SYNOPSIS

=head2 Step 1

Get the Request Token and Request Token Secret

  <%
    use WWW::LinkedIn;
    my $li = WWW::LinkedIn->new(
      consumer_key    => $consumer_key,     # Your 'API Key'
      consumer_secret => $consumer_secret,  # Your 'Secret Key'
    );
    my $token = $li->get_request_token(
      callback  => "http://www.example.com/v1/login/linkedin/"
    );
    
    # Save $token->{token} and $token->{secret} for later:
    $Session->{request_token} = $token->{token};
    $Session->{request_token_secret} = $token->{secret};
  %>
  
  <!-- User must click on this link, login and "Authorize" your app to have access: -->
  <a href="<%= $token->{url} %>">Login to LinkedIn</a>

=head2 Step 2

After the user has authorized your app to have access to their account, they will be
redirected to the URL you specified in the C<callback> parameter from Step 1.

The URL will be given the parameter C<oauth_verifier> which you will need.

Perform the following in the URL that they are redirected to:

  use WWW::LinkedIn;
  
  my $li = WWW::LinkedIn->new(
    consumer_key          => $consumer_key,
    consumer_secret       => $consumer_secret,
  );
  my $access_token = $li->get_access_token(
    verifier              => $Form->{oauth_verifier}, # <--- This is passed to us in the querystring:
    request_token         => $Session->{request_token}, # <--- From step 1.
    request_token_secret  => $Session->{request_token_secret}, # <--- From step 1.
  );

=head2 Step 3

Now you can use the C<request> method to make 'protected resource' requests like this:

  # Get the user's own profile:
  my $profile_xml = $li->request(
    request_url         => 'https://api.linkedin.com/v1/people/~:(id,first-name,last-name,headline)',
    access_token        => $access_token->{token},
    access_token_secret => $access_token->{secret},
  );

Returns something like this:

  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <person>
    <id>XnMs6jaRm6</id>
    <first-name>John</first-name>
    <last-name>Drago</last-name>
    <headline>Master Hackologist</headline>
  </person>

  # Get a specific user's profile:
  my $profile_xml = $li->request(
    request_url         => 'https://api.linkedin.com/v1/people/id=XnMs6jaRm6:(id,first-name,last-name,headline)',
    access_token        => $access_token->{token},
    access_token_secret => $access_token->{secret},
  );

=head1 DESCRIPTION

This module provides a simple interface to the LinkedIn OAuth API.

The documentation on LinkedIn's website was unclear and required a couple days
of trial-and-error to make it all work.

=head1 ACKNOWLEDGEMENTS

Special thanks to:

=over 4

=item * Taylor Singletary who put together this SlideShare presentation:
L<http://www.slideshare.net/episod/linkedin-oauth-zero-to-hero>

=item * The authors of L<Net::OAuth>, L<Digest::HMAC_SHA1>, L<LWP::UserAgent> and L<Digest::MD5> without which this module would not be possible.

=head1 AUTHOR

John Drago C<< <jdrago_999 at yahoo.com> >>

Copyright 2011 - All rights reserved.

=head1 LICENSE

This software is Free software and may be used and redistributed under the same
terms as any version of perl itself.

=cut


