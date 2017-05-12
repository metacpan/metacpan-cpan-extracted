# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-AsReadWithoutIntonation.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 12;
BEGIN { use_ok('Text::AsReadWithoutIntonation', ':test') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $simpleSentenceToRead = "Frase simple para leer.";
my $simpleSentenceRead = "frase simple para leer";

is(inSpanish($simpleSentenceToRead), 
   $simpleSentenceRead,
   "Test read simple sentence");

my $sentenceWithAcronymsToRead = "Frase con acrónimos A.S.I.";
my $sentenceWithAcronymsRead = "frase con acrónimos a ese i";
is(inSpanish($sentenceWithAcronymsToRead),
   $sentenceWithAcronymsRead,
   "Test read sentence with acronyms");

my $sentenceWithNonRecognisedCharsToRead = "Esta es una F.R.A.S.E.) con caracteres no legibles";
my $sentenceWithNonRecognisedCharsRead = "esta es una efe erre a ese e con caracteres no legibles";
is(inSpanish($sentenceWithNonRecognisedCharsToRead),
   $sentenceWithNonRecognisedCharsRead,
   "Test read sentence with non recognised chars");

my $sentenceWithRomanNumbersToRead = "Carlos I fue rey de España en el siglo XVI";
my $sentenceWithRomanNumbersRead = "carlos primero fue rey de españa en el siglo dieciséis";
is(inSpanish($sentenceWithRomanNumbersToRead),
   $sentenceWithRomanNumbersRead,
   "Test read sentence with integer arabic numbers");

my $sentenceWithIntegerArabicNumbersToRead = "Esta frase tiene 6 palabras S.A.";
my $sentenceWithIntegerArabicNumbersRead = "esta frase tiene seis palabras ese a";
is(inSpanish($sentenceWithIntegerArabicNumbersToRead),
   $sentenceWithIntegerArabicNumbersRead,
   "Test read sentence with integer arabic numbers");

my $sentenceWithOrdinalsToRead = "El 3º fue el que llegó después de la 2ª posición";
my $sentenceWithOrdinalsRead = "el tercero fue el que llegó después de la segunda posición";
is(inSpanish($sentenceWithOrdinalsToRead),
   $sentenceWithOrdinalsRead,
   "Test read sentence with ordinals");
my $sentenceWithSymbolsToRead = 'El 2º día de abril dije 12,034+2 = -1674,00365, lo que supone el 20% de la cantidad de 345,67€ que envié a http://midominio.es/micasa.html por 3ª vez.';
my $sentenceWithSymbolsRead = "el segundo día de abril dije doce con cero treinta y cuatro más dos igual a menos mil seiscientos setenta y cuatro con cero cero trescientos sesenta y cinco lo que supone el veinte por ciento de la cantidad de trescientos cuarenta y cinco con sesenta y siete euros que envié a hache te te pe dos puntos barra barra eme i de o eme i ene i o punto e ese barra eme i ce a ese a punto hache te eme ele por tercera vez";
is(inSpanish($sentenceWithSymbolsToRead),
   $sentenceWithSymbolsRead,
   "Test read sentence with many symbols");

my $sentenceWithLargeIntegerNumberToRead = "Hay 1.000.000 de cosas por hacer";
my $sentenceWithLargeIntegerNumberRead = "hay un millón de cosas por hacer";
is(inSpanish($sentenceWithLargeIntegerNumberToRead),
   $sentenceWithLargeIntegerNumberRead,
   "Test read sentence with many symbols");

my $sentenceWithStrangeCharactersToRead = "Frase rara ¶los";
my $sentenceWithStrangeCharactersRead = "frase rara los";
is(inSpanish($sentenceWithStrangeCharactersToRead),
   $sentenceWithStrangeCharactersRead,
   "Test read sentence with many symbols");

my $sentenceWithOnlyOneStangeSymbolToRead = "←";
my $sentenceWithOnlyOneStangeSymbolRead = "";
is(inSpanish($sentenceWithOnlyOneStangeSymbolToRead),
   $sentenceWithOnlyOneStangeSymbolRead,
   "Test read sentence with one strange symbol");

my $sentenceWithSpanishUpperCaseCharToRead = "Árbol";
my $sentenceWithSpanishUpperCaseCharRead = "árbol";
is(inSpanish($sentenceWithSpanishUpperCaseCharToRead),
   $sentenceWithSpanishUpperCaseCharRead,
   "Test read sentence when accented letters are upper case");