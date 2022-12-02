use 5.014;
use strict;
use warnings;

# I don't normally do inline pod, but...

=pod

=encoding utf-8

=head1 NAME

Result::Trait - the trait which all Result objects implement
head1 SYNOPSIS

  use results;
  
  sub to_uppercase {
    my $str = shift;
    
    return err( "Cannot uppercase a reference." ) if ref $str;
    return err( "Cannot uppercase undef." ) if not defined $str;
    
    return ok( uc $str );
  }
  
  my $got = to_uppercase( "hello world" )->unwrap();

=head1 DESCRIPTION

The C<err>, C<ok>, and C<ok_list> functions from L<results> return objects
which have the methods described in this trait.

=head2 Methods

These methods are available on all Result objects.

Many of them will mark the Result as "handled". All Results should be
handled.

=cut

use overload ();
use Carp ();
use Scalar::Util ();
require results;

package Result::Trait;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use Role::Tiny;

requires qw(
	_handled
	_peek
	_peek_err
	is_err
	is_ok
);

##############################################################################

# Check if we're in global destruction.
#

sub __IN_GLOBAL_DESTRUCTION__ {
	${^GLOBAL_PHASE} eq 'DESTRUCT'
}

##############################################################################

# Check if something is a coderef.
#

sub __IS_CODE__ {
	ref($_[0]) eq 'CODE'
}

##############################################################################

# Check if something is a Result object.
#

sub __IS_RESULT__ {
	Scalar::Util::blessed( $_[0] )
		and $_[0]->can( 'DOES' )
		and $_[0]->DOES( __PACKAGE__ )
}

##############################################################################

# Check if something is a type constraint object.
#

sub __IS_TYPE__ {
	Scalar::Util::blessed( $_[0] )
		and $_[0]->can( 'check' )
		and $_[0]->can( 'get_message' )
}

##############################################################################

# Check if something is a blessed exception we can work with.
#

sub __IS_FRIENDLY_EXCEPTION__ {
	Scalar::Util::blessed( $_[0] )
		and $_[0]->can( 'DOES' )
		and $_[0]->DOES( 'results::exceptions' )
}

##############################################################################

# Helper for implementations of this trait to use.
#

sub __OVERLOAD_ARGS__ {
	my ( $class, $nickname, $peek_method ) = @_;

	return (
		bool     => sub { !!1 },
		q[""]    => sub { "$nickname(@{[ $_[0]->$peek_method ]})" },
		fallback => 1,
	);
}

##############################################################################

=head3 C<< $result->and( $other_result ) >>

Returns C<< $result >> if it is an err. Returns C<< $other_result >> otherwise.
The effect of this is that C<and> returns an ok Result only if both Results are
ok, and an err Result otherwise.

C<< $result >> is considered to be handled if it was ok.
C<< $other_result >> is not considered to have been handled.

=head4 Example

Supposing the C<< create_file() >> and C<< upload_file() >> functions
return Results to indicate success:

  my $result = create_file()->and( upload_file() );
  
  if ( $result->is_err() ) {
    warn $result->unwrap_err;
  }
  else {
    say "File created and uploaded successfully!";
    $result->unwrap();
  }

Note that if the C<< create_file() >> function failed, the C<< upload_file() >>
will still be run even though it is destined to fail, because method arguments
are evaluated eagerly in Perl. For a solution, see C<< and_then() >>.

=cut

sub and {
	my ( $self, $res ) = @_;
	@_ == 2 && __IS_RESULT__($res)
		or Carp::croak( 'Usage: $result->and( $other_result )' );

	return $self if $self->is_err();

	$self->_handled( !!1 );
	$res;
}

##############################################################################

=head3 C<< $result->and_then( sub { THEN } ) >>

The coderef is expected to return a Result object.

Returns C<< $result >> if it is an err.

If C<< $result >> is ok, then executes the coderef and returns the coderef's
Result. Within the coderef, the unwrapped value of C<< $result >> in scalar
context is available as C<< $_ >> and in list context is available as C<< @_ >>.

C<< $result >> is considered to be handled if it was ok.
C<< $other_result >> is not considered to have been handled.

Effectively a version of C<and> with lazy evaluation of the second
operand.

=head4 Example

Supposing the C<< create_file() >> and C<< upload_file() >> functions
return Results to indicate success:

  my $result = create_file()->and_then( sub { upload_file() } );
  
  if ( $result->is_err() ) {
    warn $result->unwrap_err;
  }
  else {
    say "File created and uploaded successfully!";
    $result->unwrap();
  }

=cut

sub and_then {
	my ( $self, $op ) = @_;
	@_ == 2 && __IS_CODE__($op)
		or Carp::croak( 'Usage: $result->and_then( sub { ...; return $other_result } )' );

	return $self if $self->is_err();

	local $_ = $self->_peek;
	my $res = $op->( $self->unwrap() );
	__IS_RESULT__($res)
		or Carp::croak( 'Coderef did not return a Result' );
	$res;
}

##############################################################################

=head3 C<< $result->err() >>

For err Results, the same as C<unwrap>. For ok Results, returns nothing.

The Result is considered to be handled.

=cut

sub err {
	my ( $self ) = @_;
	@_ == 1
		or Carp::croak( 'Usage: $result->err()' );

	$self->_handled( !!1 );

	return $self->unwrap_err() if $self->is_err();

	return;
}

##############################################################################

=head3 C<< $result->expect( $msg ) >>

For ok Results, unwraps the result.

For err Results, throws an exception with the given message.

The Result is considered to be handled.

=cut

sub expect {
	my ( $self, $message ) = @_;
	@_ == 2
		or Carp::croak( 'Usage: $result->expect( $message )' );

	return $self->unwrap() if $self->is_ok();

	$self->_handled( !!1 );

	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	Carp::croak( $message );
}

##############################################################################

=head3 C<< $result->expect_err( $msg ) >>

For ok Results, throws an exception with the given message.

For err Results, unwraps the result.

This is the inverse of C<< expect() >>.

The Result is considered to be handled.

=cut

sub expect_err {
	my ( $self, $message ) = @_;
	@_ == 2
		or Carp::croak( 'Usage: $result->expect_err( $message )' );

	return $self->unwrap_err() if $self->is_err();

	$self->_handled( !!1 );

	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	Carp::croak( $message );
}

##############################################################################

=head3 C<< $result->flatten() >>

If this is an ok Result containing another Result, returns the inner Result.
The outer Result is considered to be handled.

If this is an ok Result not containing another Result, throws.

If this is an err Result, returns self. The Result is not considered handled.

Note this is not a recursive flatten. It only flattens one level of Results.

=cut

sub flatten {
	my ( $self ) = @_;
	@_ == 1
		or Carp::croak( 'Usage: $result->flatten()' );

	if ( $self->is_ok() ) {
		my $inner = $self->unwrap();
		__IS_RESULT__($inner)
			or Carp::croak( 'Result did not contain a Result' );
		return $inner;
	}

	return $self;
}

##############################################################################

=head3 C<< $result->inspect( sub { PEEK } ) >>

If this is an ok Result, runs the coderef. Within the coderef, the unwrapped
value in scalar context is available as C<< $_ >> and in list context is
available as C<< @_ >>.

If this is an err Result, does nothing.

Always returns self, making it suitable for chaining.

The Result is not considered handled.

=cut

sub inspect {
	my ( $self, $f ) = @_;
	@_ == 2 && __IS_CODE__( $f )
		or Carp::croak( 'Usage: $result->inspect( sub { ... } )' );

	if ( $self->is_ok() ) {
		local $_ = $self->_peek;
		$f->( $self->_peek );
	}

	return $self;
}

##############################################################################

=head3 C<< $result->inspect_err( sub { PEEK } ) >>

If this is an ok Result, does nothing.

If this is an err Result, runs the coderef. Within the coderef, the unwrapped
error in scalar context is available as C<< $_ >> and in list context is
available as C<< @_ >>.

Always returns self, making it suitable for chaining.

This is the inverse of C<< inspect() >>.

The Result is not considered handled.

=cut

sub inspect_err {
	my ( $self, $f ) = @_;
	@_ == 2 && __IS_CODE__( $f )
		or Carp::croak( 'Usage: $result->inspect( sub { ... } )' );

	if ( $self->is_err() ) {
		local $_ = $self->_peek_err;
		$f->( $self->_peek_err );
	}

	return $self;
}

##############################################################################

=head3 C<< $result->is_err() >>

Returns true if and only if this is an err Result.

The Result is not considered handled.

=cut

# Must be implemented by classes consuming this role.

##############################################################################

=head3 C<< $result->is_ok() >>

Returns true if and only if this is an ok Result.

The Result is not considered handled.

=cut

# Must be implemented by classes consuming this role.

##############################################################################

=head3 C<< $result->map( sub { MAP } ) >>

If the Result is ok, then runs the coderef. Within the coderef, the unwrapped
value in scalar context is available as C<< $_ >> and in list context is
available as C<< @_ >>. The return value of the coderef is wrapped in a
new ok Result. The original Result is considered to be handled.

If the Result is err, then returns self. The Result is not considered handled.

=head4 Example

In the example below, C<< uppercase_name() >> will return a Result which
may be an ok Result with the uppercased name from the database or the
err Result with the message "Could not connect to database".

  sub get_name {
    if ( connect_to_database() ) {
      ...;
      return ok( $name );
    }
    else {
      return err( "Could not connect to database" );
    }
  }
  
  sub uppercase_name {
    return get_name()->map( sub {
      return uc $_;
    } );
  }
  
  sub lowercase_name {
    return get_name()->map( sub {
      return lc $_;
    } );
  }

=cut

sub map {
	my ( $self, $op ) = @_;
	@_ == 2 && __IS_CODE__( $op )
		or Carp::croak( 'Usage: $result->map( sub { ... } )' );

	if ( $self->is_err() ) {
		return $self;
	}

	local $_ = $self->_peek;
	results::ok( $op->( $self->unwrap() ) );
}

##############################################################################

=head3 C<< $result->map_err( sub { MAP } ) >>

If the Result is ok, then returns self. The Result is not considered handled.

If the Result is err, then runs the coderef. Within the coderef, the unwrapped
error in scalar context is available as C<< $_ >> and in list context is
available as C<< @_ >>. The return value of the coderef is wrapped in a
new err Result. The original Result is considered to be handled.

This is the inverse of C<< map() >>.

=cut

sub map_err {
	my ( $self, $op ) = @_;
	@_ == 2 && __IS_CODE__( $op )
		or Carp::croak( 'Usage: $result->map_err( sub { ... } )' );

	if ( $self->is_ok() ) {
		return $self;
	}

	local $_ = $self->_peek_err;
	results::err( $op->( $self->unwrap_err() ) );
}

##############################################################################

=head3 C<< $result->map_or( @default, sub { MAP } ) >>

If the Result is ok, then runs the coderef. Within the coderef, the unwrapped
value in scalar context is available as C<< $_ >> and in list context is
available as C<< @_ >>. Returns the return value of the coderef.

If the Result is err, then returns @default (whih may just be a single scalar).

Note that unlike C<< map() >>, this does not return a Result, but a value.

The Result is considered to be handled.

=head4 Example

In the example below, C<< uppercase_name() >> will return a Result which
may be an ok Result with the uppercased name from the database or the
err Result with the message "Could not connect to database".

  sub get_name {
    if ( connect_to_database() ) {
      ...;
      return ok( $name );
    }
    else {
      return err( "Could not connect to database" );
    }
  }
  
  say "HELLO, ", get_name()->map_or( "ANON", sub {
    return uc $_;
  } );

=cut

sub map_or {
	my $f = pop;
	my ( $self, @default ) = @_;
	@_ >= 1 && __IS_CODE__( $f )
		or Carp::croak( 'Usage: $result->map_or( $default, sub { ... } )' );

	if ( $self->is_err() ) {
		$self->_handled( !!1 );
		return results::ok( @default )->unwrap();
	}

	local $_ = $self->_peek;
	results::ok( $f->( $self->unwrap() ) )->unwrap();
}

##############################################################################

=head3 C<< $result->map_or_else( sub { DEFAULT }, sub { MAP } ) >>

Similar to C<< map_or() >> except that the C<< @default >> is replaced
by a coderef which should return the default.

The Result is considered to be handled.

=cut

sub map_or_else {
	my ( $self, $default, $f ) = @_;
	@_ == 3 && __IS_CODE__( $default ) && __IS_CODE__( $f )
		or Carp::croak( 'Usage: $result->map_or_else( sub { ... }, sub { ... } )' );

	if ( $self->is_err() ) {
		local $_ = $self->_peek_err();
		return results::ok( $default->( $self->unwrap_err() ) )->unwrap();
	}

	local $_ = $self->_peek;
	results::ok( $f->( $self->unwrap() ) )->unwrap();
}

##############################################################################

=head3 C<< $result->match( %dispatch_table ) >>

The C<< %dispatch_table >> is a hash of coderefs.

The keys 'ok' and 'err' are required coderefs to handle ok and err Results.

(Additional coderefs with keys "err_XXX" are allowed, where "XXX" is a short
name for a kind of error. If C<match> is called on an err Result, and the
error is a blessed object which DOES the "results::exceptions" trait, then
C<< $result->unwrap_err()->err_kind() >> is called and expected to return
a string indicating the error kind. The L<results::exceptions> module makes
it very easy to create exception objects like this!)

The unwrapped value or error is available in C<< $_ >> and C<< @_ >> as
you might expect.

B<< This method is not found in the original Rust implementation of Results. >>

=head4 Example

  get_name()->match(
    ok   => sub { say "Hello, $_" },
    err  => sub { warn $_ },
  );

=head4 Example

  open_file($filename)->match(
    ok            => sub { $_->write( $data ) },
    err_Auth      => sub { die( "Permissions error!" ) },
    err_DiskFull  => sub { die( "Disk is full!" ) },
    err           => sub { die( "Another error occurred!" ) },
  );

=cut

sub match {
	my ( $self, %d ) = @_;
	exists( $d{ok} ) && exists( $d{err} )
		or Carp::croak( 'Usage: $result->match( ok => sub { ... }, err => sub { ... }, ... )' );

	if ( $self->is_ok() ) {
		my $d = $d{ok};
		__IS_CODE__($d)
			or Carp::croak( 'Usage: $result->match( ok => sub { ... }, err => sub { ... }, ... )' );
		local $_ = $self->_peek();
		return $d->( $self->unwrap );
	}

	my $d = $d{err};
	my $peek = $self->_peek_err;
	if ( __IS_FRIENDLY_EXCEPTION__($peek) ) {
		my $err_kind = $peek->err_kind;
		$d = $d{"err_$err_kind"} // $d{err};
	}
	__IS_CODE__($d)
		or Carp::croak( 'Usage: $result->match( ok => sub { ... }, err => sub { ... }, ... )' );
	local $_ = $peek;
	return $d->( $self->unwrap_err );
}

##############################################################################

=head3 C<< $result->ok() >>

For ok Results, the same as C<unwrap>. For err Results, returns nothing.

The Result is considered to be handled.

=cut

sub ok {
	my ( $self ) = @_;
	@_ == 1
		or Carp::croak( 'Usage: $result->ok()' );

	$self->_handled( !!1 );

	return $self->unwrap() if $self->is_ok();

	return;
}

##############################################################################

=head3 C<< $result->or( $other_result ) >>

Returns C<< $result >> if it is ok. Returns C<< $other_result >>
otherwise. The effect of this is that C<or> returns an ok Result if
either of the Results is ok, and an err Result if both results were
err Results.

C<< $result >> is considered to be handled if it was an err.
C<< $other_result >> is not considered to have been handled.

=head4 Example

If C<< retrieve_file() >> uses a Result to indicate success:

  retrieve_file( "server1.example.com" )
    ->or( retrieve_file( "server2.example.com" ) )
    ->or( retrieve_file( "server3.example.com" ) )
    ->expect( "Could not retrieve file from any server!" );

Like with C<< and() >>, it needs to be noted that Perl eagerly evaluates
method call arguments, so C<< retrieve_file() >> will be called three times,
even if the first server succeeded. C<< or_else() >> provides a solution.

=cut

sub or {
	my ( $self, $res ) = @_;
	@_ == 2 && __IS_RESULT__($res)
		or Carp::croak( 'Usage: $result->or( $other_result )' );

	if ( $self->is_err() ) {
		$self->_handled( !!1 );
		return $res;
	}

	return $self;
}

##############################################################################

=head3 C<< $result->or_else( sub { ELSE } ) >>

The coderef is expected to return a Result object.

Returns C<< $result >> if it is ok. 

Otherwise, executes the coderef and returns the coderef's Result. Within the
coderef, the unwrapped error in scalar context is available as C<< $_ >> and
in list context is available as C<< @_ >>.

C<< $result >> is considered to be handled if it was an err.

=head4 Example

If C<< retrieve_file() >> uses a Result to indicate success:

  retrieve_file( "server1.example.com" )
    ->or_else( sub {
      return retrieve_file( "server2.example.com" );
    } )
    ->or_else( sub {
      return retrieve_file( "server3.example.com" );
    } )
    ->expect( "Could not retrieve file from any server!" );

=cut

sub or_else {
	my ( $self, $op ) = @_;
	@_ == 2 && __IS_CODE__($op)
		or Carp::croak( 'Usage: $result->or_else( sub { ...; $other_result } )' );

	if ( $self->is_err() ) {
		local $_ = $self->_peek_err;
		my $res = $op->( $self->unwrap_err() );
		__IS_RESULT__($res)
			or Carp::croak( 'Coderef did not return a Result' );
		return $res;
	}

	return $self;
}

##############################################################################

=head3 C<< $result->type( $constraint ) >>

If this Result is an err, returns self. Not considered handled.

If this Result is ok, and passes the type constraint in scalar context,
returns self. Not considered handled.

Otherwise returns an err Result with the type validation error message.
In this case the original Result is considered handled.

B<< This method is not found in the original Rust implementation of Results. >>

=head4 Example

If C<< get_config() >> returns an ok Result containing a hashref, then:

  use Types::Common qw( HashRef );
  
  my $config = get_config->type( HashRef )->unwrap();

=cut

sub type {
	my ( $self, $type ) = @_;
	@_ == 2 && __IS_TYPE__($type)
		or Carp::croak( 'Usage: $result->type( $constraint )' );

	return $self if $self->is_err();

	my $peek = $self->_peek();
	return $self if $type->check( $peek );

	return results::err( $type->get_message( $self->unwrap() ) );
}

##############################################################################

=head3 C<< $result->type_or( @default, $constraint ) >>

If this Result is an err, returns self. Not considered handled.

If this Result is ok, and passes the type constraint in scalar context,
returns self. Not considered handled.

Otherwise returns an ok Result with the default value(s). In this case
the original Result is considered handled.

B<< This method is not found in the original Rust implementation of Results. >>

=head4 Example

If C<< get_config() >> returns an ok Result containing a hashref, then:

  use Types::Common qw( HashRef );
  
  my $config = get_config->type_or( {}, HashRef )->unwrap();

=cut

sub type_or {
	my $type = pop;
	my ( $self, @default ) = @_;
	@_ >= 1 && __IS_TYPE__($type)
		or Carp::croak( 'Usage: $result->type_or( $default, $constraint )' );

	return $self if $self->is_err();

	my $peek = $self->_peek();
	return $self if $type->check( $peek );

	$self->_handled( !!1 );
	return results::ok( @default );
}

##############################################################################

=head3 C<< $result->type_or_else( sub { ELSE }, $constraint ) >>

If this Result is an err, returns self. Not considered handled.

If this Result is ok, and passes the type constraint in scalar context,
returns self. Not considered handled.

Otherwise executes the coderef, which is expected to return a Result.
In this case the original Result is considered handled.

B<< This method is not found in the original Rust implementation of Results. >>

=cut

sub type_or_else {
	my ( $self, $op, $type ) = @_;
	@_ == 3 && __IS_TYPE__($type) && __IS_CODE__($op)
		or Carp::croak( 'Usage: $result->type_or_else( $constraint, sub { ... } )' );

	return $self if $self->is_err();

	my $peek = $self->_peek();
	return $self if $type->check( $peek );

	local $_ = $peek;
	my $res = $op->( $self->unwrap() );
	__IS_RESULT__($res)
		or Carp::croak( 'Coderef did not return a Result' );
	return $res;
}

##############################################################################

=head3 C<< $result->unwrap() >>

For ok Results, returns the value and the Result is considered handled.

For err Results, throws an exception. If you wish to customize the
error message, use C<< expect() >> instead of C<< unwrap() >>.

=cut

sub unwrap {
	my ( $self ) = @_;
	@_ == 1
		or Carp::croak( 'Usage: $result->unwrap()' );

	if ( $self->is_ok() ) {
		$self->_handled( !!1 );
		return $self->_peek();
	}
	else {
		Carp::croak( $self->unwrap_err() );
	}
}

##############################################################################

=head3 C<< $result->unwrap_err() >>

For err Results, returns the error and the Result is considered handled.

For ok Results, throws an exception. If you wish to customize the
error message, use C<< expect_err() >> instead of C<< unwrap_err() >>.

=cut

sub unwrap_err {
	my ( $self ) = @_;
	@_ == 1
		or Carp::croak( 'Usage: $result->unwrap_err()' );

	if ( $self->is_ok() ) {
		Carp::croak( $self->unwrap() );
	}
	else {
		$self->_handled( !!1 );
		return $self->_peek_err();
	}
}

##############################################################################

=head3 C<< $result->unwrap_or( @default ) >>

For ok Results, returns the value and the Result is considered handled.

For err Results, returns the default value(s).

=cut

sub unwrap_or {
	my ( $self, @default ) = @_;

	if ( $self->is_err() ) {
		$self->_handled( !!1 );
		return results::ok( @default )->unwrap();
	}

	$self->unwrap();
}

##############################################################################

=head3 C<< $result->unwrap_or_else( sub { ELSE } ) >>

For ok Results, returns the value and the Result is considered handled.

For err Results, executes the coderef and returns whatever the coderef
returned.

This is effectively a lazy version of C<< unwrap_or() >>.

=cut

sub unwrap_or_else {
	my ( $self, $op ) = @_;
	@_ == 2 && __IS_CODE__( $op )
		or Carp::croak( 'Usage: $result->unwrap_or_else( sub { ...; return $other_result } )' );

	if ( $self->is_err() ) {
		local $_ = $self->_peek_err();
		return results::ok( $op->( $self->unwrap_err() ) )->unwrap();
	}

	$self->unwrap();
}

##############################################################################

=head3 C<< $result->DESTROY() >>

You should not call this method directly. Called by Perl when the object goes
out of scope or is otherwise destroyed.

Attempts to throw an exception if the Result has not been handled. However,
the current implementation of Perl downgrades exceptions thrown by DESTROY
to be warnings.

=cut

sub DESTROY {
	my ( $self ) = @_;

	return if __IN_GLOBAL_DESTRUCTION__;
	return if $self->_handled;

	$self->_handled( !!1 );
	Carp::croak( "$self went out of scope without being unwrapped" );
}

##############################################################################
1;
##############################################################################

__END__

=head2 Implementing This Trait

This module uses L<Role::Tiny>.

Implementations of this trait need to provide the following methods:

=over

=item C<< is_err() >>, C<< is_ok() >>

As documented above.

=item C<< _handled() >>

A getter/setter for whether the Result has been handled.

=item C<< _peek() >>

If the Result is ok, should return the inner value. Should pay attention to
list versus scalar context.

Undefined behaviour for err Results.

=item C<< _peek_err() >>

If the Result is err, should return the inner value. Should pay attention to
list versus scalar context.

Undefined behaviour for ok Results.

=back

Implementations may override methods to provide more efficient versions.
In particular, C<unwrap> and C<unwrap_err> are used a lot internally, but
the default implementations are not the fastest.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-results/issues>.

=head1 SEE ALSO

L<results>,
L<https://doc.rust-lang.org/std/result/enum.Result.html>.

The unit tests for Result::Trait should provide useful clarifying examples:
L<https://github.com/tobyink/p5-results/blob/master/t/unit/Result/Trait.t>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
