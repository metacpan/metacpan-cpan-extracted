=head1 NAME

PPIx::Regexp - Represent a regular expression of some sort

=head1 SYNOPSIS

 use PPIx::Regexp;
 use PPIx::Regexp::Dumper;
 my $re = PPIx::Regexp->new( 'qr{foo}smx' );
 PPIx::Regexp::Dumper->new( $re )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp> is a L<PPIx::Regexp::Node|PPIx::Regexp::Node>.

C<PPIx::Regexp> has no descendants.

=head1 DESCRIPTION

The purpose of the F<PPIx-Regexp> package is to parse regular
expressions in a manner similar to the way the L<PPI|PPI> package parses
Perl. This class forms the root of the parse tree, playing a role
similar to L<PPI::Document|PPI::Document>.

This package shares with L<PPI|PPI> the property of being round-trip
safe. That is,

 my $expr = 's/ ( \d+ ) ( \D+ ) /$2$1/smxg';
 my $re = PPIx::Regexp->new( $expr );
 print $re->content() eq $expr ? "yes\n" : "no\n"

should print 'yes' for any valid regular expression.

Navigation is similar to that provided by L<PPI|PPI>. That is to say,
things like C<children>, C<find_first>, C<snext_sibling> and so on all
work pretty much the same way as in L<PPI|PPI>.

The class hierarchy is also similar to L<PPI|PPI>. Except for some
utility classes (the dumper, the lexer, and the tokenizer) all classes
are descended from L<PPIx::Regexp::Element|PPIx::Regexp::Element>, which
provides basic navigation. Tokens are descended from
L<PPIx::Regexp::Token|PPIx::Regexp::Token>, which provides content. All
containers are descended from L<PPIx::Regexp::Node|PPIx::Regexp::Node>,
which provides for children, and all structure elements are descended
from L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>, which provides
beginning and ending delimiters, and a type.

There are two features of L<PPI|PPI> that this package does not provide
- mutability and operator overloading. There are no plans for serious
mutability, though something like L<PPI|PPI>'s C<prune> functionality
might be considered. Similarly there are no plans for operator
overloading, which appears to the author to represent a performance hit
for little tangible gain.

=head1 NOTICE

The use of this class to parse non-regexp quote-like strings was an
experiment that I consider failed. Therefore this use is B<deprecated>
in favor of L<PPIx::QuoteLike|PPIx::QuoteLike>. As of version 0.058_01,
the first use of the C<parse> argument to L<new()|/new> resulted in a
warning. As of version 0.062_01, all uses of the C<parse> argument
resulted in a warning. After another six months, the C<parse> argument
will become fatal.

The author will attempt to preserve the documented interface, but if the
interface needs to change to correct some egregiously bad design or
implementation decision, then it will change.  Any incompatible changes
will go through a deprecation cycle.

The goal of this package is to parse well-formed regular expressions
correctly. A secondary goal is not to blow up on ill-formed regular
expressions. The correct identification and characterization of
ill-formed regular expressions is B<not> a goal of this package, nor is
the consistent parsing of ill-formed regular expressions from release to
release.

This policy attempts to track features in development releases as well
as public releases. However, features added in a development release and
then removed before the next production release B<will not> be tracked,
and any functionality relating to such features B<will be removed>. The
issue here is the potential re-use (with different semantics) of syntax
that did not make it into the production release.

From time to time the Perl regular expression engine changes in ways
that change the parse of a given regular expression. When these changes
occur, C<PPIx::Regexp> will be changed to produce the more modern parse.
Known examples of this include:

=over

=item C<$(> no longer interpolates as of Perl 5.005, per C<perl5005delta>.

Newer Perls seem to parse this as C<qr{$}> (i.e. and end-of-string or
newline assertion) followed by an open parenthesis, and that is what
C<PPIx::Regexp> does.

=item C<$)> and C<$|> also seem to parse as the C<$> assertion

followed by the relevant meta-character, though I have no documentation
reference for this.

=item C<@+> and C<@-> no longer interpolate as of Perl 5.9.4

per C<perl594delta>. Subsequent Perls treat C<@+> as a quantified
literal and C<@-> as two literals, and that is what C<PPIx::Regexp>
does. Note that subscripted references to these arrays B<do>
interpolate, and are so parsed by C<PPIx::Regexp>.

=item Only space and horizontal tab are whitespace as of Perl 5.23.4

when inside a bracketed character class inside an extended bracketed
character class, per C<perl5234delta>. Formerly any white space
character parsed as whitespace. This change in C<PPIx::Regexp> will be
reverted if the change in Perl does not make it into Perl 5.24.0.

=item Unescaped literal left curly brackets

These are being removed in positions where quantifiers are legal, so
that they can be used for new functionality. Some of them are gone in
5.25.1, others will be removed in a future version of Perl. In
situations where they have been removed,
L<perl_version_removed()|/perl_version_removed> will return the version
in which they were removed. When the new functionality appears, the
parse produced by this software will reflect the new functionality.

B<NOTE> that a literal left curly after a literal character was made an
error in Perl 5.25.1, but became a warning again in 5.27.1 due to its
use in GNU Autoconf.  Whether it will ever become illegal again is not
clear to me based on the contents of F<perl5271delta>. At the moment
C<PPIx::Regexp> considers this usage to have been removed in 5.25.1, and
this will not change based on anything in 5.27.x. But if 5.26.1 comes
out allowing this usage, the removal version will become C<undef>. The
same will apply to any other usages that were re-allowed in 5.27.1, if I
can identify them.

=back

There are very probably other examples of this. When they come to light
they will be documented as producing the modern parse, and the code
modified to produce this parse if necessary.

The functionality that parses string literals (the C<parse> argument to
C<new()>) was introduced in version 0.045, but its use is discouraged.
The preferred package for string literals is
L<PPIx::QuoteLike|PPIx::QuoteLike>, and once I consider that package to
be stable the string literal functionality in this package will be put
through a deprecation cycle and removed.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Node };

use PPIx::Regexp::Constant qw{ @CARP_NOT };
use PPIx::Regexp::Lexer ();
use PPIx::Regexp::StringTokenizer;
use PPIx::Regexp::Token::Modifier ();	# For its modifier manipulations.
use PPIx::Regexp::Tokenizer;
use PPIx::Regexp::Util qw{ __choose_tokenizer_class __instance };
use Scalar::Util qw{ refaddr };

our $VERSION = '0.063';

=head2 new

 my $re = PPIx::Regexp->new('/foo/');

This method instantiates a C<PPIx::Regexp> object from a string, a
L<PPI::Token::QuoteLike::Regexp|PPI::Token::QuoteLike::Regexp>, a
L<PPI::Token::Regexp::Match|PPI::Token::Regexp::Match>, or a
L<PPI::Token::Regexp::Substitute|PPI::Token::Regexp::Substitute>.
Honestly, any L<PPI::Element|PPI::Element> will work, but only the three
Regexp classes mentioned previously are likely to do anything useful.

Whatever form the argument takes, it is assumed to consist entirely of a
valid match, substitution, or C<< qr<> >> string.

Optionally you can pass one or more name/value pairs after the regular
expression. The possible options are:

=over

=item default_modifiers array_reference

This option specifies a reference to an array of default modifiers to
apply to the regular expression being parsed. Each modifier is specified
as a string. Any actual modifiers found supersede the defaults.

When applying the defaults, C<'?'> and C<'/'> are completely ignored,
and C<'^'> is ignored unless it occurs at the beginning of the modifier.
The first dash (C<'-'>) causes subsequent modifiers to be negated.

So, for example, if you wish to produce a C<PPIx::Regexp> object
representing the regular expression in

 use re '/smx';
 {
    no re '/x';
    m/ foo /;
 }

you would (after some help from L<PPI|PPI> in finding the relevant
statements), do something like

 my $re = PPIx::Regexp->new( 'm/ foo /',
     default_modifiers => [ '/smx', '-/x' ] );

=item encoding name

This option specifies the encoding of the regular expression. This is
passed to the tokenizer, which will C<decode> the regular expression
string before it tokenizes it. For example:

 my $re = PPIx::Regexp->new( '/foo/',
     encoding => 'iso-8859-1',
 );

=item parse parse_type

This option specifies what kind of parse is to be done. Possible values
are C<'regex'>, C<'string'>, or C<'guess'>. Any value but C<'regex'> is
experimental.

As it turns out, I consider parsing non-regexp quote-like things with
this class to be a failed experiment, and the relevant functionality is
being deprecated and removed in favor of
L<PPIx::QuoteLike|PPIx::QuoteLike>. See above for details.

If C<'regex'> is specified, the first argument is expected to be a valid
regex, and parsed as though it were.

If C<'string'> is specified, the first argument is expected to be a
valid string literal and parsed as such. The return is still a
C<PPIx::Regexp> object, but the
L<regular_expression()|/regular_expression> and L<modifier()|/modifier>
methods return nothing, and the L<replacement()|/replacement> method
returns the content of the string.

If C<'guess'> is specified, this method will try to guess what the first
argument is. If the first argument is a L<PPI::Element|PPI::Element>,
the guess will reflect the PPI parse. But the guess can be wrong if the
first argument is a string representing an unusually-delimited regex.
For example, C<'guess'> will parse C<"foo"> as a string, but Perl will
parse it as a regex if preceded by a regex binding operator (e.g. C<$x
=~ "foo">), as shown by

 perl -MO=Deparse -e '$x =~ "foo"'

which prints

 $x =~ /foo/u

under Perl 5.22.0.

The default is C<'regex'>.

=item postderef boolean

This option is passed on to the tokenizer, where it specifies whether
postfix dereferences are recognized in interpolations and code. This
experimental feature was introduced in Perl 5.19.5.

The default is the value of
C<$PPIx::Regexp::Tokenizer::DEFAULT_POSTDEREF>, which is true. When
originally introduced this was false, but was documented as becoming
true when and if postfix dereferencing became mainstream. The  intent to
mainstream was announced with Perl 5.23.1, and became official (so to
speak) with Perl 5.24.0, so the default became true with L<PPIx::Regexp>
0.049_01.

Note that if L<PPI|PPI> starts unconditionally recognizing postfix
dereferences, this argument will immediately become ignored, and will be
put through a deprecation cycle and removed.

=item strict boolean

This option is passed on to the tokenizer and lexer, where it specifies
whether the parse should assume C<use re 'strict'> is in effect.

The C<'strict'> pragma was introduced in Perl 5.22, and its
documentation says that it is experimental, and that there is no
commitment to backward compatibility. The same applies to the
parse produced when this option is asserted. Also, the usual caveat
applies: if C<use re 'strict'> ends up being retracted, this option and
all related functionality will be also.

Given the nature of C<use re 'strict'>, you should expect that if you
assert this option, regular expressions that previously parsed without
error might no longer do so. If an element ends up being declared an
error because this option is set, its C<perl_version_introduced()> will
be the Perl version at which C<use re 'strict'> started rejecting these
elements.

The default is false.

=item trace number

If greater than zero, this option causes trace output from the parse.
The author reserves the right to change or eliminate this without
notice.

=back

Passing optional input other than the above is not an error, but neither
is it supported.

=cut

{

    my $errstr;

    sub new {
	my ( $class, $content, %args ) = @_;
	ref $class and $class = ref $class;

	$errstr = undef;

	my $tokenizer_class = __choose_tokenizer_class( $content, \%args )
	    or do {
	    $errstr = ref $content ?
		sprintf '%s not supported', ref $content :
		"Unknown parse type '$args{parse}'";
	    return;
	};

	my $tokenizer = $tokenizer_class->new(
	    $content, %args ) or do {
	    $errstr = PPIx::Regexp::Tokenizer->errstr();
	    return;
	};

	my $lexer = PPIx::Regexp::Lexer->new( $tokenizer, %args );
	my @nodes = $lexer->lex();
	my $self = $class->SUPER::__new( @nodes );
	$self->{source} = $content;
	$self->{failures} = $lexer->failures();
	$self->{effective_modifiers} =
	    $tokenizer->__effective_modifiers();
	return $self;
    }

    sub errstr {
	return $errstr;
    }

}

=head2 new_from_cache

This static method wraps L</new> in a caching mechanism. Only one object
will be generated for a given L<PPI::Element|PPI::Element>, no matter
how many times this method is called. Calls after the first for a given
L<PPI::Element|PPI::ELement> simply return the same C<PPIx::Regexp>
object.

When the C<PPIx::Regexp> object is returned from cache, the values of
the optional arguments are ignored.

Calls to this method with the regular expression in a string rather than
a L<PPI::Element|PPI::Element> will not be cached.

B<Caveat:> This method is provided for code like
L<Perl::Critic|Perl::Critic> which might instantiate the same object
multiple times. The cache will persist until L</flush_cache> is called.

=head2 flush_cache

 $re->flush_cache();            # Remove $re from cache
 PPIx::Regexp->flush_cache();   # Empty the cache

This method flushes the cache used by L</new_from_cache>. If called as a
static method with no arguments, the entire cache is emptied. Otherwise
any objects specified are removed from the cache.

=cut

{

    my %cache;

    our $DISABLE_CACHE;		# Leave this undocumented, at least for
				# now.

    sub __cache_size {
	return scalar keys %cache;
    }

    sub new_from_cache {
	my ( $class, $content, %args ) = @_;

	__instance( $content, 'PPI::Element' )
	    or return $class->new( $content, %args );

	$DISABLE_CACHE and return $class->new( $content, %args );

	my $addr = refaddr( $content );
	exists $cache{$addr} and return $cache{$addr};

	my $self = $class->new( $content, %args )
	    or return;

	$cache{$addr} = $self;

	return $self;

    }

    sub flush_cache {
	my @args = @_;

	ref $args[0] or shift @args;

	if ( @args ) {
	    foreach my $obj ( @args ) {
		if ( __instance( $obj, __PACKAGE__ ) &&
		    __instance( ( my $parent = $obj->source() ),
			'PPI::Element' ) ) {
		    delete $cache{ refaddr( $parent ) };
		}
	    }
	} else {
	    %cache = ();
	}
	return;
    }

}

sub can_be_quantified { return; }


=head2 capture_names

 foreach my $name ( $re->capture_names() ) {
     print "Capture name '$name'\n";
 }

This convenience method returns the capture names found in the regular
expression.

This method is equivalent to

 $self->regular_expression()->capture_names();

except that if C<< $self->regular_expression() >> returns C<undef>
(meaning that something went terribly wrong with the parse) this method
will simply return.

=cut

sub capture_names {
    my ( $self ) = @_;
    my $re = $self->regular_expression() or return;
    return $re->capture_names();
}

=head2 delimiters

 print join("\t", PPIx::Regexp->new('s/foo/bar/')->delimiters());
 # prints '//      //'

When called in list context, this method returns either one or two
strings, depending on whether the parsed expression has a replacement
string. In the case of non-bracketed substitutions, the start delimiter
of the replacement string is considered to be the same as its finish
delimiter, as illustrated by the above example.

When called in scalar context, you get the delimiters of the regular
expression; that is, element 0 of the array that is returned in list
context.

Optionally, you can pass an index value and the corresponding delimiters
will be returned; index 0 represents the regular expression's
delimiters, and index 1 represents the replacement string's delimiters,
which may be undef. For example,

 print PPIx::Regexp->new('s{foo}<bar>')->delimiters(1);
 # prints '<>'

If the object was not initialized with a valid regexp of some sort, the
results of this method are undefined.

=cut

sub delimiters {
    my ( $self, $inx ) = @_;

    my @rslt;
    foreach my $method ( qw{ regular_expression replacement } ) {
	defined ( my $obj = $self->$method() ) or next;
	push @rslt, $obj->delimiters();
    }

    defined $inx and return $rslt[$inx];
    wantarray and return @rslt;
    defined wantarray and return $rslt[0];
    return;
}

=head2 errstr

This static method returns the error string from the most recent attempt
to instantiate a C<PPIx::Regexp>. It will be C<undef> if the most recent
attempt succeeded.

=cut

# defined above, just after sub new.

sub explain {
    return;
}

=head2 failures

 print "There were ", $re->failures(), " parse failures\n";

This method returns the number of parse failures. This is a count of the
number of unknown tokens plus the number of unterminated structures plus
the number of unmatched right brackets of any sort.

=cut

sub failures {
    my ( $self ) = @_;
    return $self->{failures};
}

=head2 max_capture_number

 print "Highest used capture number ",
     $re->max_capture_number(), "\n";

This convenience method returns the highest capture number used by the
regular expression. If there are no captures, the return will be 0.

This method is equivalent to

 $self->regular_expression()->max_capture_number();

except that if C<< $self->regular_expression() >> returns C<undef>
(meaning that something went terribly wrong with the parse) this method
will too.

=cut

sub max_capture_number {
    my ( $self ) = @_;
    my $re = $self->regular_expression() or return;
    return $re->max_capture_number();
}

=head2 modifier

 my $re = PPIx::Regexp->new( 's/(foo)/${1}bar/smx' );
 print $re->modifier()->content(), "\n";
 # prints 'smx'.

This method retrieves the modifier of the object. This comes from the
end of the initializing string or object and will be a
L<PPIx::Regexp::Token::Modifier|PPIx::Regexp::Token::Modifier>.

B<Note> that this object represents the actual modifiers present on the
regexp, and does not take into account any that may have been applied by
default (i.e. via the C<default_modifiers> argument to C<new()>). For
something that takes account of default modifiers, see
L<modifier_asserted()|/modifier_asserted>, below.

In the event of a parse failure, there may not be a modifier present, in
which case nothing is returned.

=cut

sub modifier {
    my ( $self ) = @_;
    return $self->_component( 'PPIx::Regexp::Token::Modifier' );
}

=head2 modifier_asserted

 my $re = PPIx::Regexp->new( '/ . /',
     default_modifiers => [ 'smx' ] );
 print $re->modifier_asserted( 'x' ) ? "yes\n" : "no\n";
 # prints 'yes'.

This method returns true if the given modifier is asserted for the
regexp, whether explicitly or by the modifiers passed in the
C<default_modifiers> argument.

Starting with version 0.036_01, if the argument is a
single-character modifier followed by an asterisk (intended as a wild
card character), the return is the number of times that modifier
appears. In this case an exception will be thrown if you specify a
multi-character modifier (e.g.  C<'ee*'>), or if you specify one of the
match semantics modifiers (e.g.  C<'a*'>).

=cut

sub modifier_asserted {
    my ( $self, $modifier ) = @_;
    return PPIx::Regexp::Token::Modifier::__asserts(
	$self->{effective_modifiers},
	$modifier,
    );
}

# This is a kluge for both determining whether the object asserts
# modifiers (hence the 'ductype') and determining whether the given
# modifier is actually asserted. The signature is the invocant and the
# modifier name, which must not be undef. The return is a boolean.
*__ducktype_modifier_asserted = \&modifier_asserted;

# As of Perl 5.21.1 you can not leave off the type of a '?'-delimited
# regexp. Because this is not associated with any single child we
# compute it here.
sub perl_version_removed {
    my ( $self ) = @_;
    my $v = $self->SUPER::perl_version_removed();
    defined $v
	and $v <= 5.021001
	and return $v;
    defined( my $delim = $self->delimiters() )
	or return $v;
    '??' eq $delim
	and '' eq $self->type()->content()
	and return '5.021001';
    return $v;
}

=head2 regular_expression

 my $re = PPIx::Regexp->new( 's/(foo)/${1}bar/smx' );
 print $re->regular_expression()->content(), "\n";
 # prints '/(foo)/'.

This method returns that portion of the object which actually represents
a regular expression.

=cut

sub regular_expression {
    my ( $self ) = @_;
    return $self->_component( 'PPIx::Regexp::Structure::Regexp' );
}

=head2 replacement

 my $re = PPIx::Regexp->new( 's/(foo)/${1}bar/smx' );
 print $re->replacement()->content(), "\n";
 # prints '${1}bar/'.

This method returns that portion of the object which represents the
replacement string. This will be C<undef> unless the regular expression
actually has a replacement string. Delimiters will be included, but
there will be no beginning delimiter unless the regular expression was
bracketed.

=cut

sub replacement {
    my ( $self ) = @_;
    return $self->_component( 'PPIx::Regexp::Structure::Replacement' );
}

=head2 source

 my $source = $re->source();

This method returns the object or string that was used to instantiate
the object.

=cut

sub source {
    my ( $self ) = @_;
    return $self->{source};
}

=head2 type

 my $re = PPIx::Regexp->new( 's/(foo)/${1}bar/smx' );
 print $re->type()->content(), "\n";
 # prints 's'.

This method retrieves the type of the object. This comes from the
beginning of the initializing string or object, and will be a
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure>
whose C<content> is one of 's',
'm', 'qr', or ''.

=cut

sub type {
    my ( $self ) = @_;
    return $self->_component( 'PPIx::Regexp::Token::Structure' );
}

sub _component {
    my ( $self, $class ) = @_;
    foreach my $elem ( $self->children() ) {
	$elem->isa( $class ) and return $elem;
    }
    return;
}

1;

__END__

=head1 RESTRICTIONS

By the nature of this module, it is never going to get everything right.
Many of the known problem areas involve interpolations one way or
another.

=head2 Ambiguous Syntax

Perl's regular expressions contain cases where the syntax is ambiguous.
A particularly egregious example is an interpolation followed by square
or curly brackets, for example C<$foo[...]>. There is nothing in the
syntax to say whether the programmer wanted to interpolate an element of
array C<@foo>, or whether he wanted to interpolate scalar C<$foo>, and
then follow that interpolation by a character class.

The F<perlop> documentation notes that in this case what Perl does is to
guess. That is, it employs various heuristics on the code to try to
figure out what the programmer wanted. These heuristics are documented
as being undocumented (!) and subject to change without notice. As an
example of the problems even F<perl> faces in parsing Perl, see
L<https://rt.perl.org/Public/Bug/Display.html?id=133027>.

Given this situation, this module's chances of duplicating every Perl
version's interpretation of every regular expression are pretty much nil.
What it does now is to assume that square brackets containing B<only> an
integer or an interpolation represent a subscript; otherwise they
represent a character class. Similarly, curly brackets containing
B<only> a bareword or an interpolation are a subscript; otherwise they
represent a quantifier.

=head2 Changes in Syntax

Sometimes the introduction of new syntax changes the way a regular
expression is parsed. For example, the C<\v> character class was
introduced in Perl 5.9.5. But it did not represent a syntax error prior
to that version of Perl, it was simply parsed as C<v>. So

 $ perl -le 'print "v" =~ m/\v/ ? "yes" : "no"'

prints "yes" under Perl 5.8.9, but "no" under 5.10.0. C<PPIx::Regexp>
generally assumes the more modern parse in cases like this.

=head2 Equivocation

Very occasionally, a construction will be removed and then added back --
and then, conceivably, removed again. In this case, the plan is for
L<perl_version_introduced()|PPIx::Regexp/perl_version_introduced> to
return the earliest version in which the construction appeared, and
L<perl_version_removed()> to return the version after the last version
in which it appeared (whether production or development), or C<undef> if
it is in the highest-numbered Perl.

The constructions involved in this are:

=head3 Un-escaped literal left curly after literal

That is, something like C<< qr<x{> >>.

This was made an error in C<5.25.1>, and it was an error in C<5.26.0>.
But it became a warning again in C<5.27.1>. The F<perl5271delta> says it
was re-instated because the changes broke GNU Autoconf, and the warning
message says it will be removed in Perl C<5.30>.

Accordingly,
L<perl_version_introduced()|PPIx::Regexp/perl_version_introduced>
returns C<5.0>. At the moment
L<perl_version_removed()|PPIx::Regexp/perl_version_removed> returns
C<'5.025001'>. But if it is present with or without warning in C<5.28>,
L<perl_version_removed()|PPIx::Regexp/perl_version_removed> will become
C<undef>. If you need finer resolution than this, see
L<PPIx::Regexp::Element|PPIx::Regexp::Element> methods
l<accepts_perl()|ppix::regexp::element/accepts_perl> and
l<requirements_for_perl()|ppix::regexp::element/requirements_for_perl>

=head2 Static Parsing

It is well known that Perl can not be statically parsed. That is, you
can not completely parse a piece of Perl code without executing that
same code.

Nevertheless, this class is trying to statically parse regular
expressions. The main problem with this is that there is no way to know
what is being interpolated into the regular expression by an
interpolated variable. This is a problem because the interpolated value
can change the interpretation of adjacent elements.

This module deals with this by making assumptions about what is in an
interpolated variable. These assumptions will not be enumerated here,
but in general the principal is to assume the interpolated value does
not change the interpretation of the regular expression. For example,

 my $foo = 'a-z]';
 my $re = qr{[$foo};

is fine with the Perl interpreter, but will confuse the dickens out of
this module. Similarly and more usefully, something like

 my $mods = 'i';
 my $re = qr{(?$mods:foo)};

or maybe

 my $mods = 'i';
 my $re = qr{(?$mods)$foo};

probably sets a modifier of some sort, and that is how this module
interprets it. If the interpolation is B<not> about modifiers, this
module will get it wrong. Another such semi-benign example is

 my $foo = $] >= 5.010 ? '?<foo>' : '';
 my $re = qr{($foo\w+)};

which will parse, but this module will never realize that it might be
looking at a named capture.

=head2 Non-Standard Syntax

There are modules out there that alter the syntax of Perl. If the syntax
of a regular expression is altered, this module has no way to understand
that it has been altered, much less to adapt to the alteration. The
following modules are known to cause problems:

L<Acme::PerlML|Acme::PerlML>, which renders Perl as XML.

L<Data::PostfixDeref|Data::PostfixDeref>, which causes Perl to interpret
suffixed empty brackets as dereferencing the thing they suffix.

L<Filter::Trigraph|Filter::Trigraph>, which recognizes ANSI C trigraphs,
allowing Perl to be written in the ISO 646 character set.

L<Perl6::Pugs|Perl6::Pugs>. Enough said.

L<Perl6::Rules|Perl6::Rules>, which back-ports some of the Perl 6
regular expression syntax to Perl 5.

L<Regexp::Extended|Regexp::Extended>, which extends regular expressions
in various ways, some of which seem to conflict with Perl 5.010.

=head1 SEE ALSO

L<Regexp::Parsertron|Regexp::Parsertron>, which uses
L<Marpa::R2|Marpa::R2> to parse the regexp, and L<Tree|Tree> for
navigation. Unlike C<PPIx::Regexp|PPIx::Regexp>,
L<Regexp::Parsertron|Regexp::Parsertron> supports modification of the
parse tree.

L<Regexp::Parser|Regexp::Parser>, which parses a bare regular expression
(without enclosing C<qr{}>, C<m//>, or whatever) and uses a different
navigation model. After a long hiatus, this module has been adopted, and
is again supported.

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
