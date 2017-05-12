package WordList::Phrase::FR::Proverb::Wiktionary;

our $DATE = '2016-02-10'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_whitespace",52,"num_words_contains_nonword_chars",52,"longest_word_len",50,"num_words_contains_unicode",21,"num_words",52,"shortest_word_len",17,"avg_word_len",32.0961538461538); # STATS

1;
# ABSTRACT: French proverbs from wiktionary.org

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::FR::Proverb::Wiktionary - French proverbs from wiktionary.org

=head1 VERSION

This document describes version 0.01 of WordList::Phrase::FR::Proverb::Wiktionary (from Perl distribution WordList-Phrase-FR-Proverb-Wiktionary), released on 2016-02-10.

=head1 SYNOPSIS

 use WordList::Phrase::FR::Proverb::Wiktionary;

 my $wl = WordList::Phrase::FR::Proverb::Wiktionary->new;

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
 | avg_word_len                     | 32.0961538461538 |
 | longest_word_len                 | 50               |
 | num_words                        | 52               |
 | num_words_contains_nonword_chars | 52               |
 | num_words_contains_unicode       | 21               |
 | num_words_contains_whitespace    | 52               |
 | shortest_word_len                | 17               |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-FR-Proverb-Wiktionary>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-FR-Proverb-Wiktionary>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-FR-Proverb-Wiktionary>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wiktionary.org/wiki/Category:French_proverbs>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
Paris ne s'est pas fait en un jour
Rome ne s'est pas faite en un jour
a beau mentir qui vient de loin
après la pluie, le beau temps
au royaume des aveugles, les borgnes sont rois
avec des si on mettrait Paris en bouteille
c'est en forgeant qu'on devient forgeron
c'est en forgeant que l'on devient forgeron
ce que femme veut, Dieu le veut
chat échaudé craint l'eau froide
chose promise, chose due
dis-moi qui tu fréquentes et je te dirai qui tu es
du pareil au même
il y a plusieurs façons de plumer un canard
impossible n'est pas français
l'argent ne tombe pas du ciel
l'habit ne fait pas le moine
la fortune sourit aux audacieux
la nuit, tous les chats sont gris
la vengeance est un plat qui se mange froid
le remède est pire que le mal
le silence est d'or
le temps, c'est de l'argent
les chiens aboient, la caravane passe
les grands esprits se rencontrent
les murs ont des oreilles
les petits ruisseaux font les grandes rivières
loin des yeux, loin du cœur
mieux vaut prévenir que guérir
mieux vaut tard que jamais
on ne saurait faire boire un âne qui n'a pas soif
pas de nouvelles, bonnes nouvelles
pierre qui roule n'amasse pas mousse
plus ça change, plus c'est la même chose
pour vivre heureux, vivons cachés
quand le vin est tiré, il faut le boire
qui aime bien châtie bien
qui aime bien, châtie bien
qui ne dit mot consent
qui ne risque rien n'a rien
qui ne tente rien n'a rien
qui se ressemble s'assemble
qui vole un œuf vole un bœuf
telle mère, telle fille
tous les chemins mènent à Rome
tout ce qui brille n'est pas or
tout est bien qui finit bien
un tiens vaut mieux que deux tu l'auras
une hirondelle ne fait pas le printemps
vouloir c'est pouvoir
à chaque jour suffit sa peine
à la guerre comme à la guerre
