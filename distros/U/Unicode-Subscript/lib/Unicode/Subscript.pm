use strict;
use warnings;
use utf8;
package Unicode::Subscript;
#ABSTRACT: Generate subscripted and superscripted UTF-8 text without markup

use Carp;

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(subscript superscript TM SM);
    our %EXPORT_TAGS = (all => \@EXPORT_OK);
}

my $TM = '™';
my $SM = '℠';


sub subscript {
    my $text = shift;
    croak "text is undefined" if !defined $text;
    croak "too many arguments" if @_;

    $text =~ tr/0-9+\-=()/₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎/;
    $text =~ tr/aehiklmnoprstuvx/ₐₑₕᵢₖₗₘₙₒₚᵣₛₜᵤᵥₓ/;
    return $text;
}


sub superscript {
    my $text = shift;
    croak "text is undefined" if !defined $text;
    croak "too many arguments" if @_;

    $text =~ tr/0-9+\-=()/⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾/;
    $text =~ tr/a-pr-z/ᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖʳˢᵗᵘᵛʷˣʸᶻ/;
    $text =~ tr/ABDEGHIJKLMNOPRTUVW/ᴬᴮᴰᴱᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᴿᵀᵁⱽᵂ/;
    return $text;
}


sub TM {
    return $TM;
}


sub SM {
    return $SM;
}

1;



=pod

=encoding utf-8

=head1 NAME

Unicode::Subscript - Generate subscripted and superscripted UTF-8 text without markup

=head1 SYNOPSIS

 use Unicode::Subscript qw(subscript superscript);

 say 'H' . subscript(2) . 'O';  # H₂O
 say 'This algorithm is O(n' . superscript(3) . ')';  # O(n³)

 say superscript('this text is really high!');  # ᵗʰⁱˢ ᵗᵉˣᵗ ⁱˢ ʳᵉᵃˡˡʸ ʰⁱᵍʰ!

 use Unicode::Subscript qw(SM TM);
 say 'Eat at Subway' . TM();   # Eat at Subway™

 use Unicode::Subscript ':all';   # import everything

=head1 DESCRIPTION

This module provides methods to convert characters to the equivalent UTF-8
characters for their subscripted or superscripted forms. This may come in
handy when generating fractions, chemical formulas, footnotes, etc.

=head1 FUNCTIONS

=head2 subscript ($text)

Return the subscripted version of C<$text>, in UTF-8 encoding. The following
characters has subscripted forms in Unicode:

=over 4

=item *

Digits 0-9, +, -, = and ()

=item *

A small number of lowercase letters: a e h i k l m n o p r s t u v x

=back

Any other input characters will be left un-suscripted.

=head2 superscript ($text)

Return the superscripted version of C<$text>, in UTF-8 encoding. The following
characters have superscripted forms in Unicode:

=over 4

=item *

Digits 0-9, +, -, = and ()

=item *

All of the lowercase letters except q

=item *

A small number of uppercase letters: A B D E G H I J K L M N O P R T U V W

=back

Any other input characters will be left un-superscripted.

=head2 TM

Returns the Unicode (TM) superscript character.

=head2 SM

Returns the Unicode (SM) superscript character.

=head1 SEE ALSO

L<Unicode::Fraction>

=head1 AUTHOR

Richard Harris <RJH@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Richard Harris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

