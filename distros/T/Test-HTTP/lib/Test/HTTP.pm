package Test::HTTP;
use warnings;
use strict;

our $VERSION = 0.18;

=head1 NAME

Test::HTTP - Test HTTP interactions.

=head1 SYNOPSIS
    
 use Test::HTTP tests => 9;

 {
     my $uri = "$BASE/data/page/Foo_Bar_Baz";
     my $type = 'text/x.waki-wiki';
     my $test = Test::HTTP->new('HTTP page creation and deletion');

     $test->get($uri, [Accept => $type]);
     $test->status_code_is(404, "Page not yet there.");

     $test->put($uri, ['Content-type' => $type], 'xyzzy');
     $test->status_code_is(201, "PUT returns 201."); # Created
     $test->header_is(
         'Content-type' => $type,
         "Content-type matches on PUT.");
     $test->header_like(
         Location => qr{^$BASE/data/page/},
         "Created page location makes sense.");
     $test->body_is('xyzzy');

     $test->get($uri, [Accept => $type]);
     $test->status_code_is(200, "Page is now there.");
     $test->header_is(
         'Content-type' => $type,
         "Content-type matches on GET.");
     $test->body_is('xyzzy');

     $test->delete($uri);
     $test->status_code_is(204, "DELETE returns 204."); # No content
 }

=head1 DESCRIPTION

L<Test::HTTP> is designed to make it easier to write tests which are mainly
about HTTP-level things, such as REST-type services.

Each C<Test::HTTP> object can contain state about a current request and its
response.  This allows convenient shorthands for sending requests, checking
status codes, headers, and message bodies.

=cut

use base 'Exporter';
use Carp 'croak';
use Class::Field 'field';
use Encode qw(encode_utf8 is_utf8);
use Filter::Util::Call;
use HTTP::Request;
use Test::Builder;

our $Builder = Test::Builder->new;
our $BasicPassword;
our $BasicUsername;
our $UaClass = 'LWP::UserAgent';
our $TODO = undef;
our @EXPORT = qw($TODO);

sub _partition(&@);

sub import {
    my $class = shift;

    $Builder->exported_to(scalar caller);

    my ( $syntax, $nargs ) = _partition { $_ eq '-syntax' } @_;
    $Builder->plan(@$nargs);

    # WARNING: This only exports the stuff in @EXPORT.
    $class->export_to_level(1, $class);

    if (@$syntax) {
        @_ = ();
        require Test::HTTP::Syntax;
        goto &Test::HTTP::Syntax::import;
    }
}

=head1 CONSTRUCTOR

=head2 Test::HTTP->new($name);

C<$name> is a name for the test, used to help write test descriptions when you
don't specify them.

=cut

sub new {
    my $class = shift;

    my $new_object = bless {}, $class;
    $new_object->_initiliaze(@_);
    return $new_object;
}

sub _initiliaze {
    my ( $self, $name ) = @_;

    $self->name($name);
}

# Given a predicate and a list, return two listrefs.  The elements in the
# first listref satisfy the predicate, and those in the second do not.  The
# predicate acts on a localized value of $_ rather than any arguments to it.
sub _partition(&@) {
    my ( $pred, @l )  = @_;
    my ( $tl,   $fl ) = ( [], [] );

    push @{ &$pred ? $tl : $fl }, $_ for @l;

    return ( $tl, $fl );
}

=head1 OBJECT FIELDS

You can get/set any of these by saying C<< $test->foo >> or
C<< $test->foo(5) >>, respectively.

=head2 $test->name

The name for the test.

=head2 $test->request

The current L<HTTP::Request> being constructed or most recently sent.

=head2 $test->response

The most recently received L<HTTP::Response>.

=head2 $test->ua

The User Agent object (usually an L<LWP::UserAgent>).

=head2 $test->username

=head2 $test->password

A username and password to be used for HTTP basic auth.  Default to the values
of C<$Test::HTTP::BasicUsername> and C<$Test::HTTP::BasicPassword>,
respectively.  If both are undef, then authentication is not attempted.

=cut

field 'name';
field 'request';
field 'response';
field 'ua', -init => '$self->_ua_class->new';
field 'username', -init => '$Test::HTTP::BasicUsername';
field 'password', -init => '$Test::HTTP::BasicPassword';

=head1 REQUEST METHODS

=head2 head, get, put, post, and delete

Any of these methods may be used to do perform the expected HTTP request.
They are all equivalent to

  $obj->run_request(METHOD => ARGS);

=cut

sub head {
    my $self = shift;
    $self->run_request(HEAD => @_);
}

sub get {
    my $self = shift;
    $self->run_request(GET => @_);
}

sub put {
    my $self = shift;
    $self->run_request(PUT => @_);
}

sub post {
    my $self = shift;
    $self->run_request(POST => @_);
}

sub delete {
    my $self = shift;
    $self->run_request(DELETE => @_);
}

=head2 $test->run_request([METHOD => $uri [, $headers [, $content]]]);

If there are any arguments, they are all passed to the L<HTTP::Request>
constructor to create a new C<< $test->request >>.

C<< $test->request >> is then executed, and C<< $test->response >> will hold
the resulting L<HTTP::Response>.

=cut

sub run_request {
    my ( $self, @request_args ) = @_;
    $self->new_request(@request_args) if @request_args;
    if ($self->request->method ne 'GET') {
        if (is_utf8($self->request->content)) {
            my $content = $self->request->content;
            $content = encode_utf8($content);
            $self->request->content($content);
        }
    }

    $self->response( $self->ua->simple_request( $self->request ) );
    croak( $self->request->uri . ': ' . $self->response->status_line )
        if $self->response->status_line =~ /500 Can't connect to /;
    return $self->response;
}

=head2 $test->new_request(METHOD => $uri [, $headers [, $content]]);

Set up a new request object as in run_request, but do not execute it yet.
This is handy if you want to call assorted methods on the request to tweak it
before running it with C<< $test->run_request >>.

=cut

sub new_request {
    my ( $self, $method, $uri, @args ) = @_;
    $self->request(
        HTTP::Request->new( $method => $uri, @args ) );
    $self->request->authorization_basic($self->username, $self->password)
        if (defined $self->username) || (defined $self->password);
    return $self->request;
}

=head1 TEST METHODS

=head2 $test->status_code_is($code [, $description]);

Compares the last response status code with the given code using
C<Test::Builder->is>.

=cut

sub status_code_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $expected_code, $description ) = @_;

    $description ||= $self->name . " status is $expected_code.";

    $Builder->is_eq( $self->response->code, $expected_code, $description );
}

=head2 $test->header_is($header_name, $value [, $description]);

Compares the response header C<$header_name> with the value C<$value> using
C<Test::Builder->is>.

=cut

sub header_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $header_name, $expected_value, $description ) = @_;

    $description ||= $self->name . " $header_name matches '$expected_value'.";

    $Builder->is_eq(
        scalar $self->response->header($header_name),
        $expected_value,
        $description
    );
}

=head2 $test->header_like($header_name, $regex, [, $description]);

Compares the response header C<$header_name> with the regex C<$regex> using
C<Test::Builder->like>.

=cut

sub header_like {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $header_name, $regex, $description ) = @_;

    $description ||= $self->name . " $header_name matches $regex.";

    $Builder->like(
        scalar $self->response->header($header_name),
        $regex,
        $description
    );
}

=head2 $test->body_is($expected_body [, $description]);

Verifies that the HTTP response body is exactly C<$expected_body>.

=cut

sub body_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $expected_body, $description ) = @_;

    $description ||= $self->name . " body is '$expected_body'.";

    $Builder->is_eq( $self->_decoded_content, $expected_body, $description );
}

=head2 $test->body_like($regex [, $description]);

Compares the HTTP response body with C<$regex>.

=cut

sub body_like {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $regex, $description ) = @_;

    $description ||= $self->name . " body matches $regex.";

    $Builder->like($self->_decoded_content, $regex, $description);
}

=head1 USER AGENT GENERATION

The user agent (UA) is created when the C<Test::HTTP> object is constructed.
By default, L<LWP::UserAgent> is used to create this object, but it may be
handy to test your HTTP handlers without going through an actual HTTP server
(for speed, e.g.), so there are a couple of ways to override the chosen class.

If the environment variable C<TEST_HTTP_UA_CLASS> is set, this value is used
instead.  If not, then the current value of C<$Test::HTTP::UaClass>
(C<LWP::UserAgent> by default) is used.  Thus, the incantation below may prove
useful.

    {
        local $Test::HTTP::UaClass = 'MyCorp::REST::FakeUserAgent';
        my $test = Test::HTTP->new("widget HTTP access");
        # ...
    }

=cut

sub _ua_class {
    my $self = shift;

    my $class = exists $ENV{TEST_HTTP_UA_CLASS}
        ? $ENV{TEST_HTTP_UA_CLASS}
        : $UaClass;

    eval "require $class";
    die if $@;
    $class->import;

    return $class;
}

sub _decoded_content {
    my $self = shift;
    my $content = $self->response->decoded_content;
   
    # Work around a bug in HTTP::Message where only text or xml content types
    # are decoded
    my $response = $self->response;
    my $ct = $self->response->header("Content-Type");
    unless ($response->content_is_text or $response->content_is_xml) {
        my ($charset) = $ct =~ m{charset=(\S+)};
        $charset ||= "ISO-8859-1";
        require Encode;
        $content = Encode::decode($charset, $content);
    }

    return $content;
}

=head1 SEE ALSO

L<http://www.w3.org/Protocols/rfc2616/rfc2616.html>,
L<LWP::UserAgent>,
L<HTTP::Request>,
L<HTTP::Response>,
L<Test::More>,
L<prove(1)>

=head1 AUTHOR

Socialtext, Inc. C<< <code@socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Socialtext, Inc., all rights reserved.

Same terms as Perl.

=cut

1;
