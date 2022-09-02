package Test2::Tools::HTTP;

use strict;
use warnings;
use 5.008001;
use LWP::UserAgent;
use parent qw( Exporter );
use Test2::API qw( context );
use Test2::Compare;
use Test2::Compare::Wildcard;
use Test2::Compare::Custom;
use Test2::Tools::HTTP::UA;
use Test2::Tools::HTTP::Apps;
use Test2::Tools::HTTP::Tx;
use URI;
use Carp ();

our %EXPORT_TAGS = (
  short => [qw(
    app_add req ua res code message content content_type charset content_length content_length_ok location location_uri tx headers header
  )],
);

our @EXPORT    = qw(
  http_request http_ua http_base_url psgi_app_add psgi_app_del http_response http_code http_message http_content http_tx http_is_success
  http_is_info http_is_success http_is_redirect http_is_error http_is_client_error http_is_server_error
  http_isnt_info http_isnt_success http_isnt_redirect http_isnt_error http_isnt_client_error http_isnt_server_error
  http_content_type http_content_type_charset http_content_length http_content_length_ok http_location http_location_uri
  http_headers http_header
  psgi_app_guard
);

our @EXPORT_OK = (
  @{ $EXPORT_TAGS{'short'} },
);

*ua      = \&http_ua;
*req     = \&http_request;
*res     = \&http_response;
*app_add = \&psgi_app_add;
*charset = \&http_content_type_charset;

foreach my $short (qw( code message content content_type content_length content_length_ok location location_uri tx header headers ))
{
  no strict 'refs';
  *{$short} = \&{"http_$short"};
}

# ABSTRACT: Test HTTP / PSGI
our $VERSION = '0.11'; # VERSION


my $tx;
my $apps = Test2::Tools::HTTP::UA->apps;
my $ua_wrapper;

sub http_request
{
  my($req, $check, $message) = @_;

  my %options;

  if(ref $req eq 'ARRAY')
  {
    ($req, %options) = @$req;
  }

  $req = $req->clone;

  my $url = URI->new_abs($req->uri, http_base_url());

  $message ||= "@{[ $req->method ]} @{[ $url ]}";

  my $ctx = context();
  my $ok = 1;
  my @diag;
  my $connection_error = 0;

  unless($apps->uri_to_app($req->uri))
  {
    if($req->uri =~ /^\//)
    {
      $req->uri(
        URI->new_abs($req->uri, $apps->base_url),
      );
    }
  }

  http_ua(); # sets $ua_wrapper if not already
  my $res = eval { $ua_wrapper->request($req, %options) };

  if(my $error = $@)
  {
    $ok = 0;
    $connection_error = "$error";
    push @diag, "$error";
    $res = eval { $error->res };
  }

  if(defined $res)
  {
    bless($res, 'Test2::Tools::HTTP::Tx::Response'),
  }

  if($ok && defined $check)
  {
    my $delta = Test2::Compare::compare($res, $check, \&Test2::Compare::strict_convert);
    if($delta)
    {
      $ok = 0;
      push @diag, $delta->diag->as_string;
    }
  }

  $ctx->ok($ok, $message, \@diag);
  $ctx->release;

  $tx = bless {
    req              => bless($req, 'Test2::Tools::HTTP::Tx::Request'),
    res              => $res,
    ok               => $ok,
    connection_error => $connection_error,
    location         => do {
      $res
        ? $res->header('Location')
          ? URI->new_abs($res->header('Location'), $res->base)
          : undef
        : undef;
    },
  }, 'Test2::Tools::HTTP::Tx';

  $ok;
}


sub http_response (&)
{
  Test2::Compare::build(
    'Test2::Tools::HTTP::ResponseCompare',
    @_,
  );
}


sub _caller
{
  my $i = 1;
  my @caller;
  while(@caller = caller $i)
  {
    last if $caller[0] ne __PACKAGE__;
    $i++;
  }
  @caller;
}

sub _build
{
  defined(my $build = Test2::Compare::get_build()) or Carp::croak "No current build!";
  Carp::croak "'$build' is not a Test2::Tools::HTTP::ResponseCompare"
    unless $build->isa('Test2::Tools::HTTP::ResponseCompare');

  my @caller = _caller;

  my $func_name = $caller[3];
  $func_name =~ s/^.*:://;
  Carp::croak "'$func_name' should only ever be called in void context"
    if defined $caller[5];

  ($build, file => $caller[1], lines => [$caller[2]]);
}

sub _add_call
{
  my($name, $expect, $context) = @_;
  $context ||= 'scalar';
  my($build, @cmpargs) = _build;
  $build->add_call(
    $name,
    Test2::Compare::Wildcard->new(
      expect => $expect,
      @cmpargs,
    ),
    undef,
    $context
  );
}

sub http_code ($)
{
  my($expect) = @_;
  _add_call('code', $expect);
}


sub http_message ($)
{
  my($expect) = @_;
  _add_call('message', $expect);
}


sub http_content ($)
{
  my($expect) = @_;
  my($build, @cmpargs) = _build;
  $build->add_http_check(
    sub {
      my($res) = @_;
      ($res->decoded_content || $res->content, 1);
    },
    [DREF => 'content'],
    Test2::Compare::Wildcard->new(
      expect => $expect,
      @cmpargs,
    )
  );
}


sub _T()
{
  my @caller = _caller;
  Test2::Compare::Custom->new(
    code     => sub { $_ ? 1 : 0 },
    name     => 'TRUE',
    operator => 'TRUE()',
    file     => $caller[1],
    lines    => [$caller[2]],
  );
}

sub http_is_info         { _add_call('is_info',         _T()) }
sub http_is_success      { _add_call('is_success',      _T()) }
sub http_is_redirect     { _add_call('is_redirect',     _T()) }
sub http_is_error        { _add_call('is_error',        _T()) }
sub http_is_client_error { _add_call('is_client_error', _T()) }
sub http_is_server_error { _add_call('is_server_error', _T()) }


sub _F()
{
  my @caller = _caller;
  Test2::Compare::Custom->new(
    code     => sub { $_ ? 0 : 1 },
    name     => 'TRUE',
    operator => 'TRUE()',
    file     => $caller[1],
    lines    => [$caller[2]],
  );
}

sub http_isnt_info         { _add_call('is_info',         _F()) }
sub http_isnt_success      { _add_call('is_success',      _F()) }
sub http_isnt_redirect     { _add_call('is_redirect',     _F()) }
sub http_isnt_error        { _add_call('is_error',        _F()) }
sub http_isnt_client_error { _add_call('is_client_error', _F()) }
sub http_isnt_server_error { _add_call('is_server_error', _F()) }


sub http_headers
{
  my($expect) = @_;
  my($build, @cmpargs) = _build;
  $build->add_http_check(
    sub {
      my($res) = @_;

      my @headers = $res->flatten;
      my %headers;
      while(@headers)
      {
        my($key, $val) = splice @headers, 0, 2;
        push @{ $headers{$key} }, $val;
      }
      $_ = join ',', @{$_} for values %headers;

      (\%headers, 1);
    },
    [DREF => 'headers'],
    Test2::Compare::Wildcard->new(
      expect => $expect,
      @cmpargs,
    ),
  );
}


sub http_header
{
  my($name, $expect) = @_;
  my($build, @cmpargs) = _build;
  $build->add_http_check(
    sub {
      my($res) = @_;
      my @values = $res->header($name);
      return (0,0) unless @values;
      if(ref($expect) eq 'ARRAY' || eval { $expect->isa('Test2::Compare::Array') })
      {
        return ([map { split /,/, $_ } @values], 1);
      }
      else
      {
        return (join(',',@values),1);
      }
    },
    [DREF => "header $name"],
    Test2::Compare::Wildcard->new(
      expect => $expect,
      @cmpargs,
    ),
  );
}


sub http_content_type
{
  my($expect) = @_;
  my($build, @cmpargs) = _build;
  $build->add_http_check(
    sub {
      my($res) = @_;
      my $content_type = $res->content_type;
      defined $content_type
        ? ($content_type, 1)
        : ($content_type, 0);
    },
    [DREF => 'header content-type'],
    Test2::Compare::Wildcard->new(
      expect => $expect,
      @cmpargs,
    )
  );
}

sub http_content_type_charset
{
  my($expect) = @_;
  my($build, @cmpargs) = _build;
  $build->add_http_check(
    sub {
      my($res) = @_;
      my $charset = $res->content_type_charset;
      defined $charset
        ? ($charset, 1)
        : ($charset, 0);
    },
    [DREF => 'header content-type charset'],
    Test2::Compare::Wildcard->new(
      expect => $expect,
      @cmpargs,
    )
  );
}

# TODO: header $key => $check
# TODO: cookie $key => $check ??


sub http_content_length
{
  my($check) = @_;
  _add_call('content_length', $check);
}


sub http_content_length_ok
{
  my($build, @cmpargs) = _build;

  $build->add_http_check(
    sub {
      my($res) = @_;

      (
        $res->content_length,
        1,
        Test2::Compare::Wildcard->new(
          expect => length($res->content),
          @cmpargs,
        ),
      )
    },
    [METHOD => 'content_length'],
    undef,
  );


}


sub http_location
{
  my($expect) = @_;
  my($build, @cmpargs) = _build;
  $build->add_http_check(
    sub {
      my($res) = @_;
      my $location = $res->header('Location');
      (
        $location,
        defined $location
      )
    },
    [DEREF => "header('Location')"],
    Test2::Compare::Wildcard->new(
      expect => $expect,
      @cmpargs,
    ),
  );
}

sub http_location_uri
{
  my($expect) = @_;
  my($build, @cmpargs) = _build;
  $build->add_http_check(
    sub {
      my($res) = @_;
      my $location = $res->header('Location');
      defined $location
        ? (URI->new_abs($location, $res->base), 1)
        : (undef, 0);
    },
    [DEREF => "header('Location')"],
    Test2::Compare::Wildcard->new(
      expect => $expect,
      @cmpargs,
    ),
  );
}


sub http_tx
{
  $tx;
}


sub http_base_url
{
  my($new) = @_;
  $apps->base_url($new);
}


sub http_ua
{
  my($new) = @_;

  if( (!defined $ua_wrapper) && !$new)
  {
    $new = LWP::UserAgent->new;
    $new->env_proxy;
    $new->cookie_jar({});
  }

  if($new)
  {
    $ua_wrapper = Test2::Tools::HTTP::UA->new($new);
    $ua_wrapper->instrument;
  }

  $ua_wrapper->ua;
}


sub psgi_app_add
{
  my($url, $app) = @_ == 1 ? (http_base_url, @_) : (@_);
  $apps->add_psgi($url, $app);
  return;
}


sub psgi_app_del
{
  my($url) = @_;
  $url ||= http_base_url;
  $apps->del_psgi($url);
  return;
}


sub psgi_app_guard
{
  my(%h) = @_ == 1 ? (http_base_url, @_) : (@_);

  Carp::croak "psgi_app_guard called in void context" unless defined wantarray;  ## no critic (Community::Wantarray)

  my %save;
  my $apps = Test2::Tools::HTTP::Apps->new;

  foreach my $url (keys %h)
  {
    my $old = $apps->uri_to_app($url) || 1;
    my $new = $h{$url};
    $save{$url} = $old;
    $apps->del_psgi($url) if ref $old;
    $apps->add_psgi($url => $new);
  }

  Test2::Tools::HTTP::Guard->new(%save);
}

package Test2::Tools::HTTP::Guard;

sub new
{
  my($class, %save) = @_;
  bless \%save, $class;
}

sub restore
{
  my($self) = @_;

  my $apps = Test2::Tools::HTTP::Apps->new;

  foreach my $url (keys %$self)
  {
    my $app = $self->{$url};
    $apps->del_psgi($url);
    $apps->add_psgi($url => $app)
      if ref $app;
  }
}

sub DESTROY
{
  my($self) = @_;
  $self->restore;
}

package Test2::Tools::HTTP::ResponseCompare;

use parent 'Test2::Compare::Object';

sub name { '<HTTP::Response>' }
sub object_base { 'HTTP::Response' }

sub init
{
  my($self) = @_;
  $self->{HTTP_CHECK} ||= [];
  $self->SUPER::init();
}

sub add_http_check
{
  my($self, $cb, $id, $expect) = @_;

  push @{ $self->{HTTP_CHECK} }, [ $cb, $id, $expect ];
}

sub deltas
{
  my $self = shift;
  my @deltas = $self->SUPER::deltas(@_);
  my %params = @_;

  my ($got, $convert, $seen) = @params{qw/got convert seen/};

  foreach my $pair (@{ $self->{HTTP_CHECK} })
  {
    my($cb, $id, $check) = @$pair;

    my($val, $exists, $alt_check) = eval { $cb->($got) };
    my $error = $@;

    $check = $alt_check if defined $alt_check;

    $check = $convert->($check);

    if($error)
    {
      push @deltas => $self->delta_class->new(
        verified  => undef,
        id        => $id,
        got       => undef,
        check     => $check,
        exception => $error,
      );
    }
    else
    {
      push @deltas => $check->run(
        id      => $id,
        convert => $convert,
        seen    => $seen,
        exists  => $exists,
        $exists ? ( got => $val eq '' ? '[empty string]' : $val ) : (),
      );
    }
  }

  @deltas;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::HTTP - Test HTTP / PSGI

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::HTTP;
 use HTTP::Request::Common;
 
 psgi_add_app sub { [ 200, [ 'Content-Type' => 'text/plain;charset=utf-8' ], [ "Test Document\n" ] ] };
 
 # Internally test the app from within the .t file itself
 http_request(
   # if no host/port/protocol is given then
   # the default PSGI app above is assumed
   GET('/'),
   http_response {
 
     http_code 200;
 
     # http_response {} is a subclass of object {}
     # for HTTP::Response objects only, so you can
     # also use object {} style comparisons:
     call code => 200;
 
     http_content_type match qr/^text\/(html|plain)$/;
     http_content_type_charset 'UTF-8';
     http_content match qr/Test/;
   }
 );
 
 use Test2::Tools::JSON::Pointer;
 
 # test an external website
 http_request(
   # you can also test against a real HTTP server
   GET('http://example.test'),
   http_response {
     http_is_success;
     # JSON pointer { "key":"val" }
     http_content json '/key' => 'val';
   }
 );
 
 done_testing;

with short names:

 use Test2::Tools::HTTP ':short';
 use HTTP::Request::Common;
 
 app_add { [ 200, [ 'Content-Type => 'text/plain' ], [ "Test Document\n" ] ] };
 
 req (
   GET('/'),
   res {
     code 200;
     message 'OK';
     content_type 'text/plain';
     content match qr/Test/;
   },
 );
 
 done_testing;

=head1 DESCRIPTION

This module provides an interface for testing websites and PSGI based apps with a L<Test2> style comparisons interface.
You can specify a PSGI app with a URL and responses from that URL will automatically be routed to that app, without
having to actually need a separate server process.  Requests to URLs that haven't been registered will be made
against the actual networks servers as appropriate.  You can also use the user agent returned from C<http_ua> to
make requests against PSGI apps.  L<LWP::UserAgent> is the user agent used by default, but it is possible to use
others assuming an appropriate user agent wrapper class is available (L<Test2::Tools::HTTP::UA>).

By default it uses long function names with either a C<http_> or C<psgi_app_> prefix.  The intent is to make the module
usable when you are importing lots of symbols from lots of different testing tools while reducing the chance of name
collisions.  You can instead import C<:short> which will give you the most commonly used tools with short names.
The short names are indicated below in square brackets, and were chosen to not conflict with L<Test2::V0>.

=head1 FUNCTIONS

=head2 http_request [req]

 http_request($request);
 http_request($request, $check);
 http_request($request, $check, $message);
 http_request([$request, %options], ... );

Make a HTTP request.  If there is a client level error then it will fail immediately.  Otherwise you can use a
C<object {}> or C<http_request> comparison check to inspect the HTTP response and ensure that it matches what you
expect.  By default only one request is made.  If the response is a forward (has a C<Location> header) you can
use the C<http_tx->location> method to make the next request.

Options:

=over 4

=item follow_redirects

This allows the user agent to follow redirects.

=back

=head2 http_response [res]

 my $check = http_response {
   ... # object or http checks
 };

This is a comparison check specific to HTTP::Response objects.  You may include these subchecks:

=head3 http_code [code]

 http_response {
   http_code $check;
 };

The HTTP status code should match the given check.

=head3 http_message [message]

 http_response {
   http_message $check;
 };

The HTTP status message ('OK' for 200, 'Not Found' for 404, etc) should match the given check.

=head3 http_content [content]

 http_response {
   http_content $check;
 };

The response body content.  Attempt to decode using the L<HTTP::Message> method C<decoded_content>, otherwise use the raw
response body.  If you want specifically the decoded content or the raw content you can use C<call> to specifically check
against them:

 http_response {
   call content => $check1;
   call decoded_content => $check2;
 };

=head3 http_is_info, http_is_success, http_is_redirect, http_is_error, http_is_client_error, http_is_server_error

 http_response {
   http_is_info;
   http_is_success;
   http_is_redirect;
   http_is_error;
   http_is_client_error;
   http_is_server_error;
 };

Checks that the response is of the specified type.  See L<HTTP::Status> for the meaning of each of these.

=head3 http_isnt_info, http_isnt_success, http_isnt_redirect, http_isnt_error, http_isnt_client_error, http_isnt_server_error

 http_response {
   http_isnt_info;
   http_isnt_success;
   http_isnt_redirect;
   http_isnt_error;
   http_isnt_client_error;
   http_isnt_server_error;
 };

Checks that the response is NOT of the specified type.  See L<HTTP::Status> for the meaning of each of these.

=head3 http_headers [headers]

 http_response {
   http_headers $check;
 };

Check the HTTP headers as converted into a Perl hash.  If the same header appears twice, then the values are joined together
using the C<,> character.  Example:

 http_request(
   GET('http://example.test'),
   http_response {
     http_headers hash {
       field 'Content-Type' => 'text/plain;charset=utf-8';
       etc;
     };
   },
 );

=head3 http_header [header]

 http_response {
   http_header $name, $check;
 };

Check an HTTP header against the given check.  Can be used with either scalar or array checks.  In scalar mode,
any list values will be joined with C<,> character.  Example:

 http_request(
   GET('http://example.test'),
   http_response {
 
     # single value
     http_header 'X-Foo', 'Bar';
 
     # list as scalar, will match either:
     #     X-Foo: A
     #     X-Foo: B
     # or
     #     X-Foo: A,B
     http_header 'X-Foo', 'A,B';
 
     # list mode, with an array ref:
     http_header 'X-Foo', ['A','B'];
 
     # list mode, with an array check:
     http_header 'X-Foo', array { item 'A'; item 'B' };
   },
 );

=head3 http_content_type [content_type], http_content_type_charset [charset]

 http_response {
   http_content_type $check;
   http_content_type_charset $check;
 };

Check that the C<Content-Type> header matches the given checks.  C<http_content_type> checks just the content type, not the character set, and
C<http_content_type_charset> matches just the character set.  Hence:

 http_response {
   http_content_type 'text/html';
   http_content_type_charset 'UTF-8';
 };

=head3 http_content_length [content_length]

 http_response {
   http_content_length $check;
 };

Check that the C<Content-Length> header matches the given check.

=head3 http_content_length_ok [content_length_ok]

 http_response {
   http_content_length_ok;
 };

Checks that the C<Content-Length> header matches the actual length of the content.

=head3 http_location [location], http_location_uri [location_uri]

 http_response {
   http_location $check;
   http_location_uri $check;
 };

Check the C<Location> HTTP header.  The C<http_location_uri> variant converts C<Location> to a L<URI> using the base URL of the response
so that it can be tested with L<Test2::Tools::URL>.

=head2 http_tx [tx]

 my $req    = http_tx->req;
 my $res    = http_tx->res;
 my $bool   = http_tx->ok;
 my $string = http_tx->connection_error;
 my $url    = http_tx->location;
 http_tx->note;
 http_tx->diag;

This returns the most recent transaction object, which you can use to get the last request, response and status information
related to the most recent C<http_request>.

=over 4

=item http_tx->req

The L<HTTP::Request> object.

=item http_tx->res

The L<HTTP::Response> object.

Warning: Depending on the user agent class in use, in the case of a connection error, this may be either a synthetic
response or not defined.  For example L<LWP::UserAgent> produced a synthetic response, while L<Mojo::UserAgent> does not
produce a response in the event of a connection error.

=item http_tx->ok

True if the most recent call to C<http_request> passed.

=item http_tx->connection_error.

The connection error if any from the most recent C<http_reequest>.

=item http_tx->location

The C<Location> header converted to an absolute URL, if included in the response.

=item http_tx->note

Send the request, response and ok to Test2's "note" output.  Note that the message bodies may be decoded, but
the headers will not be modified.

=item http_tx->diag

Send the request, response and ok to Test2's "diag" output.  Note that the message bodies may be decoded, but
the headers will not be modified.

=back

=head2 http_base_url

 http_base_url($url);
 my $url = http_base_url;

Sets the base URL for all requests made by C<http_request>.  This is used if you do not provide a fully qualified URL.  For example:

 http_base_url 'http://httpbin.org';
 http_request(
   GET('/status/200') # actually makes a request against http://httpbin.org
 );

If you use C<psgi_add_app> without a URL, then this is the URL which will be used to access your app.  If you do not specify a base URL,
then localhost with a random unused port will be picked.

=head2 http_ua [ua]

 http_ua(LWP::UserAgent->new);
 my $ua = http_ua;

Gets/sets the L<LWP::UserAgent> object used to make requests against real web servers.  For tests against a PSGI app, this will NOT be used.
If not provided, the default L<LWP::UserAgent> will call C<env_proxy> and add an in-memory cookie jar.

=head2 psgi_app_add [app_add]

 psgi_app_add $app;
 psgi_app_add $url, $app;

Add the given PSGI app to the testing environment.  If you provide a URL, then requests to that URL will be intercepted by C<http_request> and routed to the app
instead of making a real HTTP request via L<LWP::UserAgent>.

=head2 psgi_app_del

 psgi_app_del;
 psgi_app_del $url;

Remove the app at the given (or default) URL.

=head2 psgi_app_guard

 my $guard = psgi_app_guard $app;
 my $guard = psgi_app_guard $url, $app;
 my $guard = psgi_app_guard $url, $app, ...;

Similar to C<psgi_app_add> except a guard object is returned.
When the guard object falls out of scope, the old apps are
restored automatically.  The intent is for this to be used
in subtests or other scoped blocks to temporarily override
the internet or other PSGI apps.

 psgi_add_add 'http://foo.test' => sub { ... };
 
 subtest 'mysubtest' => sub {
   my $guard = psgi_app_guard
     'http://foo.test' => sub { ... },
     'https://www.google.com' => sub { ... };
 
   http_request
     # gets the foo.test for this scope.
     GET('http://foo.test'),
     http_response {
       ...
     };
 
   http_request
     # gets the mock google
     GET('https://www.google.com'),
     http_response {
       ...;
     };
 };
 
 http_request
   # gets the original foo.test mock
   GET('http://foo.test'),
   http_response {
     ...;
   };
 
 http_request
   # gets the real google
   GET('https://www.google.com'),
   http_response {
     ...;
   };

Because calling a function that returns a guard in void context
is usually a mistake, this function will throw an exception if you
attempt to call it in void context.

=head1 SEE ALSO

=over 4

=item L<Test::Mojo>

This is a very capable web application testing module.  Definitely worth checking out, even if you aren't developing a L<Mojolicious>
app since it can be used (with L<Test::Mojo::Role::PSGI>) to test any PSGI application.

=item L<Plack::Test>

Also allows you to make L<HTTP::Request> requests against a L<PSGI> app and get the appropriate L<HTTP::Response> response back.
Doesn't provide any special tools for interrogating that response.  This module in fact uses this one internally.

=item L<Test::LWP::UserAgent>

This is a subclass of L<LWP::UserAgent> that can return responses from a local PSGI app, similar to the way this module instruments
an instance of L<LWP::UserAgent> for similar purposes.  The limitation to this approach is that it cannot be used with classes which
cannot be used with subclasses of L<LWP::UserAgent>.  By contrast, this module can instrument an existing L<LWP::UserAgent> object
without having to rebless it into another class or other such shenanigans.  If you can at least get access to another class's user
agent instance, it can be used with L<Test2::Tools::HTTP>'s mock website system.  Doesn't work with anything that is not an
L<LWP::UserAgent> object.

=item L<LWP::Protocol::PSGI>

Provides a similar functionality to L<Test::LWP::UserAgent>, but registers apps globally using L<LWP::Protocol> so that you do not
need access to a specific L<LWP::UserAgent> object.  Does not work with anything that is not an L<LWP::UserAgent> object.
L<Test2::Tools::HTTP::UA> provides similar functionality, but is an abstraction layer which can be used with any appropriately
adapted user agent class or instance, although we use L<LWP::UserAgent> by default.  Support for L<Mojo::UserAgent> and L<HTTP::AnyUA>
is available, although not bundled with this distribution.  One advantage of this abstraction is that it
can be used to instrument either a single instance or all objects belonging to a particular class.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
