use 5.014;
use strict;
use warnings;

use Carp ();
use Devel::StrictMode ();
use Scalar::Util ();

package results;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use Exporter::Shiny qw( err is_result ok ok_list );
our @EXPORT = qw( err ok );

use Attribute::Handlers;

require Result::Err;
require Result::Ok;
require Result::OkList;

use constant {
	ERR_CLASS     => 'Result::Err',
	OK_CLASS      => 'Result::Ok',
	OK_LIST_CLASS => 'Result::OkList',
};

sub err {
	Carp::croak("Void context forbidden here") unless defined wantarray;
	ERR_CLASS->new( @_ );
}

sub is_result {
	Scalar::Util::blessed( $_[0] )
		and $_[0]->can( 'DOES' )
		and $_[0]->DOES( 'Result::Trait' )
}

sub ok {
	Carp::croak("Void context forbidden here") unless defined wantarray;
	OK_CLASS->new( @_ );
}

sub ok_list {
	Carp::croak("Void context forbidden here") unless defined wantarray;
	OK_LIST_CLASS->new( @_ );
}

sub UNIVERSAL::Result : ATTR(CODE) {
	Devel::StrictMode::STRICT or return;

	my ( $package, $symbol, $referent, $attr, $data ) = @_;
	my $name = *{$symbol}{NAME};

	no strict 'refs';
	no warnings 'redefine';

	if ( ref($data) eq 'ARRAY' ) {
		require Type::Utils;
		my $type = Type::Utils::dwim_type( $data->[0], for => $package );

		*{"$package\::$name"} = sub {
			my $return = $referent->( @_ );
			die "Function '$name' declared to return a Result, but returned: $return"
				unless is_result( $return );
			$return->type( $type );
		};
	}
	else {
		*{"$package\::$name"} = sub {
			my $return = $referent->( @_ );
			die "Function '$name' declared to return a Result, but returned: $return"
				unless is_result( $return );
			$return;
		};
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

results - why throw exceptions when you can return them?

=head1 SYNOPSIS

  use results;
  
  sub to_uppercase {
    my $str = shift;
    
    return err( "Cannot uppercase a reference." ) if ref $str;
    return err( "Cannot uppercase undef." ) if not defined $str;
    
    return ok( uc $str );
  }
  
  my $got = to_uppercase( "hello world" )->unwrap();

=head1 DESCRIPTION

This module is a Perl implementation of Rust's standard error handling
mechanism. Rust doesn't have a C<try>/C<catch>/C<throw> mechanism for
throwing errors. Instead, functions can be declared as returning a
"Result" which may be an "Ok" result or an "Err" result. Callers of
these functions will get a compile-time error if they do not inspect
the result and potentially deal with the error. (There is syntactic
sugar for propagating the error further up the call stack.)

Recent versions of Perl provide C<try>/C<catch>/C<throw> (though C<throw>
is spelled "die"), and in older versions the same thing can be roughly
accomplished using C<eval> or CPAN modules, making Rust's error handling
seem fairly foreign. For this reason I do not recommend using the
a mixture of C<try>/C<catch>/C<throw> error handling and Result-based
error handling in the same codebase. Pick one or the other.

Result-based error handling can provide some pretty succinct idioms,
so I do think it is worthy of consideration.

=head1 RETURNING RESULTS

=head2 Introduction

If you decide that your function should return a Result object, your function
should I<always> return a Result object.

Do not return Results for errors but bare values for success. The following
example is bad because the caller cannot rely on the result of C<to_uppercase>
I<always> being a Result object.

  use results;
  
  sub to_uppercase {
    my $str = shift;
    
    return err( "Cannot uppercase a reference." ) if ref $str;
    return err( "Cannot uppercase undef." ) if not defined $str;
    
    return uc $str;  # BAD
  }

Instead:

  use results;
  
  sub to_uppercase {
    my $str = shift;
    
    return err( "Cannot uppercase a reference." ) if ref $str;
    return err( "Cannot uppercase undef." ) if not defined $str;
    
    return ok( uc $str );  # FIXED
  }

C<die> can still be used in code that uses result-based error handling,
but it should only be used for errors that are thought to be unrecoverable.
Don't expect your caller to C<catch> exceptions.

=head2 Functions

The L<results> module provides three functions used to return results.
These functions should nearly always be prefixed with Perl's C<return>
keyword.

=head3 C<< ok() >>

The C<< ok() >> function returns a successful result. It can be called
without arguments to represent success without any particular value to
return.

  return ok();    # success

You may also include a value:

  sub your_function () {
    ...;
    return ok( $output );
  }

Or multiple values:

  sub your_other_function () {
    ...;
    return ok( $count, \@output );
  }

The caller can then retrieve those values using:

  my $output = your_function()->unwrap();
  my ( $count, $output_ref ) = your_other_function()->unwrap();

If a list of return values was provided, then calling C<< unwrap() >>
in scalar context will return the last item on the list only.

=head3 C<< ok_list() >>

This function acts identically to C<< ok() >> except that calling
C<< unwrap() >> in scalar context will die.

Your caller should never need to check at runtime whether it got an
C<< ok() >> result or an C<< ok_list() >> result. For any given function,
you should settle on just one of them. C<< ok() >> is usually the best
choice as it can still be used in list context.

C<< ok_list() >> is not exported by default, but can be requested:

  use results qw( :default ok_list );

Note that C<wantarray> will be useless in your function because the caller
will always be expecting a single scalar Result object. (Which may or may not
contain a list of values!)

=head3 C<< err() >>

The C<< err() >> function returns an error, or unsuccessful result.

It can be called without arguments to represent a general sense of
doom, but this is usually a bad idea:

  return err();    # failed

It is generally better to give a reason why your function failed:

  return err( "This feature isn't implemented" );

Or even better, an exception object:

  return err( MyApp::Error::NotImplemented->new );

The L<results::exceptions> module provides a very convenient way to create
a large number of lightweight exception classes suitable for that.

Like C<< ok() >> this can take a list:

  return err( MyApp::Error::Net->new, 0 .. 99 );

This would be unusual though, and is not generally recommended.

=head2 The C<< :Result >> Attribute

You can declare that your function always returns a Result using an attribute.

  sub to_uppercase : Result {
    ...;
  }

If you have L<Type::Utils> installed, then you can even specify the "inner"
type for successful Results, though this assumes that your Results are
scalars.

  sub to_uppercase : Result(Str) {
    ...;
  }

This declaration is only I<checked> if one of the C<PERL_STRICT>,
C<AUTHOR_TESTING>, C<RELEASE_TESTING>, or C<EXTENDED_TESTING> environment
variables is set to true. Otherwise, the attribute operates on the "honour
system"!

=head2 Exception Objects

It is often easier for your caller to deal with exception objects rather
than string error messages. This module comes with L<results::exceptions>
to make creating these a little easier. The example in the L</SYNOPSIS>
section could be written as:

  use results;
  use results::exceptions qw( UnexpectedRef UnexpectedUndef );
  
  sub to_uppercase {
    my $str = shift;
     
    return UnexpectedRef->err if ref $str;
    return UnexpectedUndef->err if not defined $str;
    
    return ok( uc $str );
  }

=head1 HANDLING RESULTS

=head2 Introduction

If you call a function which returns a Result, you are I<required> to handle
the result in some way. If a Result goes out of scope or otherwise gets
destroyed before being handled, this is considered a programming error.
Currently this will only result in a warning being printed, as Perl demotes
exceptions thrown in destructors to warnings.

Results are blessed objects and should be handled by calling methods on them.

=head2 Function

=head3 C<< is_result( $val ) >>

Returns true if C<< $val >> is a Result object. You should rarely need to
use C<< is_result() >> because a function which returns Results should
never return anything that isn't a Result.

C<< is_result() >> is not exported by default, but can be requested:

  use results qw( :default is_result );

=head2 Methods

The full set of methods available on Results is documented in
L<Result::Trait>, but a few important ones are described here. These
methods are C<< is_err() >>, C<< is_ok() >>, C<< unwrap() >>,
C<< unwrap_err() >>, C<< expect() >>, and C<< match() >>.

=head3 C<< $result->is_err() >>

Returns true if and only if the Result is an error.

=head3 C<< $result->is_ok() >>

Returns true if and only if the Result is a success.

=head3 C<< $result->unwrap() >>

Called on a successful Result, returns the result.

May be called in scalar or list context, and may return a list if
C<< ok() >> was given a list.

If called on an unsuccessful result (error), will promote the error to
a fatal error. (That is, calls C<die>.)

  my $upper_name = to_uppercase( $name );
  
  if ( $upper_name->is_ok() ) {
    say "HELLO ", $upper_name->unwrap();
  }
  else {
    warn "An error occurred!";
  }

If C<unwrap> is called, the Result is considered to be handled.

=head3 C<< $result->unwrap_err() >>

Called on a unsuccessful Result, returns the error.

May be called in scalar or list context, and may return a list if
C<< err() >> was given a list. A list of multiple values rarely makes
sense though.

If called on a successful result (error), will result in a fatal error.
(That is, calls C<die>.)

  my $upper_name = to_uppercase( $name );
  
  if ( $upper_name->is_ok() ) {
    say "HELLO ", $upper_name->unwrap();
  }
  else {
    warn "An error occurred: " . $upper_name->unwrap_err();
  }

If C<unwrap_err> is called, the Result is considered to be handled.

=head3 C<< $result->expect( $msg ) >>

Similar to C<unwrap>, but if called on an unsuccessful Result, dies with
the given error message.

If C<expect> is called, the Result is considered to be handled.

=head3 C<< $result->match( %dispatch_table ) >>

This provides an easy way to deal with different kinds of Results at the
same time.

  $result->match(
    err_Unauthorized   => sub { ... },
    err_FileNotFound   => sub { ... },
    err                => sub { ... },  # all other errors
    ok                 => sub { ... },
  );

=head3 Other methods

See L<Result::Trait> for other ways to concisely handle Results.

=head1 DIFFERENCES WITH RUST

Rust is strongly typed and can check many things at compile time which
this implementation cannot. These must all be done through self-discipline
in Perl. This includes:

=over

=item *

Ensuring that functions which return a Result cannot return a
non-Result.

=item *

Ensuring that the recipient of a Result handles that Result.

=item *

Ensuring that the type of the value inside the Result is expected by
the recipient. (L<Result::Trait> includes a handful of methods for run-time
enforcement of type constraints though.)

=back

Methods related to Rust's borrowing, copying, and cloning are not
implemented in L<Result::Trait> as they do not make a lot of sense.

=head1 EXPORTS

This module exports four functions:

=over

=item *

C<err>

=item *

C<ok>

=item *

C<ok_list>

=item *

C<is_result>

=back

By default, only the first two are exported, but you can list the functions
you want like this:

  use results qw( err ok ok_list is_result );

Or just:

  use results -all;

You can import no functions using:

  use results ();

And then just refer to them by their full name like C<< results::ok() >>.

You can rename functions:

  use results (
    ok   => { -as => 'Okay' },
    err  => { -as => 'Error' },
  );

Renaming imports may be useful if you find the default names conflict with
other modules you're using. In particular, L<Test::More> and other Perl testing
modules export a function called C<ok>.

=head2 Lexical exports

If you have Perl 5.37.2 or above, or install L<Lexical::Sub> on older versions
of Perl, you can import this module lexically using:

  use results -lexical;
  
  # or
  use results -lexical, -all;
  
  # or
  use results -lexical, (
    ok   => { -as => 'Okay' },
    err  => { -as => 'Error' },
  );

L<results::exceptions> also supports lexical exports:

  use results::exceptions -lexical, qw(
    UnexpectedRef
    UnexpectedUndef
  );

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-results/issues>.

=head1 SEE ALSO

L<Result::Trait>,
L<https://doc.rust-lang.org/std/result/>.

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

