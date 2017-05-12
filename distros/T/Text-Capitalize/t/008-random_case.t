# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 008-random_case.t'

#########################

use warnings;
use strict;
$|=1;
use utf8;
use Env qw( $HOME );
my $TESTCASEGEN = 0;
open my $TFH, ">", "$HOME/End/Cave/CapitalizeTitle/tmp/tempoutput.$$" or die $! if $TESTCASEGEN;

use FindBin qw($Bin);
use lib ("$Bin/../lib",  "$Bin/lib");

my $basic_test_cases = define_basic_test_cases();
my $i18n_test_cases = define_basic_test_cases_i18n();
my $basic_count = scalar( keys( %{ $basic_test_cases } ) );
my $i18n_count  = scalar( keys( %{ $i18n_test_cases } ) );
my $total = $basic_count + $i18n_count + 1;

use Test::More;
plan tests => $total;

use Text::Capitalize 0.4 qw( random_case );
use Test::Locale::Utils  qw( :all );

my $i18n_system = is_locale_international();

{
  # seeding with a known value to get repeatable sequence from rand
  srand(666);
  # Note: need to sort the test cases, to get the same order that
  # was used in generating the answer key.

  foreach my $case (sort keys %{ $basic_test_cases }) {
    my $expected = $basic_test_cases->{ $case };
    my $result   = random_case( $case );

    record_testcase( $case, $result ) if $TESTCASEGEN;

    is ($result, $expected, "test: $case");
  }

  SKIP: {
      skip "Can't test strings with international chars", $i18n_count, unless $i18n_system;

      foreach my $case (sort keys %{ $i18n_test_cases }) {
        my $expected = $i18n_test_cases->{$case};
        my $result   = random_case($case);

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
  random_case($anything);
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
# random_case, when seeded with a known value: srand(666)
sub define_basic_test_cases {
  my %expect_random_case = (
     '' =>
        '',
     '  ...huh?   ' =>
        '  ...HUh?   ',
     '  very spacey  ' =>
        '  vEry spaCey  ',
     '"but so!", sayeth I' =>
        '"bUt so!", SAyEth I',
     '\'for not!\', he said.' =>
        '\'FoR NOT!\', hE SAid.',
     '-- ack, ack, bang!' =>
        '-- ACk, ACK, bAng!',
     '...and justice for all' =>
        '...aNd JUsTIce fOr All',
     '...nor lost, nor found' =>
        '...nOr lOsT, noR FOuNd',
     '10 Little-Endians' =>
        '10 LIttle-ENDiANS',
     'AWOL in the DMZ of WWIII' =>
        'Awol in THE dmZ OF WwiiI',
     'Ah ha: and so forth' =>
        'AH ha: AND SO ForTh',
     'And more. And still more.' =>
        'And morE. ANd STILL more.',
     'And so they tramped on through the night. Tramp. Tramp. Tramp. Tramp. Tramp. Tramp. Tramp...' =>
        'AnD SO ThEY TRAmpEd on tHROUGh tHe NIghT. trAmp. TramP. TramP. TRAMP. Tramp. TramP. trAMp...',
     'And the rest is silence...' =>
        'AnD THe Rest Is SIlEnce...',
     'As I Ebb\'d with the Ocean of Life' =>
        'as i EBb\'D wITH ThE OCeaN of life',
     'Ask not' =>
        'asK nOT',
     'BEAT! BEAT! DRUMS!' =>
        'beaT! beAt! DRUMs!',
     'Baron von Arnheim\'s revenge' =>
        'bARon vON aRNHEim\'s rEvEngE',
     'DOODZ I AM SO THERE! NOT.' =>
        'DoODz i Am so tHEre! NOT.',
     'Document. Test. Code. Repeat.' =>
        'DoCUMeNt. tESt. CoDE. RePeAt.',
     'Erratic spacing:  your KEY    to     creativity   ' =>
        'eRRATiC spaciNg:  youR keY    tO     CReATIVity   ',
     'From Pent-Up Aching Rivers' =>
        'FrOm Pent-UP acHInG rIvers',
     'Hell\'s Swells' =>
        'HELL\'s SWells',
     'In the beginning... was the global-set-key' =>
        'In tHE BeGInNinG... wAs tHe GlobAL-SeT-Key',
     'Mr. Wong and Dr. And Report' =>
        'Mr. wong aND dr. AnD rEPoRt',
     'One\'s Self I Sing' =>
        'oNE\'S sElF I SiNG',
     'Pain--has an Element of Blank' =>
        'Pain--HAS An eLeMeNT of bLANK',
     'Ping... ping... ping... pong!' =>
        'PING... pINg... PInG... ponG!',
     'Quinn Weaver, agent of SFPUG' =>
        'QuINN wEavER, AGeNt Of sFPUg',
     'Scientific Study of the So-called Psychical Processes in the Higher Animals' =>
        'SciENtiFiC sTUDy oF THE sO-cAlLEd PsYChiCAl pRocESSes In tHE HIGHER AnImAls',
     'TLAs i have known and loved' =>
        'TLaS i HAVe kNOwn anD loVed',
     'The 13 Clocks' =>
        'THE 13 clOCKs',
     'The 4 False Weapons' =>
        'THe 4 falsE weApons',
     'The Next iMac: Just Another NeXt?' =>
        'the nexT ImAC: JUst AnotHer NexT?',
     'The Running-Down of the Universe' =>
        'tHe RunNinG-Down OF ThE uniVERSE',
     'The Wound-Dresser' =>
        'thE WoUNd-dREsseR',
     'The wind whispers "But!"' =>
        'thE WinD whISPErs "bUT!"',
     'Tis called perserverence in a good cause, and obstinacy in a bad one.' =>
        'Tis CALLED persERveRenCE IN A GoOd CauSE, anD oBStINaCY iN A BAD onE.',
     'What about: a an the and or nor for but so yet not to of by at for but in, huh?' =>
        'wHAT AbOuT: A AN The AND Or nOr FOR But sO yet NoT TO OF by aT FOR BuT In, HUh?',
     'When I Heard the Learn\'d Astronomer' =>
        'wHEn I hEARD tHE LEarn\'d AstRoNomER',
     'Why? Well, why not?' =>
        'WHY? WElL, WhY NoT?',
     'a brief history of the word of' =>
        'a brIeF hIStORY Of THe wORd of',
     'a history of n.a.s.a.' =>
        'A History OF N.a.S.A.',
     'a laboratory of the open fields' =>
        'a lAbOratory OF tHE open fIELds',
     'a theory I have' =>
        'A thEORY I hAvE',
     'and/or testified it shall be' =>
        'anD/Or TeStifieD it shAll Be',
     'chords against culture -- counter-sexist themes in the later works of Fetal Tissue Kleenex' =>
        'cHORDS aGAINST culTurE -- cOUNtEr-SExIsT themEs In tHE LATer Works of FETAL TIsSuE KLEenEx',
     'forget gilroy, A. Snakhausem was here' =>
        'ForgEt GilrOy, a. sNakhaUSeM WAS herE',
     'hey doc the ticker is hocked, the dial is locked, the face is botoxed, whazzup?' =>
        'hey DOC THE TIcKEr is hocked, THE DIAL Is lOckeD, The face IS Botoxed, WhazZuP?',
     'history of the gort-verada-nictu moving company' =>
        'historY Of the goRt-veRada-NICtU MoViNG CompANy',
     'how should one read a book?' =>
        'hOW shouLd ONe ReaD A bOoK?',
     'ice9count0' =>
        'ICe9cOUNt0',
     'it came from texas:  the new new world order?' =>
        'It cAMe fRoM TEXAS:  thE NEw NEW WORlD oRdeR?',
     'it\'s the man\'s, you know?' =>
        'it\'S ThE Man\'S, you KNOW?',
     'kill \'em all' =>
        'KIlL \'em ALl',
     'machine13' =>
        'machiNe13',
     'mo\' beta-testing' =>
        'MO\' beta-TeStiNg',
     'of beauty' =>
        'OF BEAutY',
     'on style' =>
        'On stYle',
     'pOiksIFiciZaLaTIonoRyISM' =>
        'pOiKsIfiCIzaLaTiOnoRyiSM',
     's.a.d. days t.a.n. shades' =>
        's.A.d. DaYs T.a.N. shadEs',
     'sarcasm yet not humor' =>
        'sARCasm YET NoT hUMor',
     'sarcasm, yet' =>
        'sARCAsM, yeT',
     'say "but!", say what?' =>
        'saY "but!", SAy WhAt?',
     'the dirty 27' =>
        'the dirTy 27',
     'the end of the dream: three-holed button manufacture in a four-holed world' =>
        'tHE eNd Of ThE drEAm: THree-holeD BUtTON MANUFAcTUre In A FoUR-HoLED WorLD',
     'the n.a.s.a. sucks rag' =>
        'THE N.a.s.A. SucKs RAg',
     'yet by and by but in for to' =>
        'yET bY AND By BUT in For tO',
     'you\'re wrong, it doesn\'t fly, it\'s not there and they\'re lost, so you\'d better not' =>
        'yoU\'RE WronG, IT DoesN\'t flY, IT\'S nOt tHEre and THEY\'RE LOST, sO You\'d betTeR NoT',
  );

  return \%expect_random_case;
};

sub define_basic_test_cases_i18n {
  my %expect_random_case = (
     'Didaktische Überlegungen/Erfahrungsbericht über den Computereinsatz im geisteswissenschaftlichen Unterricht am Bsp. "Historische Zeitung"' =>
     'DIdaKtISchE ÜbERLeGUngEN/ErFahrUnGsbERIcht üBer DeN CoMpUtEREInsATz im GeIsTesWissENscHAFTlIchEN unTERRicHt AM BSP. "HISToRIsChe zEITuNg"',

     'Explicación dél significado de los términos utilizados en "Don Quijote", por capítulo.' =>
     'explIcAciÓn dél SIgniFIcAdo De loS tÉRmiNoS UtiLiZadoS en "don QUIJoTE", pOr CAPÍtULO.',

     'où l\'on découvre une époque à travers l\'oeuvre imposante d\'Honoré de Balzac' =>
     'oÙ l\'on déCouVRE uNE ÉPOQUe à TraVErs l\'OeuvRE iMPOSAnte d\'hONorÉ De bAlzac',

     'évêque, qu\'il eût aimé voir infliger à ceux qui ont abdiqué, J\'ai été reçu, and pepe le peau' =>
     'évÊQue, Qu\'iL eûT AIMÉ vOiR inflIgER à ceux quI onT AbdiQué, J\'aI éTé REçU, and pepe lE peaU',

     'über maus' =>
     'ÜbeR mAuS',
  );
  return \%expect_random_case;
}
