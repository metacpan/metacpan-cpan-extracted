package WordList::Phrase::EN::Idiom::Wiktionary;

our $DATE = '2016-02-10'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words",8479,"num_words_contains_unicode",4,"num_words_contains_whitespace",8151,"avg_word_len",14.4614931006015,"shortest_word_len",3,"longest_word_len",83,"num_words_contains_nonword_chars",8401); # STATS

1;
# ABSTRACT: English idioms from wiktionary.org

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::EN::Idiom::Wiktionary - English idioms from wiktionary.org

=head1 VERSION

This document describes version 0.01 of WordList::Phrase::EN::Idiom::Wiktionary (from Perl distribution WordList-Phrase-EN-Idiom-Wiktionary), released on 2016-02-10.

=head1 SYNOPSIS

 use WordList::Phrase::EN::Idiom::Wiktionary;

 my $wl = WordList::Phrase::EN::Idiom::Wiktionary->new;

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
 | avg_word_len                     | 14.4614931006015 |
 | longest_word_len                 | 83               |
 | num_words                        | 8479             |
 | num_words_contains_nonword_chars | 8401             |
 | num_words_contains_unicode       | 4                |
 | num_words_contains_whitespace    | 8151             |
 | shortest_word_len                | 3                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-EN-Idiom-Wiktionary>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-EN-Idiom-Wiktionary>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-EN-Idiom-Wiktionary>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wiktionary.org/wiki/Category:English_idioms>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
'er indoors
110 proof
12-ounce curls
15 minutes of fame
1600 Pennsylvania Avenue
23 Skidoo Street
Aaron's beard
Adam Tiler
American Dream
Appendix:English 19th Century idioms
Appendix:Glossary of baseball jargon (C)
Appendix:Glossary of baseball jargon (G)
Appendix:Glossary of baseball jargon (H)
Appendix:Glossary of baseball jargon (L)
Appendix:Glossary of baseball jargon (O)
Appendix:Glossary of baseball jargon (P)
Appendix:Glossary of baseball jargon (R)
Appendix:Glossary of baseball jargon (S)
Appendix:Glossary of baseball jargon (T)
Appendix:Glossary of baseball jargon (W)
Appendix:Snowclones/that's X for you
Appendix:Star Wars derivations
Athanasian wench
Attic salt
Aunt Sally
BFD
Banbury story of a cock and a bull
Barmacide feast
Belgravian
Bharat Army
Black Russian
Bob's your uncle
Bottle of Dog
Broadway
Bronx cheer
Brussels
Buckley's and none
Buckley's chance
Buggins's turn
Bumfuck
Bumfuck, Egypt
Catch-22
Catholic twins
China syndrome
Chinaman on one's back
Chinaman's chance
Chinese Wall
Chinese cherry
Chinese compliment
Chinese green
Chinese puzzle
Christmas disease
Christmas graduate
Christmas present
Christmas tree bill
Daniel come to judgement
Davy Jones's locker
Delhi belly
Derangement Syndrome
Disgusted of Tunbridge Wells
Downing Street
Dunkirk spirit
Dutch act
Dutch courage
Dutch oven
Dutch reckoning
Elvis has left the building
Elysian
Elysian Fields
English fever
Evel Knievel
Fanny Adams
Faustian bargain
Four Horsemen of the Apocalypse
French leave
French letter
GI can
Gary Glitter
German goitre
German virgin
German wheel
God forfend
God is in the detail
God's gift to man
God's gift to women
God's green earth
God's honest truth
Great Britain and Ireland
HAL
HE-double-L
HE-double-hockey-sticks
HE-double-toothpicks
Hallmark moment
Hawaiian goose
Hollywood moment
Holy of Holies
Homer nods
Humpty Dumptyism
I could eat a horse
I do
I don't fancy yours
I haven't the foggiest
I never did
I rest my case
I see what you did there
I see, said the blind man
I take it
I wish
I would
I'd say
I'll be
I'll be a monkey's uncle
I'll be damned
I'll say
Indian sign
Internets
Jack Tar
Jane Doe
Jane Roe
Jesus, Mary and Joseph
Joe Average
Joe Citizen
Joe Public
Joe Sixpack
John Doe
John Hancock
John Henry
John Q. Public
John Thomas
Johnny-come-lately
Johnny-one-note
King Shit of Turd Island
Last Supper
Lion of Judah
Lord willing and the creek don't rise
Lord's Supper
Main Street
Mary Celeste
Master of the Universe
Merry Andrew
Mexican breakfast
Mexican standoff
Mickey Mouse
Midas touch
Miller of Dee
Miss Right
Monday-morning quarterback
Monopoly money
Nantucket sleigh ride
Netflix and chill
Nikon choir
Number 10
Number Ten
Nuremberg defense
Oreo cookie
PO'd
Peter Pan syndrome
Pierian spring
Polish parliament
Portuguese man-of-war
Potemkin village
Promised Land
Quaker gun
Queer Street
RSN
Red Baron
Richard Roe
Russian bar
Russian roulette
Santa's workshop
Scotch mist
South Tibet
Spanish flag
Speedy Gonzales
Spock ears
Sunday best
Sunday driver
Sussex Drive
Swiss bank account
TANSTAAFL
TEOTWAWKI
TINSTAAFL
TS girl
Thatcher's children
The End
Tinker to Evers to Chance
Tom, Dick and Harry
Trojan-horse
Turkish bread
Tweedledum and Tweedledee
Wall Street
White House
Whitman's sampler
X marks the spot
X's and O's
Yankee dime
Yankee go home
a Roland for an Oliver
a cold day in Hell
a cold day in July
a cut above
a cut below
a day late and a dollar short
a few sandwiches short of a picnic
a good deal
a good voice to beg bacon
a great deal
a hair's breadth
a hundred and ten percent
a into g
a life of its own
a little bird told me
a little bit of bread and no cheese
a little from column A, a little from column B
a lot
a notch above
a quick drop and a sudden stop
a riddle wrapped up in an enigma
a week from next Tuesday
a week is a long time in politics
a wild goose never laid a tame egg
abandon ship
abandon to
abide by
able to get a word in edgewise
about time
about to
about turn
above and beyond
above and beyond the call of duty
above board
above one's bend
above the curve
above the law
above the salt
above water
abstract idea
abstract verb
abuse of distress
accident of birth
accident waiting to happen
according to
according to Hoyle
ace in the hole
ace of spades
ace up one's sleeve
acid test
acknowledge the corn
acquired taste
across the board
across the pond
act of Congress
act one's age
act out
act up
activist judge
activist justice
add fuel to the fire
add insult to injury
add up
admire to
adrenaline junkie
after Saturday comes Sunday
after all
after one's own heart
after the Lord Mayor's show
after the fact
again and again
against all odds
against the clock
against the collar
against the grain
against the law
against the run of play
age before beauty
age out
agree to disagree
agree with
agreement in principle
aha moment
ahead of one's time
ahead of the curve
ahead of the game
aim at
aim to
air out
air rage
alarm bell
alarums and excursions
albatross
albatross around one's neck
albatross round one's neck
alive and kicking
all along
all and some
all and sundry
all at once
all bark and no bite
all bets are off
all dressed up and nowhere to go
all duck or no dinner
all ears
all eyes
all eyes and ears
all fur coat and no knickers
all hat and no cattle
all hell breaks loose
all hell broke loose
all holiday
all hollow
all in a day's work
all it's cracked up to be
all kidding aside
all kinds of
all mouth and no trousers
all mouth and trousers
all nations
all one's eggs in one basket
all one's life's worth
all out
all over
all over but the shouting
all over hell's half acre
all over the board
all over the map
all over the place
all over with
all rights reserved
all set
all sizzle and no steak
all talk and no cider
all that
all that jazz
all the marbles
all the rage
all the same
all the tea in China
all the way to Egery and back
all there
all things being equal
all things considered
all thumbs
all to smash
all told
all very well
all wet
all y'all's
all-a-mort
all-over oneself
almighty dollar
along about
along the lines
also known as
aluminum shower
amateur hour
ambassador of Morocco
amber gambler
amber nectar
ambulance chasing
amen curler
an apple a day
an axe to grind
an offer one can't refuse
anaconda mortgage
ancient history
and all
and all that
and all this
and be done with it
and change
and counting
and crap
and finally
and his mother
and how
and shit
and so forth
and so on
and the like
and then some
angel's advocate
angle for
angle for farthings
angle of attack
another nail in one's coffin
answer back
answer for
answer on a postcard
answer to
ants in one's pants
any more for any more
any nook or cranny
any old
any old nook or cranny
any old thing
any port in a storm
any way one slices it
anyone's guess
anything goes
ape leader
apothecary's Latin
apple of someone's eye
apples and oranges
apply oneself
apron string
apron-string hold
arch dell
arch doxy
are you blind
are you deaf
are your ears burning
area of influence
argue down
ark ruffian
arm and a leg
arm candy
arm to the teeth
arm up
arm's length
army volunteer
around Robin Hood's barn
around the Horn
around the clock
around the corner
arrive at
arse about
arse about face
arse end of nowhere
arse over tip
arse over tit
arsy varsy
arsy versy
artful dodger
artist's conception
as I was saying
as a rule
as a whole
as all get-out
as best one can
as ever trod shoe-leather
as far as
as far as one knows
as if
as if there were no tomorrow
as is
as it happens
as it is
as long as
as luck may have it
as luck would have it
as much
as of
as often as not
as soon as
as the crow flies
as the day is long
as the next girl
as the next guy
as the wind blows
as well
as well as
as yet
as you know
ask about
ask after
ask around
ask for
ask for it
ask for the moon
ask my arse
ask out
ask round
ask the question
asleep at the switch
asphalt jungle
ass in a sling
ass over teakettle
ass-backwards
assault and battery
asspussy
assume the mantle
assume the position
at a canter
at a glance
at a loss
at a loss for words
at a moment's notice
at a pinch
at a stand
at all
at all hours
at arm's length
at bay
at best
at bottom
at cross-purposes
at death's door
at first
at first blush
at full tilt
at heart
at home
at it
at large
at last
at latter Lammas
at long last
at loose ends
at odds
at once
at one's fingertips
at pains
at peace
at peace with
at places
at rest
at sea
at sixes and sevens
at stake
at that
at the best of times
at the coal face
at the drop of a hat
at the end of one's tether
at the end of the day
at the feet of
at the helm
at the high port
at the mercy of
at the moment
at the ready
at the receiving end
at the top of one's lungs
at the top of one's voice
at the very least
at the wheel
at this point in time
at times
at variance
at will
at work
atomic cocktail
atta girl
attaboy
attagal
attagirl
attention whore
auld lang syne
autem bawler
autem cackler
autem dipper
autem diver
autem mort
avant la lettre
average bear
average joe
average up
avoid like the plague
away from home
away game
away with the fairies
awesome sauce
aye aye, sir
babe in the woods
babe magnet
baby blues
baby up
baby-killer
babysitter test
back and forth
back at you
back burner
back down
back forty
back gammon player
back in the day
back into
back of one's hand
back off
back office
back out
back to square one
back to the drawing board
back to the wall
back up
back wall
back-asswards
back-burner
back-cloth star
back-of-the-envelope
back-to-back
back-to-back-to-back
backhanded compliment
backpedal
backseat driver
backwater
bacon-faced
bacon-fed
bad actor
bad apple
bad blood
bad boy
bad company
bad egg
bad form
bad hair day
bad iron
bad joke
bad name
bad news
bad penny
bad rap
bad taste in one's mouth
bad to the bone
bad word
badge bunny
bag and baggage
bag of bones
bag of rations
bag of shells
bag of tricks
bag of wind
bail out
bake up
baker's dozen
baker's half dozen
balance out
balance the books
balancing act
bale up
ball hog
ball of fire
ball-breaker
balloon goes up
balloon knot
ballpark estimate
ballpark figure
balls to the wall
balls-out
balls-up
balum rancum
banana republic
band together
bang away
bang for the buck
bang on
bang out
bang straw
bang to rights
bang up
bang up cove
banged up
bank night
bank up
bankbook
banker's dozen
bankers' hours
banyan day
baptism by fire
baptism of fire
bar none
bar off
bar sinister
bar star
bar up
bare metal
bare one's soul
bare one's teeth
bargain basement
barge in
bark up the wrong tree
barn doors
barn find
barnburner
barrel of laughs
barrel of monkeys
barrow man
base over apex
basement battler
bash the bishop
basket case
basket house
bass-ackwards
bastardly gullion
bat a thousand
bat an eyelash
bat an eyelid
bat five hundred
bat for both sides
bat for the other team
bat one's eyelashes
bat one's eyes
bater cara
bathtub gin
batten down the hatches
battle cry
bawl out
be a man
be absorbed by
be all ears
be around
be as silent as the grave
be born yesterday
be glad to see the back of
be in a spot of bother
be in for
be in luck
be in one's altitudes
be it as it may
be left holding the baby
be mother
be my guest
be on about
be on to
be oneself
be prepared
be sick
be snowed under
be still my heart
be taken ill
be that as it may
be the way to go
be-all and end-all
bean counter
bean queen
bear a hand
bear down
bear in mind
bear oneself
bear the brunt
bear up
bear with
beard the lion in his den
beast with two backs
beat Banaghan
beat a dead horse
beat a retreat
beat around the bush
beat feet
beat it
beat off
beat one's brain
beat one's head against a stone wall
beat one's meat
beat someone's brains out
beat the bishop
beat the clock
beat the crap out of
beat the daylights out of
beat the meat
beat the pants off
beat the shit out of
beat the stuffing out of
beat to the punch
beats me
beautiful people
beauty mark
beauty queen
beauty sleep
beaver away
because you touch yourself at night
beck and call
become of
become one flesh
bed blocker
bed in
bed of roses
beddy-bye
bedroom eyes
bee in one's bonnet
beef to the hoof
beef up
beefed out
been there, done that
been there, done that, bought the T-shirt
been there, done that, got the T-shirt
been to the rodeo
beer and skittles
beer goggles
beer muscles
before someone's time
before you can say Jack Robinson
beg off
beg to differ
behind bars
behind closed doors
behind its time
behind someone's back
behind the bit
behind the counter
behind the eight-ball
behind the scenes
behind the times
behind time
being that
belemnite battlefield
believe it or not
believe one's eyes
believe you me
bell out
bell the cat
bells and whistles
belly up
belly up to the bar
below par
below the belt
below the salt
belt out
bench jockey
bend one's elbow
bend over backwards
bend someone's ear
bend the rules
bend the truth
benevolent overlord
bent on
bent on a splice
beside oneself
beside the point
best bet
best bib and tucker
best laid plans
best of both worlds
best of the bunch
best regards
best thing since sliced bread
best thing since sliced pan
best-kept secret
bet one's boots
bet one's bottom dollar
bet the farm
better half
better than sex
between Scylla and Charybdis
between a rock and a hard place
between the hammer and the anvil
between the jigs and the reels
between the pipes
between you, me, and the bedpost
betwixt and between
beyond one's ken
beyond one's pay grade
beyond the black stump
beyond the call of duty
beyond the pale
bide one's time
big boy
big boys
big break
big bucks
big cheese
big daddy
big deal
big enchilada
big fat
big fish in a small pond
big girl
big girl's blouse
big gun
big guy
big house
big kahuna
big mouth
big name
big ol'
big old
big ole
big picture
big shot
big sleep
big spender
big talk
big tent
big up
big wheel
big year
big-boned
bigger fish to fry
bill of goods
binary decimal
bio queen
bird in the bosom
bird of one's own brain
bird's-eye view
birds and bees
birds of a feather
birth tourism
birthday suit
bit on the side
bitch up
bite me
bite of the cherry
bite of the reality sandwich
bite off
bite off more than one can chew
bite one's lip
bite one's tongue
bite someone in the arse
bite someone's head off
bite the big one
bite the biscuit
bite the bullet
bite the dust
bite the hand that feeds one
bite to eat
bits and bobs
bitter end
bitter pill to swallow
black and blue
black babies
black beetle
black gold
black gum
black magic
black man
black mark
black out
black rider
black sheep
black tie
black triangle
black-on-black
blame Canada
blame game
blank canvas
blank out
blanket term
blare out
blast off
blaze a trail
blaze away
blazing star
bleed the lizard
bleed to death
bleeding edge
bless you
blessed event
blessing in disguise
blimp out
blind alley
blind date
blind leading the blind
blind with science
blink of an eye
blink-and-you-miss-it
block out
blocking and tackling
blood and guts
blood in the water
blood moon
blood, sweat and tears
bloom is off the rose
blossom out
blot on the escutcheon
blot one's copy book
blot out
blow a fuse
blow a gasket
blow a kiss
blow away
blow chunks
blow hot and cold
blow it
blow me
blow me down
blow off
blow off steam
blow one's top
blow one's wad
blow out of proportion
blow over
blow sky high
blow smoke
blow someone out of the water
blow someone's cover
blow someone's mind
blow the lid off
blow the whistle
blow this pop stand
blow this popsicle stand
blow to kingdom come
blow up in one's face
blow up someone's phone
blow-by-blow
blue book
blue chamber
blue devils
blue moon
blue movie
blue note
blue state
blue wall of silence
blue-eyed
blue-eyed boy
blue-sky thinking
blurt out
board out
body English
body blow
body check
body of water
bog off
bog standard
bogged down
boil down
boil over
boil up
boiling frog
boiling hot
boiling mad
boiling point
boldly go where no man has gone before
bolt bucket
bomb out
bone dry
bone of contention
bone up
bone-crunching
bone-deep
bone-dry
bone-idle
bone-shaking
booby prize
boogie on down
book dumping
book in
boomshanka
boot camp
boot out
boots and all
boots on the ground
booze can
bored out of one's brains
bored out of one's mind
borganism
born and bred
born in a barn
born on the Fourth of July
born with a silver spoon in one's mouth
borrowed time
bottle away
bottle out
bottle up
bottom bitch
bottom edge
bottom falls out
bottom feeder
bottom fishing
bottom hand
bottom line
bottom of the line
bottom of the ninth
bottom out
bottom the house
bought and paid for
bought the farm
bounce back
bounce off
bounce off the walls
bow and scrape
bow down
bow out
bowl a googly
bowl of cherries
bowl over
box clever
box oneself into a corner
box seat
box the compass
box-office bomb
boy howdy
boy in the boat
boy toy
boys and girls
boys and their toys
bozo eruption
brace of shakes
bragging rights
brain bucket
brain candy
brain cramp
brain fart
brain surgeon
brain surgery
branch off
branch out
brass ceiling
brass farthing
brass monkey
brass monkeys
brass neck
brass ring
brass-neck
brass-necked
brassed off
brave out
brazen out
breach of promise
bread and butter
bread-and-butter
break a law
break a leg
break a sweat
break cover
break even
break ground
break in
break into
break new ground
break one's duck
break one's lance
break out
break ranks
break someone's heart
break the Sabbath
break the back of
break the bank
break the buck
break the cycle
break the deadlock
break the fourth wall
break the ice
break the mold
break the seal
break through
break up
break wind
break with
breakfast of champions
breaking and entering
breath of fresh air
breathe a sigh of relief
breathe a word
breathe down someone's neck
breathe easy
bred-in-the-bone
breed in the bone
brick and mortar
brick by brick
brick house
brick in
brick in one's hat
brick wall
bricks and mortar
bridge the gap
bridge too far
bright lights
bright line
bright shiny object
bright young thing
bright-eyed and bushy-tailed
bright-line rule
bring a knife to a gunfight
bring about
bring down the house
bring forward
bring home
bring home the bacon
bring it weak
bring on
bring one's arse to an anchor
bring out in a rash
bring over
bring owls to Athens
bring sand to the beach
bring to a boil
bring to bear
bring to heel
bring to justice
bring to light
bring to the table
bring up
bring up the rear
broad across the beam
broad church
broad in the beam
broad shoulders
broad strokes
broaden someone's horizons
broken record
broken vessel
broken-hearted
broom closet
brown bag
brown bread
brown noser
brown power
brown study
brown thumb
brown-noser
browned off
brownie point
brownnose
brush aside
brush by
brush down
brush off
brush up
bubble over
buck fever
buck for
buck naked
buck up
bucket down
bucket list
bucket of bolts
buckle down
buckle up
buff out
buff the muffin
buff up
bug off
bug out
bugger all
bugger off
build a better mousetrap
build bridges
build castles in the air
build on sand
build up
built like a brick shithouse
built like a tank
bulger
bulk bill
bulk billing
bull session
bulletproof
bum around
bum chum
bum rap
bum rush
bum steer
bum's rush
bump and grind
bump in the road
bump into
bump off
bump up
bums in seats
bun fight
bundle of energy
bundle of joy
bundle of laughs
bundle of nerves
bundle off
bunny girl
bunny hop
bunny hug
buoy up
buried treasure
burn a hole in one's pocket
burn one's bridges
burn one's candle at both ends
burn one's fingers
burn out
burn rubber
burn the midnight oil
burn to a crisp
burp the worm
burst in
burst into tears
burst out laughing
burst someone's bubble
bury one's head in the sand
bury the hatchet
bury the lead
bury the lede
bush league
bush telegraph
business as usual
business end
business girl
busman's holiday
bust a cap in someone's ass
bust a move
bust a nut
bust ass cold
bust chops
bust one's ass
bust one's balls
bust one's butt
bust one's chops
bust out
bust the dust
busted flush
busy beaver
busy little beaver
busy work
but good
but seriously folks
but then
butt heads
butt in
butt out
butt-naked
butt-ugly
butter fingers
butter one's bread on both sides
butter up
butter wouldn't melt in someone's mouth
butterfly upon a wheel
button nose
button one's lip
button-down
buttoned-down
buy and pay for
buy into
buy out
buy straw hats in winter
buy the farm
buy time
buy to let
buy up
buzz off
by a hair's breadth
by a long shot
by all accounts
by all means
by and large
by any chance
by any means
by far
by guess or by gosh
by halves
by hand
by heart
by hook or by crook
by mistake
by no means
by one's lights
by one's own hand
by oneself
by rights
by the Grace of God
by the book
by the by
by the numbers
by the same token
by the skin of one's teeth
by the time
by the way
by trade
by virtue of
by-the-book
by-the-numbers
cake walk
cakes and ale
cakewalk
call a spade a spade
call it a day
call it a night
call it even
call it quits
call off the dogs
call out
call someone's bluff
call the shots
call to account
call to the bar
call up
calling card
calm before the storm
calm your tits
camel through the eye of a needle
camel's nose
camp out
can it
can of worms
can't even
can't get enough
can't seem
can't stand
can't wait
canary in a coal mine
candle in the wind
candy-coat
cap in hand
cap it all off
cap over the windmill
captain of industry
care package
cargo-200
carried away
carrot and stick
carry a torch for
carry a tune
carry coals to Newcastle
carry forward
carry off
carry on
carry one's weight
carry oneself
carry out
carry over
carry someone's water
carry the can
carry the mail
carry the message to Garcia
carry through
carry water for
cart off
carve out
carved in stone
case closed
case in point
cash cow
cash in
cash in one's chips
cash on the barrelhead
cash up
cask wine
cast a shadow
cast aside
cast aspersions
cast one's vote
cast pearls before swine
cast the first stone
cast up one's accounts
castle in the air
casu consulto
cat and dog life
cat and mouse
cat got someone's tongue
cat in the meal-tub
cat in the sack
cat piss
cat that ate the canary
cat's claw
cat's cradle
cat's meow
cat's pajamas
cat's pyjamas
cat's tongue
cat-and-mouse
catbird seat
catch a buzz
catch a cold
catch air
catch as catch can
catch big air
catch dust
catch fire
catch flies
catch heat
catch hell
catch it
catch napping
catch on
catch one's drift
catch sight of
catch some Zs
catch some z's
catch someone napping
catch someone's eye
catch the eye
catch the sun
catch-as-catch-can
cattle call
caucus race
caught between the devil and the deep blue sea
caught on the hop
caught with one's hand in the cookie jar
caught with one's pants down
cause a stir
cave in
caviar to the general
cease and desist
cease to be
center field
central dogma
chain reaction
chalk off
chalk out
chalk up to
champ at the bit
champagne taste on a beer budget
chance upon
chance'd be a fine thing
chances are
change hands
change horses in midstream
change of heart
change of life
change of tack
change one's mind
change one's tune
change over
change someone's mind
change the channel
character assassination
charge down
charge up
charity mugger
charley horse
charmed life
chase a rainbow
chase after
chase off
chase one's tail
chase rainbows
chase tail
chat up
cheap-arse Tuesday
cheaper by the dozen
cheat on
cheat sheet
check and balance
check is in the mail
check off
check through
checks and balances
cheeky monkey
cheer up
cheese and rice
cheese it
cheese off
cheesed off
chemical imbalance
chemically imbalanced
cherry on top
cherry-pick
chesterfield rugby
chestnut
chew off
chew on
chew out
chew the cud
chew the fat
chew the meat and spit out the bones
chew the scenery
chew up
chicken bit
chicken feed
chicken fillet
chicken liver
chicken out
chickenize
chickens come home to roost
child's play
childhood friend
chill girl
chill out
chilly climate
chime in
chin up
chink up
chip away
chip in
chip off the old block
chip on one's shoulder
chip shot
chip up
chirk up
chocolate hot dog
choke off
choke the chicken
chomp at the bit
choose up
choose your battles
chop down
chopped liver
chow down
chrome dome
chrome horn
chuck in
chuck it down
chuck out
chum up
chump change
chump-change
circle the drain
circle the wagons
circuit slugger
circular file
circular firing squad
cite chapter and verse
city slicker
civil tongue
claim to fame
clam up
clamp down on
clash of the ash
class clown
class warfare
clean house
clean out
clean someone's clock
clean up
clean up one's act
clear cut
clear one's lines
clear out
clear the decks
climb down
climb the walls
clitlicker
clock in
clock is ticking
clog up
close enough for government work
close in on
close of play
close one's eyes
close one's eyes and think of England
close ranks
close shave
close the face
close the stable door after the horse has bolted
close to home
close to the wind
close up shop
close, but no cigar
closed book
closed form
closing time
cloud nine
clout list
clue in
clue stick
clutch artist
coals to Newcastle
cock a snook
cock cheese
cock in the henhouse
cock of the roost
cock of the walk
cock pilot
cock-and-bull story
coffee shop
coil up
coined name
coke dick
cold comfort
cold fish
cold one
cold reading
cold shoulder
cold snap
cold turkey
collect dust
collect one's thoughts
color inside the lines
color outside the lines
colt over the fence
come a cropper
come a long way
come across
come again
come along
come and go
come apart
come around
come at
come clean
come down
come down the pike
come down to
come down to earth
come down to us
come down with
come first
come forward
come from a good place
come full circle
come hell or high water
come home to roost
come in
come in from the cold
come in handy
come into
come into being
come into one's own
come of age
come on
come on over
come online
come out
come out in the wash
come out of one's shell
come out of the closet
come out of the woodwork
come out swinging
come the acid
come thick and fast
come through
come to
come to Jesus
come to a close
come to a head
come to a sticky end
come to an end
come to blows
come to grief
come to grips with
come to life
come to light
come to mention it
come to mind
come to nothing
come to nought
come to oneself
come to papa
come to someone's aid
come to someone's rescue
come to terms
come to terms with
come to the fore
come to think of it
come unhinged
come unstuck
come up
come up roses
come up with
come what may
come with the territory
come-to-Jesus
comedy of errors
comfort girl
comfort woman
comfort zone
comfortable in one's own skin
comfortably off
coming out of one's ears
command performance
common cause
common crossing
common ground
common name
common or garden variety
common touch
common-and-garden
company man
company town
complete game
concrete jungle
conjure up
connect up
conscience money
controlled substance
cook
cook the books
cook up
cooked
cookie licking
cookie-cutter
cooking with gas
cool head
cool it
cool one's heels
cool one's jets
coon eyes
coon's age
cop a feel
cop on
cop oneself on
cop out
cop-out
copious free time
copper-bottomed
coprophagous grin
corner the market
corporate ladder
corporate welfare bum
corporation pop
cost a pretty penny
cost the earth
cotton ceiling
cotton on
cotton to
cotton-picking
cough up
could care less
could not get elected dogcatcher
couldn't carry a note in a bucket
couldn't happen to a nicer
couldn't organise a piss-up in a brewery
count on
count one's blessings
count sheep
country mile
courage of one's convictions
covenant of salt
cover one's bases
cover one's feet
cover someone's ass
cover up
cow bite
cowboy up
cowgirl position
crab mentality
crack a book
crack a crib
crack a fat
crack a smile
crack down
crack of dawn
crack on
crack through
crack up
cradle robber
cradle snatcher
cradle-to-grave
cramp someone's style
crank out
crank up
crap one's pants
crap out
crash and burn
crash course
crash dive
crash together
crawl over each other
crawl with
crazy like a fox
cream in one's jeans
cream of the crop
creature comfort
creature feature
creep into
creme de la creme
criss-cross applesauce
crocodile tear
crop up
cross my heart
cross my heart and hope to die
cross off
cross out
cross paths
cross someone's palm
cross someone's path
cross swords
cross that bridge when one comes to it
cross the Rubicon
cross the aisle
cross the line
cross-purpose
crowd-pleaser
crown jewels
cruising for a bruising
crunch numbers
cry all the way to the bank
cry down
cry for help
cry foul
cry in one's beer
cry one's eyes out
cry someone a river
cry the blues
cry uncle
cry wolf
crying shame
crystal clear
crystal dick
crème de la crème
cue up
cuff Jonas
culpable homicide
culture hero
cum grano salis
cuntful
cup of joe
cup of tea
curate's egg
curb appeal
curb crawler
curl someone's hair
curry favor
curtain-raiser
cut a dash
cut a figure
cut a rug
cut a swath
cut a wide swath
cut and dried
cut and thrust
cut bait
cut both ways
cut corners
cut down
cut from the same cloth
cut in
cut it
cut it close
cut it fine
cut loose
cut no ice
cut of one's jib
cut off
cut off one's nose to spite one's face
cut one
cut one loose
cut one's coat according to one's cloth
cut one's teeth
cut out
cut red tape
cut short
cut someone loose
cut swathes
cut the cheese
cut the crap
cut the mustard
cut the umbilical cord
cut through
cut to pieces
cut to the chase
cut to the quick
cut up
cutie pie
cutting edge
cylinder head
damn Yankee
damn by association
damn right
damn straight
damn the torpedoes
damn with faint praise
damned if one does and damned if one doesn't
damp squib
dance of the seven veils
dance to a different tune
dance to a new tune
dance to someone's tune
dangly bits
dark horse
dark market
dark markets
darken a church door
darken someone's door
darn tootin'
darning needle
darsi da fare
dash off
date with destiny
dawn of a new day
day after day
day and age
day and night
day in, day out
day lark
day of days
day one
day or night
day out
day-to-day
daylight
daylight robbery
days of yore
dead 'n' buried
dead air
dead and buried
dead asleep
dead center
dead duck
dead end
dead giveaway
dead heat
dead in the water
dead last
dead loss
dead meat
dead men
dead of night
dead on
dead ringer
dead to rights
dead tree edition
dead weight
dead wood
deadbeat dad
deadstick landing
deafening silence
deal breaker
death by spellcheck
death knell
death spiral
death warmed up
deathbed conversion
debris field
decimal dozen
deep down
deep end
deep pockets
deep six
deep sleep
deep thinker
deep water
deep-six
deer in the headlights
deliver the goods
deliver the message to Garcia
den of iniquity
desk jockey
detective work
devil is in the details
devil's advocate
devil's luck
dial back
dial down
diamond in the rough
diamond ring
dick all
dick milk
dick munch
dick-measuring contest
dicky-bird
dictated but not read
die
die down
die off
die on the vine
die out
dig deep
dig in
dig in one's heels
dig one's own grave
dig out
dig out of a hole
dig up
dig up dirt
dim bulb
dimber damber upright man
dime a dozen
dime's worth
diminishing returns
dip a toe into
dip into
dip out
diplomatic flu
dirt file
dirt nap
dirt-poor
dirty cop
dirty laundry
dirty look
dirty money
dirty old man
dirty word
dirty work
disagree with
dish the dirt
dishpan hands
dismal science
dive in
divvy up
do a
do a bunk
do a number on
do a slow burn
do away with
do by halves
do donuts
do down
do drugs
do for
do in
do it tough
do justice
do me a lemon
do one
do one's bit
do one's block
do one's business
do one's damnedest
do one's darnedest
do one's thing
do right by
do someone dirty
do someone proud
do someone's head in
do the deed
do the hard yards
do the honors
do the honours
do the math
do the right thing
do the trick
do up
do want
do well by doing good
do well for oneself
do what
do with mirrors
do without
do-or-die
doctors make the worst patients
dodge a bullet
does the Pope shit in the woods
dog and cat
dog and pony show
dog around
dog ear
dog eat dog
dog in the hunt
dog it
dog my cats
dog's breakfast
dog's chance
dog's life
dole out
don't call us, we'll call you
don't drop the soap
don't get me started
don't give up your day job
don't go there
don't hold your breath
don't keep a dog and bark yourself
don't knock yourself out
don't let the bedbugs bite
don't let the door hit you on the way out
don't look at me
don't shit where you eat
done and done
done and dusted
done deal
donkey work
donkey's ears
donkey's years
doom and gloom
dope sheet
dormitive principle
dormitive virtue
doss about
doss around
dot the i's and cross the t's
double Dutch
double back
double booked
double down
double entendre
double over
double talk
double tap
double vertical line
double-edged sword
double-tongued
douche bag
down and out
down at heel
down cellar
down for the count
down in the dumps
down in the mouth
down on one's luck
down on one's uppers
down pat
down the drain
down the hatch
down the line
down the road
down the road, not across the street
down the track
down the tubes
down to a fine art
down to the short strokes
down to the wire
down under
down with his apple-cart
down-and-outer
down-to-earth
drag king
drag on
drag one's feet
drag out
drag through the mud
drain the main vein
drama queen
draw a blank
draw a line
draw a line in the sand
draw away
draw back
draw down
draw even
draw in
draw off
draw one's last breath
draw stumps
draw the line
draw the short straw
drawing card
dream house
dredge up
dress down
dress to kill
dressed to kill
dressed to the nines
dressing-down
dribs and drabs
drift apart
drift off
drill down
drill rig
drilling rig
drink from a firehose
drink with the flies
drinking age
drinking hole
drive away
drive home
drive off
drive out
drive someone crazy
drive someone up the wall
drive the porcelain bus
drive-by media
drool bucket
drop a bollock
drop a bomb
drop a bombshell
drop a brick
drop a dime
drop a hint
drop anchor
drop in
drop in the bucket
drop in the ocean
drop off
drop off the radar
drop out
drop science
drop someone a line
drop the ball
drop the bomb
drop the f-bomb
drop the gloves
drop the mic
drop the writ
drop trow
dropout factory
drown out
drug deal
drug of choice
drug on the market
drugstore cowboy
drum up
dry behind the ears
dry eye
dry one's eyes
dry out
dry powder
dry run
duck out
duck soup
duck test
due course
duke it out
dumb bunny
dumb down
dumb shit
dummy run
dummy spit
dump on
dump one's load
dust bunny
dust mouse
dust off
dust off a batter
dusty miller
dwarf standing on the shoulders of giants
dyed in the wool
dyed-in-the-wool
dying quail
dynamite charge
each way
eager beaver
eagle eye
ear to the ground
ear tunnel
early bath
early bird
earn one's crust
earn one's keep
ears are burning
easier said than done
easy does it
easy on the eye
easy on the eyes
easy pickings
easy street
eat crow
eat for two
eat humble pie
eat it
eat my shorts
eat one's Wheaties
eat one's gun
eat one's hat
eat one's heart out
eat one's own dog food
eat one's words
eat one's young
eat out
eat out of someone's hand
eat pussy
eat shit
eat someone alive
eat someone out of house and home
eat someone's dust
eat someone's lunch
eat something for breakfast
eat up
economical with the truth
edge out
edible frog
egg on
elbow grease
elbow room
elder brother
elder sister
element of surprise
elephant ear
elephant ears
elephant in the room
eleventh hour
embarrassment of riches
emotional cripple
emperor's new clothes
employ a steam engine to crack a nut
empty the tank
end of
end of the line
end of the world
end state
end up
enemy combatant
engine room
enough to choke a horse
enough to make the angels weep
equal marriage
err on the side of
err on the side of caution
escape fire
esprit de corps
esthetically challenged
eternal sleep
eternal triangle
ethically challenged
ethnic music
eureka moment
even keel
even money
even-steven
ever after
ever so
evergreen oak
every bit
every inch
every last
every man Jack
every old nook and cranny
every second
every time
every time one turns around
every which way
every which where
everybody and his cousin
everybody and his mother
everybody and their brother
everybody and their dog
everyone and his brother
everyone and his mother
everyone and their brother
everyone and their dog
everyone and their mother
everything and the kitchen sink
everything but the kitchen sink
evil twin
exception that proves the rule
excess baggage
exchange flesh
execution style
exercise for the reader
exit stage left
exotic cheroot
expose oneself
extra pair of hands
extract the urine
eye candy
eye for an eye
eye for an eye, a tooth for a tooth
eye of the beholder
eye sex
eye up
eyes on the ground
face that would stop a clock
face the music
face to face
face value
faceless bureaucrat
fact is
factor in
factor space
facts on the ground
fade out
fail at life
failure to thrive
fair and square
fair enough
fair game
fair sex
fair to middling
fair-haired boy
fair-weather friend
fall about the place
fall apart
fall at the last hurdle
fall behind
fall between the cracks
fall between two stools
fall by the wayside
fall for
fall foul
fall from grace
fall in line
fall into
fall into one's lap
fall into place
fall into the wrong hands
fall off a truck
fall off the back of a lorry
fall off the back of a truck
fall off the turnip truck
fall off the wagon
fall on deaf ears
fall on hard times
fall on one's face
fall on one's sword
fall on someone's neck
fall out
fall over
fall short
fall through
fall through the cracks
fall to bits
fall to pieces
fall victim
fallen over
falling out
false alarm
false friend
false light
false note
false step
family jewels
fan dance
fan the flames
fanny about
far and away
far and wide
far be it
far cry
far gone
far out
far post
fare thee well
farm nigger
farm out
farmer's tan
fart in a windstorm
fashion plate
fashionably late
fast and furious
fast asleep
fat and happy
fat cat
fat chance
fat lip
fat of the land
faux queen
feast for the eyes
feast or famine
feather in one's cap
feather one's nest
featherless biped
fed up
federal case
feed off
feed one's face
feed the dragon
feeding frenzy
feel for
feel free
feel in one's bones
feel one's oats
feel oneself
feel the pinch
feel up
feel up to
feet first
feet of clay
feet on the ground
female-to-male
fence in
fencepost problem
fend and prove
fend away
fever pitch
few and far between
fiddle while Rome burns
field day
fifth wheel
fight a losing battle
fight fire with fire
fight fires
fight in armour
fight shy of
fight tooth and nail
fighting chance
figure of speech
figure out
file off the serial numbers
fill in the blank
fill one's boots
fill one's face
fill one's hand
fill one's pants
fill someone's shoes
fill the bill
fill up
film at 11
filter down
filter up
filthy lucre
filthy rich
final curtain
final cut
final nail in the coffin
final solution
find another gear
find it in one's heart
find one's feet
find one's voice
find oneself
find out
find the net
fine line
fine print
finest hour
fink out
fire drill
fire hose
fire in the belly
fire on all cylinders
fire-breathing
firing line
firm up
first among equals
first and last
first annual
first come, first served
first loser
first love
first of all
first off
first port of call
first rate
first up
fish for compliments
fish kill
fish or cut bait
fish out
fish to fry
fish-eating grin
fishing expedition
fit for a king
fit out
fit the bill
fit to be tied
fits and starts
five will get you ten
five-finger discount
fix someone's wagon
flag down
flaithiúlach
flame up
flannelled fool
flap one's gums
flash back
flash in the pan
flat chat
flat out
flat-chested
flat-earther
flat-footed
flatten out
flavor of the week
flea in one's ear
flesh out
flick the bean
flight of fancy
flip one's lid
flip one's wig
flip out
flip the bird
float around
float someone's boat
flog a dead horse
flog the dolphin
flog the log
floor it
floppy infant syndrome
flower
fluff up
flunk out
flush out
flutter in the dovecote
fly by the seat of one's pants
fly in the face of
fly in the ointment
fly low
fly off
fly off the handle
fly on the wall
fly out of the traps
fly the coop
fly the freak flag
fly-by-night
flying fish
flying start
flying visit
fold one's tent
fold up
folk devil
follow in someone's footsteps
follow out
follow suit
follow through
food baby
food chain
food for thought
fool away
fool with
fool's errand
fool's paradise
foot-in-mouth disease
footloose and fancy free
for Africa
for England
for Pete's sake
for XYZ reasons
for a change
for a song
for a start
for all intensive purposes
for all intents and purposes
for all one is worth
for all the world
for chrissake
for crying out loud
for fuck's sake
for good
for good and all
for good measure
for goodness' sake
for heaven's sake
for keeps
for mercy's sake
for my money
for old times' sake
for old times' sakes
for once
for one's life
for one's particular
for pity's sake
for real and for true
for that matter
for the ages
for the asking
for the birds
for the heck of it
for the hell of it
for the love of
for the most part
for the nonce
for the time being
for two pins
forbidden fruit
force of habit
force someone's hand
forget oneself
forget, when up to one's neck in alligators, that the mission is to drain the swamp
forgive and forget
fork off
fork over
forked tongue
forty minutes of hell
forty winks
foul up
fountain of youth
four score and seven years ago
four sheets to the wind
four-eyes
four-leaf clover
four-on-the-floor
fourth estate
fourth wall
fox in the henhouse
freak flag
free and easy
free hand
free lunch
free rein
free ride
free space
free, white, and twenty-one
free-for-all
freedom of speech
freeze out
freezing cold
fresh country eggs
fresh legs
fresh meat
fresh off the boat
fresh out of
fresh start
fresh-faced
friend of Bill W.
friend with benefits
friends in high places
friendship with benefits
frig it
frog in one's throat
from A to Z
from A to izzard
from a mile away
from can see to can't see
from central casting
from cover to cover
from here to Sunday
from hunger
from my cold, dead hands
from pillar to post
from scratch
from soup to nuts
from stem to stern
from the Department of the Bleeding Obvious
from the East German judge
from the bottom of one's heart
from the cradle to the grave
from the get-go
from the ground up
from the word go
from time to time
front and center
front foot
front load
front runner
front wall
frown at
frown on
frown upon
fruit of one's loins
fruit of the poisonous tree
fruit of the union
fruit up
fry up
fuck all
fuck it
fuck knows
fuck me
fuck off
fuck over
fuck someone over
fuck someone's brains out
fuck the dog
fuck with
fuck you
fuck your mother
fuck your mother's cunt
fucked by the fickle finger of fate
fucked over
fucked up
fucking hell
fuckpole
fudge factor
fudge packer
fudge the issue
full English
full as a tick
full blast
full circle
full marks
full of beans
full of crap
full of hot air
full of it
full of oneself
full of piss and vinegar
full of shit
full ride
full speed ahead
full tilt
full tilt boogie
full to the brim
full to the gills
full whack
full-fledged
full-stretch
fun and games
funnies
funny bone
funny farm
funny in the head
funny man
funny money
funny stuff
gallows humor
game face
game out
game plan
game, set, match
gandy dancer
gang up
gang up on
gapers' block
garden path
garden variety
gather dust
gather rosebuds
gear up
gender bender
genetic modification
genie is out of the bottle
gentleman of the back door
get a charge out of
get a fix
get a grip
get a handle on
get a jump on
get a kick out of
get a leg up
get a load of
get a move on
get a rise out of
get a room
get a wiggle on
get a word in edgeways
get a word in edgewise
get a wriggle on
get ahead of oneself
get along
get around
get away with
get away with murder
get back at
get back on the horse that bucked you
get bent
get bent out of shape
get better
get blood from a stone
get blood out of a stone
get busy
get by
get by the balls
get carried away
get changed
get cold feet
get cracking
get down to brass tacks
get down to business
get even
get fresh
get high
get in
get in on the act
get in someone's hair
get into one's stride
get into someone's pants
get into the wrong hands
get into trouble
get it
get it on
get it over with
get it up
get laid
get lost
get moving
get off lightly
get off one's chest
get off one's high horse
get off the ground
get off with
get on someone's case
get on someone's nerves
get on someone's wick
get on the end of
get on the stick
get on to
get one's act together
get one's ass in gear
get one's back up
get one's butt somewhere
get one's claws into
get one's claws out
get one's end away
get one's feet wet
get one's fill
get one's finger out
get one's foot in the door
get one's freak on
get one's hands dirty
get one's head around
get one's hopes up
get one's juices flowing
get one's knickers in a twist
get one's marching orders
get one's money's worth
get one's panties in a bunch
get one's shirt out
get one's shorts in a knot
get one's skates on
get one's tits in a wringer
get one's wires crossed
get onto
get out of Dodge
get out of bed on the wrong side
get out of here
get out of jail free card
get out while the getting's good
get outside
get outta here
get over
get over with
get past
get ready
get some
get some air
get someone's back up
get someone's goat
get something off one's chest
get something straight
get stuck in
get stuck into
get taken in
get the bacon bad
get the ball rolling
get the better of
get the boot
get the chop
get the drift
get the drop on
get the elbow
get the goods on
get the hang of
get the lead out
get the memo
get the picture
get the point
get the sack
get the time
get the vapors
get the wind up
get thee behind me
get there
get this show on the road
get through to
get tied up
get to fuck
get to grips with
get to the bottom of
get to the point
get together
get under someone's skin
get up on the wrong side of the bed
get up someone's nose
get up the yard
get up with the chickens
get used
get well
get wet
get what's coming to one
get wind of
get with the program
get with the times
get-rich-quick
ghetto bird
ghetto lottery
ghost at the feast
gift horse
gift of the gab
gild the lily
gimme a five
ginger knob
gird up one's loins
give 110%
give a fuck
give a good account of oneself
give a person line
give a rat's arse
give a shit
give a shite
give a sneck posset
give and take
give as good as one gets
give away the store
give back
give battle
give chase
give curry
give ear
give face
give head
give heed
give hostage to fortune
give in
give it a shot
give it a whirl
give it one's best shot
give it the gun
give me
give me liberty or give me death
give notice
give of oneself
give one enough rope
give one's all
give one's head a shake
give or take
give out
give some skin
give someone Hail Columbia
give someone a big head
give someone a bloody nose
give someone a hand
give someone a hard time
give someone a piece of one's mind
give someone an earful
give someone grief
give someone his head
give someone pause
give someone the boot
give someone the brush-off
give someone the business
give someone the chair
give someone the cold shoulder
give someone the creeps
give someone the eye
give someone the heave-ho
give someone the old heave-ho
give someone the runaround
give someone the slip
give someone what for
give someone what-for
give something a go
give something a miss
give something a try
give the devil his due
give the elbow
give the lie to
give the royal treatment
give the time of day
give thought
give up the ghost
give weight
give what for
glad tidings
glass ceiling
glass-half-empty
glass-half-full
gloss over
gloves are off
glutton for punishment
gnaw someone's vitals
go Dutch
go Galt
go a long way
go a-begging
go against the grain
go ahead
go all out
go all the way
go along for the ride
go along to get along
go along with
go along with the gag
go apeshit
go astray
go back to the drawing board
go ballistic
go bananas
go batshit
go begging
go belly-up
go blue
go by
go by the board
go by the wayside
go commando
go deep
go down
go down on
go down that road
go down the road
go down the toilet
go down the tubes
go down the wrong way
go downhill
go downtown
go far
go figure
go fly a kite
go for
go for a roll in the hay
go for a song
go for broke
go for it
go for the gold
go for the jugular
go for the throat
go from strength to strength
go from zero to hero
go great guns
go halfsies
go halves
go hand in hand
go hang
go hard or go home
go in one ear and out the other
go in the out door
go in with
go into
go into one's shells
go it alone
go jump in the lake
go large
go mad
go moggy
go narrow
go native
go nowhere
go off
go off at score
go off half-cocked
go off the boil
go on
go out
go out of one's way
go out on a limb
go out with a bang
go over
go over someone's head
go overboard
go pear-shaped
go places
go play in the traffic
go potty
go public
go red
go round in circles
go snake
go so far as
go soak your head
go south
go straight
go the distance
go the extra mile
go the way of
go the way of the dinosaurs
go the way of the dodo
go the whole hog
go through hell
go through the mill
go through the motions
go through with
go to
go to Canossa
go to great lengths
go to ground
go to pot
go to sea
go to seed
go to sleep
go to someone's head
go to the dogs
go to the ends of the earth
go to the mat
go to the mattresses
go to the polls
go to the wall
go to town
go to town on
go to work
go together
go too far
go under
go underground
go up
go up for
go up in smoke
go upstairs
go west
go wide
go wild
go with
go with the flow
go without
go without saying
go wrong
go-getter
god forbid
god forfend
going at it
going rate
gold coin
gold digger
gold mine
gold plate
gold standard
golden duck
golden goose
golden handcuffs
golden handshake
golden hello
golden opportunity
golden parachute
golden rule
golden shower
golden ticket
golden touch
golden years
golf widow
gone north about
gone with the wind
gong show
good God
good and
good as one's word
good books
good drunk
good egg
good enough for jazz
good enough to eat
good for nothing
good graces
good gracious
good job
good old boy
good riddance
good to go
good turn
good value
good word
good-hearted
goodness gracious
goodness gracious me
goodness me
goodnight Irene
goof off
goof on
goon squad
goose is cooked
got it going on
gouty-handed
grab and go
grab bag
grab by the lapels
grabass
grace period
grammar Nazi
grand poobah
grand scheme
grand total
grandstand play
granny dumping
granny-bashing
grasp at straws
grasp the nettle
grass roots
grass tops
grass widower
grasstops
gravitationally challenged
gravy train
grease monkey
grease payment
grease someone's palm
grease the wheels
greasy spoon
great beyond
great deal
great unwashed
greatest thing since sliced bread
green about the gills
green as a gooseberry
green fingers
green indigo
green light
green state
green thumb
green with envy
greener pastures
grey amber
grey area
grey matter
grey power
grin like a Cheshire cat
grind down
grind one's gears
grind out
grind to a halt
grist for the mill
grist to the mill
ground ball with eyes
ground bass
ground beetle
ground laurel
ground pangolin
ground rule
ground shark
ground sloth
ground spider
ground squirrel
ground-breaking
grow a pair
grow cold
grow on
grow out of
grow up
grunt work
guarded rights
guess what
guilt trip
guilty pleasure
gum up
gun it
gunboat diplomacy
gunner's daughter
gunshy
gussie up
gut check
gut factor
gut feeling
gut reaction
gut-wrenched
gutless wonder
gym bunny
had better
hail down
hair of the dog
hair-splitting
hair-splittingly
hairy molly
halcyon days
half a mind
half term
half-baked
half-naked
half-pint
halfway decent
ham it up
hammer and sickle
hammer and tongs
hammer home
hammer-headed
hand down
hand in glove
hand in hand
hand it to someone
hand off
hand on a plate
hand over
hand over fist
hand someone his hat
hand someone his head
hand waving
hand-in-glove
handbags at dawn
handle with kid gloves
hands down
hands up
handwriting on the wall
hang a Louie
hang a Ralph
hang a leg
hang about
hang an arse
hang around
hang by a thread
hang five
hang in the balance
hang low
hang on
hang on every word
hang one's hat
hang one's hat on
hang out
hang out one's shingle
hang out to dry
hang paper
hang the moon
hang together
hang tough
hang up
hang up one's boots
hang up one's hat
hangar queen
hanging loop
hanging offence
happen along
happily ever after
happy as a pig in shit
happy medium
hard cheese
hard done by
hard feelings
hard lines
hard nut to crack
hard of hearing
hard on the eyes
hard pill to swallow
hard yards
hard-and-fast
hard-nosed
hard-pressed
harden someone's heart
harp on one string
hash out
hash slinger
hat in hand
hatchet job
hatchet man
hate someone's guts
haul ass
haul his ashes
haul off
haul someone over the coals
haunted house
have a ball
have a bone to pick
have a brick in one's hat
have a bun in the oven
have a couple
have a cow
have a fable for
have a few
have a fit
have a frog in one's throat
have a go
have a good one
have a good time
have a handle on
have a head for
have a heart
have a laugh
have a look-see
have a mind of one's own
have a mountain to climb
have a nice day
have a pair
have a say
have a screw loose
have a seat
have a snootful
have a stab
have a thing
have a tiger by the tail
have a way with
have a whale of a time
have a word
have a word with oneself
have an eye for
have at
have bats in one's belfry
have been around
have blood on one's hands
have butterflies in one's stomach
have egg on one's face
have eyes bigger than one's belly
have eyes bigger than one's stomach
have eyes for
have eyes in the back of one's head
have eyes on
have got
have had it
have had it up to here
have had one's chips
have in mind
have it both ways
have it easy
have it going on
have it in for
have it large
have it made
have it off
have it out with
have it your way
have kittens
have legs
have more chins than a Chinese phone book
have one foot in the grave
have one's cake and eat it too
have one's ducks in a row
have one's ears lowered
have one's eye on
have one's fingers in many pies
have one's hand in the till
have one's hand out
have one's hands full
have one's head read
have one's heart in the right place
have one's name on
have one's name taken
have one's number on it
have one's way
have one's way with
have one's wits about one
have one's work cut out for one
have other fish to fry
have second thoughts
have seen one's day
have someone by the balls
have someone by the short and curlies
have someone by the short hairs
have someone going
have someone's back
have someone's blood on one's head
have someone's guts for garters
have someone's hide
have someone's number
have something to eat
have the biscuit
have the blues
have the floor
have the hots for
have the last laugh
have the tiger by the tail
have the time of one's life
have the wind up
have the wolf by the ear
have the world by the tail
have to do with the price of fish
have truck with
have up
have words
have work done
he-man
head and shoulders
head butter
head case
head for the hills
head honcho
head hunter
head in the clouds
head of steam
head over heels
head scratcher
head south
head start
head to toe
head trip
head up
head-emptier
head-on
head-spinningly
head-the-ball
headlines
heads or tails
heads up
heads will roll
heads-up
hear on the grapevine
hear out
hear the end of something
hear the grass grow
hear things
hear through the grapevine
hear, hear
heart and soul
heart of glass
heart of gold
heart to heart
heart-breaking
heat wave
heaven forbid
heavy going
heavy hitter
heavy lifting
heavy-footed
heavy-hearted
hedge one's bets
heebie-jeebies
hell and half of Georgia
hell mend someone
hell on earth
hell on wheels
hell or high water
hell to pay
hell week
help oneself
helping hand
hem and haw
hen's teeth
hen's tooth
hens' teeth
herd cats
here goes nothing
here to stay
here we go
here we go again
here you are
here you go
here's to
hide nor hair
hide one's light under a bushel
hide the sausage
hiding to nothing
high and mighty
high cotton
high ground
high horse
high noon
high note
high on the hog
high road
high time
high-tail it
higher than a kite
highflier
hightail it
highway robbery
hike up
hill of beans
hill to die on
hind tit
hindsight is 20/20
hired gun
hired muscle
his back is up
hit a snag
hit above one's weight
hit below one's weight
hit home
hit it big
hit it off
hit it up
hit on
hit one out of the ballpark
hit one's stride
hit out
hit paydirt
hit piece
hit someone for six
hit the big time
hit the books
hit the bottle
hit the bricks
hit the buffers
hit the fan
hit the gas
hit the ground running
hit the hay
hit the headlines
hit the jackpot
hit the nail on the head
hit the pavement
hit the road
hit the rock
hit the rocks
hit the roof
hit the sack
hit the skids
hit the spot
hit the trail
hit up
hit upon
hither and yon
hog heaven
hoist by one's own petard
hold a candle
hold a grudge
hold back
hold court
hold down
hold it
hold off
hold on
hold one's breath
hold one's head high
hold one's horses
hold one's liquor
hold one's nerve
hold one's own
hold one's peace
hold one's tongue
hold one's water
hold out
hold over
hold over someone's head
hold someone's feet to the fire
hold someone's hand
hold sway
hold that thought
hold the cards
hold the fort
hold the line
hold the phone
hold the purse strings
hold the reins
hold the ring
hold true
hold up
hold up one's end
hold water
hold with the hare and run with the hounds
hold your fire
hold-up play
holding pattern
hole
hole in one
holy cow
holy crap
holy crap on a cracker
holy crap on a stick
holy crickets
holy fuck
holy mackerel
holy moley
holy shit
holy smoke
home and dry
home and hosed
home away from home
home game
home in on
home run
home stretch
home sweet home
home team
homeless dumping
honey do list
honey trap
honey-mouthed
honor in the breach
honorable mention
hoof it
hook in
hook up
hook, line and sinker
hoover up
hop joint
hop to it
hop up
hop, skip, and a jump
hope against hope
hopped up
hopping mad
horizontal dancing
horizontal jogging
horizontal mambo
horizontal refreshments
horizontally challenged
hormone therapy
horned up
horror show
horse and rabbit stew
horse around
horse of a different color
horse opera
horse pill
horse pucky
horse sense
horse's ass
horse's mouth
horses for courses
horsetrade
horsetrading
hose down
hot air
hot and bothered
hot and cold
hot and heavy
hot button
hot desking
hot hand
hot lunch
hot mess
hot off the presses
hot on
hot on someone's heels
hot potato
hot shit
hot stuff
hot to trot
hot under the collar
hot up
hot water
hotfoot it
house cooling party
house nigger
house of cards
house of ill fame
house poor
household name
housewarming
how are you
how come
how goes it
how so
how's the weather
how's tricks
how-d'ye-do
howdy-do
huckleberry
huckleberry above a persimmon
hugs and kisses
hum and haw
humble pie
hunker down
hunt where the ducks are
hurler on the ditch
hurt someone's feelings
husband and wife
hustle and bustle
hutch up
hydraulic ram
hydrogen ion
ice cool
ice cube
ice queen
ice-calm
idiot box
idiot light
idiot mittens
if I'm honest
if it's all the same
if looks could kill
if need be
if needs be
if nothing else
if only
if pigs had wings
if the shoe fits
ifs, ands, or buts
ill health
in Abraham's bosom
in Dickie's meadow
in Dutch
in a bake
in a bind
in a canter
in a cleft stick
in a flash
in a heartbeat
in a league of one's own
in a nutshell
in a pig's arse
in a pig's eye
in a pinch
in a state
in a walk
in addition
in aid to this fact
in all honesty
in all one's glory
in and out
in any way, shape, or form
in at the deep end
in bad odor
in bed
in bed with
in black and white
in broad daylight
in business
in character
in chorus
in clover
in cold blood
in contention
in control
in detail
in effigy
in evidence
in fact
in fee
in focus
in for it
in for the kill
in from the cold
in front of one's nose
in full force
in full gear
in full swing
in heaven's name
in high dudgeon
in jest
in kind
in layman's terms
in laymen's terms
in light of
in line
in living memory
in no time
in no time at all
in no uncertain terms
in no way, shape, or form
in one hell of a hurry
in one's armour
in one's book
in one's cups
in one's dreams
in one's element
in one's face
in one's pocket
in one's right mind
in order
in other words
in plain view
in process of time
in recent memory
in safe hands
in shape
in someone's pocket
in someone's shoes
in someone's wheelhouse
in spades
in spite of
in state
in stitches
in stride
in the act
in the altogether
in the bag
in the biblical sense
in the black
in the blink of an eye
in the books
in the buff
in the cards
in the clear
in the crosshairs
in the dark
in the dock
in the doghouse
in the drink
in the driver's seat
in the driving seat
in the face of
in the fast lane
in the final analysis
in the first place
in the game
in the here and now
in the hole
in the hopper
in the hospital
in the hot seat
in the interest of justice
in the lead
in the least
in the limelight
in the line of duty
in the long run
in the long term
in the loop
in the making
in the money
in the nick of time
in the nip
in the offing
in the pink
in the post
in the raw
in the red
in the reign of Queen Dick
in the right place at the right time
in the room
in the running
in the same boat
in the same breath
in the short run
in the soup
in the sticks
in the swim
in the thick of
in the thick of it
in the toilet
in the twinkling of an eye
in the wake of
in the way
in the way of
in the weeds
in the wind
in the wink of an eye
in the works
in the world
in the wrong place at the wrong time
in the zone
in this day and age
in thunderation
in too deep
in touch
in two shakes
in vain
in view of
in virtue of
in with a chance
in your dreams
in your face
inch-perfect
ink slinger
inner circle
inner core
inner strength
ins and outs
inside baseball
inside job
inside joke
inside the box
inside track
installed base
into detail
into thin air
iron curtain
iron eagle
iron out
ironic error
irons in the fire
is it
it can't be helped
it does exactly what it says on the tin
it figures
it goes to show
it is what it is
it takes two to tango
it's about time
it's all Greek to me
it's all good
it's one's funeral
itch the ditch
itchy feet
itchy trigger finger
itsy bitsy
itty bitty
ivory tower
jack in
jack o'lantern
jack of all trades
jack of all trades, master of none
jack off
jail lock
jam sandwich
jam tomorrow
jaw away
jerk around
jerk someone's chain
jerkoff
jet set
jet-setter
jet-setting
jill of all trades
jive turkey
joe job
jog on
join forces
join the club
joined at the hip
jolly along
jot and tittle
jot down
joust
judge, jury and executioner
jug ears
juice up
jump at
jump at the chance
jump down someone's throat
jump for joy
jump in one's skin
jump on
jump on the bandwagon
jump rope
jump ship
jump someone's bones
jump the gun
jump the queue
jump the shark
jump through hoops
jump to conclusions
jumped-up
jungle mouth
jungle telegraph
junk in the trunk
junkyard dog
jury is out
just a minute
just a second
just about
just another pretty face
just deserts
just folks
just in case
just like that
just the same
just what the doctor ordered
kangaroo piss
keel over
keep a civil tongue in one's head
keep a close watch on
keep a cool head
keep a lid on
keep a low profile
keep a weather eye open
keep an eye on
keep an eye open
keep an eye out
keep an eye peeled
keep at arm's length
keep company
keep house
keep in
keep it between the ditches
keep it real
keep it up
keep mum
keep on
keep on truckin'
keep on trucking
keep one on one's toes
keep one's cards close to one's chest
keep one's chin up
keep one's cool
keep one's eye on the ball
keep one's eyes peeled
keep one's fingers crossed
keep one's hair on
keep one's head
keep one's head above water
keep one's head below the parapet
keep one's head down
keep one's lips sealed
keep one's mouth shut
keep one's nose clean
keep one's options open
keep one's pecker up
keep one's shirt on
keep pace
keep quiet
keep shtum
keep someone company
keep someone in the dark
keep someone in the loop
keep someone on ice
keep someone posted
keep straight
keep tabs on
keep the home fires burning
keep the peace
keep the wolf from the door
keep to oneself
keep up
keep up appearances
keep up with the Joneses
keep watch
keep your rosaries off my ovaries
kernel of truth
kettle of fish
keys to the kingdom
kick against the pricks
kick ass
kick ass and take names
kick at the can
kick back
kick bollocks scramble
kick butt
kick in
kick in the balls
kick in the pants
kick in the teeth
kick into touch
kick it
kick off
kick one's heels
kick oneself
kick out
kick some tires
kick someone when they are down
kick the bucket
kick the can down the road
kick the habit
kick the tires
kick the tyres
kick to the curb
kick up
kick up a fuss
kick up one's heels
kick up the arse
kick upstairs
kick with the other foot
kicking and screaming
kicking boots
kid around
kid glove
kiddie table
kidding aside
kids will be kids
kill
kill me
kill one's darlings
kill oneself
kill the fatted calf
kill the goose that lays the golden eggs
kill the messenger
kill the rabbit
kill two birds with one stone
killer instinct
kind of
kind regards
kindest regards
kindred soul
kindred spirit
king of beasts
king of the hill
king's ransom
kiss and cry
kiss and make up
kiss arse
kiss ass
kiss my ass
kiss of death
kiss of life
kiss off
kiss someone's ass
kiss the gunner's daughter
kiss up
kiss up to
kit and caboodle
kitchen sink
kitchen table software
knacker's yard
knee slapper
knee-deep in the Big Muddy
knife-edge
knight in shining armor
knit one's brows
knit one's eyebrows
knit together
knob-gobbler
knock Anthony
knock down
knock for a loop
knock it off
knock off
knock on wood
knock oneself out
knock out
knock out of the box
knock over
knock some sense into
knock someone off his perch
knock someone's block off
knock someone's socks off
knock the living daylights out of
knock together
knocked up
knocking on heaven's door
know beans about
know every trick in the book
know for a fact
know from a bar of soap
know inside and out
know like a book
know like the back of one's hand
know one's ass from a hole in the ground
know one's own mind
know one's way around
know someone
know someone from Adam
know someone from a can of paint
know someone in the biblical sense
know the score
know what is what
know where one stands
know which end is up
know which side one's bread is buttered on
knuckle down
knuckle dragger
knuckle sandwich
knuckle under
l'esprit de l'escalier
lab rat
labor of love
labour of love
laced-up
ladies and gentlemen
ladies' lounge
ladies' man
lady garden
lady of the night
lady or tiger
lady's man
lame joke
land of opportunity
land of plenty
land on one's feet
land poor
landing strip
lap dog
lap of luxury
lap up
larger than life
last burst of fire
last minute
last of the big spenders
last resort
last straw
last thing
last thing one needs
last trump
last word
last-ditch
latch onto
latch-key child
late bloomer
late model
laugh a minute
laugh all the way to the bank
laugh in one's sleeve
laugh one's head off
laugh out of court
laugh up one's sleeve
laughing stock
laundry list
law of the jungle
lawn sleeves
lay a finger on
lay an egg
lay down the law
lay down the marker
lay eyes on
lay hands on
lay it on thick
lay odds
lay of the land
lay off
lay on
lay on the line
lay over
lay rubber
lay something at the feet of
lay the groundwork
lay the pipe
lay to rest
laze about
laze around
lead nowhere
lead on
lead someone down the garden path
lead the line
lead time
leader of the free world
leading light
leak out
lean and mean
lean on
lean towards
leap to mind
leaps and bounds
leather working
leather-lunged
leave a sour taste in one's mouth
leave behind
leave for dead
leave home
leave it be
leave no stone unturned
leave nothing to the imagination
leave off
leave someone high and dry
leave someone holding the baby
leave someone holding the bag
leave someone in the lurch
leave to one's own devices
left and right
left field
left-handed compliment
leg man
legal beagle
legal duty
legal eagle
legally binding
legend in one's own lunchtime
lemon law
lend a hand
lend itself to
lesser of two evils
let alone
let bygones be bygones
let down
let fly
let go
let go and let God
let her rip
let in on
let it be
let loose
let nature take its course
let off
let on
let one go
let one's hair down
let oneself go
let sleeping dogs lie
let slide
let slip
let someone down gently
let someone go
let someone have it
let the cat out of the bag
let the chips fall where they may
let the good times roll
let the grass grow under one's feet
let the perfect be the enemy of the good
let there be light
let us
let's not and say we did
let's roll
let-down
letters after one's name
level best
level off
level-headed
libel chill
licence to print money
lick and a promise
lick one's chops
lick one's wounds
lick someone's ass
lick the pants off
licky-licky
lie before
lie ill in one's mouth
lie through one's teeth
life and limb
life and soul of the party
life is too short
life of Riley
life of the party
life-or-death
lift a finger
light a fire under
light at the end of the tunnel
light bucket
light in the loafers
light painting
light skirt
light up
lighten someone's purse
lighten up
lightning fast
lightning in a bottle
lightning-quick
like a chicken with its head cut off
like a chicken with the pip
like cheese at fourpence
like it or lump it
like one's life depended on it
like shelling peas
like talking to a wall
like the sound of one's own voice
lily-livered
limp dick
line in the sand
line one's pockets
link whore
link whoring
lion's den
lion's share
lip service
liquid courage
listen in
listen up
little emperor
little head
little old
little person
little pitcher
little woman
live a lie
live and learn
live and let live
live in sin
live it up
live large
live off
live on
live on the edge
live one
live over the brush
live paycheck to paycheck
live the dream
live wire
live with
living death
living end
living impaired
load up
loaded dice
loaded for bear
loaded language
loaded word
loaf about
loaf around
lock horns
lock lips
lock, stock and barrel
locker room humor
log off
lone gunman
lone it
long arm
long arm of the law
long drink
long finger
long game
long green
long haul
long in the tooth
long pork
long row to hoe
long run
long screwdriver
long shot
long since
long story short
long tail
long time
long time no hear
long time no see
look after
look as if one has lost a shilling and found sixpence
look at
look back
look daggers
look down one's nose
look for a dog to kick
look forward
look forward to
look here
look into
look like
look off
look on
look on the bright side
look out
look out for number one
look the other way
look the part
look through
look through rose-tinted glasses
look to
look up
look up to
look what the cat's dragged in
look-in
loom large
loose cannon
loose change
loose end
loose ends
loose lip
loosen the apron strings
loosen the purse strings
lord it over
lord of the flies
lose face
lose ground
lose it
lose one's cool
lose one's head
lose one's mind
lose one's rag
lose one's shirt
lose one's shit
lose one's temper
lose one's touch
lose one's way
lose oneself in
lose the number of one's mess
lose the plot
lose touch
loser cruiser
loss of face
lost cause
lost errand
lost in translation
lost soul
lot lizard
loud and clear
louse up
love at first sight
love goggles
love muscle
love nest
love to bits
loved up
low blow
low on the totem pole
low road
low-down
low-hanging fruit
lower the boom
lubrication payment
luck in
luck of the draw
luck out
lucky break
lucky devil
lucky dip
lucky dog
lump in one's throat
lump it
lump to one's throat
lunatics have taken over the asylum
made for each other
made in China
made in Japan
made in the shade
made of sterner stuff
magic bullet
magic eye
magnetic deviation
main drag
main man
main sequence
make a better door than a window
make a break for it
make a clean break
make a clean breast
make a decision
make a difference
make a go of
make a killing
make a leg
make a meal of
make a mockery of
make a monkey out of
make a mountain out of a molehill
make a move
make a name for oneself
make a night of it
make a pig of oneself
make a pig's ear of
make a point
make a silk purse of a sow's ear
make a spectacle of oneself
make a splash
make a stink
make a virtue of necessity
make amends
make an appearance
make an ass of
make an example of
make an exhibition of oneself
make an honest woman
make baby Jesus cry
make believe
make book
make bricks without straw
make do
make ends meet
make faces
make for
make fun of
make game of
make good on
make ground
make hay
make hay while the sun shines
make head or tail of
make headway
make heavy going of
make heavy weather of
make history
make it
make it rain
make it snappy
make it up as one goes along
make it up to
make light of
make light work of
make like a banana and split
make like a tree and leave
make matters worse
make mincemeat out of
make news
make no bones about
make one's bed
make one's bed and lie in it
make one's bones
make one's mark
make one's way
make oneself at home
make oneself scarce
make out like a bandit
make over
make peace
make quick work of
make sense
make shit of
make short work of
make someone a happy panda
make someone's blood boil
make someone's blood run cold
make someone's day
make someone's jaw drop
make someone's skin crawl
make someone's teeth itch
make something of oneself
make sure
make the cut
make the grade
make the most of
make the welkin ring
make the world go around
make time
make tracks
make up one's mind
make up the numbers
make waves
make way
male-to-female
mama's boy
man among men
man and boy
man and wife
man down
man in the street
man of few words
man of one's word
man of parts
man of the hour
man of the people
man on the street
man the fort
man up
man-of-war
manoeuvre the apostles
many happy returns
march to the beat of a different drum
marching orders
mark my words
mark time
market day
marriage inequality
married sector
marry off
marsh grass
mass destruction
match day
match made in heaven
match made in hell
matter of course
matter of fact
matter of life and death
matter of time
may the Force be with you
me three
meal ticket
meals on wheels
mean business
mean the world to
measure up
measuring the drapes
meat and potatoes
meat market
meat rack
meat stick
meatball surgery
media darling
meet a sticky end
meet and greet
meet halfway
meet one's maker
meet with
meeting of the minds
melon head
melt into
melting pot
member for Barkshire
memory lane
mend fences
mend one's ways
mercy fuck
mere mortal
merry dance
mess around
mess of pottage
mess up
mess with
middle ground
middle of nowhere
middle of the road
milieu control
mince words
mind one's P's and Q's
mind one's own business
mind one's ps and qs
mind the store
mind you
mind's ear
mind-numbing
mine arse on a bandbox
miner's canary
miners' canary
mint chocolate chip
mint condition
miss the boat
miss the mark
miss the point
mission creep
mix apples and oranges
mix it up
mix up
mixed bag
mixed blessing
mixed message
mixed picture
modest proposal
moll buzzer
moment in the sun
moment of truth
money for jam
money for old rope
money maker
money pit
money's worth
monkey around
monkey business
monkey on one's back
monkey wrench
monkeys might fly out of my butt
monster mash
month of Sundays
monthly meeting
moon on a stick
moonlight flit
mop head
mop the floor with someone
mop up
moral compass
moral high ground
moral low ground
moral support
more Catholic than the Pope
more cry than wool
more equal
more like it
more than meets the eye
more than one bargained for
more than you can shake a stick at
more's the pity
morning person
morning, noon and night
mosque affiliation
mother hen
mother lode
motor mouth
mouse potato
mouth breather
mouth of a sailor
mouth off
mouthful of marbles
move forward
move heaven and earth
move house
move it
move on
move one's body
move the goalposts
move the yardsticks
move through the gears
mover and shaker
much ado about nothing
much less
much of a muchness
muckamuck
muckety muck
mud monkey
muddle along
muddy the waters
muddy up
muffin top
mug's game
mum's the word
murder will out
mush up
music to someone's ears
mutton dressed as lamb
mutual admiration society
my arse
my bad
my eye
my foot
my goodness
my lips are sealed
my my
my way or the highway
my word
na-na na-na na-na
naff off
nail biter
nail down
naked ape
name and shame
name names
name of the game
name your poison
narrow down
nary a
native soil
navigable waters
near post
near the knuckle
necessary evil
neck and neck
neck of the woods
necker's knob
necktie party
need yesterday
need-to-know
needle in a haystack
needless to say
neither fish nor fowl
neither fish, flesh, nor good red herring
neither here nor there
nerve-shredding
nerves of steel
nervous hit
nest egg
never fear
never in a million years
never in a month of Sundays
never mind
never the twain shall meet
never you mind
new normal
new school
new standard
new town
next thing one knows
next to
next to nothing
nice guy
nickel and dime
nickel nurser
nickel-and-dime
nigger nose
nigger rich
night and day
night out
night owl
night person
nine day wonder
nine lives
nine times out of ten
nip and tuck
nip at
nip in the bud
nip slip
no biggie
no buts
no chance
no comment
no cover
no dice
no flies on
no frills
no go
no great shakes
no hard feelings
no harm, no foul
no holds barred
no horse in this race
no ifs and buts
no joy
no love lost
no matter how one slices it
no matter how thin you slice it, it's still baloney
no mean feat
no more
no plan survives contact with the enemy
no pressure
no prize for guessing
no score
no screaming hell
no skin off one's back
no skin off one's nose
no slouch
no spring chicken
no strings attached
no sweat
no tea, no shade
no time to lose
no two ways about it
no way
no-count
no-good ass
no-show
nod off
nodding acquaintance
non-denial denial
non-starter
none of someone's business
nook or cranny
north forty
nose candy
nose out of joint
nose test
nose to the grindstone
nose-pick
nose-picker
nose-picking
nosebleed seat
nosebleed section
not a chance
not a minute too soon
not a pretty sight
not all it's cracked up to be
not as black as one is painted
not at all
not bad
not be able to get a word in edgeways
not be caught dead
not by any means
not cricket
not enough room to swing a cat
not for the world
not give a monkey's
not give someone the time of day
not half bad
not have a leg to stand on
not have the faintest
not in Kansas anymore
not in a million years
not in the least
not in the slightest
not invented here
not just a pretty face
not know which end is up
not leave one's thoughts
not long
not long for this world
not much of anything
not on your life
not on your nelly
not on your tintype
not out
not quite
not see someone for dust
not see straight
not so fast
not so hot
not the end of the world
not to mention
not to put too fine a point on it
not to say
not touch something with a barge pole
not touch something with a ten foot pole
not win for losing
not worth a Continental
not worth a brass farthing
not worth a dime
not worth a plug nickel
not worth a whistle
not worth writing home about
not your father's
notch on one's bedpost
nothing doing
nothing flat
nothing for it
nothing special
nothing to it
nothing to sneeze at
nothing to write home about
now and again
now and then
now or never
now you mention it
now you're cooking
now you're talking
nowhere to be found
nudge nudge wink wink
nugget of truth
null and void
number games
number one
number one with a bullet
nut out
nut-cutting time
nuts and bolts
oat opera
occupy oneself
odd and curious
odd duck
odd fish
odd one out
odds and ends
odds and sods
of a
of a kind
of a piece
of all people
of all things
of an
of choice
of course
of late
of one mind
of sorts
of that ilk
of the same stripe
of two minds
off and on
off and running
off balance
off board
off chance
off like a prom dress
off one's box
off one's dot
off one's face
off one's feed
off one's game
off one's meds
off one's nut
off one's own bat
off one's rocker
off one's tits
off one's tree
off one's trolley
off pat
off the back foot
off the bat
off the beaten path
off the beaten track
off the chain
off the deep end
off the grid
off the hook
off the mark
off the radar
off the rails
off the reservation
off the table
off the top of one's head
off the wagon
off to the races
off-color
off-kilter
off-roader
off-the-cuff
off-the-shelf
off-the-wall
offer affordances
offer one's condolences
offer up
officer friendly
oh dark hundred
oh dark thirty
oh my
oh my Allah
oh my goodness
oh my goodness gracious
oh my gosh
oh really
oh well
oil and water
oil burner
oil trash
old boy network
old chestnut
old college try
old enough to vote
old fart
old flame
old fogey
old hand
old hat
old money
old rose
old salt
old saw
old school
old sod
old stick
old time used to be
old woman
older adult
older brother
older sister
olive branch
oll korrect
omega
on a full stomach
on a kick
on a losing wicket
on a regular basis
on a roll
on a tear
on a whim
on about
on account of
on acid
on air
on all fours
on an irregular basis
on and off
on and on
on average
on board
on cloud nine
on course
on demand
on edge
on end
on fire
on good terms with
on hand
on high
on hold
on ice
on in years
on its merits
on no account
on one's bill
on one's deathbed
on one's feet
on one's hands
on one's high horse
on one's knees
on one's last legs
on one's lonesome
on one's own
on one's own account
on one's plate
on one's tod
on one's toes
on one's watch
on opposite sides of the barricades
on paper
on pins and needles
on purpose
on second thought
on sight
on someone's account
on someone's mind
on steroids
on sufferance
on talking terms
on tenterhooks
on the
on the Pat and Mick
on the Q.T.
on the anvil
on the back burner
on the back foot
on the back of
on the ball
on the blink
on the bounce
on the brain
on the brink
on the bubble
on the button
on the cards
on the cheap
on the clock
on the cuff
on the cutting room floor
on the dot
on the double
on the down-low
on the edge of one's seat
on the face of
on the face of it
on the fence
on the floor
on the fly
on the front foot
on the game
on the go
on the gripping hand
on the ground
on the heels of
on the hook
on the hop
on the horn
on the horns of a dilemma
on the house
on the hush-hush
on the ladder
on the lam
on the level
on the line
on the loose
on the make
on the mend
on the money
on the nose
on the one hand
on the other hand
on the outs
on the outside, looking in
on the pill
on the plus side
on the point of
on the prowl
on the pull
on the radar
on the rag
on the rampage
on the receiving end
on the right track
on the rise
on the road
on the rocks
on the ropes
on the run
on the same page
on the same wavelength
on the shelf
on the side of the angels
on the skids
on the sly
on the spot
on the spur of the moment
on the square
on the street
on the table
on the take
on the toss of a coin
on the trot
on the up
on the up-and-up
on the uptake
on the verge
on the wagon
on the wane
on the warpath
on the way
on the whole
on the wrong side of history
on thin ice
on top
on top of
on top of the world
on track
on wheels
on yer bike
on-the-spot
once again
once and for all
once in a blue moon
once in a while
once more
once or twice
one after another
one age with
one and all
one and only
one and the same
one another
one at a time
one brick short of a full load
one by one
one card shy of a full deck
one fell swoop
one flesh
one in the eye for
one of His Majesty's bad bargains
one of these days
one of those days
one of those things
one side
one small step for man, one giant leap for mankind
one step ahead
one step at a time
one step forward, two steps back
one too many
one up
one's bark is worse than one's bite
one's blood is up
one's blood runs cold
one's days are numbered
one's jig is up
one's socks off
one's word is law
one-banana problem
one-hit wonder
one-horse race
one-horse town
one-man band
one-night stand
one-note
one-off
one-star
one-track mind
one-trick pony
one-up
one-upmanship
onesie-twosie
onion seed
only daughter
only game in town
only son
only time will tell
open a can of whoop ass
open book
open doors
open fire
open one's big mouth
open one's legs
open season
open someone's eyes
open the kimono
opening of an envelope
opposite number
or else
or something
or what
or words to that effect
original character
other fish in the sea
other half
other head
other side
other than
out and about
out for blood
out loud
out of bounds
out of central casting
out of character
out of date
out of fix
out of gas
out of house and home
out of it
out of kilter
out of line
out of luck
out of nowhere
out of one's box
out of one's depth
out of one's element
out of one's face
out of one's league
out of one's mind
out of one's tree
out of order
out of place
out of pocket
out of proportion
out of shape
out of sight
out of sorts
out of stock
out of the blue
out of the box
out of the chute
out of the frying pan, into the fire
out of the loop
out of the ordinary
out of the picture
out of the question
out of the running
out of the way
out of the woods
out of thin air
out of this world
out of touch
out of wedlock
out of whack
out of work
out on one's ear
out on one's feet
out on the tiles
out the wazoo
out the window
out there
out to lunch
out-and-out
outer core
outpope the Pope
outside chance
outside the box
outside world
over a barrel
over and out
over and over
over and over again
over my dead body
over one's head
over the hill
over the hills and far away
over the moon
over the river and through the woods
over the top
over the transom
overkill
own up
ox is in the ditch
p'd off
pack a punch
pack fudge
pack heat
pack in
pack of lies
pack on the pounds
packed to the gills
packed to the rafters
pad out
paid up
pain and suffering
pain in the ass
pain in the butt
pain in the neck
paint oneself into a corner
paint the town red
paint the wagon
paint with a broad brush
painting rocks
palace politics
pale in comparison
pale rider
palm off
pan out
paper flower
paper tiger
paper trail
par for the course
parade of horribles
paradise on earth
parcel out
pardon me
pardon my French
pare down
parentally challenged
park that thought
park the bus
part and parcel
part company
parting of the ways
parting shot
party and play
party animal
party hardy
party hearty
party pooper
party to
pass muster
pass on
pass the buck
pass the hat
pass up
pat on the back
patch up
patience of Job
patience of a saint
pave the road to hell
pave the way
pay a visit
pay attention
pay one's debt to society
pay one's dues
pay packet
pay the bills
pay the fiddler
pay the freight
pay the piper
pay through the nose
pea patch
peace and quiet
peaches and cream
peaches-and-cream
peachy keen
peanut gallery
pearl necklace
pearl of wisdom
pearl-clutching
pearly whites
pee off
pee one's pants
peed off
peel out
peep pixels
peg down
peg it
pelt of the dog
penalty box
pencil in
pencil pusher
pencil whip
pencil-neck
penguin suit
penny for your thoughts
penny in the fusebox
penny pincher
penny wedding
penny wise and pound foolish
people person
people's republic
perfect storm
permanent shave
perp walk
person of size
personal capital
peter out
phase out
phone it in
phone tag
physical break
pick apart
pick at
pick corners
pick holes
pick of the litter
pick on
pick one's nose
pick out
pick out of a hat
pick someone's brain
pick up on
pick up stitches
pick up the pieces
pick up the slack
pick up the tab
pick up what someone is putting down
pick your battles
pickin' and grinnin'
piece de resistance
piece of ass
piece of cake
piece of crap
piece of one
piece of shit
piece of tail
piece of the action
piece of work
piffy on a rock bun
pig fucker
pig in a poke
pig out
pigs can fly
pigs might fly
pile on
pile on the pounds
pile up
pile-up
pill in the pocket
pill mill
pill to swallow
pillow talk
pin down
pin money
pinch and a punch for the first of the month
pinch one off
pinch-hit
pink slime
pink slip
pip to the post
pipe
pipe down
pipe dream
piping hot
piss about
piss and moan
piss and vinegar
piss around
piss away
piss in someone's cornflakes
piss like a racehorse
piss money up the wall
piss more than one drinks
piss off
piss on someone's bonfire
piss one's pants
piss up
piss up a rope
pissass
pissed off
pissing contest
pissing match
pissing war
pit
pit against
pitch a fit
pitch a tent
pitch in
pitch woo
pitch-perfect
pitched battle
pixel peeper
pizza face
pizza table
pièce de résistance
place in the sun
place of business
plantation nigger
play Old Harry
play along
play around
play back
play ball
play both sides against the middle
play by ear
play down
play dumb
play fast and loose
play first fiddle
play for love
play for time
play games
play gooseberry
play hardball
play hob with
play hookey
play hooky
play it cool
play it safe
play on words
play one against another
play one's cards right
play possum
play second fiddle
play silly buggers
play someone like a fiddle
play the angles
play the field
play the fool
play the gender card
play the hand one is dealt
play the ponies
play the race card
play the same tape
play to the crowd
play to the gallery
play to win
play up
play well with others
play with
play with a full deck
play with fire
plead the fifth
plow on
plug away
plug in
plum blossom
plumber's helper
plunge in
poacher turned gamekeeper
poachers gun
pocket dial
pocket-sized
poetry in motion
point blank
point man
point of no return
point out
point the finger
point the finger at
poison pen
poison-pen letter
poisoned chalice
poles apart
police beat
polish a turd
polish off
polite fiction
political football
politically correct
pony in the barn
pony up
poop factory
poop machine
poop one's pants
poor boy
poor little rich girl
poor power
pop a cap in someone's ass
pop one's clogs
pop one's cork
pop someone's cherry
pop the cherry
pop the question
pop up
popcorn movie
pope's nose
porch monkey
poster boy
poster child
poster girl
postgasm
pot calling the kettle black
potato chaser
potter
potter's clay
potter's field
potty mouth
pound a beat
pound of flesh
pound sand
pound the pavement
pour cold water on
pour fuel on the fire
pour gasoline on the fire
pour oil on troubled waters
pour one's heart out
powder keg
power behind the throne
power chord
powers that be
praise to the skies
prawn cocktail offensive
pray tell
preach to deaf ears
preach to the choir
present company excepted
press into service
press on
press the flesh
press the panic button
pressed for time
pretty pass
pretty penny
pretty pictures
pretty up
prevail upon
price is right
price of tea in China
price on one's head
price out of the market
prick up one's ears
prime of life
private branch exchange
private eye
private language
problem child
professional student
professional victim
progressive love
project management
prop up
prop up the bar
prophet of doom
propose a toast
protest too much
psychological warfare
pub-crawl
public comment
public eye
public intellectual
publicity hound
puddle jumper
pull a
pull a face
pull a fast one
pull a rabbit out of a hat
pull a train
pull ahead
pull an all-nighter
pull apart
pull away
pull back
pull faces
pull in
pull in one's horns
pull my finger
pull off
pull one's finger out
pull one's punches
pull one's socks up
pull one's weight
pull oneself together
pull oneself up by one's bootstraps
pull out
pull out all the stops
pull out of one's ass
pull out of the fire
pull out of the hat
pull over
pull punches
pull rank
pull someone down a peg
pull someone's bacon out of the fire
pull someone's chain
pull someone's leg
pull strings
pull teeth
pull the other leg
pull the other one, it's got bells on
pull the plug
pull the rug out from under someone
pull the trigger
pull the wool over someone's eyes
pull up
pull up a chair
pull up a floor
pull up stakes
pull up stumps
pulling power
pump iron
pump out
pumpkin head
punch above one's weight
punch below one's weight
punch someone's lights out
pure and simple
pure finder
purely and simply
purple prose
purple state
push in
push it
push one's luck
push someone's buttons
push the boat out
push the envelope
push up daisies
pushing up daisies
pussy out
put a damper on
put a foot wrong
put a lid on it
put a sock in it
put a stop to
put all one's eggs in one basket
put an end to
put back
put down
put down as
put down for
put down roots
put down to
put food on the table
put forward
put hair on someone's chest
put in motion
put in with
put into practice
put it past
put it there
put lipstick on a pig
put off
put on
put on a pedestal
put on airs
put on one's dancing shoes
put on the map
put on the red light
put on the ritz
put one foot in front of the other
put one over
put one past
put one through one's paces
put one's ass on the line
put one's back into
put one's best foot forward
put one's cards on the table
put one's feet up
put one's finger on
put one's foot down
put one's foot in it
put one's foot in one's mouth
put one's hands together
put one's house in order
put one's mind to it
put one's money where one's mouth is
put one's name in the hat
put one's pants on one leg at a time
put one's shoulder to the wheel
put oneself across
put oneself in someone's shoes
put out
put out a fire
put out feelers
put out of one's misery
put out to pasture
put paid to
put someone in his place
put someone in mind of
put someone under
put someone's back up
put someone's lights out
put something behind one
put that in your pipe and smoke it
put the bee on
put the boot in
put the brakes on
put the cart before the horse
put the cat among the pigeons
put the clock back
put the clock forward
put the fear of God into
put the feedbag on
put the hammer down
put the kibosh on
put the moves on
put the pedal to the metal
put the plug in the jug
put the screws
put the wind up
put through
put through its paces
put through the mangle
put through the wringer
put to bed
put to bed with a shovel
put to the sword
put to the test
put to use
put to work
put together
put two and two together
put up
put up one's dukes
put up or shut up
put up to
put up with
put-up job
putty in someone's hands
quake in one's boots
quarter of
quarter past
quarter-pounder
queen bee
queen of beasts
queer bashing
queer fish
queer someone's pitch
quelle surprise
question mark
quiche-eater
quick buck
quick off the mark
quick on the draw
quick on the uptake
quick-and-dirty
quick-fire
quite a bit
quote unquote
qwerty syndrome
rabble rouser
race against time
race out of the traps
race queen
rack and ruin
rack off
rack one's brain
rack up
rag bagger
rag the puck
rag-chewing
rags to riches
rain cats and dogs
rain check
rain cheque
rain dogs and cats
rain down
rain off
rain on one's parade
rain on someone's parade
rain or shine
rain pitchforks
rainy day
raise Cain
raise a hand
raise a stink
raise eyebrows
raise hell
raise one's hand
raise someone's hackles
raise the bar
raise the flag and see who salutes
raise the roof
raise the spectre
raise the stakes
raised by wolves
rake it in
rake off
rake over
rake over old coals
rake over the coals
rake together
rake up
rally around
rally round
random number
rank and file
rare animal
rare bird
rat king
rat race
rat run
rattle off
rattle someone's cage
rattle through
raw deal
ray of light
razor-sharp
reach for the sky
reach for the stars
reach-around
read between the lines
read in
read like a book
read lips
read my lips
read out
read someone the riot act
read someone's lips
read someone's mind
ready up
real Macoy
real McCoy
real McKoy
real deal
real superhero
real time
reality check
reap what one sows
rearrange the deck chairs on the Titanic
reasonable person
rebound relationship
reckon without
red ant
red as a beetroot
red car
red dog
red face test
red flag
red ink
red letter day
red light
red man
red meat
red mist
red rider
red state
red tape
red wine
red-faced
redeem oneself
rediscover fire
redolent
reduce to rubble
reel in
reel off
refrigerator mother
rein in
reinvent the wheel
remain to be seen
rent out
report to
rest assured
rest his soul
rest on one's laurels
return to form
return to one's muttons
returns to scale
rev up
revolving door syndrome
rex-pat
rhyme off
rhyme or reason
rib-tickler
rice chaser
rice queen
rickle o' banes
rid out
rid up
ridden hard and put away wet
ride down
ride herd on
ride one's luck
ride out
ride roughshod over
ride shotgun
ride tall in the saddle
ride the coattails
ride the pine
ride the rails
ride the wave
ride with the punches
rig out
right away
right on
right to life
right to work
rim job
ring a bell
ring false
ring hollow
ring off the hook
ring one's bell
ring someone's bell
ring true
ring up
ringside seat
rip into
rip off
rip on
rip one
rip to shreds
rip up
rip-off merchant
rip-snorting mad
ripen up
rise and shine
rise from the ashes
rise to the challenge
rise to the occasion
riverboat queen
rivet counter
roach coach
road apple
road movie
road to Damascus
rob Peter to pay Paul
rob the cradle
robber baron
rock bottom
rock hound
rock on
rock out with one's cock out
rock the boat
rock the house
rocket science
rocket up
rocking horse shit
rocking-horse shit
rod for one's back
roger that
rogues' gallery
roll around
roll back the years
roll in one's grave
roll in the aisles
roll in wealth
roll off the tongue
roll one's eyes
roll out
roll out the red carpet
roll the dice
roll the pill
roll up one's sleeves
roller-coasterish
rolling in dough
rolling in it
rolling stone
romp home
room for doubt
room-temperature IQ
root around
root cause
rooting interest
rose garden
rose-colored glasses
rose-coloured
rotary dial
rotation time
rough and ready
rough around the edges
rough out
rough sledding
rough sleeper
rough trot
roughen up
round of applause
round table
round the bend
round the clock
round up
row back
royal bumps
rub down
rub elbows
rub in
rub it in
rub off
rub off on
rub salt in someone's wounds
rub salt in the wound
rub shoulders
rub someone the wrong way
rub the fear of God into
rub up on
rub up the wrong way
rubber johnny
rubber jungle
rubber room
rubber-chicken dinner
ruby slippers
rue the day
ruffle some feathers
ruffle someone's feathers
rule OK
rule in
rule of thumb
rule out
rule over
rule the roost
rule the school
rum go
rumor campaign
rumor mill
rumple up
run a mile
run a red light
run about
run across
run afoul of
run amok
run around
run around after
run around like a chicken with its head cut off
run around with
run circles around
run counter
run deep
run down the clock
run for one's money
run for the hills
run for the roses
run hot and cold
run in
run in the family
run into the ground
run of play
run off
run off with
run on
run on empty
run on fumes
run one's course
run oneself ragged
run out
run out of steam
run out of town
run out the clock
run over
run past
run rampant
run rings around
run riot
run scared
run someone ragged
run something up the flagpole
run the clock down
run the gamut
run the gauntlet
run the show
run through
run to
run up
run wild
run with
run with scissors
run with the hare and hunt with the hounds
running target
rush hour
rush in
rush out
rustle up
rye seed
sack out
sacked out
sacred cow
sacrificial poet
sad sack
saddle
saddle tramp
safe and sound
said and done
sail close to the wind
salad year
salt away
salt in the wound
salt of the earth
same difference
same old same old
same old story
save by the bell
save face
save one's breath
save oneself
save someone's bacon
save someone's skin
save the day
saved by the bell
saw wood
sawdust trail
say again
say cheese
say goodbye
say grace
say it all
say no more
say uncle
say what
scandal sheet
scare out of one's wits
scare someone to death
scare story
scare straight
scare the bejeebers out of
scare the pants off
scared shitless
scared to death
scarlet red
scholar and gentleman
school of hard knocks
schoolboy error
scope out
score off
scrape along
scrape the bottom of the barrel
scrape through
scrape together
scratch one's head
scratch that
scratch the surface
scratch together
scream bloody murder
scream blue murder
scream loudest
scream one's head off
screw back
screw it
screw off
screw the pooch
screw-off
screw-up
screwed up
screwed, blued and tattooed
scrimp and save
scrounge up
scrub up
scuba diver
scum of the earth
scuzz up
sea change
sea legs
seagull approach
seagull manager
seal the deal
seat-of-the-pants
second Tuesday of the week
second banana
second childhood
second fiddle
second gear
second nature
second string
second-guess
see a man
see a man about a dog
see a man about a horse
see eye to eye
see how the land lies
see past the end of one's nose
see red
see someone's point
see stars
see the elephant
see the forest for the trees
see the light
see the light of day
see the point
see things
see through
see which way the cat jumps
see yellow
see you later
see you next Tuesday
seismic shift
seize the day
sell down
sell down the river
sell ice to Eskimos
sell like hot cakes
sell one's body
sell one's soul
sell oneself
sell out
sell someone a bill of goods
sell-by date
seller's market
selling point
send away
send away for
send shivers down someone's spine
send someone packing
send someone to the showers
send to Coventry
send up
send word
sense of craft
separate the wheat from the chaff
serve someone right
serve time
serve up
set a spell
set apart
set aside
set back
set by the ears
set down
set eyes on
set foot
set for life
set in motion
set in one's ways
set in stone
set of pipes
set of wheels
set off
set one's cap at
set one's heart on
set one's shoulder to the wheel
set one's sights on
set pulses racing
set straight
set the Thames on fire
set the bar
set the stage
set the wheels in motion
set the world on fire
set to work
set up shop
settle for
settle in
settle into
settle on
settle someone's hash
settle upon
sewer rat
sex machine
sex on a stick
sex on legs
sex pact
sex talk
sex up
sex, drugs and rock 'n' roll
sex, lies and videotape
sexual congress
sexual minority
sexual relation
sexual tension
shack up
shacked up
shake a leg
shake hands with the unemployed
shake on it
shake the pagoda tree
sham Abraham
sham Abram
shame, shame
shank-nag
shanks' mare
shanks' nag
shanks' pony
shape up
shape up or ship out
share and share alike
shark bait
shark baiter
sharp cookie
sharp tongue
sharp-elbowed
she'll be right
shed a tear
shed light upon
shell out
shell shock
shift gears
shimmy on down
ships that pass in the night
shirtless
shit a brick
shit factory
shit one's pants
shit oneself
shit or get off the pot
shit out of luck
shit soup
shit stain
shit the bed
shit-eating grin
shitstorm
shitting match
shitting planks
shoo-in
shoot 'em up
shoot a bird
shoot down
shoot first and ask questions later
shoot off
shoot off at the mouth
shoot one's bolt
shoot one's load
shoot one's mouth off
shoot one's wad
shoot oneself in the foot
shoot the boots
shoot the breeze
shoot the bull
shoot the messenger
shoot the shit
shoot through
shoot up
shooting iron
shore up
short and sweet
short code
short end of the stick
short fuse
short hairs
short leash
short of a length
short on looks
short strokes
short temper
short-sheet
shot across the bow
shot in the arm
shot in the dark
shot with a shovel
shotgun approach
shotgun shack
shotgun wedding
shots fired
shoulder to cry on
shout from the rooftops
shove it up your ass
shove off
shove something down someone's throat
show a clean pair of heels
show a leg
show ankle
show off
show one's butt
show one's cards
show one's face
show one's true colors
show one's true stripes
show someone the door
show the flag
show up
show who's boss
shower of shit
shower with
shrinking violet
shrug off
shuffle off this mortal coil
shut down
shut in
shut one's face
shut one's mouth
shut the door on
shy bladder
sibling fucker
sick and tired
sick as a parrot
sick list
sick man
sick note
sick puppy
side effect
side issue
side wall
sigh of relief
sight for sore eyes
sight to behold
sight unseen
sign in
sign of the times
sign off
sign on
sign on the dotted line
significance level
silky smooth
silly money
silly season
silver bullet
silver foil
silver screen
silver spoon
silver surfer
silver tongue
silver-tongued
simmer down
simple English
sin tax
sing along
sing from the same hymnbook
sing off the same hymn sheet
sing soprano
sing the praises of
singing soprano
single money
sink in
sink one's teeth into
sink or swim
sinking ship
siren song
sit back
sit in
sit in for
sit on
sit on it
sit on one's hands
sit on the fence
sit out
sit still
sit through
sit tight
sitting duck
sitting pretty
six and two threes
six feet under
six of one, half a dozen of the other
six of the best
six ways to Sunday
size queen
size up
skate on thin ice
skate over
skeleton crew
skimp and save
skin and bones
skin in the game
skip a beat
skip out
skip rope
skip town
skirt chaser
skittles party
skunk at a garden party
slack-jawed
slag off
slam dunk
slanging match
slap and tickle
slap in the face
slap leather
slap on the wrist
slave to fashion
sleep around
sleep camel
sleep in
sleep on
sleep rough
sleep together
sleep under the same bridge
sleep with
sleep with the fishes
sleeping at the switch
sleeping giant
sleeping policeman
sleepy head
sleeves from one's vest
slender reed
slide off
sling off
sling one's hook
slip by
slip into
slip into something more comfortable
slip of the tongue
slip someone's mind
slip through the cracks
slip under the radar
slip up
slip-up
slippery as an eel
slippery slope
slop bowl
slop out
sloshed to the gills
slot in
slow burn
slow down
slow march
slow up
slow-walk
slower than molasses
slowly but surely
slug away
smack of
small arms
small beer
small change
small fry
small potatoes
small print
small reed
small talk
small wonder
smallpox blanket
smart arse
smart chance
smart off
smash hit
smash up
smear campaign
smell a rat
smell blood
smell like a rose
smell of an oily rag
smell of the lamp
smell test
smell the barn
smell up
smile from ear to ear
smoke and mirrors
smoke like a chimney
smoke out
smoke pole
smoke signal
smoke-filled room
smoking gun
smooth down
smooth operator
smooth sailing
snail's pace
snake eyes
snake in the grass
snake oil
snakes and ladders
snap it up
snap judgment
snap someone's head off
snatch defeat from the jaws of victory
snatch the pebble
snatch victory from the jaws of defeat
snazz up
sneck posset
snedging
sniff out
sniff test
snipe hunt
snot-nosed
snow job
snow on the mountaintop
snow on the rooftop
snow out
snowball's chance in hell
snowman
snuggle bunny
so be it
so far
so long as
so much as
so much for
so quiet one could hear a pin drop
so there
so-and-so
so-called
soak up
soaked to the bone
soaked to the skin
soaking wet
soap plant
soapbox
sob story
social death
social justice warrior
social ladder
socialized medicine
sock-knocking
sod all
sod off
soda jerk
soft Mick
soft sawder
soft shoe
soft spot
soft touch
soften up
softly softly
soldier on
solitary wasp
solo run
some kind of
some old
some people
some people have all the luck
something awful
something like
somewhere along the line
somewhere over the rainbow
sommergere di cazzate
son of the morning
song and dance
sore point
sore-thumbish
sort of
sort oneself out
sort out
soul kiss
sound asleep
soup sandwich
soup-to-nuts
sour cherry
sour grapes
sour note
sour stomach
sow one's wild oats
space out
spaghetti western
spank the monkey
spare no effort
spare someone's blushes
spare tire
spare tyre
spark spread
speak for
speak for oneself
speak in circles
speak of the devil
speak of the devil and he appears
speak of the devil and he shall appear
speak one's mind
speak out
speak someone's language
speak to
speak up
speak volumes
speak with a forked tongue
spear carrier
special delivery
special measures
special needs
spectator sport
speed freak
speed merchant
speed queen
speed up
spend a penny
spic and span
spice up
spick and span
spick-and-span
spiff up
spill one's guts
spill one's seed
spill out
spill the beans
spill the tea
spin a yarn
spin one's wheels
spin out
spine-tingling
spit feathers
spit it out
spit nails
spit the dummy
spit-and-polish
spitstick
spitting distance
splash down
splice the mainbrace
split hairs
split one's sides
split up
spoilt for choice
spoken word
spot check
spread out
spring fever
spring for
spring in one's step
spring out
spring to life
spring to mind
spruce up
spur of the moment
square away
square meal
square one
square peg in a round hole
square peg into a round hole
square rod
square shooter
squeeze out
squint like a bag of nails
squirrel away
stab in the back
stack up
stack z's
stage of the game
stage-door Johnny
staircase wit
stake a claim
stalking horse
stamp out
stand a chance
stand behind
stand by
stand corrected
stand down
stand for
stand from under
stand in for
stand in one's own light
stand in someone's shoes
stand in the gap
stand on ceremony
stand on its own
stand on one's own two feet
stand one's ground
stand out
stand pat
stand someone in good stead
stand stock still
stand tall
stand the test of time
stand to reason
stand up
stand up with
standard fare
stare at the wall
stare someone in the face
stars are aligned
stars in one's eyes
start off on the wrong foot
start over
starting price
starvin' Marvin
state of affairs
stave off
stay at home
stay behind
stay hungry
stay on
stay put
stay the course
stay the distance
stay tuned
steady the ship
steady-as-she-goes
steal a march
steal someone's thunder
steal the show
steely-eyed
steely-nerved
steer clear
stem the rose
stem the tide
step aside
step back
step down
step forward
step on a frog
step on a rake
step on it
step on someone's toes
step out
step over
step up
step up one's game
step up to the plate
stepping razor
stepping stone
stew in one's juices
stick a fork in something
stick around
stick by
stick in someone's craw
stick in the mud
stick it out
stick it to the man
stick one's neck out
stick one's nose in
stick one's oar in
stick out
stick to
stick to one's guns
stick to one's knitting
stick together
stick up
stick up one's ass
stick with
stick-in-the-mud
sticker shock
sticking point
sticking-place
sticky fingers
stiff upper lip
stink eye
stink on ice
stir shit
stir-crazy
stock phrase
stone cold
stone dead
stone deaf
stone paste
stone's throw
stonewall
stop and smell the roses
stop at nothing
stop dead
stop on a dime
stop press
stop someone in his tracks
stop the lights
stop the presses
store away
store up
storm off
storm out of the blocks
stovepipe hat
straight and narrow
straight arrow
straight away
straight face
straight from the horse's mouth
straight from the shoulder
straight man
straight out of the chute
straight shooter
straighten out
strange bedfellows
strange bird
strap on a pair
straw poll
straw that stirs the drink
streak of good luck
street appeal
stretch
stretch one's legs
stretch the truth
strike a blow
strike a chord
strike it rich
strike one's flag
strike through
strike up
strike while the iron is hot
string along
string to one's bow
string up
strings attached
strip off
stroke of business
stroke of work
strut one's stuff
stub out
stuck on
stuck up
stud muffin
stuff and nonsense
stuff it
stuff one's face
stuff the ballot box
stuff up
stuff you
stuffed like a turkey
stuffed shirt
stuffed to the gills
stumbling-block
stump up
such as
such-and-such
suck a big one
suck a lemon
suck ass
suck balls
suck cock
suck donkey balls
suck donkey cock
suck down
suck face
suck hind tit
suck in
suck it
suck it up
suck my balls
suck my cock
suck someone's cock
suck the kumara
suck tits
suck up
sucker punch
sudden death
suffer fools gladly
sugar coated
sugar pill
sugarcoated
suit down to the ground
sum of its parts
sum up
summer and winter
sun worshipper
supposed to
sure as eggs
sure enough
sure of oneself
surprise surprise
suspend one's disbelief
swaddling clothes
swallow one's pride
swan song
swap spit
swear by
swear off
swear on a stack of Bibles
sweat bullets
sweat equity
sweat of one's brow
sweep aside
sweep away
sweep out
sweep someone off their feet
sweep something under the rug
sweep the board
sweet Jesus
sweet Mary
sweet Mary mother of God
sweet as
sweet cherry
sweet dreams
sweet fuck all
sweet hereafter
sweet nothings
sweet on
sweet tooth
sweet young thing
sweeten the pot
sweeten up
sweetheart deal
sweetness and light
swell up
swim upstream
swim with sharks
swing both ways
swing for the fences
swing of things
swing state
swings and roundabouts
switch off
switch on
switch-hitter
sword and sandal
sword and sorcery
syphon the python
table talk
tag along
tag team
tail between one's legs
tail wagging the dog
take a back seat
take a bath
take a bead on
take a bite
take a bow
take a breath
take a breather
take a bullet
take a chance
take a crack at
take a crap
take a dim view of
take a dirt nap
take a dive
take a flyer
take a gamble
take a gander
take a grab
take a hike
take a joke
take a leaf out of someone's book
take a leak
take a licking
take a licking and keep on ticking
take a long walk on a short pier
take a look
take a nap
take a number
take a pew
take a picture
take a powder
take a ride to Tyburn
take a risk
take a run at
take a seat
take a shit
take a shot in the dark
take a spill
take a spin
take a stab at
take a stand
take a tumble
take a turn for the better
take a turn for the worse
take a wife
take aback
take aim
take an axe to
take by storm
take cover
take down a peg
take effect
take exception
take five
take flight
take for a ride
take for a spin
take for granted
take guard
take heart
take heed
take ill
take into account
take into consideration
take it away
take it easy
take it from me
take it like a man
take it or leave it
take it out on
take it outside
take it to the bank
take it up the ass
take its toll
take kindly
take leave
take leave of one's senses
take liberties
take lightly
take lying down
take matters into one's own hands
take no for an answer
take no notice of
take no prisoners
take on
take on faith
take on the chin
take one for the team
take one's ball and go home
take one's chance
take one's eye off the ball
take one's hat off to
take one's lumps
take one's pick
take one's time
take one's tongue out of someone's ass
take out
take out an onion
take out of context
take out the trash
take over
take part
take pride
take sides
take silk
take sitting down
take someone's head off
take someone's word for it
take something as read
take something in one's stride
take something in stride
take something to the grave
take the Browns to the Super Bowl
take the Michael
take the bait
take the biscuit
take the bitter with the sweet
take the bull by the horns
take the cake
take the cure
take the fall
take the field
take the fifth
take the flak
take the game to
take the gilt off the gingerbread
take the heat
take the hint
take the law into one's own hands
take the lead
take the liberty
take the mick
take the mickey
take the offensive
take the pee
take the piss
take the plunge
take the point
take the red pill
take the reins
take the shadow for the substance
take the stand
take the wheel
take the wind out of someone's sails
take things as they come
take to
take to heart
take to one's heels
take to task
take to the cleaners
take to the hills
take to wife
take up a collection
take up the cudgel for
take up the gauntlet
take up with
talent management
talk a blue streak
talk a mile a minute
talk about
talk back
talk dirty
talk down
talk in circles
talk is cheap
talk like an apothecary
talk of the devil
talk of the town
talk out of turn
talk out one's ass
talk over someone's head
talk someone into something
talk someone under the table
talk someone's ear off
talk the talk
talk through one's hat
talk to the hand
talk turkey
talk up
talking head
tall in the saddle
tall order
tall tale
tamp down
tan someone's hide
taper off
tar with the same brush
taste of one's own medicine
taste of one's own poison
teach someone a lesson
teacher's pet
team up
team up with
tear a strip off someone
tear apart
tear away
tear one's hair out
tear up
tear up the pea patch
tee off
teed off
teensy weensy
teeny weeny
teething problems
teething troubles
telephone tag
tell against
tell all
tell apart
tell fortunes
tell it like it is
tell it to Sweeney
tell it to the judge
tell it to the marines
tell off
tell someone where to shove it
tell tales
tell tales out of school
tell the truth
tell you the truth
temper temper
tempest in a teapot
temple of immensity
tempt fate
ten a penny
ten foot pole
tentpole movie
terminal leaves
territorial pissing
test bed
test of time
test the waters
than a bygod
thank one's lucky stars
thanks a bunch
thanks for nothing
that does it
that figures
that way
that'll be the day
that's all she wrote
that's just me
that's that
that's the ticket
that's what she said
that's what's up
the ball is in someone's court
the bee's knees
the biter bit
the box they're going to bury it in
the buck stops here
the cat's out of the bag
the devil
the die is cast
the end of one's rope
the finger
the fix is in
the genie's out of the bottle
the handbags come out
the hell out of
the icing on the cake
the jig is up
the joke is on someone
the long and short
the man
the nose knows
the old woman is plucking her goose
the other day
the pants off
the pick of the litter
the pits
the place to be
the plot thickens
the quality
the rabbit died
the rest is history
the rubber meets the road
the shoe is on the other foot
the straw that broke the camel's back
the terrorists will have won
the thing is
the thing of it
the upper hand
the wheels fell off
the whole nine yards
the whole world and his dog
the world over
them's the breaks
them's the facts
then again
then and there
there and back
there for everyone to see
there we go
there you are
there you go
there you have it
there's only one
these islands
these kingdoms
thick and thin
thick as thieves
thick of things
thick skin
thief in the night
thigh-slapper
thin air
thin edge of the wedge
thin end of the wedge
thin section
thin-skinned
things that go bump in the night
think aloud
think back
think of
think of England
think of the children
think on one's feet
think one's shit doesn't stink
think over
think tank
think the world of
think twice
think up
think with one's little head
third degree
third hand
third person
third string
third wheel
this instance
this minute
this, that, and the other
thorn in someone's side
thorn in the flesh
though but
thrash out
thread the needle
three Rs
three score and ten
three sheets to the wind
three skips of a louse
three-dimensionality
three-martini lunch
three-on-the-tree
three-ring circus
thrill kill
thrill killer
through and through
through the roof
through the wire
throw a bone to
throw a fit
throw a party
throw a spanner in the works
throw a tantrum
throw a wobbly
throw an eye
throw aside
throw caution to the wind
throw chunks
throw cold water on
throw down
throw down the gauntlet
throw good money after bad
throw in
throw in at the deep end
throw in the towel
throw in with
throw money away
throw off
throw off balance
throw off the trail
throw one's cap over the windmill
throw one's hat in the ring
throw one's toys out of the pram
throw one's weight around
throw oneself at
throw out
throw shapes
throw smoke
throw someone a curve
throw the baby out with the bathwater
throw the book at
throw to the dogs
throw to the wind
throw to the wolves
throw under the bus
throw up
thumb a ride
thumb on the scale
thumb one's nose
thumbs up
thus and so
thus and such
tick all the boxes
tick off
tick over
tickle pink
tickle someone's fancy
tickle someone's funny bone
tickle the dragon's tail
tickle the ivories
tickled pink
tide over
tie one on
tie someone's hands
tie the knot
tie up
tie up loose ends
tiger team
tight lips
tight ship
tight spot
tight-lipped
tighten one's belt
tighten the purse strings
till death do us part
tilt at windmills
time after time
time and material
time bandit
time burglar
time of the month
time off
time out
time out of mind
time thief
time will tell
tin ear
tin god
tip of the hat
tip of the iceberg
tip off
tip one's hand
tip one's hat
tip the scale
tip the scales
tip-off
tipping it down
tiptoe around
tired and emotional
tit for tat
tits up
tits-up
titsup
to a T
to a fare-thee-well
to a fault
to a nicety
to a turn
to all intents and purposes
to be honest
to be named later
to be sure
to beat the band
to boot
to date
to death
to die for
to do with
to go
to hell in a handbasket
to one's heart's content
to one's mind
to pieces
to say nothing of
to say the least
to speak of
to tell the truth
to that end
to the T
to the bone
to the brim
to the gills
to the hilt
to the letter
to the max
to the moon
to the nth degree
to the point
to the tee
to the tonsils
to the tune of
toad-strangler
toast of the town
today we are all
toddle off
toe the line
toe-to-toe
toes up
toke up
tomato juice
tone down
tongue-in-cheek
tongue-tied
tonsil hockey
tonsil tennis
too bad
too big for one's boots
too big for one's britches
too clever by half
too hot to hold
too many balls in the air
too rich for one's blood
tool around
toot one's own horn
tooth and nail
top banana
top brass
top dog
top dollar
top drawer
top edge
top hand
top hat
top it off
top notch
top of mind
top of the line
top of the morning
top oneself
top shelf
top up
top-heavy with drink
top-shelf
topple over
topsy turvy
torque off
torqued off
toss around
toss up
toss-up
total clearance
totus porcus
touch a nerve
touch and go
touch base
touch cloth
touch of the tar brush
touch off
touch on
touch oneself
touch the hem of someone's garment
touch up
touch wood
touch-and-go
touched in the head
touchy-feely
tough as nails
tough call
tough cookie
tough cookies
tough love
tough luck
tough nut to crack
tough titties
tough titty
tough toodles
tough tuchus
toughen up
town and gown
toy boy
toys in the attic
track down
track record
traditional marriage
trailer park trash
trailer trash
train wreck
transbay
transcendental meditation
trash out
tread lightly
trench mouth
trial balloon
trial by fire
trials and tribulations
trick of the trade
trick up one's sleeve
tried and true
trigger-happy
trip balls
trip out
trip to the woodshed
trot out
trouble at mill
trouble in paradise
true believer
true blue
true stripes
true to form
true to one's colors
trump up
truth be told
try one's hand
try one's luck
tub of guts
tube steak
tucker out
tuckered out
tug of war
tune in
tune out
tuppence
tuppence worth
turd in the punchbowl
turf out
turf war
turkey shoot
turkey slap
turn a blind eye
turn a corner
turn a deaf ear
turn a hair
turn a phrase
turn a profit
turn a trick
turn against
turn around
turn back
turn down
turn heads
turn in
turn in one's grave
turn into
turn into a pumpkin
turn loose
turn of events
turn of phrase
turn off
turn on
turn on its head
turn on one's heel
turn one on
turn one's back
turn one's coat
turn one's nose up
turn out
turn over
turn over a new leaf
turn someone's crank
turn someone's head
turn tail
turn the air blue
turn the corner
turn the other cheek
turn the page
turn the scale
turn the screw
turn the tables
turn the tide
turn to
turn to dust
turn tricks
turn two
turn up
turn up for the book
turn up one's nose
turn up trumps
turn upside down
turn-off
turn-on
twatfaced
twelve-ounce curls
twenty to
twenty to the dozen
twenty winks
twenty-twenty hindsight
twiddle one's thumbs
twilight years
twinkle in one's father's eye
twinkly-eyed
twist in the wind
twist of fate
twist someone's arm
twist someone's balls
twist the knife
two a penny
two birds with one stone
two bob
two cents
two for two
two left feet
two penn'orth
two pennies' worth
two sides of the same coin
two thumbs up
two-edged sword
two-fisted drinker
two-second rule
two-way street
tyre kicker
unavailable energy
under a cloud
under a spell
under erasure
under fire
under glass
under lock and key
under no circumstances
under one's belt
under one's breath
under one's hat
under one's nose
under one's own steam
under one's thumb
under one's wing
under sail
under the carpet
under the cosh
under the covers
under the gun
under the impression
under the influence
under the knife
under the microscope
under the pump
under the radar
under the rug
under the sun
under the table
under the weather
under the wire
under the yoke
under water
under way
under wraps
underwater basket weaving
university of life
unknown quantity
uno ab alto
unring a bell
until hell freezes over
until one is blue in the face
until the cows come home
until the last dog is hung
unwashed masses
up a storm
up a tree
up against
up against it
up and at 'em
up and down
up and running
up for
up for grabs
up front
up hill and down dale
up in arms
up in the air
up on
up on one's ear
up one's own ass
up one's sleeve
up shit creek
up shit creek without a paddle
up shit's creek
up shit's creek without a paddle
up someone's alley
up someone's street
up the ante
up the creek
up the river
up the wall
up the walls
up the wazoo
up the ying yang
up there
up to eleven
up to here
up to no good
up to par
up to scratch
up to snuff
up to something
up to speed
up with the chickens
up with the lark
up with the larks
up yours
up-and-comer
up-and-coming
up-to-date
uphill battle
upper crust
upper-crust
ups and downs
upset the applecart
urban fabric
use a sledgehammer to crack a nut
use one's head
use one's noggin
used to
valley of death
valley of the shadow of death
variable tandem repeat locus
vaulting school
veg out
velvet handcuffs
vent one's gall
verbal assault
verge on
vertically challenged
very good
very well
vest buster
victory at sea
virgin territory
viviparous lizard
voice in the wilderness
vote down
vote with one's feet
vouch for
vowel quantity
wait for it
wait for the ball to drop
wait for the other shoe to drop
wait on
wait on hand and foot
wait on hand, foot and finger
wait on someone hand, foot and finger
wait on someone hand, foot, and finger
wait out
wait upon hand and foot
waiting game
wake up and smell the coffee
wake up on the wrong side of bed
walk a mile in someone's shoes
walk a tightrope
walk all over
walk and chew gum at the same time
walk away
walk away from
walk back
walk down the aisle
walk in on
walk in the park
walk in the snow
walk of life
walk off with
walk on eggshells
walk on the wild side
walk on water
walk over
walk the dog
walk the floor
walk the line
walk the plank
walk the talk
walk the walk
walk through
wall of silence
wallow in the mire
wanker's cramp
want out
war bride
war of nerves
warm body
warm fuzzy
warm regards
warm the cockles of someone's heart
warning shot
warrior ant
warts and all
wash one's hands
wash one's hands of
wash out
washed out
washed up
waste away
waste breath
waste not, want not
watch it
watch one's mouth
watch one's step
watch out
watch over
watch this space
water can
water down
water over the dam
water power
water under the bridge
watered-down
watering hole
wave away
wave of the hand
wave the white flag
way back when
way out of a paper bag
way to go
we haven't got all day
weak sister
weak tea
weak-kneed
weaker vessel
wear down
wear one's heart on one's sleeve
wear out one's welcome
wear rose-colored glasses
wear thin
wear too many hats
weasel out
weather the storm
wedding-cake
wee small hours
weed out
weekend warrior
weigh against
weigh down
weigh in
weight of the world
welfare Cadillac
well and good
well and truly
well done
well hung
well met
well, I never
well-oiled
well-padded
well-stacked
were you born in a tent
wet behind the ears
wet blanket
wet boy
wet dream
wet one's beak
wet one's pants
wet one's whistle
wet the bed
whack-a-mole
whale tail
what are the odds
what can I say
what did your last slave die of
what do I know
what do you say
what else is new
what for
what in tarnation
what is more
what it takes
what me worry
what not
what of it
what someone said
what the Devil
what was someone smoking
what was that
what with
what you see is what you get
what's cooking
what's eating
what's eating you
what's going on
what's in it for me
what's it to you
what's new
what's the difference
what's the good of
what's the matter
what's up
what's what
whatever creams your twinkie
whatever floats your boat
whatever it takes
whatsamatta
wheel away
wheel within a wheel
when Hell freezes over
when all is said and done
when it's at home
when pigs fly
when push comes to shove
when the chips are down
when the dust settles
when two Sundays come together
when two Sundays meet
when, as, and if
where it's at
where the sun don't shine
where's the beef
which foot the shoe is on
whichever way one slices it
while we're young
whip hand
whip through
whips and jingles
whisk away
whisk off
whiskey dick
whisper campaign
whistle Dixie
whistle for
whistle in the dark
whistle past the graveyard
whistle walk
whistle-blower
whistle-stop
white coat hypertension
white elephant
white hat
white hole
white lie
white magic
white man
white marriage
white on rice
white rider
white sheep
white trash
white trashery
white wedding
white wine
white-knuckle
whitewash
who shot John
who's 'she', the cat's mother?
who's who
whole ball of wax
whole cloth
whole shebang
whole shooting match
whomp on
whomp up
whoop it up
whoop-ass
why in God's name
why on Earth
whys and wherefores
wicked tongue
wide awake
wide berth
wide of the mark
widow-maker
wiggle room
wild cherry
wild horses
wild turkey
wild-goose chase
will do
will o' the wisp
willful ignorance
willing horse
willow in the wind
win back
win by a nose
win one for the Gipper
win over
win the day
wind at one's back
wind back the clock
wind down
wind up one's bottoms
window dressing
window-shopping
wine tosser
wing it
winning ways
winter rat
winter sun
wipe out
wipe someone's eye
wipe the slate clean
wireless network
wise apple
wise guy
wishful thinking
with a grain of salt
with a quickness
with a vengeance
with a view to
with all due respect
with an eye to
with an eye towards
with any luck
with bated breath
with both hands
with knobs on
with no further ado
with one voice
with one's bare hands
with one's dick in one's hand
with one's head held high
with open arms
with pleasure
within ames ace
within an ace of
within living memory
within reach
without fail
without further ado
woe betide
wolf down
wolf in sheep's clothing
wolfpack
wooden mare
wooden spoon
wooden spoonist
wooden-top
word of mouth
word on the street
word on the wire
word play
word to the wise
word-for-word
words of one syllable
work nights
work one's butt off
work one's fingers to the bone
work one's magic
work one's tail off
work out
work someone's arse off
work someone's ass off
work spouse
work the crowd
work the room
work to rule
work wonders
worked up
working girl
world-beater
worlds apart
worm food
worm's-eye view
worry wart
worse for wear
worship the ground someone walks on
worship the porcelain god
worst comes to worst
worst of both worlds
worth a Jew's eye
worth every penny
worth its weight in gold
worth one's salt
worth one's while
woulda, coulda, shoulda
wouldn't hurt a fly
wouldn't shout if a shark bit him
wouldn't touch with yours
wouldn't you know
wouldn't you know it
wrap around one's little finger
wrap in the flag
wrap one's head around
wrap up
wreak havoc
wrestle with a pig
wriggle out of
writ large
write down
write home about
write one's own ticket
writer's cramp
written all over someone's face
written out
wrong crowd
wrong number
wrong place at the wrong time
wrong side of the tracks
yank someone's chain
yardarm to yardarm
ye gods
yeah, right
year dot
year in, year out
yell at
yell silently
yellow brick road
yellow cake
yellow dog
yellow grease
yellow journalism
yellow light
yellow press
yellow state
yeoman's service
yes and no
yes man
yes to death
yield the ghost
you all
you bet
you can say that again
you can't judge a book by its cover
you can't say fairer than that
you don't say
you gals
you guys
you know
you know it
you know what
you knows it
you lot
you name it
you shouldn't have
you snooze you lose
you think
you what
you wish
you'll never guess
you're telling me
young Turk
young at heart
young fogey
young lady
young man
younger brother
younger sister
your ass
your blood's worth bottling
your guess is as good as mine
your man
your mileage may vary
yours sincerely
yours trulies
yours truly
zero in on
zero-day
zig when one should zag
zip one's lip
zip up
zonk out
éminence grise
