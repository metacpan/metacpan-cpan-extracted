use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::Exception;
use Data::Dumper;

use_ok('Word::Anagram');

#-------------------------------------------------------------------------------

# test instantiation
{
  my $obj = Word::Anagram->new;
  isa_ok($obj, 'Word::Anagram');

} 

#-------------------------------------------------------------------------------

# test are_anagrams
{
	my $obj = Word::Anagram->new;
	my ($word1, $word2) = qw( Leon Noel );
	my $bool = $obj->are_anagrams($word1, $word2);
	cmp_ok($bool, '==', 1, 'are_anagrams');
}

#-------------------------------------------------------------------------------

# test get_anagrams_of
{
	my $obj = Word::Anagram->new;
	my $word = 'ABC';
	my $anag = $obj->get_anagrams_of($word);
	is_deeply( [ sort @$anag ], [ sort qw(ABC ACB BAC BCA CAB CBA) ] , 'get_anagrams_of');
	
	{ $" = "\t"; print "\nget_anagrams_of '$word' has anagrams:\n\t@$anag\n\n";} # for DEBU
}

#-------------------------------------------------------------------------------

# test get_anagrams_of
{
	my $obj = Word::Anagram->new;
	my $word = 'ABBA';
	my $anag = $obj->get_anagrams_of($word);
	is_deeply( [ sort @$anag ], [ sort qw(AABB ABAB ABBA BAAB BABA BBAA) ] , 'get_anagrams_of');

	{ $" = "\t"; print "\nget_anagrams_of '$word' has anagrams:\n\t@$anag\n\n";} # for DEBUG
}

#-------------------------------------------------------------------------------

# test get_anagrams_of
{
	my $obj = Word::Anagram->new;
	my $word = 'LEON';
	my $anag = $obj->get_anagrams_of($word);
	is_deeply( [ sort @$anag ], [ sort qw( ELNO    ELON    ENLO    ENOL    EOLN    EONL    LENO    LEON    LNEO    LNOE    LOEN    LONE    NELO    NEOL    NLEO    NLOE    NOEL    NOLE    OELN    OENL    OLEN    OLNE    ONEL    ONLE) ] , 'get_anagrams_of');

	{ $" = "\t"; print "\nget_anagrams_of '$word' has anagrams:\n\t@$anag\n\n";} # for DEBUG
}

#-------------------------------------------------------------------------------

# test select_anagrams
{
	my $obj = Word::Anagram->new;
	my @words = qw(ALU	AMA	Abe	Amy	Ann	BCD	BTW	Ben	CDT	CIA	CPA	CPR	CRT	CST	Cal	DAG	DNA	Dec	Doc	Dow	EEG	EPA	Eli	Esp	Eva	FBI	FCC	FDA	FTP	Feb	Fri	GNP	GSA	Gus	Hal	ICC	ISO	ITT	IUD	Jan	Jew	Jim	Joe	Jon	KGB	Kay	Kim	Leo	Loy	Ltd	MAG	MBA	MDT	MIG	MPH	MST	MTS	MTV	Mac	Mao	Mel	Mon	NBC	NBS	NCC	NCR	NSF	Nan	Nat	PBS	PDT	PST	PTA	Pam	Poe	RCA	RMS	RPM	Rev	Rex	Rio	Ron	Sol	TNT	TRW	TTL	TVA	TWA	Tex	Thu	Tim	Tue	USA	Uzi	VGA	VHF	Vic	Vol	WFF	WWW	XOR	Zen	aha	ala	alp	boa	bop	bpi	cam	cog	con	coy	cud	d's	dab	doe	dud	dun	e's	eta	f's	fad	fax	fib	flu	fob	fop	fro	g's	gab	gal	gee	git	gnu	gob	gyp	h's	haw	hob	hoc	hon	hoy	i's	ilk	j's	jag	k's	keg	l's	las	lax	lbs	lex	lob	lop	lug	lye	m's	maw	mil	mod	moo	mum	n's	nab	nee	nob	nth	o's	oaf	ohm	ova	p's	pap	phi	pip	pol	pow	psi	pus	q's	r's	rho	s's	sax	sic	sis	sop	sow	sox	soy	sys	tao	tee	thy	tic	tog	tot	tum	tun	tut	vet	viz	wad	wok	won	wop	wow	wry	yap	yaw	yen	yin	yip	yow	yup	zag	zig	zip );
	my $anag = $obj->select_anagrams(\@words);
	is_deeply( [ sort @$anag ], [ sort qw(Ann EEG FBI FDA MST MTS Mac Nan cam fad fib gee lop pol pow wop) ] , 'select_anagrams');

	{ $" = "\t"; print "\nselect_anagrams from these words \n\t@words \n are:\n\t@$anag\n\n";} # for DEBUG
}

#-------------------------------------------------------------------------------


# test find_word_in
{
	my $obj = Word::Anagram->new;
	my $word = 'LeNo';
	my @words = qw(ARCO	ARPA	Acta	Adam	Ajax	Al's	Alan	Alec	Aler	Alex	Alfa	Amos	Andy	Anna	Anne	Avis	Aviv	Avon	Bali	Benz	Bern	Bert	Bess	Blvd	Boer	Bohr	Bonn	Borg	Bose	Bryn	Budd	Burt	CACM	Cain	Capt	Carl	Chad	Chen	Clio	Cohn	Corp	Cree	Cuba	Dade	Dali	Daly	Dane	Dave	Davy	Dept	Dion	Dora	Doug	Dyke	Earp	Edna	Elba	Ella	Emma	Enos	Eric	Erie	Erik	Eros	Ewen	Ezra	FAQs	Falk	Fess	Finn	Fisk	Fran	Frau	Fred	Frey	Fuji	Gail	Gary	Gaul	Gogh	Gris	Guam	Gwen	Hans	Hera	Herr	Hess	Hopi	Howe	Huck	Huey	Hugh	Hugo	Hume	IUDs	Igor	Inca	Indy	Iowa	Iraq	Irma	Ivan	Jake	Jane	Java	Jeff	Jews	Joan	Jodi	Jody	Joel	Joes	Jose	Jove	Juan	Jude	Judy	Juno	Kant	Karl	Kate	Kent	Kiel	Kiev	Kirk	Klan	Knox	Koch	Kong	Kris	Kurd	Kurt	Kyle	LIFO	Laos	Lars	Leon	Levi	Lima	Lisa	Liss	Lois	Lola	Lucy	Luke	Luna	Lynn	Lyon	MIGs	MIMD	Mach	Marx	Mawr	Maya	Mick	Mimi	Mira	Muir	NASA	NATO	NCAA	NOAA	NYSE	NaCl	Nash	Nate	Nero	Nile	Nina	Noah	Noel	O'Er	OK's	OPEC	Olaf	Oleg	Olga	Oman	Opel	Oslo	Otto	Ovid	Owen	Paul	Penn	Peru	Pete	Phil	Pisa	Pitt	Pius	Polk	RISC	ROTC	RSVP	Rand	Rhea	Ritz	Rome	Rosa	Ross	Roth	Roxy	Rudy	Russ	Ruth	Ryan	SCSI	SIMD	SMSA	SPSS	Salk	Sara	Saud	Scot	Sikh	Siva	Skye	Slav	Stan	Styx	Suez	Taft	Tara	Tate	Tess	Thai	Thor	Tims	Tito	Todd	Togo	Toni	Toto	USAF	USDA	USPS	USSR	Ursa	VLSI	Vail	Vega	Venn	Vera	Vern	Viet	Waco	Walt	Wang	YMCA	YWCA	Yale	Yuba	Yuri	Yves	Zeus	Zion	afro	ahem	ahoy	arty	ashy	assn	berg	bldg	boas	bock	bogy	bolo	bona	boxy	brad	burg	cams	cant	carp	cede	chaw	chic	chow	chub	chug	ciao	clot	cloy	coda	coed	cogs	cola	coma	conk	conn	cosy	coup	craw	crud	curd	dabs	dais	dang	dank	daub	deft	deja	deli	deus	dick	diem	dill	ding	diva	doff	dolt	dorm	dour	dram	dreg	drib	drub	duce	duct	duds	duet	duff	dung	dunk	dupe	dyad	e'er	eave	eden	edgy	elan	etas	exec	fads	faun	faze	fend	fest	fete	fiat	fide	fief	fink	fizz	flak	flam	flex	floe	flog	flub	flue	flux	foal	fops	foxy	fuck	funk	furl	fuzz	gala	gals	gawk	geek	geld	gent	gibe	gila	gist	glib	glim	glob	glum	glut	gnus	goof	gout	grad	grok	gunk	gyro	halo	hank	hasp	heck	heft	hewn	hick	hobo	hock	homo	hong	honk	hors	hove	hulk	ibid	ibis	iffy	info	iota	ipso	jess	jibe	jilt	jinx	jive	jock	joey	josh	joss	jowl	judo	juju	juke	jute	kcal	kegs	kelp	keno	khan	kink	lank	laud	leek	lice	lilt	loam	loge	loll	lope	lops	luge	lugs	lulu	lush	luxe	mack	magi	maul	mesa	midi	mike	mime	mini	mods	moll	moos	mope	mull	muon	murk	mush	muss	mutt	nary	neon	nosy	nova	nude	oafs	obit	oboe	ohms	oldy	omni	onus	onyx	opus	ouch	oust	ouzo	owly	perk	pert	pica	pimp	pion	pixy	plop	pock	pogo	pons	pooh	posh	pram	prep	prig	prim	prod	prof	puck	puke	puma	punk	putt	pyre	quad	quip	racy	raze	redo	reek	reps	rink	roil	rood	rube	rune	runt	ruse	rusk	saga	sari	scab	scat	semi	sept	sewn	sexy	shag	shah	shaw	shim	shoo	silo	situ	skat	skid	skit	slag	slaw	slob	sloe	slog	smut	snag	snip	snob	snub	soma	sops	sown	soya	spar	spay	spec	spew	spic	spud	sqrt	swab	swag	swat	swig	taco	tamp	taos	tarp	teal	teat	tech	tees	temp	tern	thou	tiff	tine	tofu	togs	tome	tong	tonk	tony	toot	tori	tort	tory	tote	tots	tout	tram	trig	trio	troy	tsar	tuba	tuna	tung	turk	tusk	tutu	twit	typo	urea	vain	vamp	vise	viva	vive	vivo	wads	wale	watt	wavy	welt	wham	whee	whet	whig	whir	whoa	whop	wimp	wino	winy	wive	wold	wops	yaks	yang	yawl	yaws	yoga	yogi	yolk	yore	yowl	yule	zags	zeta	zing	zips );
	my $anag = $obj->find_word_in($word, \@words);
	is_deeply( [ sort @$anag ], [ sort qw(Leon Noel) ] , 'find_word_in');
	
	{ $" = "\t"; print "\nFor '$word', in words \n\t@words \n are anagrams:\n\t@$anag\n\n";} # for DEBUG
}


done_testing();