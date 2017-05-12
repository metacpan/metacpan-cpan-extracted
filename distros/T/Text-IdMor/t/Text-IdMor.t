# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-IdMor.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 26;
BEGIN { use_ok('Text::IdMor', ':all') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $acronym1 = "S.I.G.L.A.S.";
ok(isAcronym($acronym1), "Test acronym if single uppercase letters and dots");
my $acronym2 = "EE.UU.";
ok(isAcronym($acronym2), "Test acronym if several uppercase letters and dots");
my $notAcronym3 = "Hello.";
ok(!isAcronym($notAcronym3), "Test not acronym");
my $notAcronym4 = "¿Hola?";
ok(!isAcronym($notAcronym4), "Test not acronym with question marks");
my $notAcronym5 = "hello.";
ok(!isAcronym($notAcronym5), "Test not acronym if all lowercase");
my $notAcronym6 = "I.Nacimientos.Fallecimientos.Abderramán";
ok(!isAcronym($notAcronym6), "Test not acronym from WP");
my $notAcronym7 = "Córdoba.Catego.";
ok(!isAcronym($notAcronym7), "Test another not acronym from WP");

my $romanNumberI = "IX";
ok(isRomanNumber($romanNumberI), "Test if it is roman number when it is");
my $notRomanNumberII = "cfgt";
ok(!isRomanNumber($notRomanNumberII), "Test if it is roman number when it is not");

my $number1 = "1.134,45";
ok(isNumber($number1), "Test if it is number when it is (spanish form)");
ok(isSpanishRealNumber($number1), "Test if it is real when it is (spanish form)");
ok(!isInteger($number1), "Test if it is integer when it is real(spanish form)");
my $number2 = "456.67";
ok(isNumber($number2), "Test if it is number when it is (english form)");
my $notNumber3 = "text";
ok(!isNumber($notNumber3), "Test if it is number when it is not");
my $number4 = "-2345";
ok(isNumber($number4), "Test if it is number when it is integer");
ok(isInteger($number4), "Test if it is integer when it is integer");
ok(!isSpanishRealNumber($number4), "Test if it is integer when it is real");
my $number5 = "4,34";
ok(!isInteger($number5), "Test if it is integer when it is real (spanish form) 2");
ok(isSpanishRealNumber($number5), "Test if it is real when it is (spanish form) 2");
my $number6 = 12.345;
ok(isInteger($number6), "Test if it is integer when it has thousands separator");

my $ordinalNumber7 = "3º";
ok(isOrdinalNumber($ordinalNumber7), "Test if it is ordinal when it is");
my $notOrdinalNumber8 = "3a2º";
ok(!isOrdinalNumber($notOrdinalNumber8), "Test if it is ordinal when it is not");

my $word9 = "acrónimo";
ok(isWord($word9), "Test if it is word when it is");
ok(!isWord($notOrdinalNumber8), "Test if it is word when it is not");

my $notWord10 = "¾los";
ok(!isWord($notWord10), "Test if it is word when it is not");