package Perl::Critic::Policy::ProhibitRegexForSimpleSubstring;
$Perl::Critic::Policy::ProhibitRegexForSimpleSubstring::VERSION = '1.001';
# ABSTRACT: Use index() to look for literal text, and leave split its pattern.

use strict;
use warnings;

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Regex used for a simple substring match};
Readonly::Scalar my $EXPL => q{Use index() instead of a regex when looking for literal text};

Readonly::Array my @DEFAULT_ALLOW => qw{ split };

# The one modifier that changes what a pattern of literals matches: index() is
# case sensitive.  See MODIFIERS in the POD for why /m, /s and /x are not here.
Readonly::Scalar my $EXEMPTING_MODIFIER => 'i';

# Operators that sit between arguments rather than inside one.  The
# low-precedence ones end a list operator's arguments: split m/,/, $s or die.
Readonly::Hash my %SEPARATOR => map { $_ => 1 } ( q{,}, q{=>}, qw{ or and xor } );


sub supported_parameters {
    return (
        {
            name           => 'allow',
            description    => 'Functions and methods whose first argument may be a literal regex, in addition to split.',
            default_string => join( q{ }, @DEFAULT_ALLOW ),
            behavior       => 'string list',
        }
    );
}


sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    # 'string list' hands us the configured value in place of the default, and
    # somebody naming one function of their own did not mean to start reporting
    # split.
    $self->{_allow}{$_} = 1 for @DEFAULT_ALLOW;

    return $self->SUPER::initialize_if_enabled($config);
}


sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw{ performance } }
sub applies_to       { return 'PPI::Token::Regexp::Match' }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    return if !_is_literal_text( $elem, $doc );

    my $call = _call_taking_it_first($elem);
    return if $call && $self->_allowed($call);

    return $self->violation( $DESC, $EXPL, $elem );
}

# No /i, whether written on the match or in scope from a use re, and every
# significant token of the pattern a literal.
sub _is_literal_text {
    my ( $elem, $doc ) = @_;

    my $re = $doc->ppix_regexp_from_element($elem) or return 0;
    return 0 if $re->failures();
    return 0 if $re->modifier_asserted($EXEMPTING_MODIFIER);

    my $pattern = $re->regular_expression() or return 0;

    my $has_literal = 0;
    foreach my $token ( map { $_->tokens() } $pattern->children() ) {
        next     if !$token->significant();
        return 0 if !$token->isa('PPIx::Regexp::Token::Literal');
        $has_literal = 1;
    }
    return $has_literal;
}

# The word naming the call $node is the whole of the first argument to, or
# nothing.  Looks through parentheses around it, and stops at anything else: a
# block, a subscript, a constructor, the statement.
sub _call_taking_it_first {
    my ($node) = @_;

    return if !_is_whole_argument($node);

    # `split m/,/, $s`: the call is the word straight before it, and anything
    # else straight before it means this is not the first argument.
    my $before = $node->sprevious_sibling();
    if ($before) {
        return $before if $before->isa('PPI::Token::Word') && is_function_call($before);
        return;
    }

    # `split( m/,/, $s )`: first in a list, which belongs to the word before it.
    my $expression = $node->parent();
    my $list       = $expression && $expression->parent();
    return if !$list || !$list->isa('PPI::Structure::List');

    my $caller = $list->sprevious_sibling();
    return $caller if $caller && $caller->isa('PPI::Token::Word');

    # `split( ( m/,/ ), $s )`: parentheses of its own, first in the call's.
    return _call_taking_it_first($list);
}

sub _is_whole_argument {
    my ($node) = @_;

    foreach my $neighbour ( $node->sprevious_sibling(), $node->snext_sibling() ) {
        next     if !$neighbour || !$neighbour->isa('PPI::Token::Operator');
        return 0 if !$SEPARATOR{ $neighbour->content() };
    }
    return 1;
}

# An entry with no package matches the name however it is reached; one with a
# package matches only a call that names that package, as Pkg::name or
# Pkg->name.
sub _allowed {
    my ( $self, $word ) = @_;

    my $name  = $word->content();
    my $arrow = $word->sprevious_sibling();
    if ( $arrow && $arrow->content() eq '->' ) {
        my $invocant = $arrow->sprevious_sibling();
        return $self->{_allow}{"${invocant}::$name"} || $self->{_allow}{$name}
          if $invocant && $invocant->isa('PPI::Token::Word');
        return $self->{_allow}{$name};
    }

    my $short = $name =~ s/\A.*:://r;
    return $self->{_allow}{$name} || $self->{_allow}{$short};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ProhibitRegexForSimpleSubstring - Use index() to look for literal text, and leave split its pattern.

=head1 VERSION

version 1.001

=head1 Perl::Critic::Policy::ProhibitRegexForSimpleSubstring

A regular expression made of nothing but literal characters is a substring
search, and C<index> does that without compiling and running a pattern:

    if ( $str =~ m/foo/ ) { ... }               # reported
    if ( index( $str, 'foo' ) >= 0 ) { ... }    # what it means

Except where the regex is not a search at all.  The first argument of C<split>
is the pattern it splits on, and there is no C<index> that splits.
L<Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit> requires that
argument to be a regex rather than a string, so reporting C<split m/\n/, $text>
leaves nothing to write that both policies accept.  This policy lets C<split>,
and anything else named in C<allow>, take a literal regex as its first
argument.

This is a fork of
L<Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring|https://metacpan.org/pod/Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring>
by Dean Hamstead.  What is new is the list of calls whose first argument is
exempt, and which modifiers exempt a pattern: see L</MODIFIERS>.

=head2 PROHIBITED

    if ( $str =~ m/foo/ ) { ... }
    if ( $str =~ /bar\.baz/ ) { ... }       # an escaped dot is still a literal
    print if m/foo/;
    split $sep, $str =~ m/foo/;              # a match, not split's pattern
    grep { m/foo/ } @lines;

=head2 ALLOWED

    split m/\n/, $text;
    split /,/, $line;
    my @fields = split( m/\t/, $row );
    CORE::split( m/:/, $path );

And, as in the original, any regex that is not only literal text:

    $str =~ m/foo/i;          # /i, which index() cannot do
    $str =~ m/^foo/;          # an anchor
    $str =~ m/fo+/;           # a quantifier
    $str =~ m/[ab]c/;         # a character class
    $str =~ m/(foo)/;         # a group, even of literal text
    $str =~ m/foo|bar/;       # alternation
    $str =~ m/$foo/;          # interpolation
    $str =~ s/foo/bar/;       # a substitution
    my $rx = qr/foo/;         # a compiled regex

=head2 MODIFIERS

Only C</i> exempts a pattern, because only C</i> changes what a pattern of
nothing but literals matches: C<index> is case sensitive.

    $str =~ m/foo/m;          # reported: /m changes ^ and $, and there are none
    $str =~ m/foo/s;          # reported: /s changes ., and there is none
    $str =~ m/foo bar/x;      # reported: under /x this is the string foobar

A modifier in scope from a C<use re> counts the same as one written on the match,
so a file under C<use re '/sx'> is checked like any other, and one under
C<use re '/i'> is exempt throughout.

=head2 CONFIGURATION

=over 4

=item C<allow>

Space separated list of functions and methods whose first argument may be a
literal regex.  It B<adds to> the built-in list rather than replacing it, so you
name only your own:

    [ProhibitRegexForSimpleSubstring]
    allow = grep_lines My::Util::match_all

The built-in list is:

    split

=back

What a name matches, which is the same rule as
L<Perl::Critic::Policy::ProhibitLeadingZeros>'s C<allow>:

=over 4

=item A name with no package, C<split>

Any call to a function or method of that name, however it is reached:
C<split(...)>, C<CORE::split(...)>, C<< $obj->split(...) >> and
C<< Some::Class->split(...) >>.

=item A name with a package, C<My::Util::match_all>

Only a call that names that package: C<My::Util::match_all(...)>, or the class
method C<< My::Util->match_all(...) >>.  Not a bare C<match_all(...)>, and not
C<< $object->match_all(...) >>, since the policy cannot know what package either
one ends up in.

=back

Where in the call the regex may be:

=over 4

=item As the first argument

Which is where C<split> takes its pattern.  A literal regex anywhere else in the
arguments is a match against C<$_> whose result is being passed, and that is
reported like any other: C<split m/,/, m/x/> is a violation, for the second one.

=item As the whole of that argument

C<split m/\n/, $text> is allowed; C<< split $sep, $str =~ m/x/ >> is not, since
the regex there is an operand of C<=~>.  Next to any operator but a comma, a fat
comma or a low-precedence C<or>, C<and> or C<xor>, a regex is part of an
expression rather than an argument.

=item Of the nearest call

C<< foo( split m/\n/, $text ) >> is C<split>'s argument, not C<foo>'s, and
C<split> decides.  Parentheses around the regex are looked through,
C<split( ( m/x/ ), $s )>; a subscript, a block or an anonymous array or hash is
not, and a regex inside one is reported.

=back

=head2 CAVEATS

A pattern chosen by a ternary, C<split $tab ? m/\t/ : m/,/, $line>, is two
operands of C<?:> rather than an argument, and both are reported.  Write the
choice as a C<qr//> first, or say C<## no critic (ProhibitRegexForSimpleSubstring)>.

A name with no package matches any method of that name on any object, since
there is no knowing what class an invocant is.  Name the package if that is too
broad.

=head2 DIFFERENCES FROM THE ORIGINAL

What moving from C<[Performance::ProhibitRegexForSimpleSubstring]> changes:

=over 4

=item *

A literal regex as the first argument of C<split>, or of anything named in
C<allow>, is not reported.

=item *

C</m>, C</s> and C</x> no longer exempt a pattern, and neither does a C<use re>
that turns them on.  The original exempted all three, which under
C<use re '/sx'> meant it reported nothing at all.  See L</MODIFIERS>.

=item *

A C<## no critic (Performance::ProhibitRegexForSimpleSubstring)> does not match
this policy's name, so an annotation that is still needed has to be renamed to
C<## no critic (ProhibitRegexForSimpleSubstring)>.

=back

=head2 SEE ALSO

L<Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit>, which is why
C<split>'s pattern has to be a regex in the first place.

=head2 METHODS

=head3 supported_parameters

C<allow>, the functions and methods whose first argument may be a literal regex,
added to the built-in list.

=head3 initialize_if_enabled

Folds the built-in names back into whatever C<allow> was configured with, so a
user's list adds to the defaults instead of replacing them.

=head3 default_severity

SEVERITY_MEDIUM

=head3 default_themes

performance

=head3 applies_to

PPI::Token::Regexp::Match

=head3 violates

Standard L<Perl::Critic::Policy> interface.  Returns a violation for a match of
nothing but literal text, unless it is the whole of the first argument to a call
that C<allow> names.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitregexforsimplesubstring/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

Original author, of Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring:

=over 4

=item *

Dean Hamstead <dean@fragfest.com.au>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Dean Hamstead, as
Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring in
Perl-Critic-Policy-Performance-ProhibitRegexForSimpleSubstring.

Modifications are copyright (c) 2026 Troglodyne LLC.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
