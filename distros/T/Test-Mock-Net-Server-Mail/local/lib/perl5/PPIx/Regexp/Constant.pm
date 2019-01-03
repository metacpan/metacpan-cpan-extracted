package PPIx::Regexp::Constant;

use strict;
use warnings;

use base qw{ Exporter };

# CAVEAT: do not include any other PPIx-Regexp modules in this one, or
# you will end up with a circular dependency.

our $VERSION = '0.063';

our @EXPORT_OK = qw{
    ARRAY_REF
    CODE_REF
    COOKIE_CLASS
    COOKIE_QUANT
    COOKIE_QUOTE
    COOKIE_REGEX_SET
    FALSE
    HASH_REF
    LITERAL_LEFT_CURLY_ALLOWED
    LITERAL_LEFT_CURLY_REMOVED_PHASE_1
    LITERAL_LEFT_CURLY_REMOVED_PHASE_2
    LITERAL_LEFT_CURLY_REMOVED_PHASE_3
    MINIMUM_PERL
    MODIFIER_GROUP_MATCH_SEMANTICS
    MSG_PROHIBITED_BY_STRICT
    NODE_UNKNOWN
    RE_CAPTURE_NAME
    REGEXP_REF
    SCALAR_REF
    STRUCTURE_UNKNOWN
    SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS
    TOKEN_LITERAL
    TOKEN_UNKNOWN
    TRUE
    @CARP_NOT
};

our @CARP_NOT = qw{
    PPIx::Regexp
    PPIx::Regexp::Constant
    PPIx::Regexp::Dumper
    PPIx::Regexp::Element
    PPIx::Regexp::Lexer
    PPIx::Regexp::Node
    PPIx::Regexp::Node::Range
    PPIx::Regexp::Node::Unknown
    PPIx::Regexp::StringTokenizer
    PPIx::Regexp::Structure
    PPIx::Regexp::Structure::Assertion
    PPIx::Regexp::Structure::Atomic_Script_Run
    PPIx::Regexp::Structure::BranchReset
    PPIx::Regexp::Structure::Capture
    PPIx::Regexp::Structure::CharClass
    PPIx::Regexp::Structure::Code
    PPIx::Regexp::Structure::Main
    PPIx::Regexp::Structure::Modifier
    PPIx::Regexp::Structure::NamedCapture
    PPIx::Regexp::Structure::Quantifier
    PPIx::Regexp::Structure::RegexSet
    PPIx::Regexp::Structure::Regexp
    PPIx::Regexp::Structure::Replacement
    PPIx::Regexp::Structure::Script_Run
    PPIx::Regexp::Structure::Subexpression
    PPIx::Regexp::Structure::Switch
    PPIx::Regexp::Structure::Unknown
    PPIx::Regexp::Support
    PPIx::Regexp::Token
    PPIx::Regexp::Token::Assertion
    PPIx::Regexp::Token::Backreference
    PPIx::Regexp::Token::Backtrack
    PPIx::Regexp::Token::CharClass
    PPIx::Regexp::Token::CharClass::POSIX
    PPIx::Regexp::Token::CharClass::POSIX::Unknown
    PPIx::Regexp::Token::CharClass::Simple
    PPIx::Regexp::Token::Code
    PPIx::Regexp::Token::Comment
    PPIx::Regexp::Token::Condition
    PPIx::Regexp::Token::Control
    PPIx::Regexp::Token::Delimiter
    PPIx::Regexp::Token::Greediness
    PPIx::Regexp::Token::GroupType
    PPIx::Regexp::Token::GroupType::Assertion
    PPIx::Regexp::Token::GroupType::Atomic_Script_Run
    PPIx::Regexp::Token::GroupType::BranchReset
    PPIx::Regexp::Token::GroupType::Code
    PPIx::Regexp::Token::GroupType::Modifier
    PPIx::Regexp::Token::GroupType::NamedCapture
    PPIx::Regexp::Token::GroupType::Script_Run
    PPIx::Regexp::Token::GroupType::Subexpression
    PPIx::Regexp::Token::GroupType::Switch
    PPIx::Regexp::Token::Interpolation
    PPIx::Regexp::Token::Literal
    PPIx::Regexp::Token::Modifier
    PPIx::Regexp::Token::NoOp
    PPIx::Regexp::Token::Operator
    PPIx::Regexp::Token::Quantifier
    PPIx::Regexp::Token::Recursion
    PPIx::Regexp::Token::Reference
    PPIx::Regexp::Token::Structure
    PPIx::Regexp::Token::Unknown
    PPIx::Regexp::Token::Unmatched
    PPIx::Regexp::Token::Whitespace
    PPIx::Regexp::Tokenizer
    PPIx::Regexp::Util
};

use constant COOKIE_CLASS	=> ']';
use constant COOKIE_QUANT	=> '}';
use constant COOKIE_QUOTE	=> '\\E';
use constant COOKIE_REGEX_SET	=> '])';

use constant FALSE		=> 0;
use constant TRUE		=> 1;

use constant ARRAY_REF		=> ref [];
use constant CODE_REF		=> ref sub {};
use constant HASH_REF		=> ref {};
use constant REGEXP_REF		=> ref qr{};
use constant SCALAR_REF		=> ref \0;

# In the cases where an unescaped literal left curly 'could not' be a
# quantifier, they are allowed. At least, that was the original idea.
# But read on.
use constant LITERAL_LEFT_CURLY_ALLOWED		=> undef;

# 'Most' unescaped literal left curlys were removed in 5.26.
use constant LITERAL_LEFT_CURLY_REMOVED_PHASE_1	=> '5.025001';

# Unescaped literal left curlys after literals and certain other
# elements are scheduled to be removed in 5.30.
use constant LITERAL_LEFT_CURLY_REMOVED_PHASE_2	=> undef;	# x{ 5.30

# In 5.27.8 it was decided that unescaped literal left curlys after an
# open paren will be removed in 5.32. This does not include the case
# where the entire regex is delimited by parens -- they are still legal
# there.
use constant LITERAL_LEFT_CURLY_REMOVED_PHASE_3	=> undef;	# ({ 5.32

use constant MINIMUM_PERL	=> '5.000';

use constant MODIFIER_GROUP_MATCH_SEMANTICS => 'match_semantics';

use constant MSG_PROHIBITED_BY_STRICT	=>
    q<prohibited by "use re 'strict'">;

use constant NODE_UNKNOWN	=> 'PPIx::Regexp::Node::Unknown';

# The perlre for Perl 5.010 says:
#
#      Currently NAME is restricted to simple identifiers only.  In
#      other words, it must match "/^[_A-Za-z][_A-Za-z0-9]*\z/" or
#      its Unicode extension (see utf8), though it isn't extended by
#      the locale (see perllocale).

use constant RE_CAPTURE_NAME => ' [_[:alpha:]] \w* ';

use constant STRUCTURE_UNKNOWN	=> 'PPIx::Regexp::Structure::Unknown';

use constant SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS => $] ge '5.008003';

use constant TOKEN_LITERAL	=> 'PPIx::Regexp::Token::Literal';
use constant TOKEN_UNKNOWN	=> 'PPIx::Regexp::Token::Unknown';

1;

__END__

=head1 NAME

PPIx::Regexp::Constant - Constants for the PPIx::Regexp system

=head1 SYNOPSIS

 use PPIx::Regexp::Constant qw{ TOKEN_UNKNOWN }
 print "An unknown token's class is TOKEN_UNKNOWN\n";

=head1 INHERITANCE

C<PPIx::Regexp::Constant> is an L<Exporter|Exporter>.

C<PPIx::Regexp::Constant> has no descendants.

=head1 DETAILS

This module defines manifest constants for use by the various
C<PPIx::Regexp> modules. These constants are to be considered B<private>
to the C<PPIx::Regexp> system, and the author reserves the right to
change them without notice.

This module exports the following manifest constants:

=head2 @CARP_NOT

This global variable contains the names of all modules in the package.

=head2 ARRAY_REF

This is the result of C<ref []>.

=head2 CODE_REF

This is the result of C<ref sub {}>.

=head2 COOKIE_CLASS

The name of the cookie used to control the construction of character
classes.

This cookie is set in
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure> when
the left square bracket is encountered, and cleared in the same module
when a right square bracket is encountered.

=head2 COOKIE_QUANT

The name of the cookie used to control the construction of curly
bracketed quantifiers.

This cookie is set in
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure> when a
left curly bracket is encountered. It requests itself to be cleared on
encountering anything other than a literal comma, a literal digit, or an
interpolation, or if more than one comma is encountered. If it survives
until L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure>
processes the right curly bracket, it is cleared there.

=head2 COOKIE_QUOTE

The name of the cookie used to control the parsing of C<\Q ... \E>
quoted literals.

This cookie is set in
L<PPIx::Regexp::Token::Control|PPIx::Regexp::Token::Control> when a
C<\Q> is encountered, and it persists until the next C<\E>.

=head2 COOKIE_REGEX_SET

The name of the cookie used to control regular expression sets.

=head2 HASH_REF

This is the result of C<ref {}>.

=head2 LITERAL_LEFT_CURLY_ALLOWED

The Perl version at which allowed unescaped literal left curly brackets
were removed. This may make more sense if I mention that its value is
C<undef>.

=head2 LITERAL_LEFT_CURLY_REMOVED_PHASE_1

The Perl version at which the first phase of unescaped literal left
curly bracket removal took place. The value of this constant is
C<'5.025001'>.

=head2 LITERAL_LEFT_CURLY_REMOVED_PHASE_2

The Perl version at which the second phase of unescaped literal left
curly bracket removal took place. The value of this constant is
C<undef>, but it will be assigned a value when the timing of the second
phase is known.

=head2 LITERAL_LEFT_CURLY_REMOVED_PHASE_3

The Perl version at which the third phase of unescaped literal left
curly bracket removal took place. This is the removal of curly brackets
after a left parenthesis. The value of this constant is C<undef>, but it
will be assigned a value when the timing of the second phase is known.

=head2 MINIMUM_PERL

The minimum version of Perl understood by this parser, as a float. It is
currently set to 5.000, since that is the minimum version of Perl
accessible to the author.

=head2 MODIFIER_GROUP_MATCH_SEMANTICS

The name of the
L<PPIx::Regexp::Token::Modifier|PPIx::Regexp::Token::Modifier> group
used to control match semantics.

=head2 MSG_PROHIBITED_BY_STRICT

An appropriate error message for an unknown entity created because
C<'strict'> was in effect. This is rank ad-hocery, and more than usually
subject to being changed, without any notice whatsoever. Caveat user.

=head2 NODE_UNKNOWN

The name of the class that represents an unknown node. That is,
L<PPIx::Regexp::Node::Unknown|PPIx::Regexp::Node::Unknown>.

=head2 RE_CAPTURE_NAME

A string representation of a regular expression that matches the name of
a named capture buffer.

=head2 REGEXP_REF

This is the result of C<ref qr{}>.

=head2 SCALAR_REF

This is the result of C<ref \0>.

=head2 STRUCTURE_UNKNOWN

The name of the class that represents an unknown structure. That is,
L<PPIx::Regexp::Structure::Unknown|PPIx::Regexp::Structure::Unknown>.

=head2 SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS

A Boolean which is true if the running version of Perl has UTF-8 support
sufficient for our purposes.

Currently that means C<5.8.3> or greater, with the specific requirements
being C<use open qw{ :std :encoding(utf-8) }>, C</\p{Mark}/>, and the
ability to parse things like C<qr \N{U+FFFF}foo\N{U+FFFF}>.

=head2 TOKEN_LITERAL

The name of the class that represents a literal token. That is,
L<PPIx::Regexp::Token::Literal|PPIx::Regexp::Token::Literal>.

=head2 TOKEN_UNKNOWN

The name of the class that represents the unknown token. That is,
L<PPIx::Regexp::Token::Unknown|PPIx::Regexp::Token::Unknown>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
