package WebService::Validator::Feed::W3C;
use strict;
use warnings;

use SOAP::Lite 0.65;
use LWP::UserAgent qw//;
use URI qw//;
use URI::QueryParam qw//;
use Carp qw//;
use HTTP::Request::Common;
use base qw/Class::Accessor/;

our $VERSION = "0.8";

__PACKAGE__->mk_accessors( qw/user_agent validator_uri/ );
__PACKAGE__->mk_ro_accessors( qw/response request_uri som success/ );

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    my $ua = shift;
    my $uri = shift;
    
    if (defined $ua) {
        
        # check whether it really is
        Carp::croak "$ua is not a LWP::UserAgent"
          unless UNIVERSAL::isa($ua, 'LWP::UserAgent');
        
        $self->user_agent($ua);
    } else {
        my $ua = LWP::UserAgent->new(agent => __PACKAGE__."/".$VERSION);
        $self->user_agent($ua);
    }

    if (defined $uri) {
        $self->validator_uri($uri);
    } else {
        $self->validator_uri("http://validator.w3.org/feed/check.cgi");
    }

    return $self;
}

sub _handle_response
{
    my $self = shift;
    my $res = shift;
    
    # internal or server errors...
    return 0 unless $res->is_success;
    
    local $_ = $res->content;
    
    my $som;
    eval { $som = SOAP::Deserializer->new->deserialize($_); };

    # Deserialization might fail if the response is not a legal
    # SOAP response, e.g., if the response is ill-formed... Not
    # sure how to make the reason for failure available to the
    # application, suggestions welcome.
    if ($@) {
        # Carp::carp $@;
        return 0;
    }
    
    # memorize the SOAP object model object
    $self->{'som'} = $som;
    
    # check whether this is really the Feed Validator responding
    if ($som->match("/Envelope/Body/feedvalidationresponse")) {
        $self->{'success'} = 1;
    }
    # if the response was a SOAP fault
    elsif ($som->match("/Envelope/Body/Fault")) {
        $self->{'success'} = 0; 
    }
        
    # return whether the response was successfully processed
    return $self->{'success'};
}

sub validate
{
    my $self = shift;
    my %parm = @_;
    my $uri = URI->new($self->validator_uri);
    my $ua = $self->user_agent;

    $self->{'success'} = 0;
    
    my $req;
    if (defined $parm{string}) {
        $req = POST $uri, [ rawdata => $parm{string}, manual  => 1, output  => "soap12" ];
    } elsif (defined $parm{uri}) {
        $uri->query_param(url => $parm{uri});
        $uri->query_param(output => "soap12");
        $req = GET $uri;
    } else {
        Carp::croak "you must supply a string/uri parameter\n";
    }

        
    # memorize request uri
    $self->{'request_uri'} = $uri;
    
    my $res = $ua->simple_request($req);
    
    # memorize response
    $self->{'response'} = $res;
    # print $res->as_string; # little printf debugging
    return $self->_handle_response($res);
}

sub is_valid
{
    my $self = shift;
    my $som = $self->som;
    
    # previous failure means the feed is invalid
    return 0 unless $self->success and defined $som;

    # fetch validity field in reponse
    my $validity = $som->valueof("/Envelope/Body/feedvalidationresponse/validity");
    
    # valid if m:validity is true
    return 1 if defined $validity and $validity eq "true";

    # else invalid
    return 0;
}

sub errors
{
    my $self = shift;
    my $som = $self->som;
    
    return () unless defined $som;
    return $som->valueof("//error");
}

sub warnings
{
    my $self = shift;
    my $som = $self->som;

    return () unless defined $som;
    return $som->valueof("//warning");
}

sub errorcount
{
    my $self = shift;
    my $som = $self->som;
    
    return () unless defined $som;
    return $som->valueof("//errorcount");
}

sub warningcount
{
    my $self = shift;
    my $som = $self->som;
    
    return () unless defined $som;
    return $som->valueof("//warningcount");
}



1;

__END__

=pod

=head1 NAME

WebService::Validator::Feed::W3C - Interface to the W3C Feed Validation service

=head1 SYNOPSIS

  use WebService::Validator::Feed::W3C;

  my $feed_url = "http://www.example.com";
  my $val = WebService::Validator::Feed::W3C->new;
  my $ok = $val->validate(uri => $feed_url);

  if ($ok and !$val->is_valid) {
      print "Errors:\n";
      printf "  * %s\n", $_->{message}
        foreach $val->errors
  }

=head1 DESCRIPTION

This module is an  interface to the W3C Feed Validation online service 
L<http://validator.w3.org/feed/>, based on its SOAP 1.2 support. 
It helps to find errors in RSS or Atom feeds.

The following methods are available:

=over 4

=item my $val = WebService::Validator::Feed::W3C->new

=item my $val = WebService::Validator::Feed::W3C->new($ua)

=item my $val = WebService::Validator::Feed::W3C->new($ua, $url)

Creates a new WebService::Validator::Feed::W3C object. A custom
L<LWP::UserAgent> object can be supplied which is then used for HTTP
communication with the W3C Feed Validation service. $url is the URL of the Feed
Validator, C<http://validator.w3.org/feed/check.cgi> by default.

=item my $success = $val->validate(%params)

Validate a feed takes C<%params> as defined below. Either C<string>
or C<uri> must be supplied. Returns a true value if the validation succeeded
(regardless of whether the feed contains errors).

=over 4

=item string => $feed_string

An atom or RSS feed, as a string. It is currently unlikely that validation will work
if the string is not a legal UTF-8 string. If a string is specified, the C<uri>
parameter will be ignored. Note that C<GET> will be used to pass the string
to the Validator, it might not work with overly long strings.

=item uri => $feed_uri

The location of an RSS/Atom feed

=back

=item my $success = $val->success

Same as the return value of C<validate()>.

=item my $is_valid = $val->is_valid

Returns a true value if the last attempt to C<validate()> succeeded and the
validator reported no errors in the feed.

=item my @errors = $val->errors

Returns a list with information about the errors found for the
feed. An error is a hash reference; the example in the
synopsis would currently return something like

  ( {
          type -> 'MissingDescription',
          line => '23',
          column => '0',
          text => 'Missing channel element: description',
          element =>description,
          parent =>channel,
  } )


=item my @warnings = $val->warnings

Returns a list with information about the warnings found for the
feed

@@example

=item my $ua = $val->user_agent

=item my $ua = $val->user_agent($new_ua)

The L<LWP::UserAgent> object you supplied to the constructor or a
custom object created at construction time you can manipulate.

  # set timeout to 30 seconds
  $val->user_agent->timeout(30);
  
You can also supply a new object to replace the old one.

=item my $uri = $val->validator_uri

=item my $uri = $val->validator_uri($validator_uri)

Gets or sets the URI of the validator. If you did not specify a
custom URI, C<http://validator.w3.org/feed/check.cgi> by
default.

=item my $response = $val->response

The L<HTTP::Response> object returned from the last request. This is
useful to determine why validation might have failed.

  if (!$val->validate(string => $feed_string)) {
    if (!$val->response->is_success) {
      print $val->response->message, "\n"
    }
  }

=item my $uri = $val->request_uri

The L<URI> object used for the last request.

=item my $som = $val->som

The L<SOAP::SOM> object for the last successful deserialization, check the
return value of C<validate()> or C<success()> before using the object.

=back


=head1 NOTE

Please remember that the Feed Validation service is a shared resource,
so do not abuse it: you should make your scripts sleep between requests.


=head1 AUTHOR

olivier Thereaux <ot@w3.org>

Based on the WebService::Validator::CSS::W3C module
by Bjoern Hoehrmann <bjoern@hoehrmann.de> et.al.
 
This module is licensed under the same terms as Perl itself.

=cut
