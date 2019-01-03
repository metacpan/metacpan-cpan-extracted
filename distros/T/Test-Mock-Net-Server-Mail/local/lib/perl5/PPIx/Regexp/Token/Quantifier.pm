=head1 NAME

PPIx::Regexp::Token::Quantifier - Represent an atomic quantifier.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{\w+}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Quantifier> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Quantifier> has no descendants.

=head1 DESCRIPTION

This class represents an atomic quantifier; that is, one of the
characters C<*>, C<+>, or C<?>.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::Quantifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{
    LITERAL_LEFT_CURLY_ALLOWED
    @CARP_NOT
};

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

# Return true if the token is a quantifier.
sub is_quantifier { return 1 };

my %quantifier = map { $_ => 1 } qw{ * + ? };

=head2 could_be_quantifier

 PPIx::Regexp::Token::Quantifier->could_be_quantifier( '*' );

This method returns true if the given string could be a quantifier; that
is, if it is '*', '+', or '?'.

=cut

sub could_be_quantifier {
    my ( undef, $string ) = @_;		# Invocant unused
    return $quantifier{$string};
}

{

    my %explanation = (
	'*'	=> 'match zero or more times',
	'+'	=> 'match one or more times',
	'?'	=> 'match zero or one time',
    );

    sub __explanation {
	return \%explanation;
    }

}

sub __following_literal_left_curly_disallowed_in {
    return LITERAL_LEFT_CURLY_ALLOWED;
}

sub __PPIX_TOKENIZER__regexp {
    my ( undef, $tokenizer, $character ) = @_;

    $tokenizer->prior_significant_token( 'can_be_quantified' )
	or return;

    return $quantifier{$character};
}

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
