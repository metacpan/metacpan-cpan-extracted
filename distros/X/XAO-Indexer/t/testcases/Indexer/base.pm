package testcases::Indexer::base;
use strict;
use warnings;
use utf8;
use CGI;
use Encode;
use XAO::Base;
use XAO::Utils;
use XAO::Web;

use base qw(XAO::testcases::base);

use constant NAME_LENGTH => 50;
use constant TEXT_LENGTH => 500;

sub new ($) {
    my $proto=shift;
    my $self=$proto->SUPER::new(@_);

    my %d;
    if(1) {
        open(F,'.config') ||
            die "No .config found, run 'perl Makefile.PL'";
        local($/);
        my $t=<F>;
        close(F);
        eval $t;
    }

    $self->{'skip_db_tests'}=$d{'test_dsn'} eq 'none' ? 1 : 0;

    return $self;
}

sub list_tests ($) {
    my $self=shift;

    my @tests=$self->SUPER::list_tests(@_);

    if($self->{'skip_db_tests'}) {
        @tests=();
    }

    return wantarray ? @tests : \@tests;
}

sub set_up {
    my $self=shift;

    $self->SUPER::set_up();

    my $site=XAO::Web->new(sitename => 'test');
    $site->set_current();

    my $cgi=CGI->new('foo=bar&test=1');

    $site->config->embedded('web')->enable_special_access();
    $site->config->cgi($cgi);
    $site->config->embedded('web')->disable_special_access();

    $self->{'siteconfig'}=$site->config;
    $self->{'web'}=$site;
    $self->{'cgi'}=$cgi;

    if(!$self->{'skip_db_tests'}) {
        $site->config->odb->fetch('/')->build_structure(
            Indexes => {
                type        => 'list',
                class       => 'Data::Index',
                key         => 'index_id',
            },
            Foo => {
                type        => 'list',
                class       => 'Data::Foo',
                key         => 'foo_id',
                key_format  => 'foo_<$AUTOINC$>',
                structure   => {
                    Bar => {
                        type        => 'list',
                        class       => 'Data::Bar',
                        key         => 'bar_id',
                        key_format  => 'bar_<$AUTOINC$>',
                        structure   => {
                            name => {
                                type        => 'text',
                                maxlength   => NAME_LENGTH,
                                charset     => 'utf8',
                            },
                            text => {
                                type        => 'text',
                                maxlength   => TEXT_LENGTH,
                                charset     => 'utf8',
                            },
                        },
                    },
                    name => {
                        type        => 'text',
                        maxlength   => NAME_LENGTH,
                        charset     => 'utf8',
                    },
                    text => {
                        type        => 'text',
                        maxlength   => TEXT_LENGTH,
                        charset     => 'utf8',
                    },
                },
            },
        );
    }

    $site->config->odb->fetch('/Indexes')->get_new->build_structure;

    return $self;
}

use vars qw(@words);

sub generate_content {
    my $self=shift;
    my $odb=$self->siteconfig->odb;

    ##
    # Populating the database with a semi-random, but fixed set of data.
    #
    my $foo_list=$odb->fetch('/Foo');
    my $foo_new=$foo_list->get_new;
    my $bar_new;
    dprint "Creating data set";
    srand(54321);
    $odb->transact_begin;
    for(1..150) {
        $foo_new->put(
            name   => $self->random_text($foo_new->describe('name')->{'maxlength'}),
            text   => $self->random_text($foo_new->describe('text')->{'maxlength'}),
        );
        my $foo=$foo_list->get($foo_list->put($foo_new));
        my $bar_list=$foo->get('Bar');
        $bar_new=$bar_list->get_new unless $bar_new;
        my $bar_num=int(rand(7));
        for(1..$bar_num) {
            $bar_new->put(
                name   => $self->random_text($foo_new->describe('name')->{'maxlength'}),
                text   => $self->random_text($foo_new->describe('text')->{'maxlength'}),
            );
            $bar_list->put($bar_new);
        }
    }

    @words=();
    for(1..20) {
        $foo_new->put(
            name   => $self->random_unicode($foo_new->describe('name')->{'maxlength'}),
            text   => $self->random_unicode($foo_new->describe('text')->{'maxlength'}),
        );
        $foo_list->put($foo_new);
    }

    $odb->transact_commit;
}

sub unicode_words {
    my $self=shift;
    return (
        decode('iso-8859-1',"Birkh\xf6user"),
        split(/\s/,decode('iso-8859-1',"Minist\xe8re des Affaires \xe9trang\xe8res")),
        "\x{0412}\x{0435}\x{0431}", # Russian: Web
        "\x{041a}\x{0430}\x{0440}\x{0442}\x{0438}\x{043d}\x{043a}\x{0438}", # Russian: Images
        qw(filler1 filler2 filler3 filler4 filler5 filler6 filler7 filler8 filler9),
        qw(killer1 killer2 killer3 killer4 killer5 killer6 killer7 killer8 killer9),
        qw(biller1 biller2 biller3 biller4 biller5 biller6 biller7 biller8 biller9),
    );
}

sub random_unicode {
    my ($self,$maxl)=@_;
    if(!@words) {
        @words=$self->unicode_words;
        ### binmode(STDERR,':utf8');
        ### dprint join("|",@words);
    }
    return $self->random_text($maxl);
}

sub random_text {
    my ($self,$maxl)=@_;

    if(!@words) {
        while(<DATA>) {
            push(@words,split);
        }
    }

    ##
    # Make length vary, but tend to be long..
    #
    $maxl-=int($maxl*rand(1)*rand(1)*rand(1));

    my $text='';
    while(1) {
        my $word=$words[rand(@words)];
        last if length($text)+length($word)+1 >= $maxl;
        $text.=' ' if length($text);
        $text.=$word;
    }

    ### dprint $text;
    return $text;
}

1;
__DATA__
FORTUNE DISCUSSES THE DIFFERENCES BETWEEN MEN AND WOMEN:	#5

Trust:
	The average woman would really like to be told if her mate is fooling
around behind her back.  This same woman wouldn't tell her best friend if
she knew the best friends' mate was having an affair.  She'll tell all her
OTHER friends, however.  The average man won't say anything if he knows that
one of his friend's mates is fooling around, and he'd rather not know if
his mate is having an affair either, out of fear that it might be with one
of his friends.  He will tell all his friends about his own affairs, though,
so they can be ready if he needs an alibi.

Driving:
	A typical man thinks he's Mario Andretti as soon as he slips behind
the wheel of his car.  The fact that it's an 8-year-old Honda doesn't keep
him from trying to out-accelerate the guy in the Porsche who's attempting
to cut him off; freeway on-ramps are exciting challenges to see who has The
Right Stuff on the morning commute.  Does he or doesn't he?  Only his body
shop knows for sure.  Insurance companies understand this behavior, and
price their policies accordingly.
	A woman will slow down to let a car merge in front of her, and get
rear-ended by another woman who was busy adding the finishing touches to
her makeup.

Even in the moment of our earliest kiss,
When sighed the straitened bud into the flower,
Sat the dry seed of most unwelcome this;
And that I knew, though not the day and hour.
Too season-wise am I, being country-bred,
To tilt at autumn or defy the frost:
Snuffing the chill even as my fathers did,
I say with them, "What's out tonight is lost."
I only hoped, with the mild hope of all
Who watch the leaf take shape upon the tree,
A fairer summer and a later fall
Than in these parts a man is apt to see,
And sunny clusters ripened for the wine:
I tell you this across the blackened vine.
		-- Edna St. Vincent Millay, "Even in the Moment of
		   Our Earliest Kiss", 1931

Between 1950 and 1952, a bored weatherman, stationed north of Hudson
Bay, left a monument that neither government nor time can eradicate.
Using a bulldozer abandoned by the Air Force, he spent two years and
great effort pushing boulders into a single word.

It can be seen from 10,000 feet, silhouetted against the snow.
Government officials exchanged memos full of circumlocutions (no Latin
equivalent exists) but failed to word an appropriation bill for the
destruction of this cairn, that wouldn't alert the press and embarrass
both Parliament and Party.

It stands today, a monument to human spirit.  If life exists on other
planets, this may be the first message received from us.
		-- The Realist, November, 1964.

I will not play at tug o' war.
I'd rather play at hug o' war,
Where everyone hugs
Instead of tugs,
Where everyone giggles
And rolls on the rug,
Where everyone kisses,
And everyone grins,
And everyone cuddles,
And everyone wins.
		-- Shel Silverstein, "Hug o' War"

For my son, Robert, this is proving to be the high-point of his entire life
to date.  He has had his pajamas on for two, maybe three days now.  He has
the sense of joyful independence a 5-year-old child gets when he suddenly
realizes that he could be operating an acetylene torch in the coat closet
and neither parent [because of the flu] would have the strength to object.
He has been foraging for his own food, which means his diet consists
entirely of "food" substances which are advertised only on Saturday-morning
cartoon shows; substances that are the color of jukebox lights and that, for
legal reasons, have their names spelled wrong, as in New Creemy
Chok-'n'-Cheez Lumps o' Froot ("part of this complete breakfast").
		-- Dave Barry, "Molecular Homicide"

Your Co-worker Could Be a Space Alien, Say Experts
		...Here's How You Can Tell
Many Americans work side by side with space aliens who look human -- but you
can spot these visitors by looking for certain tip-offs, say experts. They
listed 10 signs to watch for:
    (3) Bizarre sense of humor.  Space aliens who don't understand
	earthly humor may laugh during a company training film or tell
	jokes that no one understands, said Steiger.
    (6) Misuses everyday items.  "A space alien may use correction
	fluid to paint its nails," said Steiger.
    (8) Secretive about personal life-style and home.  "An alien won't
	discuss details or talk about what it does at night or on weekends."
   (10) Displays a change of mood or physical reaction when near certain
	high-tech hardware.  "An alien may experience a mood change when
	a microwave oven is turned on," said Steiger.
The experts pointed out that a co-worker would have to display most if not
all of these traits before you can positively identify him as a space alien.
		-- National Enquirer, Michael Cassels, August, 1984.

	[I thought everybody laughed at company training films.  Ed.]

The basic idea behind malls is that they are more convenient than cities.
Cities contain streets, which are dangerous and crowded and difficult to
park in.  Malls, on the other hand, have parking lots, which are also
dangerous and crowded and difficult to park in, but -- here is the big
difference -- in mall parking lots, THERE ARE NO RULES.  You're allowed to
do anything.  You can drive as fast as you want in any direction you want.
I was once driving in a mall parking lot when my car was struck by a pickup
truck being driven backward by a squat man with a tattoo that said "Charlie"
on his forearm, who got out and explained to me, in great detail, why the
accident was my fault, his reasoning being that he was violent and muscular,
whereas I was neither.  This kind of reasoning is legally valid in mall
parking lots.
		-- Dave Barry, "Christmas Shopping: A Survivor's Guide"

Many mental processes admit of being roughly measured.  For instance,
the degree to which people are bored, by counting the number of their
fidgets. I not infrequently tried this method at the meetings of the
Royal Geographical Society, for even there dull memoirs are occasionally
read.  [...]  The use of a watch attracts attention, so I reckon time
by the number of my breathings, of which there are 15 in a minute.  They
are not counted mentally, but are punctuated by pressing with 15 fingers
successively.  The counting is reserved for the fidgets.  These observations
should be confined to persons of middle age.  Children are rarely still,
while elderly philosophers will sometimes remain rigid for minutes altogether.
		-- Francis Galton, 1909

	On the other hand, the TCP camp also has a phrase for OSI people.
There are lots of phrases.  My favorite is `nitwit' -- and the rationale
is the Internet philosophy has always been you have extremely bright,
non-partisan researchers look at a topic, do world-class research, do
several competing implementations, have a bake-off, determine what works
best, write it down and make that the standard.
	The OSI view is entirely opposite.  You take written contributions
from a much larger community, you put the contributions in a room of
committee people with, quite honestly, vast political differences and all
with their own political axes to grind, and four years later you get
something out, usually without it ever having been implemented once.
	So the Internet perspective is implement it, make it work well,
then write it down, whereas the OSI perspective is to agree on it, write
it down, circulate it a lot and now we'll see if anyone can implement it
after it's an international standard and every vendor in the world is
committed to it.  One of those processes is backwards, and I don't think
it takes a Lucasian professor of physics at Oxford to figure out which.
		-- Marshall Rose, "The Pied Piper of OSI"

FORTUNE DISCUSSES THE DIFFERENCES BETWEEN MEN AND WOMEN:	#2

Desserts:
	A woman will generally admire an ornate dessert for the artistic
work it is, praising its creator and waiting a suitable interval before
she reluctantly takes a small sliver off one edge.  A man will start by
grabbing the cherry in the center.

Car repair:
	The average man thinks his Y chromosome contains complete repair
manuals for every car made since World War II.  He will work on a problem
himself until it either goes away or turns into something that "can't be
fixed without special tools".
	The average woman thinks "that funny thump-thump noise" is an
accurate description of an automotive problem.  She will, however, have the
car serviced at the proper intervals and thereby incur fewer problems than
the average man.

What they said:
	What they meant:

"If you knew this person as well as I know him, you would think as much
of him as I do."
	(Or as little, to phrase it slightly more accurately.)
"Her input was always critical."
	(She never had a good word to say.)
"I have no doubt about his capability to do good work."
	(And it's nonexistent.)
"This candidate would lend balance to a department like yours, which
already has so many outstanding members."
	(Unless you already have a moron.)
"His presentation to my seminar last semester was truly remarkable:
one unbelievable result after another."
	(And we didn't believe them, either.)
"She is quite uniform in her approach to any function you may assign her."
	(In fact, to life in general...)

Pedro Guerrero was playing third base for the Los Angeles Dodgers in 1984
when he made the comment that earns him a place in my Hall of Fame.  Second
baseman Steve Sax was having trouble making his throws.  Other players were
diving, screaming, signaling for a fair catch.  At the same time, Guerrero,
at third, was making a few plays that weren't exactly soothing to manager
Tom Lasorda's stomach.  Lasorda decided it was time for one of his famous
motivational meetings and zeroed in on Guerrero: "How can you play third
base like that?  You've gotta be thinking about something besides baseball.
What is it?"
	"I'm only thinking about two things," Guerrero said.  "First, `I
hope they don't hit the ball to me.'"  The players snickered, and even
Lasorda had to fight off a laugh.  "Second, `I hope they don't hit the ball
to Sax.'"
		-- Joe Garagiola, "It's Anybody's Ball Game"

Do not allow this language (Ada) in its present state to be used in
applications where reliability is critical, i.e., nuclear power stations,
cruise missiles, early warning systems, anti-ballistic missle defense
systems.  The next rocket to go astray as a result of a programming language
error may not be an exploratory space rocket on a harmless trip to Venus:
It may be a nuclear warhead exploding over one of our cities.  An unreliable
programming language generating unreliable programs constitutes a far
greater risk to our environment and to our society than unsafe cars, toxic
pesticides, or accidents at nuclear power stations.
- C. A. R. Hoare

There are two jazz musicians who are great buddies.  They hang out and play
together for years, virtually inseparable.  Unfortunately, one of them is
struck by a truck and killed.  About a week later his friend wakes up in
the middle of the night with a start because he can feel a presence in the
room.  He calls out, "Who's there?  Who's there?  What's going on?"
	"It's me -- Bob," replies a faraway voice.
	Excitedly he sits up in bed.  "Bob!  Bob!  Is that you?  Where are
you?"
	"Well," says the voice, "I'm in heaven now."
	"Heaven!  You're in heaven!  That's wonderful!  What's it like?"
	"It's great, man.  I gotta tell you, I'm jamming up here every day.
I'm playing with Bird, and 'Trane, and Count Basie drops in all the time!
Man it is smokin'!"
	"Oh, wow!" says his friend. "That sounds fantastic, tell me more,
tell me more!"
	"Let me put it this way," continues the voice.  "There's good news
and bad news.  The good news is that these guys are in top form.  I mean
I have *never* heard them sound better.  They are *wailing* up here."
	"The bad news is that God has this girlfriend that sings..."

...Another writer again agreed with all my generalities, but said that as an
inveterate skeptic I have closed my mind to the truth.  Most notably I have
ignored the evidence for an Earth that is six thousand years old.  Well, I
haven't ignored it; I considered the purported evidence and *then* rejected it.
There is a difference, and this is a difference, we might say, between
prejudice and postjudice.  Prejudice is making a judgment before you have
looked at the facts.  Postjudice is making a judgment afterwards.  Prejudice
is terrible, in the sense that you commit injustices and you make serious
mistakes.  Postjudice is not terrible.  You can't be perfect of course; you
may make mistakes also.  But it is permissible to make a judgment after you
have examined the evidence.  In some circles it is even encouraged.
- Carl Sagan, The Burden of Skepticism, Skeptical Enquirer, Vol. 12, pg. 46

	A sheet of paper crossed my desk the other day and as I read it,
realization of a basic truth came over me.  So simple!  So obvious we couldn't
see it.  John Knivlen, Chairman of Polamar Repeater Club, an amateur radio
group, had discovered how IC circuits work.  He says that smoke is the thing
that makes ICs work because every time you let the smoke out of an IC circuit,
it stops working.  He claims to have verified this with thorough testing.
	I was flabbergasted!  Of course!  Smoke makes all things electrical
work.  Remember the last time smoke escaped from your Lucas voltage regulator
Didn't it quit working?  I sat and smiled like an idiot as more of the truth
dawned.  It's the wiring harness that carries the smoke from one device to
another in your Mini, MG or Jag.  And when the harness springs a leak, it lets
the smoke out of everything at once, and then nothing works.  The starter motor
requires large quantities of smoke to operate properly, and that's why the wire
going to it is so large.
	Feeling very smug, I continued to expand my hypothesis.  Why are Lucas
electronics more likely to leak than say Bosch?  Hmmm...  Aha!!!  Lucas is
British, and all things British leak!  British convertible tops leak water,
British engines leak oil, British displacer units leak hydrostatic fluid, and
I might add Brititsh tires leak air, and the British defense unit leaks
secrets... so naturally British electronics leak smoke.
		-- Jack Banton, PCC Automotive Electrical School

	[Ummm ... IC circuits?  Integrated circuit circuits?]

Once there was a little nerd who loved to read your mail,
And then yank back the i-access times to get hackers off his tail,
And once as he finished reading from the secretary's spool,
He wrote a rude rejection to her boyfriend (how uncool!)
And this as delivermail did work and he ran his backfstat,
He heard an awful crackling like rat fritters in hot fat,
And hard errors brought the system down 'fore he could even shout!
	And the bio bug'll bring yours down too, ef you don't watch out!
And once they was a little flake who'd prowl through the uulog,
And when he went to his blit that night to play at being god,
The ops all heard him holler, and they to the console dashed,
But when they did a ps -ut they found the system crashed!
Oh, the wizards adb'd the dumps and did the system trace,
And worked on the file system 'til the disk head was hot paste,
But all they ever found was this:  "panic: never doubt",
	And the bio bug'll crash your box too, ef you don't watch out!
When the day is done and the moon comes out,
And you hear the printer whining and the rk's seems to count,
When the other desks are empty and their terminals glassy grey,
And the load is only 1.6 and you wonder if it'll stay,
You must mind the file protections and not snoop around,
	Or the bio bug'll getcha and bring the system down!
