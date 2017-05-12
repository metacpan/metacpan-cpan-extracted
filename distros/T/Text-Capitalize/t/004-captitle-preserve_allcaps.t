# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 002-capitalize_title-default.t'

#########################

use warnings;
use strict;
$|=1;
use utf8;

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

use Text::Capitalize 0.4 qw(capitalize_title);
use Test::Locale::Utils qw(:all);

my $i18n_system = is_locale_international();

{
  foreach my $case (sort keys %{ $basic_test_cases }) {
    my $expected = $basic_test_cases->{ $case };
    my $result = capitalize_title($case, PRESERVE_ALLCAPS => 1);
    is ($result, $expected, "test: $case");
  }

  SKIP: {
      skip "Can't test strings with international chars", $i18n_count, unless $i18n_system;
      foreach my $case (sort keys %{ $i18n_test_cases }) {
        my $expected = $i18n_test_cases->{ $case };
        my $result = capitalize_title($case, PRESERVE_ALLCAPS => 1);
        is ($result, $expected, "test: $case");
      }
    }
}


# Regression test: make sure $_ isn't munged by unlocalized use
{
  my $anything = "Whirl and Pieces";
  my $keeper = "abc123";
  local $_ = $keeper;
  capitalize_title($anything, PRESERVE_ALLCAPS => 1);
  is ($_, $keeper, "\$\_ unaffected by capitalize_title");
}


sub define_basic_test_cases {

  my %expect_capitalize_title_PRESERVE_ALLCAPS = (
     'This And ThAt' =>
        'This and That',
     "Revenge is Doom's" =>
        "Revenge Is Doom's",
     'the end of the dream: three-holed button manufacture in a four-holed world' =>
        'The End of the Dream: Three-Holed Button Manufacture in a Four-Holed World',
     'chords against culture -- counter-sexist themes in the later works of Fetal Tissue Kleenex' =>
        'Chords Against Culture -- Counter-Sexist Themes in the Later Works of Fetal Tissue Kleenex',
     'a history of n.a.s.a.' =>
        'A History of N.A.S.A.',
     'the n.a.s.a. sucks rag' =>
        'The N.A.S.A. Sucks Rag',
     's.a.d. days t.a.n. shades' =>
        'S.A.D. Days T.A.N. Shades',
     'it\'s the man\'s, you know?' =>
        'It\'s the Man\'s, You Know?',
     'hey doc the ticker is hocked, the dial is locked, the face is botoxed, whazzup?' =>
        'Hey Doc the Ticker Is Hocked, the Dial Is Locked, the Face Is Botoxed, Whazzup?',
     'Hell\'s Swells' =>
        'Hell\'s Swells',
     'you\'re wrong, it doesn\'t fly, it\'s not there and they\'re lost, so you\'d better not' =>
        'You\'re Wrong, It Doesn\'t Fly, It\'s Not There and They\'re Lost, so You\'d Better Not',
     'DOODZ I AM SO THERE! NOT.' =>
        'DOODZ I AM SO THERE! NOT.',
     'Tis called perserverence in a good cause, and obstinacy in a bad one.' =>
        'Tis Called Perserverence in a Good Cause, and Obstinacy in a Bad One.',
     'And the rest is silence...' =>
        'And the Rest Is Silence...',
     'a brief history of the word of' =>
        'A Brief History of the Word Of',
     'AWOL in the DMZ of WWIII' =>
        'AWOL in the DMZ of WWIII',
     'TLAs i have known and loved' =>
        'Tlas I Have Known and Loved',
     'The Next iMac: Just Another NeXt?' =>
        'The Next Imac: Just Another Next?',
     'Mr. Wong and Dr. And Report' =>
        'Mr. Wong and Dr. And Report',
     'Quinn Weaver, agent of SFPUG' =>
        'Quinn Weaver, Agent of SFPUG',
     'sarcasm, yet' =>
        'Sarcasm, Yet',
     'sarcasm yet not humor' =>
        'Sarcasm yet Not Humor',
     '...and justice for all' =>
        '...And Justice for All',
     'kill \'em all' =>
        'Kill \'Em All',
     'history of the gort-verada-nictu moving company' =>
        'History of the Gort-Verada-Nictu Moving Company',
     'Erratic spacing:  your KEY    to     creativity   ' =>
        'Erratic Spacing: Your KEY to Creativity',
     'it came from texas:  the new new world order?' =>
        'It Came From Texas: The New New World Order?',
     'pOiksIFiciZaLaTIonoRyISM' =>
        'Poiksificizalationoryism',
     'What about: a an the and or nor for but so yet not to of by at for but in, huh?' =>
        'What About: A an the and or nor for but so yet Not to of by at for but in, Huh?',
     'Ah ha: and so forth' =>
        'Ah Ha: And so Forth',
     'a theory I have' =>
        'A Theory I Have',
     'and/or testified it shall be' =>
        'And/or Testified It Shall Be',
     '...nor lost, nor found' =>
        '...Nor Lost, nor Found',
     'Ask not' =>
        'Ask Not',
     '\'for not!\', he said.' =>
        '\'For Not!\', He Said.',
     '"but so!", sayeth I' =>
        '"But So!", Sayeth I',
     'The wind whispers "But!"' =>
        'The Wind Whispers "But!"',
     'say "but!", say what?' =>
        'Say "But!", Say What?',
     'yet by and by but in for to' =>
        'Yet by and by but in for To',
     '-- ack, ack, bang!' =>
        '-- Ack, Ack, Bang!',
     '  very spacey  ' =>
        'Very Spacey',
     '  ...huh?   ' =>
        '...Huh?',
     'Baron von Arnheim\'s revenge' =>
        'Baron von Arnheim\'s Revenge',
     'forget gilroy, A. Snakhausem was here' =>
        'Forget Gilroy, A. Snakhausem Was Here',
     'The 13 Clocks' =>
        'The 13 Clocks',
     'The 4 False Weapons' =>
        'The 4 False Weapons',
     '10 Little-Endians' =>
        '10 Little-Endians',
     'the dirty 27' =>
        'The Dirty 27',
     'machine13' =>
        'Machine13',
     'ice9count0' =>
        'Ice9count0',
     'Why? Well, why not?' =>
        'Why? Well, Why Not?',
     'Ping... ping... ping... pong!' =>
        'Ping... Ping... Ping... Pong!',
     'Document. Test. Code. Repeat.' =>
        'Document. Test. Code. Repeat.',
     'And so they tramped on through the night. Tramp. Tramp. Tramp. Tramp. Tramp. Tramp. Tramp...' =>
        'And so They Tramped On Through the Night. Tramp. Tramp. Tramp. Tramp. Tramp. Tramp. Tramp...',
     'And more. And still more.' =>
        'And More. And Still More.',
     'mo\' beta-testing' =>
        'Mo\' Beta-Testing',
     'a laboratory of the open fields' =>
        'A Laboratory of the Open Fields',
     'Scientific Study of the So-called Psychical Processes in the Higher Animals' =>
        'Scientific Study of the so-Called Psychical Processes in the Higher Animals',
     'The Running-Down of the Universe' =>
        'The Running-Down of the Universe',
     'In the beginning... was the global-set-key' =>
        'In the Beginning... Was the Global-Set-Key',
     'how should one read a book?' =>
        'How Should One Read a Book?',
     'of beauty' =>
        'Of Beauty',
     'on style' =>
        'On Style',
     'As I Ebb\'d with the Ocean of Life' =>
        'As I Ebb\'d with the Ocean of Life',
     'When I Heard the Learn\'d Astronomer' =>
        'When I Heard the Learn\'d Astronomer',
     'From Pent-Up Aching Rivers' =>
        'From Pent-Up Aching Rivers',
     'One\'s Self I Sing' =>
        'One\'s Self I Sing',
     'BEAT! BEAT! DRUMS!' =>
        'BEAT! BEAT! DRUMS!',
     'The Wound-Dresser' =>
        'The Wound-Dresser',
     'Pain--has an Element of Blank' =>
        'Pain--Has an Element of Blank',
     '' =>
        '',
  );
  return \%expect_capitalize_title_PRESERVE_ALLCAPS;
}

sub define_basic_test_cases_i18n {
  my %expect_capitalize_title_PRESERVE_ALLCAPS_i18n =
    (
     'Didaktische Überlegungen/Erfahrungsbericht über den Computereinsatz im geisteswissenschaftlichen Unterricht am Bsp. "Historische Zeitung"' =>
        'Didaktische Überlegungen/Erfahrungsbericht Über Den Computereinsatz Im Geisteswissenschaftlichen Unterricht Am Bsp. "Historische Zeitung"',
     'über maus' =>
        'Über Maus',
     'Explicación dél significado de los términos utilizados en "Don Quijote", por capítulo.' =>
        'Explicación Dél Significado de Los Términos Utilizados En "Don Quijote", Por Capítulo.',
     'l\'oeuvre imposante d\'Honoré de Balzac' =>
        'L\'Oeuvre Imposante d\'Honoré de Balzac',
    );

  return \%expect_capitalize_title_PRESERVE_ALLCAPS_i18n;
}
