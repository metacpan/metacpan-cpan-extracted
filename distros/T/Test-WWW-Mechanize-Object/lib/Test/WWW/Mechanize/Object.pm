package Test::WWW::Mechanize::Object;

use v5.6.1;
use Carp ();
use warnings;
use strict;
use base qw(Test::WWW::Mechanize);

=head1 NAME

Test::WWW::Mechanize::Object - run mech tests by making
requests on an object

=head1 VERSION

Version 0.020

=cut

our $VERSION = '0.020';

=head1 SYNOPSIS

  use Test::WWW::Mechanize::Object;
  my $mech = Test::WWW::Mechanize::Object->new(handler => $obj);
  $mech->get_ok('/foo');
  # use $mech as usual, omitting scheme/host if you want to

=head1 DESCRIPTION

Test::WWW::Mechanize::Object exists to make it easier to run
tests with unusual request semantics.

Instead of having to guess at which parts of the
LWP::UserAgent and WWW::Mechanize code needs to be
overridden, any object that implements a (relatively) simple
API can be passed in.

All methods from Test::WWW::Mechanize.  The only change is
the addition of the 'handler' parameter to the C<< new >>
method.

=head1 METHODS

=head2 request

  $obj->request($request);

This method receives a L<HTTP::Request|HTTP::Request> as its
only argument.  It should return a
L<HTTP::Response|HTTP::Response> object.  It should not
follow redirects; LWP will take care of that.

This method B<must> exist.

=head2 url_base

=head2 default_url_base

These method should return the current or default base for
request URLs, e.g.

  http://localhost.localdomain (the default default)
  http://myserver.com/myurl

These methods are optional.  They are provided for handler
objects that change their behavior based on some contextual
information (e.g. %ENV).  If this confuses you, you probably
don't need them.

The results of these methods are cached after being called
once, so if your object's return values might change during
program execution, that will not be reflected properly in
Test::WWW::Mechanize::Object.  If this matters to anyone,
send me a bug.

=head2 prepare_request

  $obj->prepare_request($request, $mech);

Called before LWP and Mech do all their request object
preparation.

Note: this method will be called once per request in a redirect
chain.

This method is optional.

=head2 before_request

  $obj->before_request($request, $mech);

Called after LWP and Mech do their request object
preparation, but before C<< $obj->request >> is called.

Note: this method will be called once per request in a redirect
chain.

=head2 after_request

  $obj->after_request($request, $response, $mech);

Called after the object has returned its response, but before
LWP and Mech have done any post-processing.

Note: this method will be called once per request in a redirect
chain.

This method is optional.

=head2 on_redirect

  $obj->on_redirect($request, $response, $mech);

Called after C<after_request> each time the object returns a response that is a
redirect (3XX status code). 

This method is optional.

=head1 INTERNALS

You don't need to read this section unless you are
interested in finding out how this module works, for
subclassing or debugging.  Most users will only need to read
the method documentation above.

=head2 new

Overridden to note the 'handler' parameter.

=cut

sub new {
  my ($class, %arg) = @_;
  my $handler = delete $arg{handler}
    or Carp::croak("the 'handler' argument is required for $class->new()");
  my $self = $class->SUPER::new(%arg);
  $self->{handler} = $handler;
  return $self;
}

sub __hook {
  my ($self, $hookname, $args) = @_;
  return unless my $meth = $self->{handler}->can($hookname);
  $self->{handler}->$meth(@$args);
}

=head2 _make_request

Overridden (from WWW::Mechanize) to call the C<prepare_request> hook.

=cut

sub _make_request {
  my ($self, $request, @rest) = @_;
  $self->__hook(prepare_request => [ $request, $self ]);
  $self->SUPER::_make_request($request, @rest);
}

=head2 get

=head2 head

=head2 post

Overridden (from LWP::UserAgent) to allow path-only URLs to be passed in, e.g.

  $mech->get('/foo', ...);

=cut

sub __add_url_base {
  my $self = shift;
  my $url  = shift;
  if ($url =~ m!^/!) {
    #warn "prepending url_base to $url\n";
    $url = $self->__url_base . $url;
    $url =~ s{(?<!:)/+}{/}g;
  }
  return ($url, @_);
}

# replaces "$old" with "$new" in $uri
sub __rebase_uri {
  my ($uri, $old, $new) = @_;
  return $uri if $old->eq($new);
  my $clone = $uri->clone;
  for my $part (qw(host scheme)) {
    return $uri unless $clone->$part eq $old->$part;
  }
  my %path = (
    clone => [ grep { length } $clone->path_segments ],
    old   => [ grep { length } $old->path_segments ],
  );
  while (@{$path{clone}} and @{$path{old}}
           and $path{clone}->[0] eq $path{old}->[0]
         ) {
    shift @{$path{$_}} for qw(clone old);
  }
  if (@{$path{old}}) {
    # unmatched path parts remaining
    return $uri;
  }
  for my $part (qw(host scheme)) {
    $clone->$part($new->$part);
  }
  my $path = join "/", $new->path_segments, @{$path{clone}};
  $path =~ s{/+}{/}g;
  $clone->path($path);
  return $clone->canonical;
}

sub __rebase_request_uri {
  my $req = shift;
  $req->uri( __rebase_uri( $req->uri, @_ ) );
}

sub __url_base {
  my $self = shift;
  return $self->{__url_base} ||= (
    $self->{handler}->can('url_base') ?
      URI->new($self->{handler}->url_base)->canonical :
        $self->__default_url_base
      );
}

sub __default_url_base {
  my $self = shift;
  return $self->{__default_url_base} ||= (
    URI->new(
      $self->{handler}->can('default_url_base') ?
        $self->{handler}->default_url_base :
          'http://localhost.localdomain'
        )
  );
}

BEGIN {
  for my $sub (qw(get head post)) {
    no strict 'refs';
    *$sub = sub {
      my $self = shift;
      my $meth = "SUPER::$sub";
      $self->$meth($self->__add_url_base(@_));
    }
  }
}

=head2 send_request 

Overridden (from LWP::UserAgent) to send requests to the
handler object and to call the C<before_request> hook.

Note: This ignores the C<$arg> and C<$size> arguments that
LWP::UserAgent uses.

=cut

sub send_request {
  my ($self, $request, $arg, $size) = @_;
  $self->__hook(before_request => [ $request, $self ]);
  # url_base will have already been added, so we change it to the default here
  __rebase_request_uri(
    $request,
    $self->__url_base,
    $self->__default_url_base,
  );
  my $response = $self->{handler}->request($request);
  $response->request($request);

  # change the default back to the real current url_base for cookie extraction
  __rebase_request_uri(
    $request,
    $self->__default_url_base,
    $self->__url_base,
  );
  # change cookie and location headers
  unless ($self->__url_base->eq($self->__default_url_base)) {
    for my $header (qw(Set-Cookie Set-Cookie2 Set-Cookie3)) {
      my @values = $response->header($header);
      $response->header($header => [ map {
        #warn "$header: was: $_\n";
        my $domain = $self->__default_url_base->host;
        my $path   = $self->__default_url_base->path || '/';
        if (m{  \b domain = \Q$domain\E ([;\s]|$) }x and
              m{\b path   = \Q$path\E ([;\s]|$) }x) {
          s{    \b domain = \Q$domain\E ([;\s]|$) }
            {domain=@{[ $self->__url_base->host ]}$1}x;
          s{    \b path   = \Q$path\E ([;\s]|$)}
            {path=@{[ $self->__url_base->path ]}$1}x;
        }
        #warn "$header: now: $_\n";
        $_
      } @values ]);
    }
  }

  $self->cookie_jar->extract_cookies($response) if $self->cookie_jar;

  $self->__hook(after_request => [ $request, $response, $self ]);

  if ($response->is_redirect) {
    $self->__hook(on_redirect => [ $request, $response, $self ]);
    unless ($self->__url_base->eq($self->__default_url_base)) {
      $response->header(
        Location => __rebase_uri(
          URI->new($response->header('Location')),
          $self->__default_url_base,
          $self->__url_base,
        ),
      );
    }
  }

  return $response;
}

=head1 TODO

Consider using L<URI::WithBase|URI::WithBase> instead of
rebasing URIs internally.

=head1 SEE ALSO

L<Test::WWW::Mechanize|Test::WWW::Mechanize>
L<HTTP::Request|HTTP::Request>
L<HTTP::Response|HTTP::Response>

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-www-mechanize-object at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WWW-Mechanize-Object>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::WWW::Mechanize::Object

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-WWW-Mechanize-Object>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-WWW-Mechanize-Object>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-WWW-Mechanize-Object>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-WWW-Mechanize-Object>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Pobox.com, who sponsored the original development of this module.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::WWW::Mechanize::Object
