package match::simple;

use 5.006001;
use strict;
use warnings;

use Exporter::Tiny;
use List::Util 1.33 qw(any);
use Scalar::Util qw(blessed);

BEGIN {
	$match::simple::AUTHORITY = 'cpan:TOBYINK';
	$match::simple::VERSION   = '0.010';
}

our @ISA       = qw( Exporter::Tiny );
our @EXPORT    = qw( M );
our @EXPORT_OK = qw( match );

my $xs;
unless (($ENV{MATCH_SIMPLE_IMPLEMENTATION}||'') =~ /pp/i)
{
	eval {
		require match::simple::XS;
		match::simple::XS->VERSION(0.001);  # minimum
		
		# Unless we're a development version...
		# Avoid using an unstable version of ::XS
		unless (match::simple->VERSION =~ /_/)
		{
			die if match::simple::XS->VERSION =~ /_/;
		}
			
		$xs = match::simple::XS->can('match');
	};
}

eval($xs ? <<'XS' : <<'PP');

sub IMPLEMENTATION () { "XS" }

*match = *match::simple::XS::match;

XS

sub IMPLEMENTATION () { "PP" }

sub match
{
	no warnings qw(uninitialized numeric);
	
	my ($a, $b) = @_;
	
	return(!defined $a)                    if !defined($b);
	return($a eq $b)                       if !ref($b);
	return($a =~ $b)                       if ref($b) eq q(Regexp);
	return do{ local $_ = $a; !!$b->($a) } if ref($b) eq q(CODE);
	return any { match($a, $_) } @$b       if ref($b) eq q(ARRAY);
	return !!$b->check($a)                 if blessed($b) && $b->isa("Type::Tiny");
	return !!$b->MATCH($a, 1)              if blessed($b) && $b->can("MATCH");
	return eval 'no warnings; !!($a~~$b)'  if blessed($b) && $] >= 5.010 && do { require overload; overload::Method($b, "~~") };
	
	require Carp;
	Carp::croak("match::simple cannot match anything against: $b");
}

PP

sub _generate_M
{
	require Sub::Infix;
	&Sub::Infix::infix(\&match);
}

1;

__END__

=pod

=encoding utf-8

=for stopwords smartmatch recurses

=head1 NAME

match::simple - simplified clone of smartmatch operator

=head1 SYNOPSIS

   use v5.10;
   use match::simple;
   
   if ($this |M| $that)
   {
      say "$this matches $that";
   }

=head1 DESCRIPTION

match::simple provides a simple match operator C<< |M| >> that acts like
a sane subset of the (as of Perl 5.18) deprecated smart match operator.
Unlike smart match, the behaviour of the match is determined entirely by
the operand on the right hand side.

=over

=item *

If the right hand side is C<undef>, then there is only a match if the left
hand side is also C<undef>.

=item *

If the right hand side is a non-reference, then the match is a simple string
match.

=item *

If the right hand side is a reference to a regexp, then the left hand is
evaluated .

=item *

If the right hand side is a code reference, then it is called in a boolean
context with the left hand side being passed as an argument.

=item *

If the right hand side is an object which provides a C<MATCH> method, then
it this is called as a method, with the left hand side being passed as an
argument.

=item *

If the right hand side is an object which overloads C<~~>, then a true
smart match is performed.

=item *

If the right hand side is an arrayref, then the operator recurses into the
array, with the match succeeding if the left hand side matches any array
element.

=item *

If any other value appears on the right hand side, the operator will croak.

=back

If you don't like the crazy L<Sub::Infix> operator, you can alternatively
export a more normal function:

   use v5.10;
   use match::simple qw(match);
   
   if (match($this, $that))
   {
      say "$this matches $that";
   }

If you're making heavy use of this module, then this is probably your best
option, as it runs significantly faster.

=head2 XS Backend

If you install match::simple::XS, a faster XS-based implementation will be
used instead of the pure Perl functions. Depending on what sort of match you
are doing, this is likely to be several times faster. In extreme cases, such
as matching a string in an arrayref, it can be twenty-five times faster, or
more. However, where C<< $that >> is a single regexp, it's around 30% slower.
Overall though, I think the performance improvement is worthwhile.

If you want to take advantage of this speed up, use the C<match> function
rather than the C<< |M| >> operator. Otherwise all your gains will be lost to
the slow implementation of operator overloading.

The constant C<< match::simple::IMPLEMENTATION >> tells you which backend
is currently in use.

=head2 Environment

Setting the C<MATCH_SIMPLE_IMPLEMENTATION> environment variable to "PP"
encourages match::simple to use the pure Perl backend.

=begin trustme

=item M

=item match

=item IMPLEMENTATION

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=match-simple>.

=head1 SEE ALSO

L<match::smart>.

This module uses L<Exporter::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

