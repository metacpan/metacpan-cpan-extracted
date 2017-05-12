package Test::WWW::Mechanize::Declare;
use strict;
use warnings;

our $VERSION = '0.000000';

use Carp;

use Test::WWW::Mechanize;
use URI::URL;

my %METHOD_MAP = (
  GET     => 'get',
  POST    => 'post',
  PUT     => 'put',
  DELETE  => 'delete',
  get     => 'get',
  post    => 'post',
  put     => 'put',
  delete  => 'delete',
);

sub new {
  my ($class, $args) = @_;
  if(!exists $args->{ua}) {
    $args->{ua} = Test::WWW::Mechanize->new;
  }
  if(!exists $args->{tests} || ref $args->{tests} ne 'ARRAY') {
    croak "Test::WWW::Mechanize::Declare constructor needs a tests arrayref\n";
  }
  if(!exists $args->{base_uri}) {
    croak "Test::WWW::Mechanize::Declare constructor needs a base_uri\n";
  }
  bless $args, $class;
}

sub run_tests {
  my ($self) = @_;
  for my $test (@{$self->{tests}}) {
    my $method = $METHOD_MAP{$test->{method}};
    my $uri = URI::URL->new($self->{base_uri});
    $uri->path($test->{path});
    my $response = $self->{ua}->$method(
      $uri->as_string,
      $test->{params},
    );
    $test->{validate}->($response->request, $response);
  }
}

1;

__END__

=head1 NAME

Test::WWW::Mechanize::Declare - flexible, declarative Web testing

=head1 ACHTUNG

This is a B<technology preview>! I am releasing this module to solicit feedback
from the community as I develop the interface and behavior of this code.
Presently it is very small and simple and doesn't do anything more than what's
described in the synopsis. However, it is useful for me, so perhaps it will be
useful for someone else as well. I am not making any guarantees on the stability
of the API at this time.

=head1 SYNOPSIS

  my $mech = Test::WWW::Mechanize::Declare->new({
    base_uri  => 'http://localhost:8001',
    tests     => [
      {
      path    => '/',
      method  => 'GET',
      validate => \&validate_root,
      },
      {
      path    => '/client',
      method  => 'GET',
      validate => \&validate_client,
      },
      {
      path    => '/stop',
      method  => 'GET',
      validate => \&validate_stop,
      },
    ],
  });
  $mech->run_tests;

=head1 DESCRIPTION

Test::WWW::Mechanize::Declare allows one to logically separate the description
of what to test from the logic of the tests. Ideally, one can write a
configuration file to specify what should be tested, read in this file, and then
write the actual tests in Perl. I'm presently using it to do test-first
development for a number of Web services I'm writing. The data structure I write
describes the test, which will fail before any code exists for it as the Web
server doesn't know to respond to that request yet. Then, after coding the Web
service, the validate callback allows me to ensure that the behavior is correct.

Test::WWW::Mechanize::Declare doesn't run any tests on its own; the idea is that
this module takes the boring part out of writing the code to do the actual
requests. It simply calls the given method on the given URI and invokes the
callback with the request and response objects. As such, it is best for testing
Web servers that don't want or need to store state client-side.

=head1 METHODS

=head2 new LOTS OF STUFF

C<new> takes a hashref of arguments and returns an object (who'd have thought?).
It recognizes the following keys and expects them to have the following values:

=over 4

=item base_uri

The base of the URI for your Web server.

=item ua

A L<LWP::UserAgent>-derived object, or at very least something that has methods
like C<get> and C<put> which return an L<HTTP::Response> object upon invocation.
If not supplied, a L<Test::WWW::Mechanize> object is used.

=item tests

An arrayref of hashrefs. Expects the following key/value pairs:

=over 4

=item path

The absolute path to test. Will be concatenated with the base_uri given above.

=item method

The HTTP method to call on the L<LWP::UserAgent> object. Can be either
all-uppercase or all-lowercase.

=item params

A hashref of params to pass to the UA. See L<LWP::UserAgent> for what to use
here. If all you're doing is C<GET>, you probably don't need this.

=item validate

A subref to invoke after calling the given method on the given path. Will be
passed the L<HTTP::Request> and L<HTTP::Response> objects for this
request/response cycle. 

=back

=back

=head2 run_tests

C<run_tests> takes no arguments. When invoked, it iterates through the tests
arrayref provided to C<new> and makes a request of the given method against the
provided path providing the given parameters. For each request, it then calls
the validate sub with the L<HTTP::Request> and L<HTTP::Response> objects. It is
important to note that the tests are run in the order given in the constructor,
and the callbacks are invoked serially.

=head1 FUTURE DIRECTION

This is the section of the documentation where I waffle about things that may or
may not happen in the development of this module.

=over 4

=item Write tests

Yeah, I know. A test module without tests? Heresy and hypocrisy! I'll get to
them, I promise.

=item A pre-request callback

Something that would be invoked before the request is made to the server. I've
no idea what sort of information to pass to such a callback, however--maybe the
L<HTTP::Request> object?

=back

=head1 AUTHOR

Chris Nehren <apeiron@cpan.org>.

=head1 COPYRIGHT

Copyright (c) 2009 Chris Nehren.

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself.
