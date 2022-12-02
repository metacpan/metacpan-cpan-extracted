use 5.014;
use strict;
use warnings;

package results::exceptions;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use results ();
use B ();
use Exporter::Shiny;

sub _exporter_fail {
	my ( $class, $err_kind, $opts, $globals ) = @_;
	my $caller = $globals->{into};

	$err_kind =~ /
		\A
		(?:[[:upper:]][[:lower:]]*)
		(?:
			(?:[[:upper:]][[:lower:]]*)
			| [0-9]+
		)*
		\z
	/x or Carp::croak( "Bad err_kind name: $err_kind" );

	my $exception_class = "$caller\::Exception::$err_kind";
	$class->create_exception_class( $exception_class, $err_kind, $opts );

	$err_kind => eval sprintf( 'sub () { %s }', B::perlstring($exception_class) );
}

sub create_exception_class {
	my ( $class, $exception_class, $err_kind, $opts ) = @_;
	$opts //= {};

	no strict 'refs';
	*{"$exception_class\::new"} = sub {
		my $class = shift;
		bless { @_==1 ? %{$_[0]} : @_ }, $class;
	};
	*{"$exception_class\::err"} = sub {
		my $class = shift;
		results::err( $class->new( @_ ) );
	};
	*{"$exception_class\::throw"} = sub {
		my $class = shift;
		die( $class->new( @_ ) );
	};
	*{"$exception_class\::err_kind"} = sub {
		$err_kind
	};
	*{"$exception_class\::DOES"} = sub {
		my ( $class, $role ) = @_;
		return 1 if $role eq __PACKAGE__;
		$class->SUPER::DOES( $role );
	};
	*{"$exception_class\::to_string"} = sub {
		my $self = shift;
		if ( 'CODE' eq ref $opts->{to_string} ) {
			return $opts->{to_string}->( $self );
		}
		elsif ( defined $opts->{to_string} ) {
			return $opts->{to_string};
		}
		else {
			return $err_kind;
		}
	};
	for my $attr ( @{ $opts->{has} // [] } ) {
		*{"$exception_class\::$attr"} = sub { $_[0]{$attr} };
	}
	
	local $@;
	eval qq/
		package $exception_class;
		use overload (
			fallback => !!1,
			q[""]    => q[to_string],
			bool     => sub { !!1 },
		);
		1;
	/ or die( $@ );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

results::exceptions - quickly create a bunch of exception classes

=head1 SYNOPSIS

  use results;
  use results::exceptions (
    'DatabaseConnection',
    'Unauthorized' => { has => [ 'username' ] },
    'BadSqlSyntax' => { has => [ 'query' ] },
  );
  
  ...;
  
  return err( Unauthorized->new( username => $user ) );
  
  # or just:
  
  return Unauthorized->err( username => $user );
  
  # or if you prefer traditional exceptions:
  
  return Unauthorized->throw( username => $user );

=head1 DESCRIPTION

This is a module to quickly manufacture a bunch of classes to use as
exceptions/errors. There are many like it, but this one integrates nicely
with L<results>.

Each kind of exception you import is named by an "err kind", which is an
UpperCamelCase string. This may be followed by a hashref of options.

After you have imported a kind of exception, this module will create a
class called C<< "$caller\::Exception::$err_kind" >> where C<< $caller >>
is your package and C<< $err_kind >> is the err kind string. It will then
create a constant called C<< $err_kind >> in your namespace, so you don't
have to use the full C<< "$caller\::Exception::$err_kind" >> class name.

=head2 Options

Only two options are currently supported:

=over

=item C<has>

This may be an arrayref of attributes the exceptions should have. Think of
Moose's C<has> keyword, but much, much more limited.

If omitted, the exceptions will have no attributes, which is often fine.

=item C<to_string>

This may be either a string which the object should stringify to, or a
coderef which should be called to stringify the object.

If omitted, the exceptions will stringify to their err kind.

=back

=head2 Class Methods

Exception classes provide the following class methods:

=head3 C<< MyErrKind->new( %params ) >>

Create a new exception object, but don't do anything with it.

=head3 C<< MyErrKind->err( %params ) >>

Create a new exception object, and wrap it in an err L<Result|results>.
You'd normally then return that Result to your caller. For example:

  return MyErrKind->err();

=head3 C<< MyErrKind->throw( %params ) >>

Create a new exception object, and then C<die>.

=head2 Object Methods

Exception objects provide these methods, plus read-only accessors for
their attributes.

=head3 C<< $exception->err_kind >>

Returns the err kind as a string.

=head3 C<< $exception->to_string >>

Stringifies the exception. Exception objects also support string overloading.

=head2 Lexical exports

L<results::exceptions> supports lexical exports:

  use results::exceptions -lexical, (
    'DatabaseConnection',
    'Unauthorized' => { has => [ 'username' ] },
    'BadSqlSyntax' => { has => [ 'query' ] },
  );

This feature requires Perl 5.37.2 or above, or L<Lexical::Sub> on older
versions of Perl.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-results/issues>.

=head1 SEE ALSO

L<result>, C<< match() >> in L<Result::Trait>.

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
