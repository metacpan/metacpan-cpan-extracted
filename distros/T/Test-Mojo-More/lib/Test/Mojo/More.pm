package Test::Mojo::More;

use Mojo::Base 'Test::Mojo';
use Test::More;
use Mojo::JSON::Pointer;
use Mojo::Message::Request;
use Mojolicious;
use Mojolicious::Controller;
use Mojo::Transaction::HTTP;

no warnings 'utf8';

=head1 NAME

Test::Mojo::More - Test::Mojo and more.

=head1 VERSION

Version 0.061

=cut

our $VERSION = 0.061_000;


=head1 SYNOPSIS

  use Test::More;
  use Test::Mojo::More;
  
  my $t = new Test::Mojo::More 'MyApp';
  
  $t->post_ok('/account/login/', form => {
    login => 'false',
    pass  => 123,
  })
    ->status_is(302)
    ->flash_is( '/error/login' => 'Error login.' )
    ->cookie_hasnt( 'user_id' );
  
  $t->post_ok('account/login/', form => {
    login => 'true',
    pass  => 123,
  })
    ->status_is(302)
    ->flash_hasnt( '/errror' )
    ->cookie_has( 'user_id' );
  
  done_testing;


=head1 DESCRIPTION

L<Test::Mojo::More> is an extension for the L<Test::Mojo> which allows
you to test L<Mojo> and L<Mojolicious> applications.


=head1 ATTRIBUTES

L<Test::Mojo::More>  inherits all attributed from L<Test::Mojo> and inplements
the following new ones.

=head2  C<dom>

   @a = $t->dom->find('.menu li a');

Currect DOM from transaction.


=head2 C<cookie_hashref>

  $cookie = $t->cookie_hashref;

Current cookies from transaction.


=head2 C<flash_hashref>

  $flases = $t->flash_hashref;

Current flashes from transaction.


=cut

sub dom            { return shift->tx->res->dom                                                     }
sub cookie_hashref { return { map { $_->name => $_->value } @{ $_[0]->_controller->req->cookies } } }
sub flash_hashref  { return $_[0]->_session->{flash} || {}                                          }


=head1 METHODS

L<Test::Mojo::More>  inherits all method from L<Test::Mojo> and inplements
the following new ones.

=head2 C<flash_is>

  $t = $t->flash_is( '/error', { message => 'error message' } );
  $t = $t->flash_is( '/error/message', 'error message' );

Check flash the given JSON Pointer with Mojo::JSON::Pointer.

=cut

sub flash_is {
	my ($self, $key, $value, $desc) = @_;
	my ( $flash, $path ) = $self->_prepare_key($key);
	$flash = $self->_flash($flash);

	return $self->__test(
		'is_deeply',
		_pointer( $flash, $path ? "/$path" : "" ),
		$value,
		$desc || "flash exact match for JSON Pointer \"$key\"",
	);
}


=head2 C<flash_has>

  $t = $t->flash_has( '/error' );
  $t = $t->flash_has( '/error/message' );

Check if flash contains a value that can be identified using
the given JSON Pointer with Mojo::JSON::Pointer.

=cut

sub flash_has {
	my ($self, $key, $value, $desc) = @_;
	my ( $flash, $path ) = $self->_prepare_key($key);

	$flash = $self->_flash($flash);

	return $self->__test(
		'ok',
		!!_pointer($flash, $path ? "/$path" : "" ),
		$desc || "flash has value for JSON Pointer \"$key\"",
	);
}


=head2 C<flash_hasnt>

  $t = $t->flash_hasnt( '/error' );
  $t = $t->flash_hasnt( '/error/message' );

Check if flash no contains a value that can be identified using
the given JSON Pointer with Mojo::JSON::Pointer

=cut

sub flash_hasnt {
	my ($self, $key, $value, $desc) = @_;
	my ( $flash, $path ) = $self->_prepare_key($key);
	$flash = $self->_flash($flash);
	return $self->__test(
		'ok',
		!_pointer( $flash, $path ? "/$path" : "" ),
		$desc || "flash has no value for JSON Pointer \"$key\""
	);
}



=head2 C<cookie_has>

  $t = $t->cookie_has( 'error' );

Check if cookie contains a cracker.

=cut

sub cookie_has {
	my ($self, $cookie, $desc) = @_;
	return $self->__test(
		'ok',
		!!$self->_cookie( $cookie ),
		$desc || "has cookie \"$cookie\"",
	);
}


=head2 C<cookie_hasnt>

  $t = $t->cookie_hasnt( 'error' );

Check if cookie no contains a cookie.

=cut

# Polly wants a cracker
sub cookie_hasnt {
	my ($self, $cookie, $desc) = @_;
	return $self->__test(
		'ok',
		!$self->_cookie( $cookie ),
		$desc || "has no cookie \"$cookie\"",
	);
}


=head2 C<cookie_is>

  $t = $t->cookie_is( $name => $value );

Check cookie for exact match.

=cut

sub cookie_is {
	my ($self, $cookie, $value, $desc) = @_;
	return $self->__test(
		'is',
		$self->_cookie( $cookie ),
		$value,
		$desc || "cookie \"$cookie\": ".($value ? "\"$value\"" : '""'),
	);
}



=head2 C<cookie_isnt>

  $t = $t->cookie_isnt( $name => $value );

Opposite of L</"cookie_is">

=cut

sub cookie_isnt {
	my ($self, $cookie, $value, $desc) = @_;
	return $self->__test(
		'isnt',
		$self->_cookie( $cookie ),
		$value,
		$desc || "not cookie \"$cookie\": ".($value ? "\"$value\"" : '""'),
	);
}


=head2 C<cookie_like>

  $t = $t->cookie_like( 'error', 'fatal error' );

Check if cookie for similar match.

=cut

sub cookie_like {
	my ($self, $cookie, $regex, $desc) = @_;
	return $self->__test(
		'like',
		$self->_cookie( $cookie ),
		$regex,
		$desc || "cookie \"$cookie\" is similar",
	);
}

=head2 C<cookie_unlike>

  $t = $t->cookie_unlike( 'error', 'unfatal error' );

Opposite of L</"cookies_like">.

=cut

sub cookie_unlike {
	my ($self, $cookie, $regex, $desc) = @_;
	return $self->__test(
		'unlike',
		$self->_cookie( $cookie ),
		$regex,
		$desc || "cookie \"$cookie\" is not similar",
	);
}

sub _prepare_key {
	shift;
	return ( '', '' ) unless @_;
	my ( undef, $flash, $path ) = split '\/', +shift, 3;
	( $flash, $path )
}

sub _session {
	shift->_controller->session
}

sub _flash {
	return $_[0]->_controller->flash( $_[1] ) if @_ == 2;
	{}
}

sub _cookie {
	return $_[0]->_controller->cookie( $_[1] );
}

sub _controller {
	my $self = shift;

	# Build res cookies
	my $req = Mojo::Message::Request->new;
	$req->cookies( join "; ", map{ $_->name ."=". $_->value } @{$self->tx->res->cookies} );

	# Make app && controller
	my $c = Mojolicious::Controller->new(
		tx  => Mojo::Transaction::HTTP->new( req => $req ),
		app => Mojolicious->new(),
	);

	# XXX copy secret
	my $secret = $c->app->can('secrets') || $c->app->can('secret');
	$secret->( $c->app, ( $self->app->can('secrets') || $self->app->can('secret') )->( $self->app ) );

	# Init
	$c->app->handler( $c );
	$c->app->sessions->load( $c );
	$c;
}

sub _pointer {
	my ($data, $path) = @_;
	return Mojo::JSON::Pointer->new($data)->get($path)
		if Mojo::JSON::Pointer->can('data');
	return Mojo::JSON::Pointer->new->get($data, $path);
	return 0;
}

sub __test {
	my $self = shift;
	return $self->_test(@_)      if $self->can('_test');
	my $method = shift;
	Test::More->can($method)->(@_) if Test::More->can($method);
	$self;
}


=head1 SEE ALSO

L<Test::Mojo>, L<Test::Mojo::Session>

=head1 AUTHOR

coolmen, C<< <coolmen78 at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 coolmen.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Test::Mojo::More

