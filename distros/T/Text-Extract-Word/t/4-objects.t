use strict;
use warnings;

use Test::More tests => 3;

use Text::Extract::Word;
use File::Spec;

my $string;
my ($volume, $directory, $file) = File::Spec->splitpath(File::Spec->rel2abs(__FILE__));

my $extractor = Text::Extract::Word->new(File::Spec->catpath($volume, $directory, "test9.doc"));

$string = $extractor->get_body();
ok($string, "Successfully got a string body");

like($string, qr!{This line gets read fine}!, "Got first string");
like($string, qr{Ooops, where are the \( opening \( brackets\?}, "Got second string");

1;
