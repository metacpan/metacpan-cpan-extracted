package WordList::EN::CountryName::SingleWord;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-04'; # DATE
our $DIST = 'WordList-EN-CountryName'; # DIST
our $VERSION = '0.050'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("shortest_word_len",2,"num_words_contains_whitespace",0,"num_words_contains_unicode",0,"num_words_contain_unicode",0,"num_words",175,"avg_word_len",6.96,"longest_word_len",13,"num_words_contains_nonword_chars",0,"num_words_contain_whitespace",0,"num_words_contain_nonword_chars",0); # STATS

1;
# ABSTRACT: English country names (single-word entries only)

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::CountryName::SingleWord - English country names (single-word entries only)

=head1 VERSION

This document describes version 0.050 of WordList::EN::CountryName::SingleWord (from Perl distribution WordList-EN-CountryName), released on 2020-05-04.

=head1 SYNOPSIS

 use WordList::EN::CountryName::SingleWord;

 my $wl = WordList::EN::CountryName::SingleWord->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 STATISTICS

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 6.96  |
 | longest_word_len                 | 13    |
 | num_words                        | 175   |
 | num_words_contain_nonword_chars  | 0     |
 | num_words_contain_unicode        | 0     |
 | num_words_contain_whitespace     | 0     |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                | 2     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-EN-CountryName>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-EN-CountryNames>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-EN-CountryName>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Converted from L<Games::Word::Wordlist::CountrySingleWord> 0.02.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
afghanistan
albania
algeria
andorra
angola
anguilla
antarctica
argentina
armenia
aruba
australia
austria
azerbaijan
bahamas
bahrain
bangladesh
barbados
belarus
belgium
belize
benin
bermuda
bhutan
bolivia
botswana
brazil
brunei
bulgaria
burma
burundi
cambodia
cameroon
canada
chad
chile
china
colombia
comoros
congo
croatia
cuba
curacao
cyprus
denmark
djibouti
dominica
ecuador
egypt
eritrea
estonia
ethiopia
fiji
finland
france
gabon
gambia
georgia
germany
ghana
gibraltar
greece
greenland
grenada
guadeloupe
guam
guatemala
guernsey
guinea
guyana
haiti
honduras
hungary
iceland
india
indonesia
iran
iraq
ireland
israel
italy
jamaica
japan
jersey
jordan
kazakstan
kenya
kiribati
kuwait
kyrgyzstan
latvia
lebanon
lesotho
liberia
libya
liechtenstein
lithuania
luxembourg
macao
macedonia
madagascar
malawi
malaysia
maldives
mali
malta
martinique
mauritania
mauritius
mayotte
mexico
monaco
mongolia
montenegro
montserrat
morocco
mozambique
namibia
nauru
nepal
netherlands
nicaragua
niger
nigeria
niue
norway
oman
pakistan
palau
panama
paraguay
peru
philippines
pitcairn
poland
portugal
qatar
reunion
romania
rwanda
samoa
senegal
serbia
seychelles
singapore
slovakia
slovenia
somalia
spain
sudan
suriname
swaziland
sweden
switzerland
syria
taiwan
tajikistan
thailand
togo
tokelau
tonga
tunisia
turkey
turkmenistan
tuvalu
uganda
uk
ukraine
uruguay
us
uzbekistan
vanuatu
vietnam
yemen
zambia
zimbabwe
