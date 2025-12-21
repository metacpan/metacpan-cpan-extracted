package WordList::EN::ByCategory::Animal;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-14'; # DATE
our $DIST = 'WordListBundle-EN-ByCategory'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words",319,"num_words_contain_nonword_chars",12,"num_words_contains_unicode",0,"num_words_contains_nonword_chars",12,"num_words_contains_whitespace",12,"avg_word_len",6.38871473354232,"shortest_word_len",2,"num_words_contain_whitespace",12,"longest_word_len",15,"num_words_contain_unicode",0); # STATS

1;
# ABSTRACT: List of animals in English

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::ByCategory::Animal - List of animals in English

=head1 VERSION

This document describes version 0.001 of WordList::EN::ByCategory::Animal (from Perl distribution WordListBundle-EN-ByCategory), released on 2025-01-14.

=head1 SYNOPSIS

 use WordList::EN::ByCategory::Animal;

 my $wl = WordList::EN::ByCategory::Animal->new;

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
 | avg_word_len                     | 6.38871473354232 |
 | longest_word_len                 | 15               |
 | num_words                        | 319              |
 | num_words_contain_nonword_chars  | 12               |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 12               |
 | num_words_contains_nonword_chars | 12               |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 12               |
 | shortest_word_len                | 2                |
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
aardvark
albatross
alligator
alpaca
anaconda
angelfish
ant
antbird
anteater
antelope
ape
armadillo
axolotl
baboon
barracuda
bat
bear
beaver
bee
beetle
binturong
bird
bison
boa
boa constrictor
bobcat
bonobo
buffalo
bulldog
bullfrog
bumblebee
butterfly
caiman
camel
capybara
caribou
cassowary
cat
chameleon
cheetah
chick
chicken
chimpanzee
chinchilla
chipmunk
clownfish
cobra
cockatoo
cockroach
cougar
cow
coyote
crab
crane
crocodile
crow
cuckoo
cuttlefish
dachsund
deer
dingo
dodo
dog
dolphin
donkey
dove
dragon
dragonfly
dromedary
duck
duckling
dugong
eagle
earthworm
echidna
eel
egret
elephant
elk
emu
falcon
ferret
finch
firefly
fish
flamingo
flounder
fly
fossa
fox
frog
fruit bat
gazelle
gecko
gharial
gibbon
giraffe
gnat
goat
goldfish
goose
gopher
gorilla
groundhog
guinea pig
gull
haddock
hamster
hare
harrier
hawk
hedgehog
heron
herring
hippo
hippopotamus
hog
hornet
horse
hound
hummingbird
hyena
ibex
ibis
icefish
iguana
impala
inchworm
indri
jackal
jackrabbit
jaguar
jay
jaybird
jellyfish
jerboa
kangaroo
kitten
kiwi
knot
koala
koi
komodo
komodo dragon
kookaburra
krill
kudu
ladybug
lamprey
langur
lapwing
lark
leech
lemming
lemur
leopard
lion
lizard
llama
lobster
lynx
macaque
macaw
magpie
mallard
mammoth
manatee
mandrill
manta ray
mantis
mastiff
meerkat
mink
minnow
mongoose
monkey
moose
moth
mouse
mule
muskrat
narwhal
newt
nighthawk
nightingale
numbat
ocelot
octopus
okapi
opossum
orangutan
orca
oriole
oryx
osprey
ostrich
otter
owl
owlet
ox
oyster
panda
panther
parakeet
parrot
peacock
pelican
penguin
pigeon
pika
platypus
pony
poodle
porcupine
possum
prawn
pufferfish
puffin
puma
python
quahog
quail
quetzal
quokka
quoll
rabbit
raccoon
rat
rattlesnake
raven
reindeer
rhea
rhino
rhinoceros
roadrunner
robin
rombat
rook
rooster
rottweiler
salamander
salmon
sandpiper
sardine
scallop
scorpion
seahorse
seal
shark
sheep
shih tzu
skunk
sloth
snail
snake
snow leopard
spider
squid
squirrel
starfish
stork
swan
tahr
tamarin
tapir
tarantula
tasmanian devil
termite
tern
thrush
tiger
toad
tortoise
toucan
triceratops
trout
tsetse
tuatara
tuna
turtle
uakari
unau
unicorn
urchin
urial
vampire bat
vaquita
velociraptor
vicuna
viper
vole
vulture
wallaby
walrus
warthog
wasp
water buffalo
weasel
whale
whippet
wildebeest
wolf
wolverine
woodpecker
wren
x-ray tetra
xenops
xerus
yak
yellowtail
yeti
yeti crab
zander
zebra
zebrafish
zebu
zonkey
zorilla
zorse
