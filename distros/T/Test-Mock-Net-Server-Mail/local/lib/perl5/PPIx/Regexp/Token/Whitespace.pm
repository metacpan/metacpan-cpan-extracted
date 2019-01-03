=head1 NAME

PPIx::Regexp::Token::Whitespace - Represent whitespace

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{ foo }smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Whitespace> is a
L<PPIx::Regexp::NoOp|PPIx::Regexp::NoOp>.

C<PPIx::Regexp::Token::Whitespace> has no descendants.

=head1 DESCRIPTION

This class represents whitespace. It will appear inside the regular
expression only if the C</x> modifier is present, but it may also appear
between the type and the opening delimiter (e.g. C<qr {foo}>) or after
the regular expression in a bracketed substitution (e.g. C<s{foo}
{bar}>).

If the C</xx> modifier is present, it can also appear inside bracketed
character classes. This was introduced in Perl 5.25.9.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Whitespace;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::NoOp };

use PPIx::Regexp::Constant qw{
    COOKIE_REGEX_SET
    MINIMUM_PERL
    @CARP_NOT
};

our $VERSION = '0.063';

sub __new {
    my ( $class, $content, %arg ) = @_;

    defined $arg{perl_version_introduced}
	or $arg{perl_version_introduced} = 
	( grep { 127 < ord } split qr{}, $content )
	? '5.021001'
	: MINIMUM_PERL;

    return $class->SUPER::__new( $content, %arg );
}

sub explain {
    my ( $self ) = @_;
    my $parent;
    if (
	$parent = $self->parent()
	    and $parent->isa( 'PPIx::Regexp' )
    ) {
	return $self->SUPER::explain();
    } elsif ( $self->in_regex_set() ) {
	return q<Not significant in extended character class>;
    } elsif ( my $count = $self->modifier_asserted( 'x*' ) ) {
	return q<Not significant under /> . ( 'x' x $count );
    } else {
	return $self->SUPER::explain();
    }
}

sub whitespace {
    return 1;
}

# Objects of this class are generated either by the tokenizer itself
# (when scanning for delimiters) or by PPIx::Regexp::Token::Literal (if
# it hits a match for \s and finds the regular expression has the /x
# modifier asserted.
#
# sub __PPIX_TOKENIZER__regexp {
#     my ( $class, $tokenizer, $character ) = @_;
#
#     return scalar $tokenizer->find_regexp( qr{ \A \s+ }smx );
#
# }

1;

__END__

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
