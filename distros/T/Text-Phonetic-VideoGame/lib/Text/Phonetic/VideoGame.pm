package Text::Phonetic::VideoGame;
use warnings;
use strict;
use base 'Text::Phonetic';

use String::Nysiis;
use Roman ();
use Lingua::EN::Inflect::Number qw( to_S );
use List::MoreUtils qw( uniq );

our $VERSION = '0.05';
my %ordinal = (
    '1st' => 'first',
    '2nd' => 'second',
    '3rd' => 'third',
    '4th' => 'fourth',
    '5th' => 'fifth',
    '6th' => 'sixth',
    '7th' => 'seventh',
    '8th' => 'eighth',
    '9th' => 'ninth',
);
my %abbreviation = (
    breathe => 'breath',   # NYSIIS handles this case poorly
    bros => 'brothers',
    csi  => 'crime scene investigation',
    ddr  => 'dance dance revolution',
    doa  => 'dead or alive',
    dora => 'dora the explorer',
    ff   => 'final fantasy',
    gta  => 'grand theft auto',
    iss  => 'international superstar soccer',
    kotr => 'knights of the old republic',
    le   => 'limited edition',
    mlb  => 'major league baseball',
    motocross => 'motorcross',
    mr   => 'mister',
    nam  => 'vietnam',
    ny   => 'new york',
    pbr  => 'pro bull riders',
    pgr  => 'project gotham racing',
    rabbids => 'raving rabbids',
    spongebob => 'spongebob squarepants',
    spyro => 'legend spyro',
    t2   => 'terminator 2',
    tmnt => 'teenage mutant ninja turtles',
    w => 'with',   # w/ before removing slashes becomes w
    wwf  => 'wwe',
    xtreme => 'extreme',
    zelda => 'the legend of zelda',


    # easier than using a words to numbers module
    eighteen => 18,

    # easier than using split_compound_word
    bustamove => 'bust a move',
    davinci   => 'da vinci',
    fzero     => 'f zero',
    motogp    => 'moto gp',
    mysims    => 'my sims',
    proam     => 'pro am',
    rtype     => 'r type',
    xmen      => 'x men',
);
my $publishers = join '|', (
    'disney',
    'disneys',
    'ea',
    'hasbro',
    'james camerons',
    'sega',
    'tom clancys',
    'mobile suit',  # not a publisher. commonly omitted "gundam" prefix
);

sub _do_encode {
    my $self   = shift;
    my $string = lc shift;
    my $original = $string;

    $string =~ s{[-/:]}{ }g;     # dashes, slashes are like spaces
    $string =~ s/[&.'",]//g;     # most punctuation can be ignored

    # remove useless publisher names (usually found at the front)
    $string =~ s/^(?:$publishers)\b//;

    # expand some common abbreviations
    my $abbr = join '|', keys(%abbreviation);
    $string =~ s/\b($abbr)\b/$abbreviation{$1}/ge;

    $string =~ s/sk8/skate/g;
    $string =~ s/\b([1-9])(st|nd|rd|th)\b/$ordinal{"$1$2"}/ge;
    $string =~ s/\bv(\d)\b/volume $1/g;
    $string =~ s/\b(\d+)gb\b/$1 gb/g;      # 40GB -> 40 GB
    $string =~ s/\b2k([0-9])\b/200$1/ig;   # 2K4 -> 2004
    $string =~ s/\b(\d+)k\b/${1}000/g;       # 40K -> 40000
    $string =~ s/(\D)(\d)/$1 $2/g;  # "xbox360", "kombat4", etc

    # remove some noise words
    $string =~ s/\b(videogame|video game|as|ds|3d)\b//g;
    $string =~ s/\b(n|a|an|the|and|of|vs|at|in|for|if|game only|with)\b//g;
    $string =~ s/\b(edition|volume|vol|versus|game|games|used)\b//g;

    $string =~ s/\s+/ /g;
    $string =~ s/^\s+|\s+$//g; # remove leading/trailing spaces

    # do some in-place substitutions
    my @words = map { $self->split_compound_word($_) } split / /, $string;
    for my $word (@words) {
        $word = $self->word2num($word);
        next if $word eq 'mix';  # looks Roman but is rarely meant that way
        $word = Roman::arabic($word) if Roman::isroman($word);
    }

    my @encodings = map { /^\d+$/ ? $_ : String::Nysiis::nysiis($_) } @words;
    $string = join ' ', @encodings;

    # normalize numbers that might be years
    $string =~ s/\b(7|8|9)([0-9])\b/19$1$2/g;  # 97 -> 1997
    $string =~ s/\b(0|1|2)([0-9])\b/20$1$2/g;  # 03 -> 2003

    # remove redundant words
    $string =~ s/\b(\d+)\s\1\b/$1/g;    # 2 2 -> 2
    for ($string) {
        s/\bNANTAND\b//   if $original =~ /\bds\b/;      # Nintendo   <- DS
        s/\bNANTAND\b//   if $original =~ /\bwii\b/;     # Nintendo   <- Wii
        s/\bSACAR\b//     if $original =~ /\bfifa\b/;    # soccer     <- FIFA
        s/\bBASCATBAL\b// if $original =~ /\bnba\b/;     # basketball <- NBA
        s/\bFAT BAL\b//   if $original =~ /\bnfl\b/;     # football   <- NFL
        s/\bHACY\b//      if $original =~ /\bnhl\b/;     # hockey     <- NHL
    }
    for ($string) {
        s/\bNFL\b//    if /\bMAD DAN\b/;      # NFL      <- Madden
        s/\bGALF\b//   if /\bTAGAR WAD\b/;    # golf     <- Tiger Woods
        s/\bFAT BAL\b// if /\bBLAT\b/;        # football <- blitz
        s/\bHAGAG\b//  if /\bSANAC\b/;        # hedgehog <- Sonic
        s/\bCABAL\b//  if /\bDANGAR HAN\b/;   # Cabela's <- Dangerous Hunts
        s/\bBNX\b//    if /\bDAV MAR\b/;      # BMX      <- Dave Mirra
        s/\bW\b//      if /\bRASTL MAN\b/;    # WWE      <- Wrestlemania
        s/\bS\b//      if /\bRAN STANPY\b/;   # Show     <- Ren & Stimpy
        s/\bSPANG BAB\b// if /\bSGAR PAN\b/;  # Sponge Bob <- Square Pants
        s/\bRASC RANGAR\b// if /\bCAP DAL\b/; # Rescue Rangers <- Chip & Dale
        s/\bLAR CRAFT\b//   if /\bTANB RADAR\b/; # Lara Croft  <- Tomb Raider
    }

    $string =~ s/X\b/C/g;      # "TANX" -> "TANC" etc
    $string =~ s/\bCRASN\b/CRASAN/g;
    $string =~ s/\s+/ /g;
    $string =~ s/^\s+|\s+$//g; # remove leading/trailing spaces

    # remove duplicates and sort
    @words = uniq sort split /\s+/, $string;
    return join ' ', @words;
}

# returns an arabic numeral representation of number word
# ("five" -> 5). If the word is not a number word, returns the word.
sub word2num {
    my ($self, $word) = @_;
    my %words = (
        zero  => 0,
        one   => 1,
        two   => 2,
        three => 3,
        four  => 4,
        five  => 5,
        six   => 6,
        seven => 7,
        eight => 8,
        nine  => 9,
    );
    return $words{$word} if exists $words{$word};
    return $word;
}

sub split_compound_word {
    my ( $self, $word ) = @_;

    # don't produce subwords less than 3 characters
    my $length = length $word;
    return $word if $length < 6;

    # try to split the word into smaller two smaller words
    for my $i ( 3 .. $length-3 ) {
        my $front = substr $word, 0, $i;
        my $back  = substr $word, $i;
        return ( $front, $back )
          if $self->is_word($front)
          and $self->is_word($back);
        return ( $front, $back )
          if $self->is_word( to_S $front )
          and $self->is_word( to_S $back );
    }

    return $word;
}

# a hand picked dictionary of short nouns and adjectives
my %dictionary = map { $_ => 1 } qw(
    acid
    acme
    acne
    acre
    act
    aeon
    aero
    after
    age
    aid
    air
    all
    alpha
    ammo
    anal
    andreas
    anti
    apex
    aqua
    arch
    area
    arm
    arms
    army
    ash
    assault
    astro
    atom
    aunt
    aura
    axe
    axes
    axle
    axon
    baby
    back
    bad
    bag
    bail
    bain
    bait
    bald
    bale
    ball
    band
    bane
    bang
    bank
    bar
    barb
    bark
    barn
    baru
    base
    bass
    bath
    bats
    battle
    bead
    beam
    bean
    bear
    beat
    beef
    beer
    beet
    bell
    belt
    best
    big
    bike
    bird
    bite
    blade
    blast
    blind
    blob
    blood
    blue
    boar
    boat
    bob
    body
    bomb
    bomber
    bond
    bone
    book
    boom
    boot
    boss
    bot
    bound
    bow
    boy
    brain
    brat
    bread
    break
    brew
    buck
    bud
    bull
    bump
    bunk
    burger
    burner
    bush
    bust
    butt
    cage
    cake
    caliber
    calibur
    call
    camp
    cane
    car
    card
    cart
    cat
    chip
    chrome
    chum
    city
    clay
    clod
    clown
    club
    coal
    coaster
    coat
    cog
    coke
    comb
    cook
    corn
    corp
    corps
    craft
    crew
    crib
    crop
    cross
    crow
    cry
    cube
    cup
    cyan
    dam
    dart
    dash
    data
    date
    dawn
    day
    days
    dead
    deaf
    debt
    deck
    den
    dent
    diet
    dime
    dino
    dock
    dog
    dogs
    donkey
    doo
    dope
    dorm
    double
    down
    drag
    dragon
    dream
    drip
    drop
    dry
    dual
    duck
    duct
    dude
    due
    duel
    dump
    dust
    duty
    ear
    earth
    east
    eat
    edit
    eel
    egg
    elf
    elk
    elm
    end
    epic
    ever
    excite
    exit
    extra
    eye
    face
    fad
    fake
    fall
    fan
    far
    fare
    fat
    fear
    feat
    fest
    field
    fighter
    film
    fire
    fit
    flag
    flat
    fly
    foal
    foil
    fold
    food
    fool
    foot
    force
    fort
    fox
    francisco
    free
    front
    fuel
    fun
    fury
    fuse
    game
    garb
    gash
    gate
    geek
    gem
    gene
    germ
    ghost
    gig
    girl
    glen
    glue
    gnat
    goal
    goat
    god
    gold
    golden
    golf
    good
    goof
    grad
    gram
    grave
    gray
    green
    grey
    grid
    grog
    ground
    grub
    gun
    guy
    gym
    hair
    halo
    hand
    hang
    harm
    hat
    hawk
    head
    heart
    heat
    heel
    helm
    help
    herb
    herd
    high
    hiss
    hit
    hive
    hobo
    holy
    home
    hot
    hounds
    hour
    house
    howl
    hub
    hunter
    hurt
    hymn
    ice
    idea
    idol
    inch
    iris
    isle
    ivy
    jade
    jaw
    jazz
    jeep
    jig
    jive
    job
    joke
    jot
    jug
    jump
    junk
    kart
    keel
    keep
    kill
    king
    kong
    kingdom
    kit
    kite
    knob
    lacy
    lady
    lake
    lamb
    lamp
    land
    lane
    lank
    lap
    law
    lead
    leaf
    leg
    life
    light
    lily
    limb
    lime
    lip
    list
    loaf
    loan
    lock
    locked
    long
    loot
    loud
    love
    low
    mad
    mail
    man
    mania
    mario
    master
    mate
    maze
    mech
    mega
    melt
    mesh
    mess
    metal
    metroid
    milk
    mint
    mix
    moat
    monk
    monkey
    moon
    moss
    mote
    motor
    mud
    myth
    name
    navy
    night
    nine
    ninja
    north
    nuke
    oak
    oar
    odd
    odor
    off
    ogre
    old
    one
    out
    owl
    pac
    pack
    page
    palm
    pant
    paper
    parents
    park
    pawn
    pay
    peer
    pilot
    ping
    pint
    pixy
    play
    poem
    poet
    pole
    poll
    pong
    power
    pray
    prey
    prime
    pro
    puck
    puff
    pug
    pump
    pun
    punch
    pure
    quiz
    race
    rag
    rage
    rain
    ranger
    rant
    rap
    rare
    rayne
    realm
    red
    rich
    ride
    rig
    riot
    road
    rock
    roll
    roller
    roof
    rook
    room
    root
    rope
    rose
    row
    ruby
    rump
    rust
    rye
    sack
    sale
    salt
    san
    sanity
    sash
    scab
    scooby
    seal
    seam
    seat
    sect
    self
    sew
    shadow
    shell
    shift
    ship
    shock
    shoot
    shore
    sick
    side
    sign
    silk
    silo
    sim
    sink
    six
    skin
    skit
    slam
    slug
    slum
    smart
    smash
    smog
    snow
    soap
    sock
    sofa
    soft
    soul
    sound
    soup
    sour
    south
    speed
    spider
    splitter
    sponge
    spot
    spy
    square
    star
    start
    station
    steel
    stem
    step
    stew
    stool
    story
    street
    strike
    stunt
    super
    swim
    switch
    tail
    take
    talk
    tall
    tank
    tanx
    task
    tax
    team
    tear
    tech
    teck
    teen
    temp
    text
    thin
    thru
    thunder
    tick
    tide
    tiger
    time
    toad
    toe
    toll
    tomb
    tome
    tot
    toy
    trap
    tree
    tropic
    tube
    tusk
    twin
    ultra
    under
    user
    vain
    veil
    vein
    vest
    vial
    visa
    vote
    vow
    wage
    waker
    walker
    war
    ward
    ware
    wario
    warp
    wart
    wasp
    wave
    weak
    weal
    web
    west
    wet
    wheel
    whip
    wick
    wii
    wind
    wine
    wing
    wise
    wolf
    womb
    wonder
    wood
    world
    worm
    wrestle
    yard
    yarn
    year
    york
    zero
    zone
    zoom
);
sub is_word {
    my ($self, $word) = @_;
    return $dictionary{ lc $word };
}

1;

=head1 NAME

Text::Phonetic::VideoGame - phonetic encoding for video game titles

=head1 SYNOPSIS

    use Text::Phonetic::VideoGame;
    my $phonetic = Text::Phonetic::VideoGame->new;
    my $first = $phonetic->encode('super smash brothers');
    my $second = $phonetic->encode('Super Smash Bros.');
    warn "They match\n" if $first eq $second;

    warn "They match\n" if $phonetic->compare('ff 7', 'final fantasy vii');

This module implements a phonetic algorithm for the comparison of video game
titles.  It uses L<String::Nysiis> to disambiguate common English typos and
adds additional rules which apply specifically to typos in video game titles.

The module implements the L<Text::Phonetic> interface.  See that documentation
for details about the interface.

=head1 METHODS

See L<Text::Phonetic>.

=head1 VARIATIONS HANDLED

=head2 Common English Typos

L<String::Nysiis> handles common English typos such as misspellings of proper
names which makes titles like "adams family" match "addams family".

=head2 Punctuation Variants

Most punctuation and its variants are handled correctly.  For instance "tom &
jerry" and "tom and jerry" or "Lord of the Rings: Two Towers" with and without
the colon.

=head2 Common Abbreviations

Abbreviations such as "bros" for "brothers" and "TMNT" for "Teenage Mutant
Ninja Turtles".

=head2 Canonical Years

The titles "NFL 2004", "NFL '04" and "NFL 2K4" all hash to the same code.

=head2 Canonical Numbers

Roman numerals, ordinal numbers and spelled out numbers are recognized as
being equal.

=head2 Compound Words

The game titles "mega man" and "megaman" are recognized as being identical.

=head2 Word Order

The order of certain parts of a title are often confused.  For instance,
"Sonic Adventure 2: Battle" and "Sonic Adventure: Battle 2" both indicate the
same game.

=head1 AUTHOR

Michael Hendricks, C<< <michael@ndrix.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-phonetic-videogame at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Phonetic-VideoGame>.  I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

The source code is available on GitHub:
L<http://github.com/mndrix/Text-Phonetic-VideoGame>  Patches and pull requests
are welcome.

=head1 ACKNOWLEDGEMENTS

Thanks to JJGames (L<http://www.jjgames.com>) and Video Game Price Charts
(L<http://vgpc.com>) for sponsoring development of this module.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Hendricks, all rights reserved.

This program is released under the following license: MIT
