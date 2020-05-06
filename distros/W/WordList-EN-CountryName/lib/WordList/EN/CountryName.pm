package WordList::EN::CountryName;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-04'; # DATE
our $DIST = 'WordList-EN-CountryName'; # DIST
our $VERSION = '0.050'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_nonword_chars",74,"num_words_contain_whitespace",72,"num_words_contain_nonword_chars",74,"avg_word_len",10.0923694779116,"num_words",249,"longest_word_len",36,"num_words_contains_whitespace",72,"shortest_word_len",2,"num_words_contains_unicode",0,"num_words_contain_unicode",0); # STATS

1;
# ABSTRACT: English country names

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::CountryName - English country names

=head1 VERSION

This document describes version 0.050 of WordList::EN::CountryName (from Perl distribution WordList-EN-CountryName), released on 2020-05-04.

=head1 SYNOPSIS

 use WordList::EN::CountryName;

 my $wl = WordList::EN::CountryName->new;

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

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 10.0923694779116 |
 | longest_word_len                 | 36               |
 | num_words                        | 249              |
 | num_words_contain_nonword_chars  | 74               |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 72               |
 | num_words_contains_nonword_chars | 74               |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 72               |
 | shortest_word_len                | 2                |
 +----------------------------------+------------------+

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

Converted from L<Games::Word::Wordlist::Country> 0.02.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
afghanistan
aland islands
albania
algeria
american samoa
andorra
angola
anguilla
antarctica
antigua and barbuda
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
bonaire, sint eustatius and saba
bosnia and herzegovina
botswana
bouvet island
brazil
british indian ocean territory
brunei
bulgaria
burkina faso
burma
burundi
cabo verde
cambodia
cameroon
canada
cayman islands
central african republic
chad
chile
china
christmas island
cocos islands
colombia
comoros
congo
congo-kinshasa
cook islands
costa rica
cote d'ivoire
croatia
cuba
curacao
cyprus
czech republic
denmark
djibouti
dominica
dominican republic
east timor
ecuador
egypt
el salvador
equatorial guinea
eritrea
estonia
ethiopia
falkland islands (malvinas)
faroe islands
federated states of micronesia
fiji
finland
france
french guiana
french polynesia
french southern territories
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
guinea-bissau
guyana
haiti
heard island and mcdonald islands
holy see
honduras
hong kong
hungary
iceland
india
indonesia
iran
iraq
ireland
isle of man
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
lao people's democratic republic
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
marshall islands
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
new caledonia
new zealand
nicaragua
niger
nigeria
niue
norfolk island
north korea
northern mariana islands
norway
oman
pakistan
palau
panama
papua new guinea
paraguay
peru
philippines
pitcairn
poland
portugal
puerto rico
qatar
republic of moldova
reunion
romania
russian federation
rwanda
saint barthelemy
saint helena
saint kitts and nevis
saint lucia
saint martin
saint pierre and miquelon
saint vincent and the grenadines
samoa
san marino
sao tome and principe
saudi arabia
senegal
serbia
seychelles
sierra leone
singapore
sint maarten (dutch part)
slovakia
slovenia
solomon islands
somalia
south africa
south georgia and the islands
south korea
south sudan
spain
sri lanka
state of palestine
sudan
suriname
svalbard and jan mayen
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
trinidad and tobago
tunisia
turkey
turkmenistan
turks and caicos islands
tuvalu
uganda
uk
ukraine
united arab emirates
united republic of tanzania
united states minor outlying islands
uruguay
us
uzbekistan
vanuatu
venezuela, bolivarian republic of
vietnam
virgin islands
virgin islands (uk)
wallis and futuna
western sahara
yemen
zambia
zimbabwe
