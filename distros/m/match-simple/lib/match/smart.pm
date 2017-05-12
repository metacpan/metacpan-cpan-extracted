package match::smart;

use 5.006001;
use strict;
use warnings;

use B qw();
use Exporter::Tiny;
use List::Util 1.33 qw(any all);
use Scalar::Util qw(blessed looks_like_number refaddr);

BEGIN {
	$match::smart::AUTHORITY = 'cpan:TOBYINK';
	$match::smart::VERSION   = '0.010';
}

our @ISA       = qw( Exporter::Tiny );
our @EXPORT    = qw( M );
our @EXPORT_OK = qw( match );

sub match
{
	no warnings qw(uninitialized numeric);
	
	my ($a, $b, $seen) = @_;
	
	return(!defined $a)                    if !defined($b);
	return !!$b->check($a)                 if blessed($b) && $b->isa("Type::Tiny");
	return !!$b->MATCH($a, 1)              if blessed($b) && $b->can("MATCH");
	return eval 'no warnings; !!($a~~$b)'  if blessed($b) && $] >= 5.010 && do { require overload; overload::Method($b, "~~") };
	
	if (blessed($b) and not $b->isa("Regexp"))
	{
		require Carp;
		Carp::croak("Smart matching a non-overloaded object breaks encapsulation");
	}
	
	$seen ||= {};
	my $refb = refaddr($b);
	return refaddr($a)==$refb if $refb && $seen->{$refb}++;
	
	if (ref($b) eq q(ARRAY))
	{
		if (ref($a) eq q(ARRAY))
		{
			return !!0 unless @$a == @$b;
			for my $i (0 .. $#$a)
			{
				return !!0 unless match($a->[$i], $b->[$i], $seen);
			}
			return !!1;
		}
		
		return any { exists $a->{$_} } @$b  if ref($a) eq q(HASH);
		return any { $_ =~ $a } @$b         if ref($a) eq q(Regexp);
		return any { !defined($_) } @$b     if !defined($a);
		return any { match($a, $_) } @$b;
	}
	
	if (ref($b) eq q(HASH))
	{
		return match([sort map "$_", keys %$a], [sort map "$_", keys %$b])
			if ref($a) eq q(HASH);
		
		return any { exists $b->{$_} } @$a  if ref($a) eq q(ARRAY);
		return any { $_ =~ $a } keys %$b    if ref($a) eq q(Regexp);
		return !!0                          if !defined($a);
		return exists $b->{$a};
	}
	
	if (ref($b) eq q(CODE))
	{
		return all { !!$b->($_) } @$a       if ref($a) eq q(ARRAY);
		return all { !!$b->($_) } keys %$a  if ref($a) eq q(HASH);
		return $b->($a);
	}
	
	if (ref($b) eq q(Regexp))
	{
		return any { $_ =~ $b } @$a       if ref($a) eq q(ARRAY);
		return any { $_ =~ $b } keys %$a  if ref($a) eq q(HASH);
		return $a =~ $b;
	}
	
	return !!$a->check($b)                 if blessed($a) && $a->isa("Type::Tiny");
	return !!$a->MATCH($b)                 if blessed($a) && $a->can("MATCH");
	return eval 'no warnings; !!($a~~$b)'  if blessed($a) && $] >= 5.010 && do { require overload; overload::Method($a, "~~") };
	return !defined($b)                    if !defined($a);
	return $a == $b                        if _is_number($b);
	return $a == $b                        if _is_number($a) && looks_like_number($b);
	
	return $a eq $b;
}

sub _is_number
{
	my $value = shift;
	return if ref $value;
	my $flags = B::svref_2object(\$value)->FLAGS;
	$flags & ( B::SVp_IOK | B::SVp_NOK ) and !( $flags & B::SVp_POK );
}

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

match::smart - clone of smartmatch operator

=head1 SYNOPSIS

   use v5.10;
   use match::smart;
   
   if ($this |M| $that)
   {
      say "$this matches $that";
   }

=head1 DESCRIPTION

match::smart provides a match operator C<< |M| >> that acts like more or
less identically to the (as of Perl 5.18) deprecated smart match operator.

If you don't like the crazy L<Sub::Infix> operator, you can alternatively
export a more normal function:

   use v5.10;
   use match::smart qw(match);
   
   if (match($this, $that))
   {
      say "$this matches $that";
   }

=head2 Differences with ~~

There were major changes to smart match between 5.10.0 and 5.10.1. This
module attempts to emulate the behaviour of the operator in more recent
versions of Perl. In particular, 5.18.0 (minus the warnings). Divergences
not noted below should be considered bugs.

While the real smart match operator implicitly takes references to operands
that are hashes or arrays, match::smart's operator does not.

   @foo ~~ %bar       # means: \@foo ~~ \%bar
   @foo |M| %bar      # means: scalar(@foo) |M| scalar(%bar)

If you want the C<< \@foo ~~ \%bar >> behaviour, you need to add the
backslashes yourself:

   \@foo |M| \%bar

Similarly:

   "foo" ~~  /foo/    # works
   "foo" |M| /foo/    # no worky!
   "foo" |M| qr/foo/  # do this instead

match::smart treats the C<MATCH> method on blessed objects (if it exists)
like an overloaded C<< ~~ >>. This is for compatibility with L<match::simple>,
and for compatibility with pre-5.10 Perls that don't allow overloading
C<< ~~ >>.

=begin trustme

=item M

=item match

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=match-simple>.

=head1 SEE ALSO

L<match::simple>.

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

