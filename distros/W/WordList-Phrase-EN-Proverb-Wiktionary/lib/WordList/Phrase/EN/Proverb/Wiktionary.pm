package WordList::Phrase::EN::Proverb::Wiktionary;

our $DATE = '2016-02-10'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_whitespace",683,"avg_word_len",31.592972181552,"num_words_contains_unicode",1,"num_words",683,"shortest_word_len",10,"num_words_contains_nonword_chars",683,"longest_word_len",111); # STATS

1;
# ABSTRACT: English proverbs from wiktionary.org

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::EN::Proverb::Wiktionary - English proverbs from wiktionary.org

=head1 VERSION

This document describes version 0.01 of WordList::Phrase::EN::Proverb::Wiktionary (from Perl distribution WordList-Phrase-EN-Proverb-Wiktionary), released on 2016-02-10.

=head1 SYNOPSIS

 use WordList::Phrase::EN::Proverb::Wiktionary;

 my $wl = WordList::Phrase::EN::Proverb::Wiktionary->new;

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

 +----------------------------------+-----------------+
 | key                              | value           |
 +----------------------------------+-----------------+
 | avg_word_len                     | 31.592972181552 |
 | longest_word_len                 | 111             |
 | num_words                        | 683             |
 | num_words_contains_nonword_chars | 683             |
 | num_words_contains_unicode       | 1               |
 | num_words_contains_whitespace    | 683             |
 | shortest_word_len                | 10              |
 +----------------------------------+-----------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-EN-Proverb-Wiktionary>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-EN-Proverb-Wiktionary>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-EN-Proverb-Wiktionary>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wiktionary.org/wiki/Category:English_proverbs>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
April showers bring May flowers
God helps them that help themselves
God helps them who help themselves
God helps those who help themselves
God is in the detail
God works in mysterious ways
If you torture the data long enough, it will confess to anything
Rome wasn't built in a day
Rome wasn't burned in a day
The Lord works in mysterious ways
a bad penny always comes back
a bad penny always turns up
a bad workman always blames his tools
a bird in the hand is worth two in the bush
a camel is a horse designed by a committee
a camel is a horse made by a committee
a cat can look at a king
a cat in gloves catches no mice
a cat may look at a king
a chain is only as strong as its weakest link
a closed mouth gathers no feet
a dumb priest never got a parish
a fool and his money are soon parted
a friend in need is a friend indeed
a golden key can open any door
a good beginning makes a good ending
a house divided against itself cannot stand
a house is not a home
a journey of a thousand miles begins with a single step
a leopard cannot change its spots
a lie has no legs
a man is known by the company he keeps
a man's home is his castle
a mind is a terrible thing to waste
a miss is as good as a mile
a new broom sweeps clean
a nod is as good as a wink
a penny saved is a penny earned
a penny saved is a penny gained
a picture is worth a thousand words
a picture paints a thousand words
a promise is a promise
a promise made is a promise kept
a rising tide lifts all boats
a rolling stone gathers no moss
a spoonful of sugar helps the medicine go down
a stitch in time saves nine
a stopped clock is right twice a day
a turning wheel gathers no rust
a watched kettle never boils
a watched pot never boils
absence makes the heart grow fonder
actions speak louder than words
all cats are gray at night
all cats are gray in the dark
all cats are grey at night
all cats are grey by night
all cats are grey in the dark
all good things come to an end
all politics are local
all politics is local
all roads lead to Rome
all that glisters is not gold
all that glitters is not gold
all the world's a stage
all things come to those who wait
all work and no play makes Jack a dull boy
all's fair in love and war
all's well that ends well
almost doesn't count
an Englishman's home is his castle
an apple a day keeps the doctor away
an army marches on its stomach
another day, another dollar
any press is good press
apple does not fall far from the stem
apple does not fall far from the tree
apple does not fall far from the trunk
apple never falls far from the tree
as a dog returns to his vomit, so a fool repeats his folly
as you sow, so shall you reap
attack is the best form of defence
barking dogs never bite
barking dogs seldom bite
beauty is in the eye of the beholder
beauty is only skin deep
beggars can't be choosers
better Dead than Red
better an egg today than a hen tomorrow
better dead than Red
better dead than red
better safe than sorry
better the devil you know
better the devil you know than the devil you don't
better the devil you know than the devil you don't know
better the devil you know than the one you don't
better the devil you know than the one you don't know
better to light a single candle than to curse the darkness
beware of Greeks bearing gifts
big things come in small packages
bird in the hand
birds of a feather flock together
birds of the feather flock together
blood is thicker than water
boys will be boys
brevity is the soul of wit
bros before hoes
bros before hos
business before pleasure
buy cheap, buy twice
buy low, sell high
buy when it snows and sell when it goes
buy when it snows, sell when it goes
can't live with 'em, can't live without 'em
can't live with them and can't live without them
can't live with them, can't live without them
carpe diem
carpe diem cras
casu consulto
caveat lector
che sara sara
che sera sera
cheaters never prosper
chickens come home to roost
chicks before dicks
children should be seen and not heard
claw me, claw thee
clogs to clogs in three generations
close only counts in horseshoes
clothes don't make the man
cold hands, warm heart
cool heads must prevail
cool heads prevail
cool heads will prevail
cooler heads must prevail
cooler heads prevail
cooler heads will prevail
curiosity killed the cat
dead men can tell no tales
dead men tell no tales
desperate times call for desperate measures
desperate times require desperate measures
devil is in the details
diamonds are a girl's best friend
discretion is the better part of valor
discretion is the better part of valour
do as I say, not as I do
do unto others as you would have them do unto you
does Macy's tell Gimbel's
don't change a winning team
don't count your chickens before they're hatched
don't cry over spilled milk
don't dip your pen in company ink
don't drive faster than your guardian angel can fly
don't drop the soap
don't judge a book by its cover
don't look a gift horse in the mouth
don't put all your eggs in one basket
don't shit in your own nest
don't shit where you eat
don't shoot the messenger
don't sweat the small stuff
don't take any wooden nickels
don't try to teach grandma how to suck eggs
each to his own
early bird catches the worm
early to bed, early to rise, makes a man healthy, wealthy and wise
easy come, easy go
eat, drink and be merry
eaten bread is soon forgotten
empty vessels make the most sound
enough is as good as a feast
even Homer nods
even Jove nods
even a blind pig can find an acorn once in a while
every Jack has his Jill
every cloud has a silver lining
every dark cloud has a silver lining
every day is a school day
every dog has his day
every dog has its day
every dog must have his day
every dog must have its day
every king needs a queen
every little helps
every man has a price
every rule has an exception
every shut eye isn't asleep
every silver lining has a cloud
experience is the best teacher
eye for an eye, a tooth for a tooth
familiarity breeds contempt
feed a cold, starve a fever
finders keepers
fine feathers make fine birds
fine words butter no parsnips
first come, first served
first things first
fool me once, shame on you; fool me twice, shame on me
fools rush in where angels fear to tread
forbidden fruit is the sweetest
forewarned is forearmed
forewarned, forearmed
fortune favors the bold
fortune favors the brave
fortune favours the bold
fortune favours the brave
give a man a fish
give a man a fish and you feed him for a day; teach a man to fish and you feed him for a lifetime
give him enough rope and he'll hang himself
go hard or go home
good fences make good neighbors
good things come to those who wait
good wine needs no bush
grasp all, lose all
great minds
great minds think alike
great oaks from little acorns grow
half a loaf is better than no loaf
half a loaf is better than none
handsome is as handsome does
handsome is that handsome does
haste makes waste
haters gonna hate
he who laughs last laughs best
he who laughs last laughs hardest
he who smelt it dealt it
heaven helps those that help themselves
heaven helps those who help themselves
hell hath no fury like a woman scorned
here today, gone tomorrow
hic Rhodus, hic salta
hindsight is 20/20
history repeats itself
home is where the heart is
home is where you hang your hat
honesty is the best policy
honey catches more flies than vinegar
hope springs eternal
hope springs eternal in the human breast
hunger is a good sauce
hunger is the best sauce
hunger is the best spice
hunt where the ducks are
idle hands are the Devil's playthings
idle hands are the Devil's tools
idle hands are the Devil's workshop
idle hands are the devil's tools
idle hands are the devil's workshop
if all you have is a hammer, everything looks like a nail
if at first you don't succeed
if it ain't broke, don't fix it
if my aunt had balls, she'd be my uncle
if pigs had wings they would fly
if the mountain won't come to Muhammad
if there's grass on the field, play ball
if there's grass on the pitch, play ball
if you can't beat them, join them
if you can't do the time, don't do the crime
if you can't stand the heat, get out of the kitchen
if you lie down with dogs, you get up with fleas
if you lie with dogs you will get fleas
if you love someone, set them free
if you pay bananas, you get monkeys
if you pay peanuts, you get monkeys
if you want a thing done well, do it yourself
ignorance is bliss
in for a dime, in for a dollar
in for a penny, in for a pound
in for an inch, in for a mile
in the land of the blind, the one-eyed man is king
in unity there is strength
in vino veritas
it ain't over 'til the fat lady sings
it ain't the meat, it's the motion
it ain't the whistle that pulls the train
it is a wise child that knows his own father
it is all fun and games until someone loses an eye
it is easier for a camel to go through the eye of a needle than for a rich man to enter into the kingdom of God
it is easy to find a stick to beat a dog
it is not the whistle that pulls the train
it isn't the whistle that pulls the train
it never rains but it pours
it never rains but that it pours
it pays to advertise
it takes all kinds to make a world
it takes one to know one
it takes two to tango
it's a long road that has no turning
it's an ill bird that fouls its own nest
it's an ill wind
it's an ill wind that blows no good
it's an ill wind that blows no one any good
it's an ill wind that blows nobody any good
it's better to ask forgiveness than permission
it's never too late to mend
it's not the meat, it's the motion
it's not the whistle that pulls the train
it's not what you know but who you know
it's the thought that counts
know thyself
knowledge is power
laughter is the best medicine
leaves of three let it be
less is more
let a thousand flowers bloom
lex dubia non obligat
life is like a box of chocolates
life is not all beer and skittles
life's a bitch and then you die
lightning never strikes twice in the same place
like father, like son
little pitchers have big ears
little pitchers have long ears
live and let live
live by the sword, die by the sword
long absent, soon forgotten
long ways, long lies
look before you leap
loose lips sink ships
love is blind
make it do or do without
man is a wolf to man
man plans and God laughs
man proposes, God disposes
many a mickle makes a muckle
many hands make light work
marry in haste, repent at leisure
measure twice and cut once
measure twice, cut once
mess with the bull and you get the horns
might is right
might makes right
mighty oaks from little acorns grow
mills of the gods grind slowly
mind over matter
misery loves company
misfortunes never come singly
mocking is catching
money can't buy happiness
money doesn't grow on trees
money talks
money talks and bullshit walks
money talks, bullshit walks
more haste, less speed
murder will out
my enemy's enemy is my friend
ne'er cast a clout til May be out
necessity is the mother of innovation
necessity is the mother of invention
never change a running system
never look a gift horse in the mouth
nice guys finish last
no bucks, no Buck Rogers
no good deed ever goes unpunished
no good deed goes unpunished
no guts, no glory
no man is an island
no matter how thin you slice it, it's still baloney
no news is good news
no one ever went broke underestimating the intelligence of the American people
no one ever went broke underestimating the intelligence of the American public
no one ever went broke underestimating the taste of the American people
no one ever went broke underestimating the taste of the American public
no pain, no gain
no rest for the wicked
no sleep for the wicked
no smoke without fire
no time like the present
nobody ever went broke underestimating the good taste of the American people
nobody ever went broke underestimating the good taste of the American public
nobody ever went broke underestimating the intelligence of the American people
nobody ever went broke underestimating the intelligence of the American public
nobody ever went broke underestimating the taste of the American people
nobody ever went broke underestimating the taste of the American public
nothing succeeds like success
nothing ventured, nothing gained
old sins cast long shadows
old sins have long shadows
on the internet nobody knows you're a dog
once bitten, twice shy
once you go black, you never go back
one can run but one can't hide
one can't hold two watermelons in one hand
one can't live with them, one can't live without them
one good turn deserves another
one man's meat is another man's poison
one may as well hang for a sheep as a lamb
one swallow does not a spring make
one swallow does not a summer make
one swallow does not make a spring
one swallow does not make a summer
one swallow doesn't a spring make
one swallow doesn't a summer make
one swallow doesn't make a spring
one swallow doesn't make a summer
one who hesitates is lost
one's got to do what one's got to do
only Nixon can go to China
only Nixon could go to China
only fools and horses work
only the good die young
ontogeny recapitulates phylogeny
opportunity knocks at every man's door
opposites attract
other days, other ways
out of sight, out of mind
out of the mouths of babes
out of the mouths of babes and sucklings
people who have, get
people who have, get more
people who live in glass houses shouldn't throw stones
pile it high, sell it cheap
plus ça change
poison tree bears poison fruit
possession is nine points of the law
possession is nine-tenths of the law
power corrupts, absolute power corrupts absolutely
practice makes perfect
pressure makes diamonds
prevention is better than cure
pride comes before a fall
pride cometh before a fall
pride goes before a fall
pride goeth before a fall
pride wenteth before a fall
procrastination is the thief of time
proverbs come in pairs
proverbs go in pairs
proverbs hunt in pairs
proverbs often come in pairs
proverbs run in pairs
respice finem
revenge is a dish best served cold
rubbish in, rubbish out
rules are made to be broken
scientia potentia est
seeing is believing
seek and ye shall find
sell in May
sell in May and go away
sell in May and stay away
sell in May then go away
sell in May, then go away
sell in May, then stay away
shallow brooks are noisy
short reckonings make long friends
shy bairns get noot
shy bairns get nowt
silence is golden
sisters before misters
six of one, half a dozen of the other
slow and steady wins the race
so far so good
some days you get the bear, other days the bear gets you
sow the wind and reap the whirlwind
sow the wind, reap the whirlwind
spare the rod and spoil the child
speak softly and carry a big stick
speech is silver, but silence is golden
speech is silver, silence is gold
speech is silver, silence is golden
spoil the ship for a hap'orth of tar
squeaky wheel gets the grease
squeaky wheels get oiled
start from where you are
sticks and stones
still water runs deep
still waters run deep
strike while the iron is hot
stupid is as stupid does
success depends on your backbone, not your wishbone
success has many fathers, failure is an orphan
sufficient unto the day is the evil thereof
take care of the pennies and the pounds will take care of themselves
take the cash and let the credit go
talk is cheap
talk softly and carry a big stick
tempus fugit
that which doesn't kill you makes you stronger
that's the way life is
that's the way the ball bounces
that's the way the cookie crumbles
that's the way the mop flops
the Lord helps those that help themselves
the Lord helps those who help themselves
the apple doesn't fall far from the tree
the bad penny always comes back
the bad penny always turns up
the bigger they are, the harder they fall
the cake is a lie
the cobbler's children are the worst shod
the course of true love never did run smooth
the cowl does not make the monk
the devil you know is better than the devil you don't know
the dogs bark, but the caravan goes on
the early bird catches the worm
the early bird gets the worm
the end justifies the means
the ends justify the means
the enemy of my enemy is my friend
the fish rots from the head
the fucking you get isn't worth the fucking you get
the fucking you get isn't worth the fucking you take
the fucking you get isn't worth the fucking you're going to get
the good die young
the grass is always greener on the other side
the hand that rocks the cradle is the hand that rules the world
the hand that rocks the cradle rules the world
the heart wants what it wants
the law is a ass
the law is an ass
the longest pole knocks the persimmon
the map is not the territory
the more the merrier
the more things change, the more they stay the same
the only thing one should fear is fear itself
the pen is mightier than the sword
the proof is in the pudding
the proof of the pudding is in the eating
the road to hell is paved with good intentions
the screwing you get isn't worth the screwing you get
the screwing you get isn't worth the screwing you take
the screwing you get isn't worth the screwing you're going to get
the shoemaker's children go barefoot
the sky is the limit
the spirit is willing but the flesh is weak
the way to a man's heart is through his stomach
the wheel turns
the whistle does not pull the train
the whistle doesn't pull the train
the world is one's lobster
the world is one's oyster
them that has gets
them that has, gets
them that has, gets more
them what has gets
them what has, gets
them what has, gets more
them's the breaks
there are many ways to skin a cat
there are none so blind as those who will not see
there are plenty more fish in the sea
there are plenty of fish in the sea
there are two sides to every question
there but for the grace of God go I
there is an exception to every rule
there is nothing new under the sun
there is reason in the roasting of eggs
there may be snow on the mountaintop but there's fire in the valley
there may be snow on the rooftop but there is fire in the furnace
there's a rotten apple in every barrel
there's a sucker born every minute
there's always a bigger fish
there's many a slip twixt cup and lip
there's more than one way to skin a cat
there's no I in team
there's no accounting for taste
there's no fool like an old fool
there's no place like home
there's no point crying over spilt milk
there's no such thing as a free lunch
there's no time like the present
there's no use crying over spilt milk
they're only after one thing
third time pays for all
third time's a charm
third time's the charm
this too shall pass
this too shall pass away
those that have get
those that have get more
those that have, get
those that have, get more
those who can't do, teach
those who can't use their head must use their back
those who have get
those who have get more
those who have, get
those who will not when they may, when they will they shall have nay
throw dirt enough, and some will stick
throw enough mud at the wall and some of it will stick
throw enough mud at the wall, some of it will stick
time and tide
time and tide tarry for no man
time and tide wait for no man
time flies
time flies when you're having fun
time heals all wounds
time is money
timing is everything
to each his own
to err is human
to the victor go the spoils
to thine own self be true
tomorrow is another day
too many cooks spoil the broth
too much bed makes a dull head
treat 'em mean to keep 'em keen
treat them mean, keep them keen
trust every man, but cut the cards
trust everybody, but always cut the cards
trust everybody, but always cut the deck
trust everybody, but cut the cards
trust everybody, but cut the deck
trust your friends, but cut the cards
truth will out
tune in, turn on, drop out
turnabout is fair play
two can play that game
two heads are better than one
two wrongs don't make a right
two wrongs make a right
two's company, three's a crowd
united we stand, divided we fall
use it or lose it
walls have ears
wanton kittens make sober cats
waste not, want not
well begun is half done
what doesn't kill you makes you stronger
what goes around comes around
what goes up must come down
what happens in Vegas stays in Vegas
what happens on the road stays on the road
what happens on tour stays on tour
what has been seen cannot be unseen
what you see is what you get
what's done is done
what's good for the goose is good for the gander
what's sauce for the goose is sauce for the gander
when in Rome
when in Rome, do as the Romans do
when it rains, it pours
when life gives you lemons, make lemonade
when one door closes, another door opens
when one door closes, another one opens
when one door closes, another opens
when one door shuts, another door opens
when one door shuts, another one opens
when one door shuts, another opens
when the cat's away
when the cat's away the mice will play
when the going gets tough, the tough get going
where there's muck there's brass
where there's smoke, there's fire
wherever you go, there you are
who pays the piper calls the tune
work smarter, not harder
wrap it before you tap it
you attract more flies with honey than vinegar
you can catch more flies with honey than with vinegar
you can lead a horse to water but you can't make him drink
you can't fight city hall
you can't get a quart into a pint pot
you can't judge a book by its cover
you can't live with 'em, you can't live without 'em
you can't live with them, you can't live without them
you can't make a silk purse of a sow's ear
you can't make an omelette without breaking eggs
you can't polish a turd
you can't put a wise head on young shoulders
you can't put an old head on young shoulders
you can't run with the hare and hunt with the hounds
you can't take it with you
you can't teach an old dog new tricks
you can't tell a book by its cover
you can't unring a bell
you don't dip your pen in company ink
you don't dip your pen in the company's ink
you don't dip your pen in the inkwell
you don't need a weatherman to know which way the wind blows
you get more with a kind word and a gun than you do with a kind word alone
you get what you pay for
you make the bed you lie in
you never know what you've got till it's gone
you only get what you give
you pays your money and you takes your choice
you scratch my back and I'll scratch yours
you snooze you lose
you're never too old to learn
you've got to be in it to win it
you've got to crack a few eggs to make an omelette
