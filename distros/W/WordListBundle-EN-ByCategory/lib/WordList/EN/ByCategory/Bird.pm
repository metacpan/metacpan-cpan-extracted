package WordList::EN::ByCategory::Bird;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-14'; # DATE
our $DIST = 'WordListBundle-EN-ByCategory'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words",126,"num_words_contain_nonword_chars",4,"num_words_contains_whitespace",4,"avg_word_len",6.42063492063492,"num_words_contains_nonword_chars",4,"num_words_contains_unicode",0,"num_words_contain_unicode",0,"longest_word_len",11,"shortest_word_len",3,"num_words_contain_whitespace",4); # STATS

1;
# ABSTRACT: List of birds in English

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::ByCategory::Bird - List of birds in English

=head1 VERSION

This document describes version 0.001 of WordList::EN::ByCategory::Bird (from Perl distribution WordListBundle-EN-ByCategory), released on 2025-01-14.

=head1 SYNOPSIS

 use WordList::EN::ByCategory::Bird;

 my $wl = WordList::EN::ByCategory::Bird->new;

 # Pick a (or several) random word(s) from the list
 my ($word) = $wl->pick;
 my ($word) = $wl->pick(1);  # ditto
 my @words  = $wl->pick(3);  # no duplicates

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }  # case-sensitive

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Iterate
 my $first_word = $wl->first_word;
 while (defined(my $word = $wl->next_word)) { ... }

 # Get all the words (beware, some wordlists are *huge*)
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 6.42063492063492 |
 | longest_word_len                 | 11               |
 | num_words                        | 126              |
 | num_words_contain_nonword_chars  | 4                |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 4                |
 | num_words_contains_nonword_chars | 4                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 4                |
 | shortest_word_len                | 3                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListBundle-EN-ByCategory>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListBundle-EN-ByCategory>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListBundle-EN-ByCategory>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
albatross
auk
avocet
bald eagle
barn owl
blackbird
blue jay
bunting
buzzard
canary
cardinal
chickadee
cockatoo
condor
crow
cuckoo
curlew
darter
dipper
dodo
dove
drongo
duck
duckling
dunlin
eagle
egret
eider
emu
euphonia
falcon
falconet
finch
firecrest
flamingo
flatbill
flicker
flufftail
flycatcher
frigatebird
fulmar
gannet
goldfish
goose
goshawk
gull
harrier
hawk
hen
heron
hoatzin
hobby
hornbill
hummingbird
ibis
jackdaw
jay
jerboa
kakapo
kestrel
kingfisher
kite
kiwi
knot
kookaburra
lapwing
lark
linnet
loon
lovebird
macaw
magpie
mallard
merlin
mockingbird
myna
nighthawk
nightingale
nutcracker
oriole
osprey
ostrich
owl
owlet
parakeet
parrot
peacock
pelican
penguin
pheasant
pigeon
pintail
plover
puffin
quail
quelea
quetzal
raven
roadrunner
robin
rook
sandpiper
seagull
siskin
snipe
sora
sparrow
starling
stork
swallow
swan
teal
tern
thrush
toucan
turaco
turkey
vanga
vireo
vulture
warbler
woodpecker
wren
xeme
xenops
zebra fish
