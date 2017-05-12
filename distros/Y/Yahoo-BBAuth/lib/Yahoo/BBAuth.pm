package Yahoo::BBAuth;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Carp;
use CGI;
use URI;
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);
use JSON;

our $VERSION = '0.50';

__PACKAGE__->mk_accessors(qw/
    appid secret userhash appdata timeout token WSSID
    cookie access_credentials_error sig_validation_error
/);

my $WSLOGIN_PREFIX = 'https://api.login.yahoo.com/WSLogin/V1/';
my $JSON_RPC_ENDPOINT = 'http://mail.yahooapis.com/ws/mail/v1.1/jsonrpc';

sub new {
    my ($class, %param) = @_;
    croak('appid and secret required')
        if !exists $param{appid} or !exists $param{secret};
    bless {
        appid  => $param{appid},
        secret => $param{secret},
    }, $class;
}

sub auth_url {
    my ($self, %param) = @_;
    my $url = URI->new($WSLOGIN_PREFIX . 'wslogin');
    my %query = (appid => $self->appid);
    $query{appdata} = $param{appdata} if exists $param{appdata};
    $query{send_userhash} = 1 if exists $param{send_userhash};
    $url->query_form(%query);
    $self->_create_auth_url($url);
}

sub _create_auth_url {
    my ($self, $url) = @_;
    unless (ref $url) { # not URI object
        $url = URI->new($url);
    }
    my %query = $url->query_form;
    $url->query_form([%query, (ts => time)]);
    my $sig = md5_hex($url->path_query . $self->secret);
    # sig must be last
    $url->as_string . "&sig=$sig";
}

sub validate_sig {
    my ($self, %param) = @_;
    my $cgi = CGI->new;
    $self->userhash($cgi->param('userhash')) if defined $cgi->param('userhash');
    $self->appdata($cgi->param('appdata'))   if defined $cgi->param('appdata');
    my $ts  = exists $param{ts}  ? $param{ts}  : $cgi->param('ts');
    my $sig = exists $param{sig} ? $param{sig} : $cgi->param('sig');
    my ($relative_url, $get_sig) = $ENV{'REQUEST_URI'} =~ /^(.+)&sig=(\w{32})$/;
    unless (defined $get_sig) {
        $self->{sig_validation_error} = "Invalid url may have been passed - relative_url:".$relative_url;
        return 0;
    }
    if ($get_sig ne $sig) {
        $self->{sig_validation_error} = "Invalid sig may have been passed:". $get_sig . $sig;
        return 0;
    }
    my $current_time = time;
    my $clock_skew = abs(time - $ts);
    if ($clock_skew >= 600) {
        $self->{sig_validation_error} = "Invalid timestamp - clock_skew is $clock_skew seconds, current time is $current_time, ts is $ts";
        return 0;
    }
    my $sig_input = $relative_url . $self->{secret};
    my $calculated_sig = md5_hex($sig_input);
    if ($calculated_sig eq $sig) {
        return 1;
    } else {
        $self->{sig_validation_error} = "calculated_sig was $calculated_sig, supplied sig was $sig, sig input was $sig_input";
        return 0;
    }
}

sub _get_access_credentials {
    my $self = shift;
    my $url = $self->_access_url;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->get($url);
    if ($res->is_error) {
        $self->{access_credentials_error} = $res->status_line;
        return 0;
    }
    my $content = $res->content;
    if ($content =~ m!<ErrorCode>(.+)</ErrorCode>!) {
        $self->{access_credentials_error} = "Error code returned in XML response: $1";
        return 0;
    }
    if ($content =~ /(Y=.*)/) {
        $self->cookie($1);
    } else {
        $self->{access_credentials_error} = 'No cookie found';
        return 0;
    }
    if ($content =~ m!<WSSID>(.+)</WSSID>!) {
        $self->WSSID($1);
    } else {
        $self->{access_credentials_error} = 'No WSSID found';
        return 0;
    }
    if ($content =~ m!<Timeout>(.+)</Timeout>!) {
        $self->timeout($1);
    } else {
        $self->{access_credentials_error} = 'No timeout found';
        return 0;
    }
    return 1;
}

sub _access_url {
    my $self = shift;
    unless (defined $self->{token}) {
        my $cgi = CGI->new;
        $self->token($cgi->param('token'));
    }
    my $url = URI->new($WSLOGIN_PREFIX. 'wspwtoken_login');
    $url->query_form(token => $self->{token}, appid => $self->{appid});
    return $self->_create_auth_url($url);
}

sub _create_auth_ws_url {
    my ($self, $url) = @_;
    if (!defined($self->{cookie})) {
        if (!$self->_get_access_credentials) {
            return 0;
        }
    }
    unless (ref $url) {
        $url = URI->new($url);
    }
    $url->query_form(
        WSSID => $self->{WSSID},
        appid => $self->{appid},
    );
    return $url->as_string;
}

sub auth_ws_get_call {
    my ($self, $url) = @_;
    $self->_auth_ws_call($url, 'get');
}

sub auth_ws_post_call {
    my ($self, $url) = @_;
    $self->_auth_ws_call($url, 'post');
}

sub _auth_ws_call {
    my ($self, $url, $method) = @_;
    $url = $self->_create_auth_ws_url($url);
    if (!$url) {
        return 0;
    }
    my $wscall = LWP::UserAgent->new;
    $wscall->default_headers->push_header('Cookie' => $self->{cookie});
    my $res = $wscall->$method($url);
    if ($res->is_error) {
        $self->{access_credentials_error} = $res->status_line;
        return 0;
    }
    return $res->content;
}

sub make_jsonrpc_call {
    my ($self, $method, $params) = @_;
    if (!$self->_get_access_credentials) {
        return 0;
    }

    my $thecall = { params => $params, method =>  $method  };
    my $jsonclass = new JSON;
    my $json = $jsonclass->objToJson($thecall);

    my $url = $JSON_RPC_ENDPOINT . '?appid=' . $self->{appid} . '&WSSID=' . $self->{WSSID};

    my $req = HTTP::Request->new(POST => $url, HTTP::Headers->new, $json); 
    $req->content_type('application/json'); 
    $req->content_length(length $json); 
    $req->header('Cookie' => $self->{cookie});

    my $res = LWP::UserAgent->new->request($req); 

    if ($res->is_error) {
        $self->{access_credentials_error} = $res->status_line;
        return 0;
    }

    return $jsonclass->jsonToObj($res->content);
}

1;
__END__

=head1 NAME

Yahoo::BBAuth - Perl interface to the Yahoo! Browser-Based Authentication.

=head1 SYNOPSIS

      my $bbauth = Yahoo::BBAuth->new(
          appid  => $appid,
          secret => $secret,
      );
      # Get your appid and secret by registering your application here:
      # https://developer.yahoo.com/wsregapp/index.php
      # Create an authentication link
      printf '<a href="%s">Click here to authorize</a>', $bbauth->auth_url; 
      # You can include some application data or return a user hash using optional params:
      printf '<a href="%s">Click here to authorize</a>', $bbauth->auth_url(
          send_userhash  => '1',
          appdata => 'someappdata',
          );  
      # After the user authenticates successfully, Yahoo returns the user to the page you
      # dictated when you signed up. To verify whether authentication succeeded, you need to
      # validate the signature:
      if (!$bbauth->validate_sig()) {
      print '<h2>Authentication Failed. Error is: </h2>'.$bbauth->{sig_validation_error};
      exit(0);
      }
      # You can then make an authenticated web service call on behalf of the user
      # For Yahoo! Mail:
      my $json = $bbauth->make_jsonrpc_call('ListFolders', [{}] );
      if (!$json) {
            print '<h2>Web services call failed. Error is:</h2> '. $bbauth->{access_credentials_error};
            exit(0);
      }
      # For Yahoo! Photos:
      my $url = 'http://photos.yahooapis.com/V3.0/listAlbums?';
      my $xml = $bbauth->auth_ws_get_call($url);
      if (!$xml) {
          print '<h2>Web services call failed. Error is:</h2> '. $bbauth->{access_credentials_error};
          exit(0);
      }

=head1 DESCRIPTION

This module priovides an Object Oriented interface for Yahoo! Browser-Based Authentication.

This module is ported from the official PHP class which is located on this page: http://developer.yahoo.com/php

=head1 METHODS

=head2 new(appid => $appid, secret => $secret)

Returns an instance of this module.
You must set the your application id and shared secret.

=head2 auth_url(%param)

Create the Login URL used to fetch authentication credentials.
This is the first step in the browser authentication process.

You can set the %param to send_userhash and appdata if you need(optional).

The appdata typically a session id that Yahoo will transfer to the target application upon successful authentication.

If send_userhash set, the send_userhash=1 request will be appended to the request URL so that the userhash will be returned by Yahoo! after successful authentication.

=head2 validate_sig

Validates the signature returned by Yahoo's browser authentication services.

Returns false if the sig is invalid. Returns 0 if any error occurs.
If 0 is returned, $self->sig_validation_error should contain a string describing the error.

=head2 auth_ws_get_call($url)

Make an authenticated web services call using HTTP GET.
Returns response if successful, a string is returned containing the web service response which might be XML, JSON, or some other type of text.
If an error occurs, 0 is returned, and the error is stored in $self->access_credentials_error.

=head2 auth_ws_post_call($url)

Make an authenticated web services call using HTTP POST.

=head2 make_jsonrpc_call($method, $params)

Make an authenticated web services JSON-RPC call.

=head2 sig_validation_error

The error message when validate_sig fails.

=head2 access_credentials_error

The error message when auth_ws_get_call or auth_ws_post_call fail.

=head1 ACCESSORS

=over 4

=item appid

=item secret

=item userhash

=item appdata

=item timeout

=item token

=item WSSID

=item cookie

=back

=head1 AUTHORS

  Jiro Nishiguchi <jiro@cpan.org>
  Jason Levitt <jlevitt@yahoo-inc.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * http://developer.yahoo.com/auth/

=back

=cut
