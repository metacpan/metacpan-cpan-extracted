# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 009-scramble_case.t'

#########################

use warnings;
use strict;
$|=1;
use Env qw( $HOME );
use utf8;
my $TESTCASEGEN = 0;
open my $TFH, ">", "$HOME/End/Cave/CapitalizeTitle/tmp/tempoutput.$$" or die $! if $TESTCASEGEN;

use FindBin qw($Bin);
use lib ("$Bin/../lib",  "$Bin/lib");

my $basic_test_cases = define_basic_test_cases();
my $i18n_test_cases = define_basic_test_cases_i18n();
my $basic_count = scalar( keys( %{ $basic_test_cases } ) );
my $i18n_count  = scalar( keys( %{ $i18n_test_cases } ) );
my $total = $basic_count + $i18n_count + 1;

# use Test::More tests => 77;
use Test::More;
plan tests => $total;

use Text::Capitalize 0.4 qw(scramble_case);
use Test::Locale::Utils qw(:all);

my $i18n_system = is_locale_international();

{
  # seeding with a known value, should get repeatable sequence from rand
  srand(666);
  # Note: need to sort the test cases, to get the same order that
  # was used in generating the answer key.

  foreach my $case (sort keys %{ $basic_test_cases }) {
    my $expected = $basic_test_cases->{ $case };
    my $result   = scramble_case( $case );

    record_testcase( $case, $result ) if $TESTCASEGEN;

    is ($result, $expected, "test: $case");
  }

  SKIP: {
      skip "Can't test strings with international chars", $i18n_count, unless $i18n_system;

      foreach my $case (sort keys %{ $i18n_test_cases }) {
        my $expected = $i18n_test_cases->{$case};
        my $result   = scramble_case($case);

        record_testcase( $case, $result ) if $TESTCASEGEN;

        is ($result, $expected, "test: $case");
    }
  }
}


# Regression test: make sure $_ isn't munged by unlocalized use
{
  my $anything = "Whirl and Pieces";
  my $keeper = "abc123";
  local $_ = $keeper;
  scramble_case($anything);
  is ($_, $keeper, "\$\_ unaffected by capitalize_title");
}


#######
### end main, into the subs

# I need to have test case generator code embedded in this *.t
# A stand-alone script didn't work...
# Something odd about using srand for a repeatable rand sequence?
sub record_testcase {
  my $in  = shift;
  my $out = shift;
  $in  =~ s{'}{\\'}g;
  $out =~ s{'}{\\'}g;
  print {$TFH} "     '$in' =>\n        '$out',\n";
}

# Hash of test cases (keys) and expected results (values) for
# scramble_case, when seeded with a known value: srand(666)

sub define_basic_test_cases {

  my %expect_scramble_case = (
     '' =>
        '',
     '  ...huh?   ' =>
        '  ...hUh?   ',
     '  very spacey  ' =>
        '  vEry spACey  ',
     '"but so!", sayeth I' =>
        '"bUt so!", SAyEth I',
     '\'for not!\', he said.' =>
        '\'FoR NOT!\', hE Said.',
     '-- ack, ack, bang!' =>
        '-- ACk, ACk, bang!',
     '...and justice for all' =>
        '...aNd JUsTICe fOr All',
     '...nor lost, nor found' =>
        '...nOr losT, noR FOuNd',
     '10 Little-Endians' =>
        '10 LIttle-ENDiANS',
     'AWOL in the DMZ of WWIII' =>
        'Awol In THE dmZ OF WwiiI',
     'Ah ha: and so forth' =>
        'Ah ha: AND SO forTh',
     'And more. And still more.' =>
        'And moRE. And STIlL more.',
     'And so they tramped on through the night. Tramp. Tramp. Tramp. Tramp. Tramp. Tramp. Tramp...' =>
        'AnD So ThEY TRAmpEd on tHROUGh tHe NIghT. tramp. TramP. TramP. TRAMP. Tramp. TramP. trAMp...',
     'And the rest is silence...' =>
        'And The Rest Is SIlEnce...',
     'As I Ebb\'d with the Ocean of Life' =>
        'as i EBb\'D wITH ThE OCeaN of life',
     'Ask not' =>
        'asK nOT',
     'BEAT! BEAT! DRUMS!' =>
        'beAT! beAt! DRUMs!',
     'Baron von Arnheim\'s revenge' =>
        'bARon vON aRNHEim\'s rEvEngE',
     'DOODZ I AM SO THERE! NOT.' =>
        'doODz i Am so THEre! NOT.',
     'Document. Test. Code. Repeat.' =>
        'DoCUmeNt. tESt. coDE. RePeat.',
     'Erratic spacing:  your KEY    to     creativity   ' =>
        'eRRaTic spACiNg:  youR keY    tO     CREATIvity   ',
     'From Pent-Up Aching Rivers' =>
        'frOm Pent-UP acHInG rIverS',
     'Hell\'s Swells' =>
        'HeLL\'s SWells',
     'In the beginning... was the global-set-key' =>
        'In tHE BeginNinG... wAs tHe GlobAL-SeT-Key',
     'Mr. Wong and Dr. And Report' =>
        'Mr. wong aND dr. AnD rEPoRT',
     'One\'s Self I Sing' =>
        'oNe\'S sElF i SiNG',
     'Pain--has an Element of Blank' =>
        'Pain--HAS An eLemeNT of bLANK',
     'Ping... ping... ping... pong!' =>
        'pINg... pINg... PInG... ponG!',
     'Quinn Weaver, agent of SFPUG' =>
        'QuINN weavER, AGeNt of sFPUg',
     'Scientific Study of the So-called Psychical Processes in the Higher Animals' =>
        'SciENtiFiC sTUDy oF THE sO-cAllEd PsYChiCal pRocESSes In tHE HIGHER AnImAls',
     'TLAs i have known and loved' =>
        'TLas i HAVe kNOwn anD loVed',
     'The 13 Clocks' =>
        'THe 13 clOCKs',
     'The 4 False Weapons' =>
        'tHe 4 fAlsE weApons',
     'The Next iMac: Just Another NeXt?' =>
        'the nexT ImAC: JUst AnotHer NexT?',
     'The Running-Down of the Universe' =>
        'tHe RunNinG-Down OF ThE uniVERSE',
     'The Wound-Dresser' =>
        'thE WoUNd-dRessER',
     'The wind whispers "But!"' =>
        'thE WinD whISPers "bUT!"',
     'Tis called perserverence in a good cause, and obstinacy in a bad one.' =>
        'Tis CAlLED persERveRenCE IN A GoOd CauSE, and oBStINaCY iN A BAD onE.',
     'What about: a an the and or nor for but so yet not to of by at for but in, huh?' =>
        'wHaT AbOuT: A aN The AnD Or nOr FOR But sO yet NoT TO OF by aT FOR BuT In, HUh?',
     'When I Heard the Learn\'d Astronomer' =>
        'wHEn I hEARD tHE LEarn\'d AstRonomER',
     'Why? Well, why not?' =>
        'WHY? Well, WhY Not?',
     'a brief history of the word of' =>
        'a brIeF HIStORY Of THe wORd of',
     'a history of n.a.s.a.' =>
        'A history OF N.A.S.A.',
     'a laboratory of the open fields' =>
        'a lAbOratOry OF THE open fIELds',
     'a theory I have' =>
        'A thEORY I havE',
     'and/or testified it shall be' =>
        'anD/Or TeStifieD it sHALl Be',
     'chords against culture -- counter-sexist themes in the later works of Fetal Tissue Kleenex' =>
        'cHoRDS aGAINSt culTurE -- cOUNtEr-SExIsT themEs In tHE lATer Works of FETAL TIsSuE KLEenEx',
     'forget gilroy, A. Snakhausem was here' =>
        'ForgEt GilrOy, a. sNakhaUSeM WAS herE',
     'hey doc the ticker is hocked, the dial is locked, the face is botoxed, whazzup?' =>
        'hey DOC THe TIckEr is hocked, THE DiAL is lOckeD, The face IS Botoxed, WhazZuP?',
     'history of the gort-verada-nictu moving company' =>
        'histOrY Of thE goRt-VeRaDa-NICtU MoViNG CompANy',
     'how should one read a book?' =>
        'hOW shouLD ONe ReaD A bOoK?',
     'ice9count0' =>
        'Ice9cOUNt0',
     'it came from texas:  the new new world order?' =>
        'It cAMe fRoM TEXAS:  thE New NEW WoRlD oRdeR?',
     'it\'s the man\'s, you know?' =>
        'it\'S ThE Man\'S, you KNOW?',
     'kill \'em all' =>
        'KilL \'em ALl',
     'machine13' =>
        'macHiNe13',
     'mo\' beta-testing' =>
        'MO\' beta-TeStiNg',
     'of beauty' =>
        'oF BEAutY',
     'on style' =>
        'On stYle',
     'pOiksIFiciZaLaTIonoRyISM' =>
        'pOiKsIfiCIzaLaTiOnoRyiSM',
     's.a.d. days t.a.n. shades' =>
        's.A.d. DaYs T.a.N. shadEs',
     'sarcasm yet not humor' =>
        'sARCasm YEt noT hUMor',
     'sarcasm, yet' =>
        'sARCAsm, yeT',
     'say "but!", say what?' =>
        'saY "but!", SAy WhAt?',
     'the dirty 27' =>
        'thE dirTY 27',
     'the end of the dream: three-holed button manufacture in a four-holed world' =>
        'tHE eNd of ThE drEAm: THree-holeD BUtTON MANUFAcTUre In A FoUR-HoLeD WorLD',
     'the n.a.s.a. sucks rag' =>
        'ThE N.a.s.A. SucKs RAg',
     'yet by and by but in for to' =>
        'yEt bY AND By BUt in For tO',
     'you\'re wrong, it doesn\'t fly, it\'s not there and they\'re lost, so you\'d better not' =>
        'yoU\'RE WronG, IT DoesN\'t flY, IT\'S nOt tHEre and THEY\'RE LOST, sO You\'d betTeR NoT',
  );

  return \%expect_scramble_case;
};

sub define_basic_test_cases_i18n {
  my %expect_scramble_case = (
     'Didaktische Überlegungen/Erfahrungsbericht über den Computereinsatz im geisteswissenschaftlichen Unterricht am Bsp. "Historische Zeitung"' =>
     'dIdaKtISchE ÜbERLeGUngEN/ErFahrUnGsbERIcht üBer DeN CoMpUtEREInsATz im GeIsTesWissENscHAFTlIchEN unTERRicHt AM BSP. "hIStoRIsChe zEITuNg"',

     'Explicación dél significado de los términos utilizados en "Don Quijote", por capítulo.' =>
     'exPlIcAciÓn dÉL SIgniFIcAdo De loS tÉRmiNoS UtiLiZadoS en "don QUIJoTE", pOr CAPÍtULO.',

     'où l\'on découvre une époque à travers l\'oeuvre imposante d\'Honoré de Balzac' =>
     'oÙ l\'on déCouVRE uNE ÉPOQUe à traVErs l\'OeuvRE iMPOSAnte d\'hONorÉ De bAlzac',

     'évêque, qu\'il eût aimé voir infliger à ceux qui ont abdiqué, J\'ai été reçu, and pepe le peau' =>
     'évÊQue, Qu\'iL eûT AIMÉ vOiR inflIgER à ceux quI onT AbdIQué, J\'aI éTé REçU, and pepe lE peaU',

     'über maus' =>
     'übeR mAuS',
  );
  return \%expect_scramble_case;
}
