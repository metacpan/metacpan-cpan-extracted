package UserAgent::Any;

use 5.036;

use Carp;
use Moo;
use Scalar::Util 'blessed';

use namespace::clean;

our $VERSION = 0.05;

our @CARP_NOT = 'UserAgent::Any::Wrapper';

# We expect a single argument to this class, so we take it without the need to
# pass it in a hash. See:
# https://metacpan.org/pod/Moo#BUILDARGS
around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  return {ua => $args[0]}
      if @args == 1 && (ref($args[0]) ne 'HASH' || !blessed($args[0]));

  return $class->$orig(@args);
};

has _impl => (
  init_arg => 'ua',
  is => 'ro',
  required => 1,
  handles => 'UserAgent::Any::Impl',
  coerce => sub ($ua) {
    croak 'Passed User Agent object must be a blessed reference' unless blessed($ua);
    if ($ua isa LWP::UserAgent) {
      require UserAgent::Any::Impl::LwpUserAgent;
      return UserAgent::Any::Impl::LwpUserAgent->new(ua => $ua);
    } elsif ($ua isa AnyEvent::UserAgent) {
      require UserAgent::Any::Impl::AnyEventUserAgent;
      return UserAgent::Any::Impl::AnyEventUserAgent->new(ua => $ua);
    } elsif ($ua isa Mojo::UserAgent) {
      require UserAgent::Any::Impl::MojoUserAgent;
      return UserAgent::Any::Impl::MojoUserAgent->new(ua => $ua);
    } elsif ($ua isa HTTP::Promise) {
      require UserAgent::Any::Impl::HttpPromise;
      return UserAgent::Any::Impl::HttpPromise->new(ua => $ua);
    } elsif ($ua->DOES('UserAgent::Any')) {
      return $ua;
    } else {
      croak 'Unknown User Agent type "'.ref($ua).'"';
    }
  }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any – Wrapper above any UserAgent library, supporting sync and async
calls

=head1 SYNOPSIS

  my $ua = UserAgent::Any->new(LWP::UserAgent->new(%options));

  my $res = $ua->get($url, %params);

=head1 DESCRIPTION

C<UserAgent::Any> is to user agents what L<Log::Any> is to loggers: it allows to
write libraries making RPC calls without having to rely on one particular user
agent implementation.

C<UserAgent::Any> supports both synchronous and asynchronous calls (if supported
by the underlying user agent).

The main goal of this library is to be used for Cloud API wrappers so that they
can be written without imposing the use of one particular user agent on their
users. As such, only a subset of the features usually exposed by full-fledged
user agents is available for now in C<UserAgent::Any>. Feel free to ask for or
contribute new features if needed.

=head2 Supported user agents

=head3 L<LWP::UserAgent>

When using an L<LWP::UserAgent>, a C<UserAgent::Any> object only implements the
synchronous calls (without the C<_cb> or C<_p> suffixes) and the asynchronous
ones will throw exceptions when called.

=head3 L<Mojo::UserAgent>

When using a L<Mojo::UserAgent>, a C<UserAgent::Any> object implements the
asynchronous calls using the global singleton L<Mojo::IOLoop> and the methods
with the C<_p> suffix return L<Mojo::Promise> objects.

=head3 L<AnyEvent::UserAgent>

When using a L<AnyEvent::UserAgent>, a C<UserAgent::Any> object implements the
asynchronous calls using L<AnyEvent> C<condvar> and the methods with the C<_p>
suffix return L<Promise::XS> objects (that module needs to be installed).

Note that you probably want to set the event loop used by the promise, which has
global effect so is not done by this module. It can be achieved with:

  Promise::XS::use_event('AnyEvent');

You can read more about that in L<Promise::XS/EVENT LOOPS>.

If you need different promise objects (especially L<Future>), feel free to ask
for or contribute new implementations.

=head3 L<HTTP::Promise>

When using a L<HTTP::Promise>, a C<UserAgent::Any> object implements the
asynchronous calls using L<Promise::Me> which execute the calls in forked
processes. Because of that, there are some caveats with the use of this module
and its usage is discouraged when another one can work.

=head3 C<UserAgent::Any>

As a convenience, you can pass a C<UserAgent::Any> to the constructor of the
package and the exact same object will be returned.

=head2 Constructor

  my $ua = UserAgent::Any->new($underlying_ua);

Builds a new C<UserAgent::Any> object wrapping the given underlying user agent.
The wrapped object must be an instance of a
L<supported user agent|/Supported user agents>. Feel free to ask for or
contribute new implementations.

=head2 Synchronous and asynchronous supports

When supported by the underlying user agent, all the C<UserAgent::Any> methods
exist in 3 versions. The synchronous version, without a suffix, and two
asynchronous versions, one taking a callback executed when the call is done and
one returning a promise that is fulfilled with the result of the call

Note that, as documented above in L<supported user agent|Supported user agents>,
the asynchronous methods will throw an exception if the object is built with a
user agent that does not support asynchronous calls.

See the documentation of the L<C<get()> method|/get> for more explanation on the
asynchronous support. And see the documentation of L<UserAgent::Any::Wrapper> to
learn how you can easily expose sets of methods with the same sync/async
semantics in your own library.

=head2 User agent methods

=head3 get

  my $res = $ua->get($url, %params);

  $ua->get_cb($url, %params)->($cb);

  my $promise = $ua->get_p($url, %params);

Execute an HTTP call with the C<GET> verb to the given url and with the
specified parameters, passed as request headers.

Note that, while the examples above are using C<%params>, the arguments are
actually treated as a list and the same key can appear multiple times to send
the same header multiple times. So, that list of arguments must still be an
even-sized list of alternating key-value pairs.

Like all the user agent methods below, the synchronous C<get()> returns a
L<UserAgent::Any::Response> object, the asynchronous-with-callback C<get_cb()>
returns a code-reference expecting a callback that will be called with an
L<UserAgent::Any::Response> object, and the promise based C<get_p()> will return
a promise, whose type depends on the type of user agent used, and that will be
fulfilled with a L<UserAgent::Any::Response> object once the request returns.

Note that the two steps call to C<get_cb()> is just syntactic sugar and the
actual GET call is done after the callback is passed. Nothing will happen if the
code reference returned by C<get_cb()> is not called.

If an error happens (like an invalid argument) these methods will throw an
exception synchronously in the initial call. It is unlikely (but possible) that
the methods fail during the processing of the request in which case the error
handling depends on the underlying user agent asynchronous model. With the
callback based methods you can generally not catch the errors while the promise
based one can allow it (in general through a C<catch()> method or a second
argument to the C<then()> method).

=head3 post

  my $res = $ua->post($url, %params, $content);

  $ua->post_cb($url, %params, $content)->($cb);

  my $promise = $ua->post_p($url, %params, $content);

This is similar to the C<get> method, except that the call uses the C<POST> HTTP
verb. Also, in addition to the C<$url> and C<%params> (which is still actually a
C<@params>) arguments, this method can take an optional C<$content> scalar that
will be sent as the body of the request.

=head3 delete

  my $res = $ua->delete($url, %params);

  $ua->delete_cb($url, %params)->($cb);

  my $promise = $ua->delete_p($url, %params);

Same as the C<get> method, but uses the C<DELETE> HTTP verb for the request.

=head3 patch

  my $res = $ua->patch($url, %params, $content);

  $ua->patch_cb($url, %params, $content)->($cb);

  my $promise = $ua->patch_p($url, %params, $content);

Same as the C<post> method, but uses the C<PATCH> HTTP verb for the request.

=head3 put

  my $res = $ua->put($url, %params, $content);

  $ua->put_cb($url, %params, $content)->($cb);

  my $promise = $ua->put_p($url, %params, $content);

Same as the C<post> method, but uses the C<PUT> HTTP verb for the request.

=head3 head

  my $res = $ua->head($url, %params);

  $ua->head_cb($url, %params)->($cb);

  my $promise = $ua->head_p($url, %params);

Same as the C<get> method, but uses the C<HEAD> HTTP verb for the request. Note
that it means that in general the user agent will ignore the content returned by
the server (except for the headers), even if some content is returned.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

L<AnyEvent::UserAgent> does not properly support sending a single header
multiple times: all the values will be concatenated (separated by C<, >) and
sent as a single header. This is supposed to be equivalent but might give a
different behavior from other implementations.

=item *

The message passing system used by L<HTTP::Promise> (internally based on
L<Promise::Me>) appears to be unreliable and a program using it might dead-lock
unexpectedly. If you only want to send requests in the background without
waiting for their result, then this might not be an issue for you.

=back

=head1 AUTHOR

Mathias Kende <mathias@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Mathias Kende

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over 4

=item *

L<UserAgent::Any::Wrapper>

=item *

L<UserAgent::Any::Response>

=item *

L<LWP::UserAgent>

=item *

L<AnyEvent::UserAgent>

=item *

L<Mojo::UserAgent>

=item *

L<HTTP::Promise>

=back

=cut
