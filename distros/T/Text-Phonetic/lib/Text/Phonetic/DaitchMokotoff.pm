# ============================================================================
package Text::Phonetic::DaitchMokotoff;
# ============================================================================
use utf8;

use Moo;
extends qw(Text::Phonetic);

__PACKAGE__->meta->make_immutable;

our $VERSION = $Text::Phonetic::VERSION;

our @RULES = (
    ["SCHTSCH", 2, 4, 4],
    ["SCHTSH", 2, 4, 4],
    ["SCHTCH", 2, 4, 4],
    ["SHTCH", 2, 4, 4],
    ["SHTSH", 2, 4, 4],
    ["STSCH", 2, 4, 4],
    ["TTSCH", 4, 4, 4],
    ["ZHDZH", 2, 4, 4],
    ["SHCH", 2, 4, 4],
    ["SCHT", 2, 43, 43],
    ["SCHD", 2, 43, 43],
    ["STCH", 2, 4, 4],
    ["STRZ", 2, 4, 4],
    ["STRS", 2, 4, 4],
    ["STSH", 2, 4, 4],
    ["SZCZ", 2, 4, 4],
    ["SZCS", 2, 4, 4],
    ["TTCH", 4, 4, 4],
    ["TSCH", 4, 4, 4],
    ["TTSZ", 4, 4, 4],
    ["ZDZH", 2, 4, 4],
    ["ZSCH", 4, 4, 4],
    ["CHS", 5, 54, 54],
    ["CSZ", 4, 4, 4],
    ["CZS", 4, 4, 4],
    ["DRZ", 4, 4, 4],
    ["DRS", 4, 4, 4],
    ["DSH", 4, 4, 4],
    ["DSZ", 4, 4, 4],
    ["DZH", 4, 4, 4],
    ["DZS", 4, 4, 4],
    ["SCH", 4, 4, 4],
    ["SHT", 2, 43, 43],
    ["SZT", 2, 43, 43],
    ["SHD", 2, 43, 43],
    ["SZD", 2, 43, 43],
    ["TCH", 4, 4, 4],
    ["TRZ", 4, 4, 4],
    ["TRS", 4, 4, 4],
    ["TSH", 4, 4, 4],
    ["TTS", 4, 4, 4],
    ["TTZ", 4, 4, 4],
    ["TZS", 4, 4, 4],
    ["TSZ", 4, 4, 4],
    ["ZDZ", 2, 4, 4],
    ["ZHD", 2, 43, 43],
    ["ZSH", 4, 4, 4],
    ["AI", 0, 1, undef],
    ["AJ", 0, 1, undef],
    ["AY", 0, 1, undef],
    ["AU", 0, 7, undef],
    ["CZ", 4, 4, 4],
    ["CS", 4, 4, 4],
    ["DS", 4, 4, 4],
    ["DZ", 4, 4, 4],
    ["DT", 3, 3, 3],
    ["EI", 0, 1, undef],
    ["EJ", 0, 1, undef],
    ["EY", 0, 1, undef],
    ["EU", 1, 1, undef],
    ["IA", 1, undef, undef],
    ["IE", 1, undef, undef],
    ["IO", 1, undef, undef],
    ["IU", 1, undef, undef],
    ["KS", 5, 54, 54],
    ["KH", 5, 5, 5],
    ["MN", 66, 66, 66],
    ["NM", 66, 66, 66],
    ["OI", 0, 1, undef],
    ["OJ", 0, 1, undef],
    ["OY", 0, 1, undef],
    ["PF", 7, 7, 7],
    ["PH", 7, 7, 7],
    ["SH", 4, 4, 4],
    ["SC", 2, 4, 4],
    ["ST", 2, 43, 43],
    ["SD", 2, 43, 43],
    ["SZ", 4, 4, 4],
    ["TH", 3, 3, 3],
    ["TS", 4, 4, 4],
    ["TC", 4, 4, 4],
    ["TZ", 4, 4, 4],
    ["UI", 0, 1, undef],
    ["UJ", 0, 1, undef],
    ["UY", 0, 1, undef],
    ["UE", 0, 1, undef],
    ["ZD", 2, 43, 43],
    ["ZH", 4, 4, 4],
    ["ZS", 4, 4, 4],
    ["RZ", [94,4], [94,4], [94,4]],
    ["CH", [5,4], [5,4], [5,4]],
    ["CK", [4,45], [4,45], [4,45]],
    ["RS", [94,4], [94,4], [94,4]],
    ["FB", 7, 7, 7],
    ["A", 0, undef, undef],
    ["B", 7, 7, 7],
    ["D", 3, 3, 3],
    ["E", 0, undef, undef],
    ["F", 7, 7, 7],
    ["G", 5, 5, 5],
    ["H", 5, 5, undef],
    ["I", 0, undef, undef],
    ["K", 5, 5, 5],
    ["L", 8, 8, 8],
    ["M", 6, 6, 6],
    ["N", 6, 6, 6],
    ["O", 0, undef, undef],
    ["P", 7, 7, 7],
    ["Q", 5, 5, 5],
    ["R", 9, 9, 9],
    ["S", 4, 4, 4],
    ["T", 3, 3, 3],
    ["U", 0, undef, undef],
    ["V", 7, 7, 7],
    ["W", 7, 7, 7],
    ["X", 5, 54, 54],
    ["Y", 1, undef, undef],
    ["Z", 4, 4, 4],
    ["C", [5,4], [5,4], [5,4]],
    ["J", [1,4], [4,undef], [4,undef]],
);

sub _do_compare {
    my ($self,$result1,$result2) = @_;

    return 50 
       if Text::Phonetic::_compare_list($result1,$result2);    

    return 0;
}

sub _do_encode {
    my ($self,$string) = @_;

    my $match_index;
    my $last_match;
    my $result_list = [''];
    
    $string = uc($string);
    $string =~ tr/A-Z//cd;
    
    while (length($string)) {
        # Loop all rules
        RULES: foreach my $rule (@RULES) {
            
            # Check if rule matches
            #if ($string =~ s/^([AEIOUJY]{2})([AEIOU])//i) {

            if ($string =~ s/^$rule->[0]//) {
                # Is Start of a string?
                if ($result_list->[0] eq '') {
                    $match_index = 1;
                # Before a vowel?
                } elsif (Text::Phonetic::_is_inlist(substr($string,0,1),qw(A E I O U)))  {
                    $match_index = 2;
                # Other situation
                } else{    
                    $match_index = 3;
                }
                unless (defined $rule->[$match_index]) {
                    undef $last_match;
                    last RULES;
                }
                last RULES if (defined($last_match) && $last_match eq $rule->[$match_index]);
                $last_match = $rule->[$match_index];
                $result_list = _add_result($result_list,$rule->[$match_index]);
                last RULES;
            }
        }
    }
    
    foreach my $result (@$result_list) {
        $result .= '0'  x (6-length $result);
        $result = substr($result,0,6);
    }

    return $result_list;
}

sub _add_result {    
    my $result = shift;
    my $rule = shift;

    return $result unless defined $rule;

    if (ref($rule) eq 'ARRAY') {
        my $newresult = [];
        foreach my $result_string (@$result) {
            foreach my $rule_string (@$rule) {    
                push @$newresult,$result_string.$rule_string;
            }
        }
        return $newresult;
    } else {
        foreach my $result_string (@$result) {
            $result_string .= $rule;
        }
        return $result;
    }
}

1;

=encoding utf8

=pod

=head1 NAME

Text::Phonetic::DaitchMokotoff - Daitch-Mokotoff algorithm

=head1 DESCRIPTION

Daitch-Mokotoff Soundex (D-M Soundex) is a phonetic algorithm invented in 1985 
by genealogist Gary Mokotoff, and later improved by Randy Daitch, both of the 
Jewish Genealogical Society. It is a refinement of the Russell and American 
Soundex algorithms designed to allow matching of Slavic and Yiddish surnames 
with similar pronunciation but differences in spelling. (Wikipedia, 2007)

Some strings in the Daitch-Mokotoff algorithm produce ambigous results. 
Therefore the results are always returned as Array references, even if there 
is only a single result.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 COPYRIGHT

Text::Phonetic::Metaphone is Copyright (c) 2006,2007 Maroš. Kollár.
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Description of the algorithm can be found at 
L<http://en.wikipedia.org/wiki/Daitch-Mokotoff_Soundex>

L<Text::Metaphone>

=cut
