package Test::WWW::Mechanize::PSGI;

use strict;
use warnings;

our $VERSION = '0.39';

use Carp qw( confess );
use HTTP::Message::PSGI ();    # adds from_psgi() to HTTP::Response
use Try::Tiny qw( catch try );

use base 'Test::WWW::Mechanize';

my $Test = Test::Builder->new();

sub new {
    my $class = shift;
    my %args  = @_;

    # Dont let LWP complain about options for our attributes
    my $app = $args{app};
    delete $args{app};
    my $env = delete $args{env};
    confess('Missing argument app') unless $app;
    confess('Argument app should be a code reference')
        unless ref($app) && ref($app) eq 'CODE';

    my $self = $class->SUPER::new(%args);
    $self->{app} = $app;
    $self->{env} = $env if $env;
    return $self;
}

sub simple_request {
    my ( $self, $request ) = @_;

    my $uri = $request->uri;
    $uri->scheme('http')    unless defined $uri->scheme;
    $uri->host('localhost') unless defined $uri->host;

    my $env = $self->prepare_request($request)
        ->to_psgi( %{ $self->{env} || {} } );
    $self->run_handlers( 'request_send', $request );
    my $response;
    try {
        $response = HTTP::Response->from_psgi( $self->{app}->($env) );
    }
    catch {
        $Test->diag("PSGI error: $_");
        $response = HTTP::Response->new(500);
        $response->content($_);
        $response->content_type(q{});
    };
    $response->request($request);

    # Trigger set_my_handler call in LWP::UserAgent::parse_head()
    $self->run_handlers( 'response_header', $response );

    # Running the reponse_data handlers via run_handlers() doesn't pass all of
    # the args that are required, so we'll run each handler explicitly.  We do
    # this here so that we can fire off the handler which gets added in
    # LWP::UserAgent::parse_head().  Without this handler firing,
    # LWP::UserAgent::base() will not know about any URL which may have been
    # set in a <base href="..."> tag.  If we don't know about this tag then we
    # may end up with an incorrect base URL and, by extension, we could end up
    # at the wrong location when trying to follow relative URLs.

    for my $handler ( $self->handlers( 'response_data', $response ) ) {
        $handler->{callback}
            ->( $response, $self, $handler, $response->content );
    }

    $self->run_handlers( 'response_done', $response );
    return $response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Test::WWW::Mechanize::PSGI - Test PSGI programs using WWW::Mechanize

=head1 VERSION

version 0.39

=head1 SYNOPSIS

  # We're in a t/*.t test script...
  use Test::WWW::Mechanize::PSGI;

  my $mech = Test::WWW::Mechanize::PSGI->new(
      app => sub {
          my $env = shift;
          return [
              200,
              [ 'Content-Type' => 'text/html' ],
              [ '<html><head><title>Hi</title></head><body>Hello World</body></html>'
              ]
          ];
      },
  );
  $mech->get_ok('/');
  is( $mech->ct, 'text/html', 'Is text/html' );
  $mech->title_is('Hi');
  $mech->content_contains('Hello World');
  # ... and all other Test::WWW::Mechanize methods

=head1 DESCRIPTION

L<PSGI> is a specification to decouple web server environments from
web application framework code. L<Test::WWW::Mechanize> is a subclass
of L<WWW::Mechanize> that incorporates features for web application
testing. The L<Test::WWW::Mechanize::PSGI> module meshes the two to
allow easy testing of L<PSGI> applications.

Testing web applications has always been a bit tricky, normally
requiring starting a web server for your application and making real HTTP
requests to it. This module allows you to test L<PSGI> web
applications but does not require a server or issue HTTP
requests. Instead, it passes the HTTP request object directly to
L<PSGI>. Thus you do not need to use a real hostname:
"http://localhost/" will do. However, this is optional. The following
two lines of code do exactly the same thing:

  $mech->get_ok('/action');
  $mech->get_ok('http://localhost/action');

This makes testing fast and easy. L<Test::WWW::Mechanize> provides
functions for common web testing scenarios. For example:

  $mech->get_ok( $page );
  $mech->title_is( "Invoice Status", "Make sure we're on the invoice page" );
  $mech->content_contains( "Andy Lester", "My name somewhere" );
  $mech->content_like( qr/(cpan|perl)\.org/, "Link to perl.org or CPAN" );

An alternative to this module is L<Plack::Test>.

=head1 CONSTRUCTOR

=head2 new

Behaves like, and calls, L<WWW::Mechanize>'s C<new> method. You should pass
in your application:

  my $mech = Test::WWW::Mechanize::PSGI->new(
      app => sub {
          my $env = shift;
          return [ 200, [ 'Content-Type' => 'text/plain' ], ['Hello World'] ],;
      },
      env => { REMOTE_USER => 'Foo Bar' },
  );

=head1 METHODS: HTTP VERBS

=head2 $mech->get_ok($url, [ \%LWP_options ,] $desc)

A wrapper around WWW::Mechanize's get(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

A default description of "GET $url" is used if none if provided.

=head2 $mech->head_ok($url, [ \%LWP_options ,] $desc)

A wrapper around WWW::Mechanize's head(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

A default description of "HEAD $url" is used if none if provided.

=head2 $mech->post_ok( $url, [ \%LWP_options ,] $desc )

A wrapper around WWW::Mechanize's post(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

A default description of "POST to $url" is used if none if provided.

=head2 $mech->put_ok( $url, [ \%LWP_options ,] $desc )

A wrapper around WWW::Mechanize's put(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

A default description of "PUT to $url" is used if none if provided.

=head2 $mech->submit_form_ok( \%params [, $desc] )

Makes a C<submit_form()> call and executes tests on the results.
The form must be found, and then submitted successfully.  Otherwise,
this test fails.

I<%params> is a hashref containing the params to pass to C<submit_form()>.
Note that the params to C<submit_form()> are a hash whereas the params to
this function are a hashref.  You have to call this function like:

    $agent->submit_form_ok({
        form_number => 3,
        fields      => {
            username    => 'mungo',
            password    => 'lost-and-alone',
        }
    }, "looking for 3rd form" );

As with other test functions, C<$desc> is optional.  If it is supplied
then it will display when running the test harness in verbose mode.

Returns true value if the specified link was found and followed
successfully.  The L<HTTP::Response> object returned by submit_form()
is not available.

=head2 $mech->follow_link_ok( \%params [, $desc] )

Makes a C<follow_link()> call and executes tests on the results.
The link must be found, and then followed successfully.  Otherwise,
this test fails.

I<%params> is a hashref containing the params to pass to C<follow_link()>.
Note that the params to C<follow_link()> are a hash whereas the params to
this function are a hashref.  You have to call this function like:

    $mech->follow_link_ok( {n=>3}, "looking for 3rd link" );

As with other test functions, C<$desc> is optional.  If it is supplied
then it will display when running the test harness in verbose mode.

Returns a true value if the specified link was found and followed
successfully.  The L<HTTP::Response> object returned by follow_link()
is not available.

=head2 click_ok( $button[, $desc] )

Clicks the button named by C<$button>.  An optional C<$desc> can
be given for the test.

=head1 METHODS: CONTENT CHECKING

=head2 $mech->html_lint_ok( [$desc] )

Checks the validity of the HTML on the current page.  If the page is not
HTML, then it fails.  The URI is automatically appended to the I<$desc>.

Note that HTML::Lint must be installed for this to work.  Otherwise,
it will blow up.

=head2 $mech->title_is( $str [, $desc ] )

Tells if the title of the page is the given string.

    $mech->title_is( "Invoice Summary" );

=head2 $mech->title_like( $regex [, $desc ] )

Tells if the title of the page matches the given regex.

    $mech->title_like( qr/Invoices for (.+)/

=head2 $mech->title_unlike( $regex [, $desc ] )

Tells if the title of the page matches the given regex.

    $mech->title_unlike( qr/Invoices for (.+)/

=head2 $mech->base_is( $str [, $desc ] )

Tells if the base of the page is the given string.

    $mech->base_is( "http://example.com/" );

=head2 $mech->base_like( $regex [, $desc ] )

Tells if the base of the page matches the given regex.

    $mech->base_like( qr{http://example.com/index.php?PHPSESSID=(.+)});

=head2 $mech->base_unlike( $regex [, $desc ] )

Tells if the base of the page matches the given regex.

    $mech->base_unlike( qr{http://example.com/index.php?PHPSESSID=(.+)});

=head2 $mech->content_is( $str [, $desc ] )

Tells if the content of the page matches the given string

=head2 $mech->content_contains( $str [, $desc ] )

Tells if the content of the page contains I<$str>.

=head2 $mech->content_lacks( $str [, $desc ] )

Tells if the content of the page lacks I<$str>.

=head2 $mech->content_like( $regex [, $desc ] )

Tells if the content of the page matches I<$regex>.

=head2 $mech->content_unlike( $regex [, $desc ] )

Tells if the content of the page does NOT match I<$regex>.

=head2 $mech->has_tag( $tag, $text [, $desc ] )

Tells if the page has a C<$tag> tag with the given content in its text.

=head2 $mech->has_tag_like( $tag, $regex [, $desc ] )

Tells if the page has a C<$tag> tag with the given content in its text.

=head2 $mech->followable_links()

Returns a list of links that L<WWW::Mechanize> can follow.  This is only http
and https links.

=head2 $mech->page_links_ok( [ $desc ] )

Follow all links on the current page and test for HTTP status 200

    $mech->page_links_ok('Check all links');

=head2 $mech->page_links_content_like( $regex [, $desc ] )

Follow all links on the current page and test their contents for I<$regex>.

    $mech->page_links_content_like( qr/foo/,
      'Check all links contain "foo"' );

=head2 $mech->links_ok( $links [, $desc ] )

Follow specified links on the current page and test for HTTP status
200.  The links may be specified as a reference to an array containing
L<WWW::Mechanize::Link> objects, an array of URLs, or a scalar URL
name.

    my @links = $mech->find_all_links( url_regex => qr/cnn\.com$/ );
    $mech->links_ok( \@links, 'Check all links for cnn.com' );

    my @links = qw( index.html search.html about.html );
    $mech->links_ok( \@links, 'Check main links' );

    $mech->links_ok( 'index.html', 'Check link to index' );

=head2 $mech->link_status_is( $links, $status [, $desc ] )

Follow specified links on the current page and test for HTTP status
passed.  The links may be specified as a reference to an array
containing L<WWW::Mechanize::Link> objects, an array of URLs, or a
scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_status_is( \@links, 403,
      'Check all links are restricted' );

=head2 $mech->link_status_isnt( $links, $status [, $desc ] )

Follow specified links on the current page and test for HTTP status
passed.  The links may be specified as a reference to an array
containing L<WWW::Mechanize::Link> objects, an array of URLs, or a
scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_status_isnt( \@links, 404,
      'Check all links are not 404' );

=head2 $mech->link_content_like( $links, $regex [, $desc ] )

Follow specified links on the current page and test the resulting
content of each against I<$regex>.  The links may be specified as a
reference to an array containing L<WWW::Mechanize::Link> objects, an
array of URLs, or a scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_content_like( \@links, qr/Restricted/,
        'Check all links are restricted' );

=head2 $mech->link_content_unlike( $links, $regex [, $desc ] )

Follow specified links on the current page and test that the resulting
content of each does not match I<$regex>.  The links may be specified as a
reference to an array containing L<WWW::Mechanize::Link> objects, an array
of URLs, or a scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_content_unlike( \@links, qr/Restricted/,
      'No restricted links' );

=head2 $mech->stuff_inputs( [\%options] )

Finds all free-text input fields (text, textarea, and password) in the
current form and fills them to their maximum length in hopes of finding
application code that can't handle it.  Fields with no maximum length
and all textarea fields are set to 66000 bytes, which will often be
enough to overflow the data's eventual receptacle.

There is no return value.

If there is no current form then nothing is done.

The hashref $options can contain the following keys:

=over

=item * ignore

hash value is arrayref of field names to not touch, e.g.:

    $mech->stuff_inputs( {
        ignore => [qw( specialfield1 specialfield2 )],
    } );

=item * fill

hash value is default string to use when stuffing fields.  Copies
of the string are repeated up to the max length of each field.  E.g.:

    $mech->stuff_inputs( {
        fill => '@'  # stuff all fields with something easy to recognize
    } );

=item * specs

hash value is arrayref of hashrefs with which you can pass detailed
instructions about how to stuff a given field.  E.g.:

    $mech->stuff_inputs( {
        specs=>{
            # Some fields are datatype-constrained.  It's most common to
            # want the field stuffed with valid data.
            widget_quantity => { fill=>'9' },
            notes => { maxlength=>2000 },
        }
    } );

The specs allowed are I<fill> (use this fill for the field rather than
the default) and I<maxlength> (use this as the field's maxlength instead
of any maxlength specified in the HTML).

=back

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Test PSGI programs using WWW::Mechanize

