use 5.014;
use strict;
use warnings;

use results ();

package results::wrap;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

BEGIN {
	if ( $] ge '5.034' ) {
		require experimental;
		'experimental'->import( 'try' );
	}
	else {
		require Syntax::Keyword::Try;
		'Syntax::Keyword::Try'->import;
	}
};

sub AUTOLOAD {
	my ( $invocant, @args ) = @_;
	my ( $method ) = ( our $AUTOLOAD =~ /::(\w+)$/ );
	try {
		return results::ok( $invocant->$method( @args ) );
	}
	catch ( $e ) {
		return results::err( $e );
	}
}

sub results::wrap (&) {
	if ( @_ == 1 and ref($_[0]) eq 'CODE' ) {
		my ( $code ) = @_;
		try {
			return results::ok( $code->() );
		}
		catch ( $e ) {
			return results::err( $e );
		}
	}
	else {
		my ( $invocant, $method, @args ) = @_;
		try {
			return results::ok( $invocant->$method( @args ) );
		}
		catch ( $e ) {
			return results::err( $e );
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

results::wrap - wrap a method call in a Result

=head1 SYNOPSIS

Assuming that C<< $object->foo( @args ) >> is a method call which might return
a value or throw an exception, you can convert it to an ok/err Result using:

  use results::wrap;
  
  my $result = $object->results::wrap::foo( @args );

Or:

  use results::wrap;
  
  my $result = $object->results::wrap( foo => @args );

Or:

  use results::wrap;

  my $result = results::wrap { $object->foo( @args ) };

=head1 DESCRIPTION

This module uses AUTOLOAD to provide a Result wrapper around any method call.

It also provides a C<< results::wrap >> sub which can be either passed a
list of C<< $invocant >>, C<< $method >>, C<< @args >> or a single coderef.

C<< results::wrap >> is conveniently prototyped with C<< (&) >> to that it can
be called with a block.

  my $result = results::wrap {
    if ( $failing_condition ) {
      die "Error";
    }
    else {
      return "Value";
    }
  };

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-results/issues>.

=head1 SEE ALSO

L<results>.

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

