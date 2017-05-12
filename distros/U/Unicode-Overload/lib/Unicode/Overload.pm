package Unicode::Overload;

use utf8;
use strict;
use warnings; # XXX Version-dependent
use Filter::Simple;
use Carp;

#use charnames ':full'; # AHA XXX THIS IS THE MODULE THAT CAUSES $WEIRD_ERROR
use vars qw($VERSION);

$VERSION = '0.01';

sub _map_params
	{
	my %legal_types =
		(
		prefix => 1,
		postfix => 1,
		infix => 1,
		outfix => 1,
		);
	my %ops = ();
	for(my $i=0;$i<@_;$i+=3)
		{
		my ($name,$type,$sub) = @_[$i..$i+2];
		croak "Illegal type '$type' for '$name'\n"
			unless defined $legal_types{$type};
		croak "Not a subroutine reference for '$name'\n"
			unless ref $sub eq 'CODE';
		croak "Outfix type requires an array reference of names\n"
			if $type eq 'outfix' and ref($name) ne 'ARRAY';
		croak "Outfix type only takes two characters\n"
			if $type eq 'outfix' and @$name != 2;

		if(ref $name eq 'ARRAY')
			{
			$ops{$name->[0]} = [ 'outfix_l' => $sub ];
			$ops{$name->[1]} = [ 'outfix_r' => $sub ];
			}
		else
			{
			$ops{$name} = [ $type => $sub ];
			}
		}
	\%ops;
	}

sub _unicode_subchr
	{
	my ($str_ref,$pos,$rep) = @_;
	my $len = 1;
	$len++ if ord(substr($$str_ref,$pos,1)) > 0x7F;
	$len++ if ord(substr($$str_ref,$pos,1)) > 0xDF;
	$len++ if ord(substr($$str_ref,$pos,1)) > 0xEF;
	substr($$str_ref,$pos,$len) = $rep;
	}

sub _outfix_r
	{
	my ($ops,$str_ref) = @_;
	for my $char (keys %$ops)
		{
		next unless $ops->{$char}[0] eq 'outfix_r';
		my $pos;
		while(($pos = index($$str_ref,$char)) >= 0)
			{
			_unicode_subchr($str_ref,$pos,')');
			}
		}
	}

sub _outfix_l
	{
	my ($ops,$str_ref) = @_;
	for my $char (keys %$ops)
		{
		next unless $ops->{$char}[0] eq 'outfix_l';
		while((my $pos = index($$str_ref,$char)) >= 0)
			{
			_unicode_subchr($str_ref,$pos,$ops->{$char}[2].'(');#'_floor(');
			}
		}
	}

sub _infix
	{
	my ($ops,$str_ref) = @_;
	for my $char (keys %$ops)
		{
		next unless $ops->{$char}[0] eq 'infix';
		while((my $pos = index($$str_ref,$char)) >= 0)
			{
			my $front = _balance_parens($$str_ref,$pos-1,-1);
			_unicode_subchr($str_ref,$pos,',');
			substr($$str_ref,$front,0) = $ops->{$char}[2];#'_element';
			}
		}
	}

sub _prefix
	{
	my ($ops,$str_ref) = @_;
	for my $char (keys %$ops)
		{
		next unless $ops->{$char}[0] eq 'prefix';
		while((my $pos = index($$str_ref,$char)) >= 0)
			{
			_unicode_subchr($str_ref,$pos,$ops->{$char}[2]);#'_sigma');
			}
		}
	}

sub _postfix
	{
	my ($ops,$str_ref) = @_;
	for my $char (keys %$ops)
		{
		next unless $ops->{$char}[0] eq 'postfix';
		while((my $pos = index($$str_ref,$char)) >= 0)
			{
			my $front = _balance_parens($$str_ref,$pos-1,-1);
			_unicode_subchr($str_ref,$pos,'');
			substr($$str_ref,$front,0) = $ops->{$char}[2];#'_square';
			}
		}
	}

sub _balance_parens # Assume it's starting on the appropriate paren
	{
	my ($str,$pos,$dir) = @_;
	if($dir > 0)
		{
		my $balance = 1;
		$pos++ while substr($str,$pos,1) =~ /\s/;
		while($pos++ < length($str))
			{
			$balance++ if substr($str,$pos,1) eq '(';
			$balance-- if substr($str,$pos,1) eq ')';
			return $pos if $balance == 0;
			}
		return -1;
		}
	else
		{
		my $balance = 1;
		$pos-- while substr($str,$pos,1) =~ /\s/;
		while(--$pos > 0)
			{
			$balance-- if substr($str,$pos,1) eq '(';
			$balance++ if substr($str,$pos,1) eq ')';
			return $pos if $balance == 0;
			}
		return -1;
		}
	}

my $package;
BEGIN { $package = (caller(0))[0]; }; # Filter::Simple gets in the way here
use Filter::Simple;
FILTER_ONLY code => sub
	{
	shift @_;
	croak "Incorrect number of parameters\n" if @_ % 3;
	my $ops = _map_params(@_);
	my @lines = split /\n/;
	my $sym = 'aaaa';
	for(keys %$ops)
		{
		$ops->{$_}[2]='_'.$sym++;
		}
	{ no strict 'refs';
	use POSIX;
	for(keys %$ops)
		{
		*{$package.'::'.$ops->{$_}[2]}=$ops->{$_}[1];
		}
	};
	_outfix_r($ops,\$_);
	_outfix_l($ops,\$_);
	_infix($ops,\$_);
	_prefix($ops,\$_);
	_postfix($ops,\$_);
#die "<$_>\n";
	};

1;
__END__

=head1 NAME

Unicode::Overload - Perl source filter to implement Unicode operations

=head1 SYNOPSIS

  use charnames ':full';
  use Unicode::Overload (
    "\N{UNION}" => infix =>
      sub { my %a = map{$_=>1}@{$_[0]};
            my %b = map{$_=>1}@{$_[1]};
            return keys(%a,$b); },
    "\N{SUPERSCRIPT TWO}" => postfix => sub { $_[0] ** 2 },
    "\N{NOT SIGN}" => prefix => sub { !$_[0] },
    [ "\N{LEFT FLOOR}", "\N{RIGHT FLOOR}" ] => outfix =>
      sub { POSIX::floor($_[0]) },
  );

  @union = (@a \N{UNION @b); # Parentheses REQUIRED
  die "Pythagoras was WRONG!" # Same here
    unless sqrt((3)\N{SUPERSCRIPT TWO} + (4)\N{SUPERSCRIPT TWO}) == 5;
  $b = \N{NOT SIGN}($b); # Required here too
  die "Fell through floor" # Balanced characters form their own parentheses
    unless \N{LEFT FLOOR}-3.2\N{RIGHT FLOOR} == 4;

=head1 DESCRIPTION

Allows you to declare your own Unicode operators and have them behave as
prefix (like sigma or integral), postfix (like superscripted 2), infix (like
union), or outfix (like the floor operator, with the 'L'-like and 'J'-like
brackets).

To keep this document friendly to people without UTF-8 terminals, the \N{}
syntax for Unicode characters will be used throughout, but please note that
the \N{} characters can be replaced with the actual UTF-8 characters anywhere.

Also, please note that since Perl 5 doesn't support the notion of arbitrary
operators, this module cheats and uses source filters to do its job. As such,
all "operators" must have their arguments enclosed in parentheses. This
limitation will be lifted when a better way to do this is found.

Also, note that since these aren't "real" operators there is no way (at the
moment) to specify precedence. All Unicode "operators" have the precedence
(such as it is) of function calls, as they all get transformed into function
calls inline before interpreting.

In addition, due to a weird unicode-related bug, only one character per operator
is currently permitted. Despite behaving correctly elsewhere, C<substr()>
thinks that one character equals one byte inside L<Unicode::Overload> .

Anyway, this module defines four basic types of operators. Prefix and infix
should be familiar to most users of perl, as prefix operators are basically
function calls without the parens. Infix operators are of course the familiar
C<+> etcetera.

The best analogy for postfix operators is probably the algebraic notation for
squares. C<$a**2> is perl's notation, C<($a)\N{SUPERSCRIPT TWO}> is the
L<Unicode::Overload> equivalent, looking much closer to a mathematical
expression, with the '2' in its proper position.

Outfix is the last operator, and a little odd. Outfix can best be thought of
as user-definable brackets. One of the more common uses for this notation again
comes from mathematics in the guise of the floor operator. Looking like brackets
with the top bar missing, they return effectively POSIX::floor() of their
contents.

Since outfix operators define their own brackets, extra parentheses are not
needed on this type of operator.

A quick summary follows:

=over

=item prefix

Operator goes directly before the parentheses containing its operands. 
Whitespace is allowed between the operator and opening parenthesis. This acts
like a function call.

Sample: C<\N{NOT SIGN}($b)>

=item postfix

Operator goes directly after the parentheses containing its operands. Whitespace
is allowed between the closing parenthesis and operator. This doesn't have a
good Perl equivalent, but there are many equivalents in algebra, probably the
most common being:

Sample: C<($a+$b)\N{SUPERSCRIPT TWO}>

=item infix

Operator goes somewhere inside the parentheses.
Whitespace is allowed between either parenthesis and the operator.

Sample: C<($a \N{ELEMENT OF} @list)>

=item outfix

Operators surround their arguments and are translated into parentheses. As
such, whitespace is allowed anywhere inside the operator pairs. There is no
requirement that the operators be visually symmetrical, although it helps.

Sampe: C<$c=\N{LEFT FLOOR}$a_+$b\N{RIGHT FLOOR}>

=back

The requirements for parentheses will be removed as soon as I can figure out how
to make these operators behave closer to perl builtins. Nesting is perfectly
legal, but multiple infix operators can't coexists within one set of parentheses.

=head2 EXPORT

=head1 SEE ALSO

L<Filter::Simple>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
