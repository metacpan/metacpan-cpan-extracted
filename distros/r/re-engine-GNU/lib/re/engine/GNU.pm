package re::engine::GNU;
use strict;
use warnings FATAL => 'all';
use 5.010000;
use XSLoader ();

# ABSTRACT: GNU Regular Expression Engine

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

BEGIN {
    our $VERSION = '0.025'; # VERSION
    XSLoader::load __PACKAGE__, $VERSION;
}

{
    no strict 'subs';                     ## no critic
    our $RE_SYNTAX_AWK                    = RE_SYNTAX_AWK;
    our $RE_SYNTAX_ED                     = RE_SYNTAX_ED;
    our $RE_SYNTAX_EGREP                  = RE_SYNTAX_EGREP;
    our $RE_SYNTAX_EMACS                  = RE_SYNTAX_EMACS;
    our $RE_SYNTAX_GNU_AWK                = RE_SYNTAX_GNU_AWK;
    our $RE_SYNTAX_GREP                   = RE_SYNTAX_GREP;
    our $RE_SYNTAX_POSIX_AWK              = RE_SYNTAX_POSIX_AWK;
    our $RE_SYNTAX_POSIX_BASIC            = RE_SYNTAX_POSIX_BASIC;
    our $RE_SYNTAX_POSIX_EGREP            = RE_SYNTAX_POSIX_EGREP;
    our $RE_SYNTAX_POSIX_EXTENDED         = RE_SYNTAX_POSIX_EXTENDED;
    our $RE_SYNTAX_POSIX_MINIMAL_BASIC    = RE_SYNTAX_POSIX_MINIMAL_BASIC;
    our $RE_SYNTAX_POSIX_MINIMAL_EXTENDED = RE_SYNTAX_POSIX_MINIMAL_EXTENDED;
    our $RE_SYNTAX_SED                    = RE_SYNTAX_SED;
    #
    # __USE_GNU specifics
    #
    our $RE_BACKSLASH_ESCAPE_IN_LISTS = RE_BACKSLASH_ESCAPE_IN_LISTS;
    our $RE_BK_PLUS_QM                = RE_BK_PLUS_QM;
    our $RE_CHAR_CLASSES              = RE_CHAR_CLASSES;
    our $RE_CONTEXT_INDEP_ANCHORS     = RE_CONTEXT_INDEP_ANCHORS;
    our $RE_CONTEXT_INDEP_OPS         = RE_CONTEXT_INDEP_OPS;
    our $RE_CONTEXT_INVALID_OPS       = RE_CONTEXT_INVALID_OPS;
    our $RE_DOT_NEWLINE               = RE_DOT_NEWLINE;
    our $RE_DOT_NOT_NULL              = RE_DOT_NOT_NULL;
    our $RE_HAT_LISTS_NOT_NEWLINE     = RE_HAT_LISTS_NOT_NEWLINE;
    our $RE_INTERVALS                 = RE_INTERVALS;
    our $RE_LIMITED_OPS               = RE_LIMITED_OPS;
    our $RE_NEWLINE_ALT               = RE_NEWLINE_ALT;
    our $RE_NO_BK_BRACES              = RE_NO_BK_BRACES;
    our $RE_NO_BK_PARENS              = RE_NO_BK_PARENS;
    our $RE_NO_BK_REFS                = RE_NO_BK_REFS;
    our $RE_NO_BK_VBAR                = RE_NO_BK_VBAR;
    our $RE_NO_EMPTY_RANGES           = RE_NO_EMPTY_RANGES;
    our $RE_UNMATCHED_RIGHT_PAREN_ORD = RE_UNMATCHED_RIGHT_PAREN_ORD;
    our $RE_NO_POSIX_BACKTRACKING     = RE_NO_POSIX_BACKTRACKING;
    our $RE_NO_GNU_OPS                = RE_NO_GNU_OPS;
    our $RE_DEBUG                     = RE_DEBUG;
    our $RE_INVALID_INTERVAL_ORD      = RE_INVALID_INTERVAL_ORD;
    our $RE_ICASE                     = RE_ICASE;
    our $RE_CARET_ANCHORS_HERE        = RE_CARET_ANCHORS_HERE;
    our $RE_CONTEXT_INVALID_DUP       = RE_CONTEXT_INVALID_DUP;
    our $RE_NO_SUB                    = RE_NO_SUB;
}

sub import {
    my $class = shift;

    $^H{regcomp} = ENGINE;

    if (@_) {
        my %args = @_;
        if ( exists $args{'-debug'} ) {
            $^H{ __PACKAGE__ . '/debug' } = $args{'-debug'};
        }
        if ( exists $args{'-syntax'} ) {
            $^H{ __PACKAGE__ . '/syntax' } = $args{'-syntax'};
        }
    }

}

sub unimport {
    my $class = shift;

    if ( exists( $^H{regcomp} ) && $^H{regcomp} == ENGINE ) {
        delete( $^H{regcomp} );
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

re::engine::GNU - GNU Regular Expression Engine

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  use re::engine::GNU;
  'test' =~ /\(tes\)t/ && print "ok 1\n";
  'test' =~ [ 0, '\(tes\)t' ] && print "ok 2\n";
  'test' =~ { syntax => 0, pattern => '\(tes\)t' } && print "ok 3\n";

=head1 DESCRIPTION

The GNU regular expression engine plugged into perl. The package can be "used" with the following pragmas:

=over

=item -debug => boolean

E.g. use re::engine::GNU -debug => 1;    # a true value will print on stderr

=item -syntax => bitwised value

E.g. use re::engine::GNU -syntax => 0;   # Default syntax. Useful for the // form.

=back

Regular expressions can be writen in three form:

=over

=item classic

e.g. qr/xxx/. The default syntax is then GNU Emacs.

=item array

e.g. [ syntax, 'xxx' ], where syntax is a bitwised value.

=item hash

e.g. { syntax => value, pattern => 'xxx' }, where value is bitwised, like in the array form.

=back

The following convenient class variables are available for the syntax:

=over

=item $re::engine::GNU::RE_SYNTAX_ED

=item $re::engine::GNU::RE_SYNTAX_EGREP

=item $re::engine::GNU::RE_SYNTAX_EMACS (default)

=item $re::engine::GNU::RE_SYNTAX_GNU_AWK

=item $re::engine::GNU::RE_SYNTAX_GREP

=item $re::engine::GNU::RE_SYNTAX_POSIX_AWK

=item $re::engine::GNU::RE_SYNTAX_POSIX_BASIC

=item $re::engine::GNU::RE_SYNTAX_POSIX_EGREP

=item $re::engine::GNU::RE_SYNTAX_POSIX_EXTENDED

=item $re::engine::GNU::RE_SYNTAX_POSIX_MINIMAL_BASIC

=item $re::engine::GNU::RE_SYNTAX_POSIX_MINIMAL_EXTENDED

=item $re::engine::GNU::RE_SYNTAX_SED

=back

All the convenient class variables listed upper are made of these GNU internal bits, that you can also manipulate yourself to tune the syntax to your needs (documentation is copied verbatim from the file regex.h distributed with this package):

=over

=item $re::engine::GNU::RE_BACKSLASH_ESCAPE_IN_LISTS

If this bit is not set, then \ inside a bracket expression is literal. If set, then such a \ quotes the following character.

=item $re::engine::GNU::RE_BK_PLUS_QM

If this bit is not set, then + and ? are operators, and \+ and \? are literals. If set, then \+ and \? are operators and + and ? are literals.

=item $re::engine::GNU::RE_CHAR_CLASSES

If this bit is set, then character classes are supported.  They are: [:alpha:], [:upper:], [:lower:],  [:digit:], [:alnum:], [:xdigit:], [:space:], [:print:], [:punct:], [:graph:], and [:cntrl:]. If not set, then character classes are not supported.

=item $re::engine::GNU::RE_CONTEXT_INDEP_ANCHORS

If this bit is set, then ^ and $ are always anchors (outside bracket expressions, of course). If this bit is not set, then it depends:

=over

=item ^

is an anchor if it is at the beginning of a regular expression or after an open-group or an alternation operator;

=item $

is an anchor if it is at the end of a regular expression, or before a close-group or an alternation operator.

=back

This bit could be (re)combined with RE_CONTEXT_INDEP_OPS, because POSIX draft 11.2 says that * etc. in leading positions is undefined. We already implemented a previous draft which made those constructs invalid, though, so we haven't changed the code back.

=item $re::engine::GNU::RE_CONTEXT_INDEP_OPS

If this bit is set, then special characters are always special regardless of where they are in the pattern. If this bit is not set, then special characters are special only in  some contexts; otherwise they are ordinary. Specifically, * + ? and intervals are only special when not after the beginning, open-group, or alternation operator.

=item $re::engine::GNU::RE_CONTEXT_INVALID_OPS

If this bit is set, then *, +, ?, and { cannot be first in an re or immediately after an alternation or begin-group operator.

=item $re::engine::GNU::RE_DOT_NEWLINE

If this bit is set, then . matches newline. If not set, then it doesn't.

=item $re::engine::GNU::RE_DOT_NOT_NULL

If this bit is set, then . doesn't match NUL. If not set, then it does.

=item $re::engine::GNU::RE_HAT_LISTS_NOT_NEWLINE

If this bit is set, nonmatching lists [^...] do not match newline. If not set, they do.

=item $re::engine::GNU::RE_INTERVALS

If this bit is set, either \{...\} or {...} defines an interval, depending on RE_NO_BK_BRACES. If not set, \{, \}, {, and } are literals.

=item $re::engine::GNU::RE_LIMITED_OPS

If this bit is set, +, ? and | aren't recognized as operators. If not set, they are.

=item $re::engine::GNU::RE_NEWLINE_ALT

If this bit is set, newline is an alternation operator. If not set, newline is literal.

=item $re::engine::GNU::RE_NO_BK_BRACES

If this bit is set, then '{...}' defines an interval, and \{ and \} are literals. If not set, then '\{...\}' defines an interval.

=item $re::engine::GNU::RE_NO_BK_PARENS

If this bit is set, (...) defines a group, and \( and \) are literals. If not set, \(...\) defines a group, and ( and ) are literals.

=item $re::engine::GNU::RE_NO_BK_REFS

If this bit is set, then \<digit> matches <digit>. If not set, then \<digit> is a back-reference.

=item $re::engine::GNU::RE_NO_BK_VBAR

If this bit is set, then | is an alternation operator, and \| is literal. If not set, then \| is an alternation operator, and | is literal.

=item $re::engine::GNU::RE_NO_EMPTY_RANGES

If this bit is set, then an ending range point collating higher than the starting range point, as in [z-a], is invalid. If not set, then when ending range point collates higher than the starting range point, the range is ignored.

=item $re::engine::GNU::RE_UNMATCHED_RIGHT_PAREN_ORD

If this bit is set, then an unmatched ) is ordinary. If not set, then an unmatched ) is invalid.

=item $re::engine::GNU::RE_NO_POSIX_BACKTRACKING

If this bit is set, succeed as soon as we match the whole pattern,  without further backtracking.

=item $re::engine::GNU::RE_NO_GNU_OPS

If this bit is set, do not process the GNU regex operators. If not set, then the GNU regex operators are recognized.

=item $re::engine::GNU::RE_DEBUG

If this bit is set, turn on internal regex debugging. If not set, and debugging was on, turn it off. This only works if regex.c is compiled -DDEBUG. We define this bit always, so that all that's needed to turn on  debugging is to recompile regex.c; the calling code can always have this bit set, and it won't affect anything in the normal case.

=item $re::engine::GNU::RE_INVALID_INTERVAL_ORD

If this bit is set, a syntactically invalid interval is treated as a string of ordinary characters.  For example, the ERE 'a{1' is treated as 'a\{1'.

=item $re::engine::GNU::RE_ICASE

If this bit is set, then ignore case when matching. If not set, then case is significant.

=item $re::engine::GNU::RE_CARET_ANCHORS_HERE

This bit is used internally like RE_CONTEXT_INDEP_ANCHORS but only for ^, because it is difficult to scan the regex backwards to find whether ^ should be special.

=item $re::engine::GNU::RE_CONTEXT_INVALID_DUP

If this bit is set, then \{ cannot be first in a regex or immediately after an alternation, open-group or \} operator.

=item $re::engine::GNU::RE_NO_SUB

If this bit is set, then no_sub will be set to 1 during re_compile_pattern.

=back

Please refer to L<Gnulib Regular expression syntaxes|https://www.gnu.org/software/gnulib/manual/html_node/Regular-expression-syntaxes.html#Regular-expression-syntaxes> documentation.

The following perl modifiers are supported and applied to the chosen syntax:

=over

=item //m

This is triggering an internal flag saying that newline is an anchor.

=item //s

This is setting a bit in the syntax value, saying that "." can also match newline.

=item //i

This is making the regular expression case insensitive.

=item //p

Please refer to perlvar section about MATCH family.

=back

The perl modifiers //x is explicited dropped.

=head2 EXPORT

None by default.

=head1 NAME

re::engine::GNU - Perl extension for GNU regular expressions

=head1 NOTES

=over

=item I18N

This is using the perl semantics with which this library is compiled.

=item Collation

Collating symbols and Equivalence classes are not (yet supported).

=item Execution and compilation semantics

The //msip perl semantics are applied at compile-time. Perl's localization if any always apply. The GNU regex semantic is in effect for the rest; for instance, there is no "last successful match" perl semantic in here.

=back

=head1 SEE ALSO

L<GNU Gnulib Regular expressions|https://www.gnu.org/software/gnulib/manual/html_node/Regular-expressions.html>

L<perlre>

=for Pod::Coverage ENGINE RE_SYNTAX_AWK RE_SYNTAX_ED RE_SYNTAX_EGREP RE_SYNTAX_EMACS RE_SYNTAX_GNU_AWK RE_SYNTAX_GREP RE_SYNTAX_POSIX_AWK RE_SYNTAX_POSIX_BASIC RE_SYNTAX_POSIX_EGREP RE_SYNTAX_POSIX_EXTENDED RE_SYNTAX_POSIX_MINIMAL_BASIC RE_SYNTAX_POSIX_MINIMAL_EXTENDED RE_SYNTAX_SED RE_BACKSLASH_ESCAPE_IN_LISTS RE_BK_PLUS_QM RE_CHAR_CLASSES RE_CONTEXT_INDEP_ANCHORS RE_CONTEXT_INDEP_OPS RE_CONTEXT_INVALID_OPS RE_DOT_NEWLINE RE_DOT_NOT_NULL RE_HAT_LISTS_NOT_NEWLINE RE_INTERVALS RE_LIMITED_OPS RE_NEWLINE_ALT RE_NO_BK_BRACES RE_NO_BK_PARENS RE_NO_BK_REFS RE_NO_BK_VBAR RE_NO_EMPTY_RANGES RE_UNMATCHED_RIGHT_PAREN_ORD RE_NO_POSIX_BACKTRACKING RE_NO_GNU_OPS RE_DEBUG RE_INVALID_INTERVAL_ORD RE_ICASE RE_CARET_ANCHORS_HERE RE_CONTEXT_INVALID_DUP RE_NO_SUB

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 CONTRIBUTOR

=for stopwords Yves Orton

Yves Orton <demerphq@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
