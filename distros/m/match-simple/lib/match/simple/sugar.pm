package match::simple::sugar;

use 5.006001;
use strict;
use warnings;

use Exporter::Tiny;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use match::simple qw( match );

BEGIN {
	$match::simple::sugar::AUTHORITY = 'cpan:TOBYINK';
	$match::simple::sugar::VERSION   = '0.012';
	my $strict = 0;
	$ENV{$_} && $strict++ for qw(
		EXTENDED_TESTING
		AUTHOR_TESTING
		RELEASE_TESTING
		PERL_STRICT
	);
	eval qq{
		sub STRICT () { !! $strict }
		sub LAX    () {  ! $strict }
	};
}

our @ISA       = qw( Exporter::Tiny );
our @EXPORT    = qw( when then numeric match );

my $then_class    = __PACKAGE__ . '::then';
my $numeric_class = __PACKAGE__ . '::numeric';

sub when {
	my @things = @_;
	my $then = pop @things;
	if ( blessed $then and $then->isa( $then_class ) ) {
		if ( match $_, \@things ) {
			no warnings 'exiting';
			$then->();
			next;
		}
	}
	else {
		croak "when: expects then";
	}
	return;
}

sub _check_coderef {
	my $coderef = shift;
	require B;
	local *B::OP::__match_simple_sugar_callback = sub {
		my $name = $_[0]->name;
		croak "Block appears to contain a `$name` statement; not suitable for use with when/then"
			if match $name, [ qw/ wantarray return redo last next / ];
		return;
	};
	B::svref_2object( $coderef )->ROOT->B::walkoptree( '__match_simple_sugar_callback' );
}

sub then (&) {
	my $coderef = shift;
	_check_coderef $coderef if STRICT;
	bless $coderef, $then_class;
}

sub numeric ($) {
	my $n = shift;
	bless \$n, $numeric_class;
}

{
	my $check = sub {
		my ( $x, $y ) = map {
			( blessed $_ and $_->isa( $numeric_class ) )
				? $$_
				: $_;
		} @_[0, 1];
		no warnings qw( numeric );
		defined $x and defined $y and !ref $x and !ref $y and $x == $y;
	};
	no strict 'refs';
	*{"$numeric_class\::MATCH"} = $check;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords smartmatch recurses

=head1 NAME

match::simple::sugar - a few extras for match::simple

=head1 SYNOPSIS

This module provides a C<given>/C<when> substitute for L<match::simple>.

   use match::simple::sugar;
   
   for ( $var ) {
      when 'foo',        then { ... };
      when 'bar', 'baz', then { ... };
      ...;  # otherwise
   }

It also provides a function for numeric matching (because L<match::simple>
always assumes you want stringy matching if the right-hand-side is a defined
non-reference value).

   use match::simple::sugar;
   
   for ( $var ) {
      when numeric 0, then { ... };
      when numeric 1, then { ... };
      ...;  # otherwise
   }


=head1 DESCRIPTION

This module exports three functions C<when>, C<then>, and C<numeric>,
and also re-exports C<match> from L<match::simple>.

=head2 C<when> and C<then>

The C<when> and C<then> functions are intended to be used together,
inside a C<< for ( SCALAR ) { ... } >> block. The block acts as a
topicalizer (it sets C<< $_ >>) and also a control-flow mechanism
(C<when> can use C<next> to jump out of it). Any other use of C<when>
and C<then> is unsupported.

=head3 C<< when( @values, $then ) >>

The C<when> function accepts a list of values, followed by a special
C<< $then >> argument.

If C<< $_ >> matches (according to the definition in L<match::simple>)
any of the values, then the C<< $then >> argument will be executed, and
C<when> will use the Perl built-in C<next> keyword to jump out of the
surrounding C<for> block.

=head3 C<< then { ... } >>

The C<then> function takes a block of code and returns an object suitable
for use as C<when>'s C<< $then >> argument.

In the current implementation, the block of code should not inspect
C<< @_ >> or C<wantarray>, and should not use the C<return>, C<next>,
C<last>, or C<redo> keywords. (If you set any of the C<PERL_STRICT>,
C<EXTENDED_TESTING>, C<AUTHOR_TESTING>, or C<RELEASE_TESTING> environment
variables to true, then match::simple::sugar will I<try> to enforce this!
This is intended to catch faulty C<then> blocks when running your test
suite.)

=head2 C<numeric>

The C<numeric> function accepts a number and returns a blessed object
which has a C<MATCH> method. The C<MATCH> method returns true if it is
called with a single defined non-referece scalar that is numerically
equal to the original number passed to C<numeric>. Example:

   numeric( '5.0' )->MATCH( '5.000' );    # true

This is intended for use in cases like:

   if ( match $var, numeric 1 ) {
      ...;
   }

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-match-simple/issues>.

=head1 SEE ALSO

L<match::simple>.

This module uses L<Exporter::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

This module is inspired by a talk I gave to
L<Boston.PM|https://boston-pm.github.io/>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

