# ============================================================================
package Text::Phonetic::Koeln;
# ============================================================================
use utf8;

use Moo;
extends qw(Text::Phonetic);

__PACKAGE__->meta->make_immutable;

our $VERSION = $Text::Phonetic::VERSION;

sub _do_encode {
    my ($self,$string) = @_;
    
    my (@character_list,$result,$last_match);

    $string = uc($string);
    
    # Replace umlaut
    $string =~ s/ß/S/g;
    $string =~ s/[äÄ]/AE/g;
    $string =~ s/[öÖ]/OE/g;
    $string =~ s/[üÜ]/UE/g;
    
    # Replace double consonants
    #$string =~ s/([BCDFGHJKLMNPQRSTVWXZ])\1+/$1/g;    
    
    # Convert string to array
    @character_list = split //,$string;
    $result = '';

    # Handle initial sounds
    # A,E,I,J,O,U,Y => 0
    if (Text::Phonetic::_is_inlist($character_list[0],qw(A E I J Y O U))) {
        $result .= 0;
        $last_match = shift @character_list;
    } elsif ($character_list[0] eq 'C') {
        if (Text::Phonetic::_is_inlist($character_list[1],qw(A H K L O Q R U X))) {
            $result .= 4;
        } else {
            $result .= 8;
        }
        $last_match = shift @character_list;
    }
    
    # Loop all characters
    while (scalar(@character_list)) {
        # A,E,I,J,O,U,Y => 0
        #if (Text::Phonetic::_is_inlist($character_list[0],qw(A E I J O U Y))) {
        #    $result .= 0;
        #    $last_match = shift @character_list;
        #    next;
        #}
        # B => 1
        if ($character_list[0] eq 'B') {
            $result .= 1;
            $last_match = shift @character_list;
            next;
        }
        # P in front of H => 1
        # P => 3
        if ($character_list[0] eq 'P') {
            if (defined($character_list[1])
                && $character_list[1] eq 'H') {    
                $result .= 3;    
            } else {
                $result .= 1;
            }
            $last_match = shift @character_list;
            next;
        }
        # D,T in front of C,S,Z => 8
        # D,T => 2
        if (Text::Phonetic::_is_inlist($character_list[0],qw(D T))) {
            if (defined($character_list[1]) && $character_list[1] =~ m/[CSZ]/) {
                $result .= 8;
            } else {
                $result .= 2;
            }
            $last_match = shift @character_list;
            next;
        }
        # F,V,W => 3
        if (Text::Phonetic::_is_inlist($character_list[0],qw(F V W))) {
            $result .= 3;
            $last_match = shift @character_list;
            next;
        } 
        # C in front of A,H,K,O,Q,U,X => 4
        # C after S,Z => 8
        if ($character_list[0] eq 'C') {
            if (Text::Phonetic::_is_inlist($last_match,qw(S Z))) {
                $result .= 8;
            } elsif (defined($character_list[1])
                && Text::Phonetic::_is_inlist($character_list[1],qw(A H K O Q U X))) {    
                $result .= 4;
            }
            $last_match = shift @character_list;
            next;
        }
        
        # G,K,Q => 4
        if (Text::Phonetic::_is_inlist($character_list[0],qw(G Q K))) {
            $result .= 4;
            $last_match = shift @character_list;
            next;
        }
        # X not after C,K,Q => 48
        # X after C,K,Q => 8
        if ($character_list[0] eq 'X') {
            if (Text::Phonetic::_is_inlist($last_match,qw(C K Q))) {
                $result .= 8;
            } else {
                $result .= 48;
            }
            $last_match = shift @character_list;
            next;
        }
        # L => 5
        if ($character_list[0] eq 'L') {
            $result .= 5;
            $last_match = shift @character_list;
            next;
        }
        # M,N => 6
        if (Text::Phonetic::_is_inlist($character_list[0],qw(M N))) {
            $result .= 6;
            $last_match = shift @character_list;
            next;
        }    
        # R => 7
        if ($character_list[0] eq 'R') {
            $result .= 7;
            $last_match = shift @character_list;
            next;
        }
        # S,Z => 8
        if (Text::Phonetic::_is_inlist($character_list[0],qw(S Z))) {
            $result .= 8;
            $last_match = shift @character_list;
            next;
        }

        # No rule matched
        $last_match = shift @character_list;
    }
    
    # Replace consecutive codes
    $result =~ s/(\d)\1+/$1/g;
    
    # Replace zero code (except for first position)
    #$result =~ s/(\d+)0/$1/g;
    
    return $result
}


1;

=encoding utf8

=pod

=head1 NAME

Text::Phonetic::Koeln - Kölner Phonetik algorithm

=head1 DESCRIPTION

The "Kölner Phonetik" is a phonetic algorithm for indexing names by sound, as 
pronounced in German. The goal is for names with the same pronunciation to be 
encoded to the same representation so that they can be matched despite minor 
differences in spelling.

In contrast to Soundex this algorithm is suitable for long names since the
length of the encoded result is not limited. This algorithm is able to find
allmost all ortographic variations in names, but also produces many false
positives.

The result is always a sequence of numbers. Special characters and whitespaces
are ignored. If your text might contain non-latin characters (except for
German umlaute and 'ß') you should unaccent it prior to creating a phonetic
code.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 COPYRIGHT

Text::Phonetic::Koeln is Copyright (c) 2006,2007 Maroš. Kollár.
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Description of the algorithm can be found at 
L<http://de.wikipedia.org/wiki/K%C3%B6lner_Phonetik>

Hans Joachim Postel: Die Kölner Phonetik. Ein Verfahren zur Identifizierung 
von Personennamen auf der Grundlage der Gestaltanalyse. in: IBM-Nachrichten, 
19. Jahrgang, 1969, S. 925-931

=cut
