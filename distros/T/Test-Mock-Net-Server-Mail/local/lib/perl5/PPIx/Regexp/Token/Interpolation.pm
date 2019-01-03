=head1 NAME

PPIx::Regexp::Token::Interpolation - Represent an interpolation in the PPIx::Regexp package.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new('qr{$foo}smx')->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Interpolation> is a
L<PPIx::Regexp::Token::Code|PPIx::Regexp::Token::Code>.

C<PPIx::Regexp::Token::Interpolation> has no descendants.

=head1 DESCRIPTION

This class represents a variable interpolation into a regular
expression. In the L</SYNOPSIS> the C<$foo> would be represented by an
object of this class.

=head1 METHODS

This class provides the following public methods beyond those provided
by its superclass.

=cut

package PPIx::Regexp::Token::Interpolation;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Code };

use Carp qw{ confess };
use PPI::Document;
use PPIx::Regexp::Constant qw{
    COOKIE_CLASS
    COOKIE_REGEX_SET
    MINIMUM_PERL
    TOKEN_LITERAL
    @CARP_NOT
};

our $VERSION = '0.063';

use constant VERSION_WHEN_IN_REGEX_SET => '5.017009';

sub __new {
    my ( $class, $content, %arg ) = @_;

    defined $arg{perl_version_introduced}
	or $arg{perl_version_introduced} = MINIMUM_PERL;

    my $self = $class->SUPER::__new( $content, %arg );

    return $self;
}

# Return true if the token can be quantified, and false otherwise
# This can be quantified because it might interpolate a quantifiable
# token. Of course, it might not, but we need to be permissive here.
# sub can_be_quantified { return };

# We overrode this in PPIx::Regexp::Token::Code, since (?{...}) did not
# appear until Perl 5.5. But interpolation has been there since the
# beginning, so we have to override again. This turns out to be OK,
# though, because while Regex Sets were introduced in 5.17.8,
# interpolation inside them was not introduced until 5.17.9.
sub perl_version_introduced {
    my ( $self ) = @_;
    return $self->{perl_version_introduced};
}

=head2 ppi

This convenience method returns the L<PPI::Document|PPI::Document>
representing the content. This document should be considered read only.

Note that the content of the returned L<PPI::Document|PPI::Document> may
not be the same as the content of the original
C<PPIx::Regexp::Token::Interpolation>. This can happen because
interpolated variable names may be enclosed in curly brackets, but this
does not happen in normal code. For example, in C</${foo}bar/>, the
content of the C<PPIx::Regexp::Token::Interpolation> object will be
C<'${foo}'>, but the content of the C<PPI::Document> will be C<'$foo'>.

=cut

sub ppi {
    my ( $self ) = @_;
    if ( exists $self->{ppi} ) {
	return $self->{ppi};
    } elsif ( exists $self->{content} ) {
	( my $code = $self->{content} ) =~
	    s/ \A ( [\@\$] ) [{] ( .* ) [}] \z /$1$2/smx;
	return ( $self->{ppi} = PPI::Document->new(
		\$code, readonly => 1 ) );
    } else {
	return;
    }
}


# Match the beginning of an interpolation.

my $interp_re =
	qr{ \A (?= [\@\$]? \$ [-\w&`'+^./\\";%=~:?!\@\$<>\[\]\{\},#] |
		   \@ [\w\{] )
	}smx;

# Match bracketed interpolation

my $brkt_interp_re =
    qr{ \A (?: [\@\$] \$* [#]? \$* [\{] (?: [][\-&`'+,^./\\";%=:?\@\$<>,#] |
		\^? \w+ (?: :: \w+ )* ) [\}] |
	    \@ [\{] \w+ (?: :: \w+ )* [\}] )
    }smx;

# We pull out the logic of finding and dealing with the interpolation
# into a separate subroutine because if we fail to find an interpolation
# we want to do something with the sigils.

my %allow_subscript_based_on_cast_symbol = (
    q<$#>	=> 0,
    q<$>	=> 1,
    q<@>	=> 1,
);

sub _interpolation {
    my ( $class, $tokenizer, undef, $in_regexp ) = @_;	# $character unused

    # If the regexp does not interpolate, bail now.
    $tokenizer->interpolates() or return;

    # If we're a bracketed interpolation, just accept it
    if ( my $len = $tokenizer->find_regexp( $brkt_interp_re ) ) {
	return $len;
    }

    # Make sure we start off plausibly
    defined $tokenizer->find_regexp( $interp_re )
	or return;

    # See if PPI can figure out what we have
    my $doc = $tokenizer->ppi_document()
	or return;

    # Get the first statement to work on.
    my $stmt = $doc->find_first( 'PPI::Statement' )
	or return;

    my @accum;	# The elements of the interpolation
    my $allow_subscript;	# Assume no subscripts allowed

    # Find the beginning of the interpolation
    my $next = $stmt->schild( 0 ) or return;

    # The interpolation should start with
    if ( $next->isa( 'PPI::Token::Symbol' ) ) {

	# A symbol
	push @accum, $next;
	$allow_subscript = 1;	# Subscripts are allowed

    } elsif ( $next->isa( 'PPI::Token::Cast' ) ) {

	# Or a cast followed by a block
	push @accum, $next;
	$next = $next->next_sibling() or return;
	if ( $next->isa( 'PPI::Token::Symbol' ) ) {
	    defined (
		$allow_subscript =
		    $allow_subscript_based_on_cast_symbol{
			$accum[-1]->content()
		    }
	    ) or return;
	    push @accum, $next;
	} elsif ( $next->isa( 'PPI::Structure::Block' ) ) {
	    push @accum, $next;
	} else {
	    return;
	}

    } elsif ( $next->isa( 'PPI::Token::ArrayIndex' ) ) {

	# Or an array index
	push @accum, $next;

    } else {

	# None others need apply.
	return;

    }

    # The interpolation _may_ be subscripted. If so ...
    {

	# Only accept a subscript if wanted and available
	$allow_subscript and $next = $next->snext_sibling() or last;

	# Accept an optional dereference operator.
	my @subscr;
	if ( $next->isa( 'PPI::Token::Operator' ) ) {
	    $next->content() eq '->' or last;
	    push @subscr, $next;
	    $next = $next->next_sibling() or last;

	    # postderef was introduced in 5.19.5, per perl5195delta.
	    if ( my $deref = $tokenizer->__recognize_postderef(
		    __PACKAGE__, $next ) ) {
		push @accum, @subscr, $deref;
		last;
	    }
	}

	# Accept only a subscript
	$next->isa( 'PPI::Structure::Subscript' ) or last;

	# The subscript must have a closing delimiter.
	$next->finish() or last;

	# If we are in a regular expression rather than a replacement
	# string, screen the subscript for content, since [] could be a
	# character class, and {} could be a quantifier. The perlop docs
	# say that Perl applies undocumented heuristics subject to
	# change without notice to figure this out. So we do our poor
	# best to be heuristical and undocumented.
	not $in_regexp or $class->_subscript( $next ) or last;

	# If we got this far, accept the subscript and try for another
	# one.
	push @accum, @subscr, $next;
	redo;
    }

    # Compute the length of all the PPI elements accumulated, and return
    # it.
    my $length = 0;
    foreach ( @accum ) {
	$length += ref $_ ? length $_->content() : $_;
    }
    return $length;
}

{
    no warnings qw{ qw };	## no critic (ProhibitNoWarnings)

    my %accept = map { $_ => 1 } qw{ $ $# @ };

    sub __postderef_accept_cast {
	return \%accept;
    }
}

{

    my %allowed = (
	'[' => '_square',
	'{' => '_curly',
    );

    sub _subscript {
	my ( $class, $struct ) = @_;

	# We expect to have a left delimiter, which is either a '[' or a
	# '{'.
	my $left = $struct->start() or return;
	my $lc = $left->content();
	my $handler = $allowed{$lc} or return;

	# We expect a single child, which is a PPI::Statement
	( my @kids = $struct->schildren() ) == 1 or return;
	$kids[0]->isa( 'PPI::Statement' ) or return;

	# We expect the statement to have at least one child.
	( @kids = $kids[0]->schildren() ) or return;

	return $class->$handler( @kids );

    }

}

# Return true if we think a curly-bracketed subscript is really a
# subscript, rather than a quantifier.
# Called as $class->$handler( ... ) above
sub _curly {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( undef, @kids ) = @_;		# Invocant unused

    # If the first child is a word, and either it is an only child or
    # the next child is the fat comma operator, we accept it as a
    # subscript.
    if ( $kids[0]->isa( 'PPI::Token::Word' ) ) {
	@kids == 1 and return 1;
	$kids[1]->isa( 'PPI::Token::Operator' )
	    and $kids[1]->content() eq '=>'
	    and return 1;
    }

    # If the first child is a symbol,
    if ( @kids && $kids[0]->isa( 'PPI::Token::Symbol' ) ) {
	# Accept it if it is the only child
	@kids == 1
	    and return 1;
	# Accept it if there are exactly two children and the second is
	# a subscript.
	@kids == 2
	    and $kids[1]->isa( 'PPI::Structure::Subscript' )
	    and return 1;
    }

    # We reject anything else.
    return;
}

# Return true if we think a square-bracketed subscript is really a
# subscript, rather than a character class.
# Called as $class->$handler( ... ) above
sub _square {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( undef, @kids ) = @_;		# Invocant unused

    # We expect to have either a number or a symbol as the first
    # element.
    $kids[0]->isa( 'PPI::Token::Number' ) and return 1;
    $kids[0]->isa( 'PPI::Token::Symbol' ) and return 1;

    # Anything else is rejected.
    return;
}

# Alternate classes for the sigils, depending on whether we are in a
# character class (index 1) or not (index 0).
my %sigil_alternate = (
    '$' => [ 'PPIx::Regexp::Token::Assertion', TOKEN_LITERAL ],
    '@' => [ TOKEN_LITERAL, TOKEN_LITERAL ],
);

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    exists $sigil_alternate{$character} or return;

    if ( my $accept = $class->_interpolation( $tokenizer, $character, 1 ) ) {
	return $accept;
    }

    my $alternate = $sigil_alternate{$character} or return;
    return $tokenizer->make_token(
	1, $alternate->[$tokenizer->cookie( COOKIE_CLASS ) ? 1 : 0 ] );

}

sub __PPIX_TOKENIZER__repl {
    my ( $class, $tokenizer, $character ) = @_;

    exists $sigil_alternate{$character} or return;

    if ( my $accept = $class->_interpolation( $tokenizer, $character, 0 ) ) {
	return $accept;
    }

    return $tokenizer->make_token( 1, TOKEN_LITERAL );

}

1;

__END__

=begin comment

Interpolation notes:

$ perl -E '$foo = "\\w"; $bar = 3; say qr{$foo{$bar}}'
(?-xism:)
white2:~/Code/perl/PPIx-Regexp.new tom 22:50:33
$ perl -E '$foo = "\\w"; $bar = 3; say qr{foo{$bar}}'
(?-xism:foo{3})
white2:~/Code/perl/PPIx-Regexp.new tom 22:50:59
$ perl -E '$foo = "\\w"; $bar = 3; %foo = {baz => 42};  say qr{$foo{$bar}}'
(?-xism:)
white2:~/Code/perl/PPIx-Regexp.new tom 22:51:38
$ perl -E '$foo = "\\w"; $bar = 3; %foo = {baz => 42};  say qr{$foo}'
(?-xism:\w)
white2:~/Code/perl/PPIx-Regexp.new tom 22:51:50
$ perl -E '$foo = "\\w"; $bar = 3; %foo = {baz => 42};  say qr{$foo{baz}}'
(?-xism:)
white2:~/Code/perl/PPIx-Regexp.new tom 22:52:49
$ perl -E '$foo = "\\w"; $bar = 3; %foo = {baz => 42};  say qr{${foo}{baz}}'
(?-xism:\w{baz})
white2:~/Code/perl/PPIx-Regexp.new tom 22:54:07
$ perl -E '$foo = "\\w"; $bar = 3; %foo = {baz => 42};  say qr{${foo}{$bar}}'
(?-xism:\w{3})

The above makes me think that Perl is extremely reluctant to understand
an interpolation followed by curlys as a hash dereference. In fact, only
when the interpolation was what PPI calls a block was it understood at
all.

$ perl -E '$foo = { bar => 42 }; say qr{$foo->{bar}};'
(?-xism:42)
$ perl -E '$foo = { bar => 42 }; say qr{$foo->{baz}};'
(?-xism:)

On the other hand, Perl seems to be less reluctant to accept an explicit
dereference as a hash dereference.

$ perl -E '$foo = "\\w"; $bar = 3; @foo = (42);  say qr{$foo}'
(?-xism:\w)
white2:~/Code/perl/PPIx-Regexp.new tom 22:58:20
$ perl -E '$foo = "\\w"; $bar = 3; @foo = (42);  say qr{$foo[0]}'
(?-xism:42)
white2:~/Code/perl/PPIx-Regexp.new tom 22:58:28
$ perl -E '$foo = "\\w"; $bar = 3; @foo = (42);  say qr{$foo[$bar]}'
(?-xism:)
white2:~/Code/perl/PPIx-Regexp.new tom 22:58:43
$ perl -E '$foo = "\\w"; $bar = 0; @foo = (42);  say qr{$foo[$bar]}'
(?-xism:42)

The above makes it somewhat easier to get $foo[$bar] interpreted as an
array dereference, but it appears to make use of information that is not
available to a static analysis, such as whether $foo[$bar] exists.

Actually, the above suggests a strategy: a subscript of any kind is to
be accepted as a subscript if it looks like \[\d+\], \[\$foo\], \{\w+\},
or \{\$foo\}. Otherwise, accept it as a character class or a quantifier
depending on the delimiter. Obviously when I bring PPI to bear I will
have to keep track of '->' operators before subscripts, and shed them
from the interpolation as well if the purported subscript does not pass
muster.

=end comment

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
