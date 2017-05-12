# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-ToSenteces.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 25;
BEGIN { use_ok('Text::ToSentences', ':test') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# use Text::ToSentences;
use File::Slurp qw(write_file);
my $notSentenceStartWord1 = " word  ";
ok(_isNotSentenceStart($notSentenceStartWord1), "Test lowercase word as not sentence start");
my $notSentenceStartWord2 = " ASD  ";
ok(_isNotSentenceStart($notSentenceStartWord2), "Test uppercase word as not sentence start");
my $sentenceStartWord3 = " Asd.  ";
ok(!_isNotSentenceStart($sentenceStartWord3), "Test first letter uppercase word as sentence start");

my $textToBeFormatted = "      texto simple(con espacios mal puestos )  ";
my $correctlyFormattedText = "Texto simple (con espacios mal puestos).";
is(_correctSpacesAndFormat($textToBeFormatted), $correctlyFormattedText,
   "Test correct format");

my $acronym1 = "S.I.G.L.A.S.";
ok(_isAcronym($acronym1), "Test acronym if single uppercase letters and dots");
my $acronym2 = "EE.UU.";
ok(_isAcronym($acronym2), "Test acronym if several uppercase letters and dots");
my $notAcronym3 = "Hello.";
ok(!_isAcronym($notAcronym3), "Test not acronym");
my $notAcronym4 = "¿Hola?";
ok(!_isAcronym($notAcronym4), "Test not acronym with question marks");
my $notAcronym5 = "hello.";
ok(!_isAcronym($notAcronym5), "Test not acronym if all lowercase");
my $notAcronym6 = "I.Nacimientos.Fallecimientos.Abderramán";
ok(!_isAcronym($notAcronym6), "Test not acronym from WP");
my $notAcronym7 = "Córdoba.Catego.";
ok(!_isAcronym($notAcronym7), "Test another not acronym from WP");

my $sentenceEndWord = "end.";
ok(_isSentenceEnd($sentenceEndWord), "Test sentence end");

my $blockOpeningWord = "(";
ok(_isBlockOpening($blockOpeningWord), "Test determine block opening");

my $textWithBlockDelimiters = "word Jilyen).";
is(_removeBlockDelimiters($textWithBlockDelimiters), "word Jilyen.",
   "Test remove block delimiters");

my $simpleTextToConvert = "texto simple. Sólo dos frases separadas por puntos.";
my $simpleTextConverted = ["Texto simple.",
                           "Sólo dos frases separadas por puntos."];

is_deeply(convert($simpleTextToConvert),
          $simpleTextConverted,
          "Test convert simple text");

my $textWithAcronymsToConvert = "Este es un texto con S.I.G.L.A.S. de VARIOS. tipos.";
my $textWithAcronymsConverted = ["Este es un texto con S.I.G.L.A.S. de VARIOS. tipos."];
is_deeply(convert($textWithAcronymsToConvert), $textWithAcronymsConverted,
          "Test convert text with acronyms");

my $textWithBracketsToConvert = "Este es un texto de prueba (aunque no lo parezca) buena.";
my $textWithBracketsConverted = ["Este es un texto de prueba buena.",
                                 "Aunque no lo parezca."];
is_deeply(convert($textWithBracketsToConvert),
          $textWithBracketsConverted,
          "Test convert text with brackets");

my $textWithBracketsAtEndToConvert = "Este es un texto de prueba (aunque no lo parezca).";
my $textWithBracketsAtEndConverted = ["Este es un texto de prueba.",
                                 "Aunque no lo parezca."];
is_deeply(convert($textWithBracketsAtEndToConvert),
          $textWithBracketsAtEndConverted,
          "Test convert text with brackets at end");

my $text = "Este es un texto de prueba (aunque no lo parezca). Tiene varias frases para buscar   .   E incluso acrónimos como WWF o W.W.F. que se procesan bien.";
my $sentences = ["Este es un texto de prueba.",
                 "Aunque no lo parezca.",
                 "Tiene varias frases para buscar.",
                 "E incluso acrónimos como WWF o W.W.F. que se procesan bien."];

is_deeply(convert($text), $sentences, "Test convert to sentences");

my $textWithNestedBlocksToConvert = "Este es un texto de prueba (que no lo parece (bueno un poco) en absoluto) para probar";
my $textWithNestedBlocksConverted = ["Este es un texto de prueba para probar.",
                                     "Que no lo parece en absoluto.",
                                     "Bueno un poco."];
is_deeply(convert($textWithNestedBlocksToConvert), 
          $textWithNestedBlocksConverted, 
          "Test convert to sentences with nested blocks");

my $textWithQuestionsToConvert = "Este es un texto de prueba. ¿Qué significará probar?";
my $textWithQuestionsConverted = ["Este es un texto de prueba.",
                                     "¿Qué significará probar?."];
is_deeply(convert($textWithQuestionsToConvert), 
          $textWithQuestionsConverted, 
          "Test convert to sentences with questions");

my $sentencesSepByDotButNoSpacesToConvert = "Esta es la primera frase.Esta es la segunda frase.Otra.Palabra";
my $sentencesSepByDotButNoSpacesConverted = ["Esta es la primera frase.",
                                             "Esta es la segunda frase.",
                                             "Otra.",
                                             "Palabra."];
is_deeply(convert($sentencesSepByDotButNoSpacesToConvert), 
          $sentencesSepByDotButNoSpacesConverted, 
          "Test convert to sentences separated by dot but no spaces");

my $textFromWPToConvert1 = "Acontecimientos.España : Hisham I al-Andalus , sucede como emir a Abderramán I.Nacimientos.Fallecimientos.Abderramán I, primer emir independiente de Córdoba.Catego.Jilyen).Map-.Ru-.";
my $textFromWPConverted1 = ["Acontecimientos.",
                           "España : Hisham I al-Andalus, sucede como emir a Abderramán I. Nacimientos.",
                           "Fallecimientos.",
                           "Abderramán I, primer emir independiente de Córdoba.",
                           "Catego.",
                           "Jilyen.",
                           "Map-.",
                           "Ru-."];
is_deeply(convert($textFromWPToConvert1), 
          $textFromWPConverted1, 
          "Test convert real text from Wikipedia.");

my $textFromWPToConvert2 = "Ana, como toda una reina, como siempre había sido, altiva y con una gran dignidad, se presentó el día de su ejecución con el cabello levantado y demostrando una gran entereza.Fue ejecutada en la Torre de Londres con una espada, por un verdugo francés, ambos especialmente traídos de Calais para su muerte, el 19 de mayo de 1536, antes de ello sus últimas palabras fueron para su verdugo: &quot;No te daré mucho trabajo, tengo el cuello muy fino&quot;.Fue sepultada en la cercana capilla de San-Pedro-ad-Vincula, en la Torre.Enlaces externos.Para la ópera basada en su vida, vea Anna Bolena.Más sobre Ana Bolena.Bolena.Catego Tudor.Sim.";
my $textFromWPConverted2 = ["Ana, como toda una reina, como siempre había sido, altiva y con una gran dignidad, se presentó el día de su ejecución con el cabello levantado y demostrando una gran entereza.", "Fue ejecutada en la Torre de Londres con una espada, por un verdugo francés, ambos especialmente traídos de Calais para su muerte, el 19 de mayo de 1536, antes de ello sus últimas palabras fueron para su verdugo: &quot;No te daré mucho trabajo, tengo el cuello muy fino&quot;.", "Fue sepultada en la cercana capilla de San-Pedro-ad-Vincula, en la Torre.", "Enlaces externos.", "Para la ópera basada en su vida, vea Anna Bolena.", "Más sobre Ana Bolena.", "Bolena.", "Catego Tudor.", "Sim."];
is_deeply(convert($textFromWPToConvert2), 
          $textFromWPConverted2, 
          "Test convert real text 2 from Wikipedia.");
