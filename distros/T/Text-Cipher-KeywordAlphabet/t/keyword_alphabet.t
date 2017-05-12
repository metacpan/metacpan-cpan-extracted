###############################################################################
# Purpose : Unit test for Text::Cipher::KeywordAlphabet
# Author  : John Alden
# Created : 2 Jan 2005
# CVS     : $Header: t:\\John\\cvsroot/text-cipher-keyword-alphabet/t/keyword_alphabet.t,v 1.1.1.1 2005/01/09 15:34:11 Alex Exp $
###############################################################################

use strict;
use Test::More;

#Move into the t directory
chdir($1) if($0 =~ /(.*)\/(.*)/);
unshift @INC, "./lib", "../lib";

#The tests
plan tests => 12;
require_ok("Text::Cipher::KeywordAlphabet");
ok($Text::Cipher::KeywordAlphabet::VERSION =~ /^\d\.\d{3}$/, "Version - $Text::Cipher::KeywordAlphabet::VERSION");

#Typical usage
my $keywords = "the lazy brown fox jumped over";
my $cipher = new Text::Cipher::KeywordAlphabet($keywords);
isa_ok($cipher, "Text::Cipher::KeywordAlphabet");

ok($cipher->alphabet() eq "THELAZYBROWNFXJUMPDVCGIKQS", "expected alphabet");
ok($cipher->encipher(join("", 'a'..'z')) eq "thelazybrownfxjumpdvcgikqs", "encipher");
ok($cipher->decipher("thelazybrownfxjumpdvcgikqs") eq join("", 'a'..'z'), "decipher");

#Limiting cases
$cipher = new Text::Cipher::KeywordAlphabet();
ok($cipher->alphabet() eq join("", 'A'..'Z'), "Null cipher");
$cipher = new Text::Cipher::KeywordAlphabet(undef, 13);
ok($cipher->alphabet() eq join("", 'N'..'Z','A'..'M'), "Rot 13");

#Negative and wrap-around offsets
$cipher = new Text::Cipher::KeywordAlphabet(undef, -1);
ok($cipher->alphabet() eq join("", 'Z','A'..'Y'), "Rot -1");
$cipher = new Text::Cipher::KeywordAlphabet(undef, 39);
ok($cipher->alphabet() eq join("", 'N'..'Z','A'..'M'), "Rot 39");
$cipher = new Text::Cipher::KeywordAlphabet(undef, -27);
ok($cipher->alphabet() eq join("", 'Z','A'..'Y'), "Rot -27");

#Error trapping
eval {
	$cipher = new Text::Cipher::KeywordAlphabet(undef, "text");
};
ok($@ =~ /integer/, "Check offset is an integer");