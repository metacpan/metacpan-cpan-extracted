package UserAgent::Any;

use 5.036;

use Carp;
use Exporter 'import';
use Scalar::Util 'blessed';

use namespace::clean -except => ['import'];

our $VERSION = 0.01;
our @EXPORT_OK = ('wrap_method');

# The class hierarchy here is somehow inside out. When you call
# UserAgent::Any->new, the constructor in fact delegates to one of the
# implementations class which are (ISA) UserAgent::Any::Impl and which have
# (DOES) the UserAgent::Any role. This makes deriving from this class be a
# little difficult. Instead you should in general use composition or delegation.

sub new ($class, $ua) {
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

sub _wrap_response {
  return undef unless @_;  ## no critic (ProhibitExplicitReturnUndef)
  return @_ if @_ == 1;
  return \@_;
}

sub wrap_method {  ## no critic (RequireArgUnpacking)
  my $name = shift;
  my $member = shift if ref($_[0]) eq 'CODE';  ## no critic (ProhibitConditionalDeclarations)
  my ($method, $code, $cb) = @_;
  my $dest_pkg = caller(0);
  no strict 'refs';  ## no critic (ProhibitNoStrict)
  my $get_obj = defined $member ? sub ($this) { $this->$member() } : sub ($this) { $this };
  if (defined $cb) {
    *{"${dest_pkg}::${name}"} = sub ($this, @args) {
      $cb->($this, _wrap_response($get_obj->($this)->$method($code->($this, @args))), @args);
    };
    my $method_cb = "${method}_cb";
    *{"${dest_pkg}::${name}_cb"} = sub ($this, @args) {
      return sub ($final_cb) {
        $get_obj->($this)->$method_cb($code->($this, @args))
            ->(sub { $final_cb->($cb->($this, &_wrap_response, @args)) });
      }
    };
    my $method_p = "${method}_p";
    *{"${dest_pkg}::${name}_p"} = sub ($this, @args) {
      $get_obj->($this)->$method_p($code->($this, @args))
          ->then(sub { $cb->($this, &_wrap_response, @args) });
    };
  } else {
    *{"${dest_pkg}::${name}"} =
        sub ($this, @args) { $get_obj->($this)->$method($code->($this, @args)) };
    my $method_cb = "${method}_cb";
    *{"${dest_pkg}::${name}_cb"} =
        sub ($this, @args) { $get_obj->($this)->$method_cb($code->($this, @args)) };
    my $method_p = "${method}_p";
    *{"${dest_pkg}::${name}_p"} =
        sub ($this, @args) { $get_obj->($this)->$method_p($code->($this, @args)) };
  }
  return;
}

# Do not define methods after this line, otherwise they are part of the role.
use Moo::Role;

has ua => (
  is => 'ro',
  required => 1,
);

my @methods = qw(get post delete);

requires map { ($_, $_.'_cb', $_.'_p') } @methods;

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
synchronous calls (without the C<_cb> or C<_p> suffixes).

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

Note that C<UserAgent::Any> is a L<Moo::Role> and not a class. As such you can
compose it or delegate to it, but you can’t extend it directly.

=head2 User agent methods

=head3 get

  my $res = $ua->get($url, %params);

  $ua->get_cb($url, %params)->($cb);

  my $promise = $ua->get_p($url, %params);

Note that while the examples above are using C<%params>, the parameters are
actually treated as a list as the same key can appear multiple times to send the
same header multiple time. But that list must be an even-sized list of
alternating key-value pairs.

=head3 post

  my $res = $ua->post($url, %params, $content);

  $ua->post_cb($url, %params, $content)->($cb);

  my $promise = $ua->post_p($url, %params, $content);

This is similar to the C<get> method except that the call uses the C<POST> HTTP
verb. in addition to the C<$url> and C<%params> (which is still actually a
C<@params>), this method can take an optional C<$content> scalar that will be
sent as the body of the request.

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

=head3 HEAD

  my $res = $ua->head($url, %params);

  $ua->head_cb($url, %params)->($cb);

  my $promise = $ua->head_p($url, %params);

Same as the C<get> method, but uses the C<HEAD> HTTP verb for the request. Note
that it means that in general the user agent will ignore the content returned by
the server (except for the headers), even if some content is returned.

=head2 Using UserAgent::Any in client APIs

=head3 wrap_method

=head4 Calling a class method

  wrap_method($name => $delegate, sub ($self, ...) { ... }, sub ($self, $res, ...));

This method (which is the only one that can be exported by this module) is there
to help implement API client library using C<UserAgent::Any> and expose methods
handling callback and promise without having to implement them all.

The call above will generate in your class a set of method named with C<$name>
and the (optional) suffix C<_cb> and C<_p>, that will call the methods named
with C<$delegate> and the same suffix on the same object, passing it the result
of the first code reference and passing the result of that call to the second
code reference.

For example, if you have a class that can handle methods C<foo>, C<foo_cb>, and
C<foo_p> with the same semantics as the user agent methods above (this will
typically be the methods for C<UserAgent::Any> itself) and you want to expose a
method C<bar> that depends on C<foo> you can write:

  wrap_method('bar' => 'foo', sub ($self, @args) { make_args_for_foo($@args) });

And this will expose in your package a set of C<bar>, C<bar_cb>, and C<bar_p>
methods with the same semantics that will use the provided method reference to
build the arguments to C<foo>. For the synchronous case, the method from the
example above will be equivalent to:

  sub bar ($self, @args) { $self->foo($self, make_args_for_foo(@args))}

You can optionally pass a second callback that will be called with the response
from the wrapped method:

  wrap_method($name => $delegate, $cb, sub ($self, $res, ...));

The second callback will be called with the current object, the response from
the wrapped method and the arguments that were passed to the wrappers (the same
that were already passed to the first callback). The wrapped method will be
called in list context. If it returns exactly 1 result, then that result is
passed as-is to the second callback; if it returns 0 result, then the callback
will receive C<undef>; otherwise the callback will receive an array reference
with the result of the call.

If you don’t pass a second callback, then the callback, promise or method will
return the default result from the invoked method, without any transformation.

=head4 Calling a method of a class member

  wrap_method($name => \&method, $delegate, $cb1[, $cb2]);

Alternatively to the above, C<wrap_method> can be used to wrap a method of a
class member. Instead of calling the method named C<$delegate> in your class,
the call above will call the method named C<$delegate> on the reference returned
by the call to C<&method>.

=head3 Example

Here is a minimal example on how to create a client library for a hypothetical
service exposing a C<create> call using the C<POST> method.

Note in particular that, to bring the C<post> method from C<UserAgent::Any> in
C<MyPackage>, we are using L<Moo> delegation to the C<UserAgent::Any>
package, which is an L<Moo::Role> with the user agent methods.

Another class extending C<MyPackage> would not need this trick and could
directly derive from C<MyPackage> without issues.

  package MyPackage;

  use 5.036;

  use Moo;
  use UserAgent::Any 'wrap_method';

  use namespace::clean;

  has ua => (
    is => 'ro',
    handles => 'UserAgent::Any',
    coerce => sub { UserAgent::Any->new($_[0]) },
    required => 1,
  );

  wrap_method(create_document => 'post', sub ($self, %opts) {
    return ('https://example.com/create/'.$opts{document_id}, $opts{content});
  });

Or, if you don’t want to re-expose the C<UserAgent::Any> method in your class
directly (possibly because you want to re-use the same name), you can do:

  package MyPackage;

  use 5.036;

  use Moo;
  use UserAgent::Any 'wrap_method';

  use namespace::clean;

  has ua => (
    is => 'ro',
    coerce => sub { UserAgent::Any->new($_[0]) },
    required => 1,
  );

  wrap_method(create_document => \&ua => 'post', sub ($self, %opts) {
    return ('https://example.com/create/'.$opts{document_id}, $opts{content});
  });

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

L<LWP::UserAgent>

=item *

L<AnyEvent::UserAgent>

=item *

L<Mojo::UserAgent>

=item *

L<HTTP::Promise>

=back

=cut
