package Unicode::Regex::Set;

require 5.008;

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(parse maketree tostring);
our @EXPORT    = ();

our $VERSION = '0.04';
our $PACKAGE = __PACKAGE__;

use constant TRUE  => 1;
use constant FALSE => '';

my %Meaning = (
    '[' => 'group beginning',
    ']' => 'group end',
    '&' => 'intersection',
    '|' => 'union',
    ''  => 'union',
    '-' => 'subtraction',
);

#  Token combination table:  e.g  '[' followed by '&' is NG.
#
#	1\2   '['  ']'  '&'  '|'  '-'  Lit
#	'['   OK   NG   NG   NG   NG   OK
#	']'   OK   OK   OK   OK   OK   OK
#	'&'   OK   NG   NG   NG   NG   OK
#	'|'   OK   NG   NG   NG   NG   OK
#	'-'   OK   NG   NG   NG   NG   OK
#	Lit   OK   OK   OK   OK   OK   OK
#
#  Lit, literal, includes A-Z, \[, \|, \-, '\ ' (escaped space), \n, \r,
#       \t, \f, \cA, \ooo, \xhh, \x{hhhh}, \p{Prop}, \N{NAME}, [:posix:].
#       They are retained as they are.
# [=oops=] are not considered.

sub parse { tostring(maketree(@_)) }

#   $node = {
#	parent  => $node_or_undef, # undef for root
#	neg     => $boolean, # true if group begins with '[^'
#	follow  => $boolean, # true if requires literal
#	op      => $char,    # '&', '-', '|'
#	childs  => $arrayref_of_nodes,
#    }

sub maketree {
    my $cur;
    my $arg = shift;

    foreach (ref $arg ? $$arg : $arg) # store in $_
    {
	if (!s/^\[//) {
	    croak "a character class not beginning at [";
	}
	$cur = { parent => undef, op => FALSE, childs => [] };
	s/^\^// and $cur->{neg} = TRUE;

	while (1) {

	    # skip whitespaces
	    if (s/^\s+//) {
		next;
	    }

	    # beginning of a group
	    if (s/^\[  (?! \: [^\[\]]+ \:\] )//x) {
		if ($cur->{op} eq '&' && !$cur->{follow}) {
		    $cur = $cur->{parent};
		}

		push @{ $cur->{childs} },
			+{ parent => $cur, op => FALSE, childs => [] };

		$cur = $cur->{childs}->[-1];
		s/^\^// and $cur->{neg} = TRUE;
		next;
	    }

	    # end of a group
	    if (s/^\]//) {
		if (! $cur->{childs} || ! @{ $cur->{childs} }) {
		    croak "empty (sub)group in a character class";
		}

		if ($cur->{op} eq '&' && !$cur->{follow}) {
		    $cur = $cur->{parent};
		}

	    # LAST:
		last if ! $cur->{parent};

		if ($cur->{follow}) {
		    my $op = $cur->{op};
		    croak "no operand after '$op' ($Meaning{$op})";
		}

		$cur = $cur->{parent};

		$cur->{follow} and $cur->{follow} = FALSE;
		next;
	    }

	    # operators
	    if (s/^([\&\|\-])(?=[\s\[\]])//) {
		my $o = $1;

		if (! $cur->{childs} || ! @{ $cur->{childs} }) {
		    croak "no operand before '$o' ($Meaning{$o})";
		}

		if ($cur->{follow}) {
		    my $p = $cur->{op};
		    croak "no operand between '$p' ($Meaning{$p}) "
			. "and '$o' ($Meaning{$o})";
		}

		if ($cur->{op} eq $o)
		{
		    $cur->{follow} = TRUE;
		    next;
		}

		if ($cur->{op} eq '&' && !$cur->{follow})
		    # in this case $op must not be '&' (see the prev block)
		    # '&' has high precedence: [A & B - C] as [[A & B] - C]
		{
		    $cur = $cur->{parent};
		}

		if ($o eq '&')
		    # '&' has high precedence: [A B & C D] as [A [B & C] D]
		{
		    my $last = pop @{ $cur->{childs} };

		    push @{ $cur->{childs} },
			{ parent => $cur, op => $o, childs => [ $last ] };

		    $cur = $cur->{childs}->[-1];
		    $cur->{follow} = TRUE;
		    next;
		}

		if ($o eq '-') {
		    if (@{ $cur->{childs} } > 1)
			# '-' has low precedence: [A B - C] as [[A B] - C]
		    {
			my @kids = @{ $cur->{childs} };
			@{ $cur->{childs} } =
			    { parent => $cur, op => FALSE, childs => \@kids };
		    }

		    $cur->{op} = $o;
		    next;
		}

		if ($o eq '|') { # simple union
		    $cur->{op} = $o;
		    next;
		}
	    }


	    if (s/^((?:
		    \\[pPN]\{ [^{}]* \}
		  | \\c?(?s:.)
		  | [^\s\[\]]
		  | \[\: [^\[\]]+ \:\]
			)+)//x)
	    {
		my $lit = $1;

		if ($lit eq '^') {
		    croak "A bare '^', that has nothing to be negated.";
		}

		if ($cur->{op} eq '&' && !$cur->{follow})
		    # '&' has high precedence: [A & B C] as [[A & B] C]
		{
		    $cur = $cur->{parent};
		}

		$cur->{follow} and $cur->{follow} = FALSE;
		my $kid = $cur->{childs};

		if (@$kid
		    && ! ref($kid->[-1])
		    && $lit	  !~ /^[\-\^]/
		    && $kid->[-1] !~ /^\[\^/
		    && $kid->[-1] !~ /\-\]\z/
		    && $cur->{op} ne '&'
		    && !($cur->{op} eq '-' && @$kid == 1))
		# this is only simplification, so avoids uncertain cases
		{
		    substr($kid->[-1], -1, 0, $lit);
		}
		else {
		    push @$kid, "[$lit]";
		}
		next;
	    }

	    croak "panic or incomplete character class (missing last ']'?);";
	}
    }

    return $cur;
}

sub tostring {
    my $list = shift;

    for (@{ $list->{childs} }) {
	next  if !ref($_);
	croak "panic" if ref($_) ne 'HASH';
	$_ = tostring($_); # recursive
    }
    my $ret;
    my $op   = $list->{op} || FALSE;
    my $kids = $list->{childs};

    if ($op eq '&') {
	my $base = shift @$kids;
	my $pre  = join '', map "(?=$_)", @$kids;
	$ret = "(?:$pre$base)";
    }
    elsif ($op eq '-') {
	my $base = shift @$kids;
	my $pre  = join('|', @$kids);
	$ret = "(?:(?!$pre)$base)";
    }
    else {
	$ret = @$kids > 1 ? "(?:".join('|', @$kids).")" : $kids->[0];
    }
    return $list->{neg} ? "(?:(?!$ret)(?s:.))" : $ret;
}

1;
__END__

=head1 NAME

Unicode::Regex::Set - Subtraction and Intersection of Character Sets
in Unicode Regular Expressions

=head1 SYNOPSIS

    use Unicode::Regex::Set qw(parse);

    $regex = parse('[\p{Latin} & \p{L&} - A-Z]');

=head1 DESCRIPTION

Perl 5.8.0 misses subtraction and intersection of characters,
which is described in Unicode Regular Expressions (UTS #18).
This module provides a mimic syntax of character classes
including subtraction and intersection,
taking advantage of look-ahead assertions.

The syntax provided by this module is considerably incompatible
with the standard Perl's regex syntax.

Any whitespace character (that matches C</\s/>) is allowed between any tokens.
Square brackets (C<'['> and C<']'>) are used for grouping.
A literal whitespace and square brackets must be backslashed
(escaped with a backslash, C<'\'>).
You cannot put literal C<']'> at the start of a group.

A POSIX-style character class like C<[:alpha:]> is allowed
since its C<'['> is not a literal.

SEPARATORS (C<'&'> for intersection, C<'|'> for union, and C<'-'>
for subtraction) should be enclosed with one or more whitespaces.
E.g. C<[A&Z]> is a list of C<'A'>, C<'&'>, C<'Z'>.
C<[A-Z]> is a character range from C<'A'> to C<'Z'>.
C<[A-Z - Z]> is a set by removal of C<[Z]> from C<[A-Z]>.

Union operator C<'|'> may be omitted.
E.g. C<[A-Z | a-z]> is equivalent to C<[A-Z a-z]>,
and also to C<[A-Za-z]>.

Intersection operator C<'&'> has high precedence,
so C<[\p{A} \p{B} & \p{C} \p{D}]> is equivalent to
C<[\p{A} | [\p{B} & \p{C}] | \p{D}]>.

Subtraction operator C<'-'> has low precedence,
so C<[\p{A} \p{B} - \p{C} \p{D}]> is equivalent to
C<[[\p{A} | \p{B}] - [\p{C} | \p{D}] ]>.

C<[\p{A} - \p{B} - \p{C}]> is a set
by removal of C<\p{B}> and C<\p{C}> from C<\p{A}>.
It is equivalent to C<[\p{A} - [\p{B} \p{C}]]> and C<[\p{A} - \p{B} \p{C}]>.

Negation. when C<'^'> just after a group-opening C<'['>,
i.e. when they are combined as C<'[^'>, all the tokens following are negated.
E.g. C<[^A-Z a-z]> matches anything but neither C<[A-Z]> nor C<[a-z]>.
More clearly you can say this with grouping as C<[^ [A-Z a-z]]>.

If C<'^'> that is not next to C<'['> is prefixed
to a sequence of literal characters, character ranges,
and/or metacharacters, such a C<'^'> only negates that sequence;
e.g. C<[A-Z ^\p{Latin}]> matches C<A-Z> or a non-Latin character.
But C<[A-Z [^\p{Latin}]]> (or C<[A-Z \P{Latin}]>, for this is a simple case)
is recommended for clarity.

If you want to remove anything other than C<PERL> from C<[A-Z]>,
use C<[A-Z & PERL]> as well as C<[A-Z - [^PERL]]>.
Similarly, if you want to intersect C<[A-Z]> and a thing not C<JUNK>,
use C<[A-Z - JUNK]> as well as  C<[A-Z & [^JUNK]]>.

For further examples, please see tests.

=head1 FUNCTION

=over 4

=item C<$perl_regex = parse($unicode_character_class)>

parses a Character Class pattern according to F<Unicode Regular Expressions>
and converts it into a regular expression in Perl (returned as a string).

=back

=head1 AUTHOR

SADAHIRO Tomoyuki <SADAHIRO@cpan.org>

Copyright(C) 2003, SADAHIRO Tomoyuki. Japan. All rights reserved.

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item http://www.unicode.org/unicode/reports/tr18/

Unicode Regular Expression Guidelines - UTR #18
(to be Unicode Regular Expressions - UTS #18)

=back

=cut

