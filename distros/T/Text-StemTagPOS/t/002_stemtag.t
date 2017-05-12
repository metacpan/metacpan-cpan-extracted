# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok( 'Text::StemTagPOS' ); }

my $object = Text::StemTagPOS->new ();
isa_ok ($object, 'Text::StemTagPOS');
ok (testStemPosTaggingEN (), 'Testing English stemmer and part-of-speech tagger.');
#ok (testStemPosTaggingDE (), 'German parser appears to work.');

# return the relative error between two vectors.
sub getError
{
  my ($Counts1, $Counts2) = @_;

  my $error = 0;
  my $sum = 0;
  foreach my $key (keys %$Counts1)
  {
    my $original = 0;
    $original = $Counts1->{$key} if exists $Counts1->{$key};

    my $approximation = 0;
    $approximation = $Counts2->{$key} if exists $Counts2->{$key};

    $error = abs ($original - $approximation);
    $sum += $original;
  }
  $sum = 1 unless $sum;
  $error /= $sum;
  return abs ($error);
}


sub testStemPosTaggingEN
{
  my $maxErrorPercentage = 0.0001;
  my $tagger = Text::StemTagPOS->new ();
  my ($text, $originalWordCounts, $originalStemmedWordCounts, $originalTagCounts) = getTestData (0);
  my $stemmedTaggedText = $tagger->getStemmedAndTaggedText ($text);
  my ($wordCounts, $stemmedWordCounts, $tagCounts) = getTokenTagCounts ($stemmedTaggedText);
  return 0 if (getError ($originalWordCounts, $wordCounts) > $maxErrorPercentage);
  return 0 if (getError ($originalWordCounts, $stemmedWordCounts) > $maxErrorPercentage);
  return 0 if (getError ($originalTagCounts, $tagCounts) > $maxErrorPercentage);
  return 1;
}

sub testStemPosTaggingDE
{
  my $maxErrorPercentage = 0.0001;
  my $tagger = Text::StemTagPOS->new (isoLangCode => 'de');
  my ($text, $originalWordCounts, $originalStemmedWordCounts, $originalTagCounts) = getTestData (1);
  my $stemmedTaggedText = $tagger->getStemmedAndTaggedText ($text);
  my ($wordCounts, $stemmedWordCounts, $tagCounts) = getTokenTagCounts ($stemmedTaggedText);
  writeHashAsArray ($wordCounts);
  writeHashAsArray ($stemmedWordCounts);
  writeHashAsArray ($tagCounts);


  return 0 if (getError ($originalWordCounts, $wordCounts) > $maxErrorPercentage);
  return 0 if (getError ($originalWordCounts, $stemmedWordCounts) > $maxErrorPercentage);
  return 0 if (getError ($originalTagCounts, $tagCounts) > $maxErrorPercentage);


  return 1;
}


sub getTokenTagCounts
{
  my $TaggedText = shift;

  my %tokenCounts;
  my %stemmedtokenCounts;
  my %tagCounts;

  foreach my $sentence (@$TaggedText)
  {
    foreach my $word (@$sentence)
    {
      $tokenCounts{$word->[Text::StemTagPOS::WORD_ORIGINAL]} = 0 unless exists $tokenCounts{$word->[Text::StemTagPOS::WORD_ORIGINAL]};
      $tokenCounts{$word->[Text::StemTagPOS::WORD_ORIGINAL]}++;

      $stemmedtokenCounts{$word->[Text::StemTagPOS::WORD_STEMMED]} = 0 unless exists $stemmedtokenCounts{$word->[Text::StemTagPOS::WORD_STEMMED]};
      $stemmedtokenCounts{$word->[Text::StemTagPOS::WORD_STEMMED]}++;

      $tagCounts{$word->[Text::StemTagPOS::WORD_POSTAG]} = 0 unless exists $tagCounts{$word->[Text::StemTagPOS::WORD_POSTAG]};
      $tagCounts{$word->[Text::StemTagPOS::WORD_POSTAG]}++;
    }
  }

  return (\%tokenCounts, \%stemmedtokenCounts, \%tagCounts);
}


# get the samples of public domain text used for testing.
sub getTestData
{
  my $TextNo = shift;
  $TextNo = 0 unless defined $TextNo;

  if ($TextNo == 0)
  {
    my $text =
      'The studio was filled with the rich odor of roses, and when the light summer wind stirred amidst the trees of the garden there came through the open door the heavy scent of the lilac, or the more delicate perfume of the pink-flowering thorn.

From the corner of the divan of Persian saddle-bags on which he was lying, smoking, as usual, innumerable cigarettes, Lord Henry Wotton could just catch the gleam of the honey-sweet and honey-colored blossoms of the laburnum, whose tremulous branches seemed hardly able to bear the burden of a beauty so flame-like as theirs; and now and then the fantastic shadows of birds in flight flitted across the long tussore-silk curtains that were stretched in front of the huge window, producing a kind of momentary Japanese effect, and making him think of those pallid jade-faced painters who, in an art that is necessarily immobile, seek to convey the sense of swiftness and motion. The sullen murmur of the bees shouldering their way through the long unmown grass, or circling with monotonous insistence round the black-crocketed spires of the early June hollyhocks, seemed to make the stillness more oppressive, and the dim roar of London was like the bourdon note of a distant organ.

In the centre of the room, clamped to an upright easel, stood the full-length portrait of a young man of extraordinary personal beauty, and in front of it, some little distance away, was sitting the artist himself, Basil Hallward, whose sudden disappearance some years ago caused, at the time, such public excitement, and gave rise to so many strange conjectures.

As he looked at the gracious and comely form he had so skilfully mirrored in his art, a smile of pleasure passed across his face, and seemed about to linger there. But he suddenly started up, and, closing [4] his eyes, placed his fingers upon the lids, as though he sought to imprison within his brain some curious dream from which he feared he might awake.

"It is your best work, Basil, the best thing you have ever done," said Lord Henry, languidly. "You must certainly send it next year to the Grosvenor. The Academy is too large and too vulgar. The Grosvenor is the only place."

"I don\'t think I will send it anywhere," he answered, tossing his head back in that odd way that used to make his friends laugh at him at Oxford. "No: I won\'t send it anywhere."

Lord Henry elevated his eyebrows, and looked at him in amazement through the thin blue wreaths of smoke that curled up in such fanciful whorls from his heavy opium-tainted cigarette. "Not send it anywhere? My dear fellow, why? Have you any reason? What odd chaps you painters are! You do anything in the world to gain a reputation. As soon as you have one, you seem to want to throw it away. It is silly of you, for there is only one thing in the world worse than being talked about, and that is not being talked about. A portrait like this would set you far above all the young men in England, and make the old men quite jealous, if old men are ever capable of any emotion."

"I know you will laugh at me," he replied, "but I really can\'t exhibit it. I have put too much of myself into it."

Lord Henry stretched his long legs out on the divan and shook with laughter.';

    my %wordCounts = ('you',8,'full-length',1,'immobile',1,'form',1,'put',1,'many',1,'heavy',2,'easel',1,'trees',1,'perfume',1,'light',1,'old',2,'awake',1,'unmown',1,'odd',2,'used',1,'In',1,'though',1,'elevated',1,'time',1,'of',27,'n\'t',3,'round',1,'necessarily',1,'all',1,'tremulous',1,'being',2,'wind',1,'will',2,'much',1,'Oxford',1,'exhibit',1,'closing',1,'when',1,'throw',1,'said',1,'silly',1,'man',1,'flight',1,'You',2,'laburnum',1,'way',2,'a',6,'would',1,'gracious',1,'birds',1,'might',1,'in',11,'placed',1,'sitting',1,'quite',1,'upon',1,'Wotton',1,'only',2,'swiftness',1,'me',1,'momentary',1,'innumerable',1,'wo',1,'excitement',1,'upright',1,'eyes',1,'The',4,'hollyhocks',1,'looked',2,'whose',2,'pleasure',1,'My',1,'public',1,'beauty',2,'huge',1,'bourdon',1,'insistence',1,'legs',1,']',1,'back',1,'extraordinary',1,'note',1,'there',3,'saddle-bags',1,'blossoms',1,'anywhere',3,'as',4,'spires',1,'why',1,'started',1,'filled',1,'Lord',4,'It',2,'talked',2,'know',1,',',45,'jade-faced',1,'shouldering',1,'imprison',1,'circling',1,'on',2,'disappearance',1,'producing',1,'comely',1,'linger',1,'out',1,'shadows',1,'fingers',1,'reason',1,'cigarettes',1,'theirs',1,'murmur',1,'seem',1,'came',1,'suddenly',1,'must',1,'Persian',1,'front',2,'into',1,'seemed',3,'whorls',1,'stretched',2,'kind',1,'But',1,'making',1,'clamped',1,'really',1,'[',1,'stillness',1,'smoke',1,'able',1,'\'\'',7,'curtains',1,'ca',1,'work',1,'ago',1,'roses',1,'flame-like',1,'little',1,'now',1,'then',1,'divan',2,'Henry',4,'fantastic',1,'bear',1,'about',3,'centre',1,'honey-sweet',1,'As',2,'painters',2,'stirred',1,'languidly',1,'skilfully',1,'those',1,'mirrored',1,'their',1,'I',6,'away',2,'best',2,'ever',2,'send',4,'bees',1,'reputation',1,'What',1,'up',2,'June',1,'lids',1,';',1,'vulgar',1,'he',9,'Hallward',1,'artist',1,'was',4,'seek',1,'want',1,'which',2,'far',1,'if',1,'convey',1,'him',3,'himself',1,'England',1,'black-crocketed',1,'London',1,'thorn',1,'open',1,'door',1,'your',1,'but',1,'and',17,'usual',1,'too',3,'answered',1,'roar',1,'lying',1,'is',7,'men',3,'dear',1,'No',1,'have',3,'think',2,'Academy',1,'!',1,'art',2,'distant',1,'it',8,'organ',1,'tussore-silk',1,'capable',1,'within',1,'fanciful',1,'were',1,'next',1,'conjectures',1,'gleam',1,'flitted',1,'like',2,'head',1,'lilac',1,'studio',1,'anything',1,'summer',1,'passed',1,'fellow',1,'?',3,'gave',1,'myself',1,'worse',1,'smile',1,':',1,'Have',1,'rich',1,'personal',1,'his',10,'branches',1,'make',3,'across',2,'through',3,'thing',2,'From',1,'distance',1,'caused',1,'rise',1,'not',1,'that',6,'odor',1,'Grosvenor',2,'who',1,'years',1,'curled',1,'dim',1,'grass',1,'brain',1,'cigarette',1,'pallid',1,'one',2,'chaps',1,'hardly',1,'some',3,'with',3,'``',7,'emotion',1,'do',2,'garden',1,'face',1,'burden',1,'to',12,'from',2,'replied',1,'motion',1,'stood',1,'set',1,'opium-tainted',1,'sought',1,'effect',1,'any',2,'strange',1,'large',1,'delicate',1,'sense',1,'eyebrows',1,'amidst',1,'more',2,'an',2,'year',1,'the',42,'done',1,'friends',1,'sudden',1,'smoking',1,'certainly',1,'pink-flowering',1,'curious',1,'or',2,'dream',1,'laughter',1,'soon',1,'could',1,'amazement',1,'wreaths',1,'this',1,'monotonous',1,'feared',1,'so',3,'oppressive',1,'for',1,'gain',1,'such',2,'corner',1,'portrait',2,'tossing',1,'window',1,'world',2,'Japanese',1,'place',1,'are',2,'honey-colored',1,'young',2,'room',1,'blue',1,'above',1,'early',1,'long',3,'.',20,'at',6,'laugh',2,'Not',1,'A',1,'had',1,'thin',1,'sullen',1,'than',1,'Basil',2,'scent',1,'4',1,'just',1,'jealous',1,'catch',1,'shook',1);
    my %stemmedCounts = ('you',10,'full-length',1,'form',1,'hallward',1,'put',1,'my',1,'easel',1,'london',1,'sens',1,'what',1,'light',1,'old',2,'lord',4,'unmown',1,'odd',2,'though',1,'mirror',1,'time',1,'of',27,'n\'t',3,'round',1,'momentari',1,'all',1,'still',1,'wind',1,'will',2,'much',1,'extraordinari',1,'lie',1,'exhibit',1,'when',1,'throw',1,'said',1,'pass',1,'branch',1,'heavi',2,'man',1,'flight',1,'laburnum',1,'way',2,'centr',1,'a',7,'would',1,'whorl',1,'no',1,'realli',1,'gracious',1,'earli',1,'might',1,'in',12,'upon',1,'fanci',1,'flit',1,'me',1,'bee',1,'blossom',1,'wo',1,'upright',1,'eyebrow',1,'whose',2,'wors',1,'public',1,'huge',1,'bourdon',1,']',1,'monoton',1,'perfum',1,'back',1,'note',1,'there',3,'as',6,'eye',1,'know',1,'tree',1,'stretch',2,',',45,'imprison',1,'strang',1,'honey-color',1,'on',2,'curl',1,'linger',1,'out',1,'reason',1,'emot',1,'murmur',1,'came',1,'seem',4,'hard',1,'leg',1,'must',1,'front',2,'jade-fac',1,'into',1,'england',1,'amaz',1,'certain',1,'kind',1,'[',1,'smoke',2,'toss',1,'\'\'',7,'ca',1,'work',1,'black-crocket',1,'caus',1,'ago',1,'now',1,'then',1,'insist',1,'divan',2,'produc',1,'mani',1,'bear',1,'about',3,'conjectur',1,'honey-sweet',1,'hollyhock',1,'whi',1,'those',1,'their',2,'away',2,'best',2,'silli',1,'ever',2,'send',4,'up',2,'elev',1,'flame-lik',1,'use',1,'oxford',1,';',1,'quit',1,'vulgar',1,'he',9,'academi',1,'grosvenor',2,'artist',1,'ani',2,'was',4,'necessarili',1,'capabl',1,'seek',1,'want',1,'which',2,'come',1,'wreath',1,'curtain',1,'far',1,'if',1,'rose',1,'convey',1,'him',3,'himself',1,'abov',1,'thorn',1,'japanes',1,'finger',1,'innumer',1,'open',1,'sit',1,'door',1,'your',1,'but',2,'and',17,'usual',1,'too',3,'start',1,'anyth',1,'roar',1,'stir',1,'anywher',3,'larg',1,'is',7,'men',3,'dear',1,'littl',1,'have',4,'think',2,'!',1,'art',2,'distant',1,'it',10,'painter',2,'organ',1,'tussore-silk',1,'within',1,'talk',2,'were',1,'next',1,'basil',2,'gleam',1,'cigarett',2,'disappear',1,'like',2,'head',1,'lilac',1,'studio',1,'pleasur',1,'summer',1,'fellow',1,'?',3,'gave',1,'myself',1,'smile',1,'fear',1,':',1,'languid',1,'fill',1,'pink-flow',1,'close',1,'person',1,'rich',1,'his',10,'i',6,'make',4,'answer',1,'chap',1,'across',2,'through',3,'onli',2,'spire',1,'thing',2,'rise',1,'not',2,'that',6,'odor',1,'bird',1,'immobil',1,'who',1,'excit',1,'dim',1,'grass',1,'brain',1,'repli',1,'pallid',1,'one',2,'oppress',1,'some',3,'abl',1,'with',3,'friend',1,'``',7,'do',2,'shoulder',1,'garden',1,'face',1,'burden',1,'to',12,'from',3,'motion',1,'clamp',1,'stood',1,'set',1,'sought',1,'effect',1,'tremul',1,'persian',1,'skil',1,'amidst',1,'more',2,'circl',1,'an',2,'year',2,'the',46,'done',1,'sudden',2,'opium-taint',1,'curious',1,'or',2,'dream',1,'laughter',1,'soon',1,'could',1,'this',1,'so',3,'delic',1,'shadow',1,'for',1,'gain',1,'be',2,'such',2,'corner',1,'portrait',2,'awak',1,'reput',1,'window',1,'wotton',1,'world',2,'place',2,'are',2,'fantast',1,'young',2,'room',1,'distanc',1,'look',2,'henri',4,'blue',1,'beauti',2,'long',3,'.',20,'at',6,'laugh',2,'had',1,'swift',1,'thin',1,'sullen',1,'than',1,'lid',1,'scent',1,'4',1,'just',1,'june',1,'jealous',1,'saddle-bag',1,'catch',1,'shook',1);
    my %tagCounts = ('/PPL',7,'/RBR',1,'/VBD',28,'/IN',85,'/VBZ',7,'/CD',3,'/VBP',10,'/MD',8,'/PPR',7,'/PPC',45,'/NNP',22,'/DET',65,'/WDT',2,'/PRP',41,'/PPS',2,'/NN',89,'/NNS',30,'/PRPS',12,'/CC',21,'/LRB',1,'/WRB',2,'/RB',40,'/WPS',2,'/VBN',9,'/PP',24,'/TO',12,'/WP',2,'/JJS',2,'/VBG',8,'/RRB',1,'/VB',21,'/JJ',54,'/JJR',2);
    return (\$text, \%wordCounts, \%stemmedCounts, \%tagCounts);
  }

  if ($TextNo == 1)
  {
    my $text =
      'Elias Lönnrot wurde am 9. April 1802 im südfinnischen Sammatti als viertes von sieben Kindern des Schneiders Frederik Juhana Lönnrot und dessen Frau Ulriika Wahlberg geboren. Seine Kindheit verbrachte er in ärmlichen Verhältnissen. Für den Lebensunterhalt der Familie musste er seinem Vater bei der Arbeit helfen und teils sogar betteln. Weil er als Kind große Begabung zeigte und bereits im Alter von fünf Jahren lesen lernte, ermöglichten ihm seine Eltern trotz ihrer Armut eine Schulbildung. Zwischen 1814 und 1818 besuchte er die Schulen von Ekenäs (Tammisaari) und Turku. Zwischenzeitlich musste er den Schulbesuch aus finanziellen Gründen unterbrechen. Nachdem er unter anderem als fahrender Sänger Geld verdient hatte, konnte er 1820 seinen Bildungsweg in Porvoo fortsetzen, wo er das Abitur erhielt.

1822 begann er sein Studium zunächst an der Akademie zu Turku. Zu seinen Kommilitonen gehörten unter anderem Johan Ludvig Runeberg und Johan Vilhelm Snellman, die später zu den einflussreichsten Förderern der finnischen Kultur werden sollten. 1827 erhielt Lönnrot die Doktorwürde der Philosophie. Der Titel seiner Dissertation lautete De Väinämöine, priscorum Fennorum numine (Über Väinämöinen, eine Gottheit der alten Finnen). Die Anregung für die Wahl des Themas hatte ihm sein Professor Reinhold von Becker gegeben. Zwischenzeitlich arbeitete Lönnrot als Privatlehrer am Hause des Medizinprofessors J. A. Törngren in Vesilahti. Törngren und seine Frau Eva Agatha wurden zu wichtigen Förderern Lönnrots und ermutigten ihn zu seinen philologischen Forschungen.

Wohl auch unter dem Einfluss des Mediziners Törngren setzte Elias Lönnrot sein Studium im Fach Medizin fort. Die Akademie wurde indes 1828 nach dem Großbrand von Turku nach Helsinki verlegt und in die Universität Helsinki umgewandelt. 1832 erhielt Lönnrot mit der Dissertation Om finnarnes magiska medicin (Über die magische Medizin der Finnen) die Approbation als Arzt.

Durch seinen Lehrer Reinhold von Becker war Elias Lönnrot schon während seines Studiums mit der finnischen Volksdichtung in Kontakt gekommen. Den Grundstein für deren Erforschung hatten zuvor bereits Henrik Gabriel Porthan und Zacharias Topelius der Ältere gelegt. Zur gleichen Zeit entstand in Finnland durch das erwachende Nationalbewusstsein und Johann Gottfried von Herders Volksgeist-Ideen ein verstärktes Interesse, die traditionellen, mündlich übermittelten Lieder (auch als Runen bezeichnet) aufzuzeichnen. Diese Aufgabe wurde von Elias Lönnrot übernommen. Zu diesem Zwecke unternahm er zwischen 1828 und 1844 insgesamt elf Reisen. Er legte unter teils entbehrungsreichen Bedingungen hauptsächlich zu Fuß, rudernd oder auf Skiern eine Gesamtstrecke von schätzungsweise 20.000 Kilometern zurück. Insgesamt sammelte er auf seinen Reisen 65.000 Verse Volksdichtung.[1]

Seine erste Reise unternahm Lönnrot 1828, als er nach dem Brand von Turku auf die Fortsetzung seiner Studien warten musste. Zwischen April und September bereiste er zu Fuß die Regionen Häme, Savo und Nordkarelien bis hin zur Insel Valamo. Als Produkt dieser ersten Reise entstanden das Reisetagebuch Vandraren (Der Wanderer) und vier Lyrikbände mit dem Titel Kantele.

Eine 1831 angetretene Sammelreise nach Ostkarelien endete bereits in Kuusamo, als er von der Gesundheitsbehörde nach Südfinnland zurückbeordert wurde, um bei der Bekämpfung einer Choleraepidemie mitzuhelfen. Nach Abschluss seines Medizinstudiums reiste Lönnrot von Juli bis September 1832 mit zwei Kommilitonen nach Karelien. Von Nurmes aus überquerte er die Grenze zu Russland und besuchte die Dörfer Repola und Akonlahti, wo ihm der Runensänger Trohkimaii Soava wertvolle Aufzeichnungen lieferte.

1833 erhielt Lönnrot eine Stelle als Bezirksarzt im nordfinnischen Kajaani, wo er bis 1854 praktizieren sollte. Von dort aus trat er noch im selben Jahr seine vierte und wichtigste Sammelreise nach Ostkarelien an. Im Dorf Vuonninen traf er die Sänger Ontrei Malinen und Vaassila Kieleväinen; letzterer inspirierte Lönnrot dazu, die gesammelten Runen zu einem einheitlichen Werk zusammenzustellen. 1834 veröffentlichte Lönnrot anhand des gesammelten Materials das aus 5052 Versen bestehende Runokokous Väinämöisestä (Runensammlung über Väinämöinen), eine Art Proto-Kalevala, bei der erstmals die künstlerische Intention statt einer wissenschaftlich-textkritischen Auseinandersetzung im Vordergrund stand.

Im selben Jahr unternahm Lönnrot von Kajaani aus eine weitere Reise und sammelte Lieder von Arhippa Perttunen aus Latvajärvi, der zur wichtigsten Quelle für das Kalevala werden sollte. Nachdem er das Manuskript für das Kalevala abgegeben hatte, folgte im April 1835 die sechste Reise, während derer er in fünf Wochen 800 Kilometer zurücklegte. Die erste Ausgabe des Kalevala erschien 1835 bis 1836 in zwei Bänden unter dem Titel Kalewala, taikka Wanhoja Karjalan Runoja Suomen kansan muinoisista ajoista (Kalevala, oder alte Runen Kareliens über altertümliche Zeiten des finnischen Volkes).

Auch nach Veröffentlichung des Epos setzte Lönnrot seine Reisen fort. Zwischen September 1836 und Mai 1837 unternahm er eine längere Reise, die viele Strapazen, aber kaum Ergebnisse mit sich brachte. Nach zwei weiteren Reisen in den Folgejahren erschien 1840 bis 1841 die Lyriksammlung Kanteletar in drei Bänden.

Bei den späteren Reisen Lönnrots standen sprachwissenschaftliche Interessen im Vordergrund. Von Anfang 1841 bis Ende 1842 reiste er zusammen mit dem Linguisten M. A. Castrén nach Lappland, Kola und Archangelsk sowie zu den Wepsen in Ostkarelien. Seine elfte und letzte Reise führte Elias Lönnrot 1844 nach Estland und ins Ingermanland.';

    my %wordCounts = ('gro�e',1,'�ltere',1,'Wepsen',1,'sp�teren',1,'besuchte',2,'1831',1,'gleichen',1,'selben',2,'Schulen',1,'Zwischenzeitlich',2,'f�nf',2,'Vater',1,'Jahren',1,'Arbeit',1,'Schulbesuch',1,'bezeichnet',1,'fort',2,'Kind',1,'1836',2,'Brand',1,'numine',1,'Linguisten',1,'elfte',1,'Aufzeichnungen',1,'priscorum',1,'Elias',5,'ajoista',1,'Akonlahti',1,'1841',2,'Den',1,'bei',3,'Fennorum',1,'Runensammlung',1,'Sammatti',1,'Kalevala',4,'Durch',1,'Geld',1,'anderem',2,'l�ngere',1,'weiteren',1,'kansan',1,'Eltern',1,'und',24,'das',7,'musste',3,'zur',2,'Insgesamt',1,'indes',1,'Insel',1,')',7,'Zeiten',1,'Dorf',1,'sp�ter',1,'schon',1,'mitzuhelfen',1,'Approbation',1,'zur�cklegte',1,'ein',1,'zuvor',1,'Estland',1,'sammelte',2,'unternahm',4,'in',12,'Begabung',1,'B�nden',2,'sowie',1,'finnarnes',1,'Gesundheitsbeh�rde',1,'Kantele',1,'stand',1,'Gro�brand',1,'Ontrei',1,'teils',2,'Zwecke',1,'Hause',1,'20.000',1,'seines',2,'haupts�chlich',1,'Auseinandersetzung',1,'dem',6,'Epos',1,'D�rfer',1,'wo',3,'sechste',1,'taikka',1,'diesem',1,'des',8,'Kilometern',1,'Arhippa',1,'Vandraren',1,'sollten.',1,'Familie',1,'kaum',1,'Der',2,'magiska',1,'Ulriika',1,'Studiums',1,'Zu',2,'am',2,'erm�glichten',1,'Nach',2,'insgesamt',1,'einflussreichsten',1,'Lyrikb�nde',1,'Lehrer',1,'w�hrend',2,'wurden',1,'zun�chst',1,']',1,'zur�ck',1,'wurde',4,'sieben',1,'Lappland',1,'J.',1,'Wochen',1,'Kielev�inen',1,'Medizin',2,'Art',1,'wichtigsten',1,'setzte',2,'�ber',2,'gesammelten',2,'1842',1,'mit',6,'ihm',3,'statt',1,'September',3,'entstanden',1,'Choleraepidemie',1,'begann',1,'Kultur',1,'Sammelreise',2,'Gesamtstrecke',1,',',26,'letzte',1,'Fu�',2,'erhielt',3,'praktizieren',1,'V�in�m�inen',2,'Runens�nger',1,'trotz',1,'Kareliens',1,'alte',1,'Russland',1,'Helsinki',2,'Regionen',1,'Skiern',1,'Soava',1,'1854',1,'alten',1,'Themas',1,'Studium',2,'L�nnrot',16,'Wanhoja',1,'unter',5,'unterbrechen',1,'Dissertation',2,'Frederik',1,'Vaassila',1,'zwei',3,'April',3,'fortsetzen',1,'F�rderern',2,'entbehrungsreichen',1,'�bernommen',1,'viertes',1,'Fortsetzung',1,'Im',2,'Savo',1,'Weil',1,'wichtigen',1,'fahrender',1,'abgegeben',1,'Frau',2,'finnischen',3,'1832',2,'Wohl',1,'[',1,'Auch',1,'wissenschaftlich-textkritischen',1,'traf',1,'Bildungsweg',1,'Einfluss',1,'�rmlichen',1,'Arzt',1,'Von',3,'Juhana',1,'Materials',1,'einem',1,'wertvolle',1,'1844',2,'seiner',2,'erste',2,'Kommilitonen',2,'M.',1,'Stelle',1,'durch',1,'Medizinstudiums',1,'Philosophie',1,'angetretene',1,'1',1,'1827',1,'dazu',1,'dort',1,'oder',2,'bis',6,'rudernd',1,'lautete',1,'sich',1,'hatte',3,'Werk',1,'800',1,'im',8,'Fach',1,'1814',1,'aus',6,'zu',9,'Repola',1,'65.000',1,'1818',1,'Akademie',2,'1837',1,'Aufgabe',1,'Volksdichtung',2,'Tammisaari',1,'Seine',3,'medicin',1,'sch�tzungsweise',1,'1820',1,'elf',1,'5052',1,';',1,'dieser',1,'gegeben',1,'Zur',1,'Karjalan',1,'f�r',4,'Die',3,'brachte',1,'1802',1,'Manuskript',1,'werden',2,'Kalewala',1,'Mediziners',1,'von',14,'1822',1,'Finnen',2,'sogar',1,'Eva',1,'Anfang',1,'letzterer',1,'lieferte.',1,'Reisetagebuch',1,'Abitur',1,'Strapazen',1,'Bezirksarzt',1,'Folgejahren',1,'V�in�m�isest�',1,'ver�ffentlichte',1,'De',1,'einer',2,'Turku',4,'standen',1,'Zacharias',1,'Latvaj�rvi',1,'vierte',1,'zur�ckbeordert',1,'Als',1,'Johan',2,'Kola',1,'Vesilahti',1,'1833',1,'ersten',1,'Bedingungen',1,'�ber',2,'Wahlberg',1,'f�hrte',1,'Kajaani',2,'arbeitete',1,'erwachende',1,'Gr�nden',1,'Porthan',1,'erstmals',1,'Nationalbewusstsein',1,'Lieder',2,'warten',1,'�berquerte',1,'hatten',1,'zwischen',1,'Finnland',1,'Nordkarelien',1,'folgte',1,'Studien',1,'Verse',1,'die',18,'V�in�m�ine',1,'Gabriel',1,'lesen',1,'Diese',1,'Er',1,'zusammen',1,'Grundstein',1,'Anregung',1,'erhielt.',1,'Gottheit',1,'Johann',1,'wichtigste',1,'finanziellen',1,'geh�rten',1,'trat',1,'Trohkimaii',1,'Kindern',1,'lernte',1,'Ende',1,'�bermittelten',1,'seinen',5,'Ingermanland',1,'zeigte',1,'Herders',1,'um',1,'S�dfinnland',1,'verdient',1,'Versen',1,'reiste',2,'Malinen',1,'Universit�t',1,'Schneiders',1,'S�nger',2,'Suomen',1,'Volksgeist-Ideen',1,'Kanteletar',1,'Ausgabe',1,'1834',1,'k�nstlerische',1,'Becker',2,'(',7,'verst�rktes',1,'Lyriksammlung',1,'inspirierte',1,'Topelius',1,'bestehende',1,'ihrer',1,'Vilhelm',1,'war',1,'nach',10,'umgewandelt.',1,'Archangelsk',1,'m�ndlich',1,'magische',1,'Zeit',1,'sprachwissenschaftliche',1,'Lebensunterhalt',1,'s�dfinnischen',1,'1840',1,'philologischen',1,'traditionellen',1,'weitere',1,'Schulbildung',1,'Reise',6,'Bei',1,'Privatlehrer',1,'Forschungen',1,'drei',1,'H�me',1,'Professor',1,'einheitlichen',1,'Erforschung',1,'Medizinprofessors',1,'ihn',1,'Runoja',1,'derer',1,'vier',1,'betteln',1,'Grenze',1,'Verh�ltnissen',1,'Zwischen',3,'F�r',1,'dessen',1,'Runeberg',1,'Kontakt',1,'Perttunen',1,'Produkt',1,'endete',1,'legte',1,'Juli',1,'Doktorw�rde',1,'Ver�ffentlichung',1,'Valamo',1,'Alter',1,'bereits',3,'Abschluss',1,'Wahl',1,'Porvoo',1,'Interessen',1,'konnte',1,'sein',3,'Vordergrund',2,'Interesse',1,'seinem',1,'verbrachte',1,'auf',3,'hin',1,'viele',1,'bereiste',1,'den',6,'1828',3,'Snellman',1,'Kindheit',1,'auch',2,'Ergebnisse',1,'sollte',2,'an',2,'Proto-Kalevala',1,'Bek�mpfung',1,'der',15,'Jahr',2,'Castr�n',1,'A.',2,'Kilometer',1,'gekommen',1,'altert�mliche',1,'seine',4,'L�nnrots',2,'Karelien',1,'erschien',2,'1835',2,'zusammenzustellen.',1,'T�rngren',3,'gelegt',1,'Reinhold',2,'verlegt',1,'Quelle',1,'er',22,'Armut',1,'helfen',1,'Eine',1,'Kuusamo',1,'eine',7,'Henrik',1,'aufzuzeichnen',1,'Intention',1,'als',9,'Gottfried',1,'Runen',3,'deren',1,'Nachdem',2,'Wanderer',1,'Volkes',1,'muinoisista',1,'Ostkarelien',3,'Agatha',1,'Eken�s',1,'Mai',1,'.',39,'Reisen',5,'geboren',1,'noch',1,'anhand',1,'entstand',1,'9',1,'Runokokous',1,'Om',1,'ins',1,'aber',1,'nordfinnischen',1,'Titel',3,'Ludvig',1,'ermutigten',1,'Nurmes',1,'Vuonninen',1);
    my %stemmedCounts = ('runokokous',1,'lernt',1,'1831',1,'gr�nden',1,'�bermittelt',1,'titel',3,'f�nf',2,'estland',1,'finanziell',1,'eltern',1,'setzt',2,'wanhoja',1,'j.',1,'folgejahr',1,'bezeichnet',1,'fort',2,'konnt',1,'lappland',1,'epos',1,'lyrikb�nd',1,'1836',2,'kareli',2,'savo',1,'aufgab',1,'priscorum',1,'ajoista',1,'choleraepidemi',1,'vat',1,'1841',2,'gesamtstreck',1,'bei',4,'studium',3,'schulbild',1,'elias',5,'wahlberg',1,'einheit',1,'besucht',2,'geh�rt',1,'bezirksarzt',1,'juli',1,'medizinprofessor',1,'kansan',1,'karjalan',1,'endet',1,'zun�ch',1,'bereit',3,'gesundheitsbeh�rd',1,'ind',1,'und',24,'das',7,'nationalbewusstsein',1,'zur',3,'henrik',1,'fach',1,'musst',3,')',7,'dess',1,'inspiriert',1,'elft',1,'sp�ter',2,'viel',1,'kalewala',1,'les',1,'schon',1,'�berquert',1,'reist',2,'ein',12,'zuvor',1,'wand',1,'septemb',3,'linguist',1,'unternahm',4,'in',12,'eva',1,'erst',3,'frau',2,'stand',2,'johan',2,'20.000',1,'om',1,'anregung',1,'haupts�chlich',1,'dem',6,'praktizi',1,'mai',1,'vandrar',1,'russland',1,'wo',3,'taikka',1,'des',8,'magisch',1,'produkt',1,'weps',1,'brand',1,'sollten.',1,'castr�n',1,'vesilahti',1,'letzt',2,'kaum',1,'magiska',1,'am',2,'insgesamt',2,'aufzeichn',1,'ende',1,'manuskript',1,'runoja',1,'sowi',1,'folgt',1,'w�hrend',2,'alt',2,'volk',1,']',1,'zur�ck',1,'ulriika',1,'zwischenzeit',2,'vaassila',1,'h�me',1,'1842',1,'reis',11,'mit',6,'ihm',3,'statt',1,'begann',1,'themas',1,',',26,'topelius',1,'erhielt',3,'kanteletar',1,'geld',1,'interess',2,'wertvoll',1,'gro�brand',1,'helf',1,'grundstein',1,'trotz',1,'f�rder',2,'kalevala',4,'1854',1,'gabriel',1,'juhana',1,'zwei',3,'gottfried',1,'l�nnrot',18,'sprachwissenschaft',1,'wahl',1,'�lter',1,'fortsetz',2,'kind',2,'1832',2,'[',1,'traf',1,'intention',1,'k�nstlerisch',1,'m.',1,'famili',1,'kilomet',2,'zwisch',4,'sollt',2,'strapaz',1,'weit',2,'abschluss',1,'universit�t',1,'1844',2,'medizin',3,'durch',2,'bek�mpfung',1,'�bernomm',1,'verbracht',1,'1',1,'1827',1,'dazu',1,'dort',1,'sammelreis',2,'bereist',1,'oder',2,'bis',6,'alter',1,'quell',1,'rudernd',1,'sich',1,'ausgab',1,'professor',1,'s�dfinnland',1,'einfluss',1,'insel',1,'800',1,'skiern',1,'im',10,'1814',1,'aus',6,'de',1,'dorf',1,'armut',1,'zu',11,'ingermanland',1,'ostkareli',3,'65.000',1,'weil',1,'1818',1,'zur�cklegt',1,'beding',1,'abgegeb',1,'agatha',1,'1837',1,'malin',1,'wohl',1,'april',3,'medicin',1,'1820',1,'elf',1,'5052',1,';',1,'schul',1,'erstmal',1,'gekomm',1,'kola',1,'approbation',1,'f�r',5,'stell',1,'1802',1,'lebensunterhalt',1,'von',17,'vilhelm',1,'1822',1,'lautet',1,'sogar',1,'tammisaari',1,'kantel',1,'nachd',2,'lieferte.',1,'s�dfinnisch',1,'arbeit',1,'sieb',1,'repola',1,'helsinki',2,'forschung',1,'zur�ckbeordert',1,'latvaj�rvi',1,'1833',1,'lied',2,'kommiliton',2,'�ber',4,'f�hrte',1,'arhippa',1,'trohkimaii',1,'sech',1,'traditionell',1,'and',2,'numin',1,'erwach',1,'verst�rkt',1,'entbehrungsreich',1,'die',21,'jahr',3,'fennorum',1,'gottheit',1,'erschi',2,'art',1,'fahrend',1,'erhielt.',1,'arzt',1,'trat',1,'philosophi',1,'medizinstudium',1,'haus',1,'akonlahti',1,'bildungsweg',1,'�rmlich',1,'ludvig',1,'a.',2,'um',1,'sammatti',1,'begab',1,'nordkareli',1,'verdient',1,'b�nden',2,'kielev�in',1,'gro�',1,'doktorw�rd',1,'studi',1,'1834',1,'verh�ltniss',1,'kindheit',1,'erforschung',1,'(',7,'t�rngren',3,'johann',1,'kuusamo',1,'eken�s',1,'dies',3,'aufzuzeichn',1,'valamo',1,'ergebniss',1,'altert�m',1,'war',1,'gebor',1,'run',3,'nach',12,'umgewandelt.',1,'m�ndlich',1,'selb',2,'zeit',2,'suom',1,'1840',1,'zeigt',1,'arbeitet',1,'fu�',2,'beck',2,'wart',1,'herd',1,'lehr',1,'zweck',1,'hatt',4,'ihr',1,'zacharias',1,'gleich',1,'schulbesuch',1,'ermutigt',1,'finnarn',1,'drei',1,'d�rfer',1,'viert',2,'kajaani',2,'wissenschaftlich-textkrit',1,'ihn',1,'porthan',1,'runensamml',1,'vier',1,'betteln',1,'sammelt',2,'soava',1,'kontakt',1,'nurm',1,'ontrei',1,'runeberg',1,'besteh',1,'region',1,'unt',5,'ver�ffentlicht',1,'erm�glicht',1,'finnisch',3,'anfang',1,'bracht',1,'volksdicht',2,'snellman',1,'volksgeist-ide',1,'sein',20,'v�in�m�isest�',1,'akademi',2,'teil',2,'auseinandersetz',1,'angetret',1,'vers',2,'auf',3,'nordfinn',1,'hin',1,'archangelsk',1,'den',7,'1828',3,'dissertation',2,'auch',3,'proto-kalevala',1,'material',1,'an',2,'porvoo',1,'der',19,'legt',1,'runens�ng',1,'gegeb',1,'ver�ffentlich',1,'1835',2,'zusammenzustellen.',1,'reisetagebuch',1,'gelegt',1,'finn',2,'verlegt',1,'er',23,'einflussreich',1,'unterbrech',1,'finnland',1,'mitzuhelf',1,'philolog',1,'turku',4,'vordergrund',2,'freder',1,'reinhold',2,'vuonnin',1,'abitur',1,'als',10,'privatlehr',1,'woch',1,'lyriksamml',1,'schneid',1,'perttun',1,'muinoisista',1,'wichtig',3,'werd',2,'.',39,'sch�tzungsweis',1,'noch',1,'anhand',1,'kultur',1,'entstand',2,'9',1,'wurd',5,'ins',1,'aber',1,'grenz',1,'l�nger',1,'zusamm',1,'werk',1,'gesammelt',2,'s�nger',2,'v�in�m�in',3);
    my %tagCounts = ('/JJ',67,'/VB',128,'/NN',408,'/IN',29,'/VBZ',1,'/SYM',66,'/NNP',173,'/FW',6);
    return (\$text, \%wordCounts, \%stemmedCounts, \%tagCounts);
  }
}

sub writeHashAsArray
{
  my $Hash = shift;
  my @keyValue;
  while (my ($key, $value) = each %$Hash)
  {
    my $keyStr = $key;
    $key =~ s/\'/\\\'/g;
    $key = "'" . $key . "'";
    push @keyValue, ($key, $value);
  }
  print ' = (' . join (',', @keyValue) . ');' . "\n";
}

# random clear a list of fake stemmed words that all
# begin with the letter 'a'. Next, randomly create a
# list of unique phrases that all begin with a unique
# string (numbers). Randomly compute positions to insert
# the strings.










