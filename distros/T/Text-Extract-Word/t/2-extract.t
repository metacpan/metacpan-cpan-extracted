use strict;
use warnings;

use Test::More tests => 27;

use Text::Extract::Word qw(get_all_text);
use File::Spec;
use utf8;

my $string;
my ($volume, $directory, $file) = File::Spec->splitpath(File::Spec->rel2abs(__FILE__));

$string = get_all_text(File::Spec->catpath($volume, $directory, "test1.doc"));
ok($string, "Got text for test1.doc");
like($string, qr{Welcome to BlogCFC}, "Got first string");
like($string, qr{http://lyla.maestropublishing.com/}, "Got second string");
like($string, qr{You must use the IDs.}, "Got third string");

$string = get_all_text(File::Spec->catpath($volume, $directory, "test2.doc"));
ok($string, "Got text for test2.doc");
like($string, qr{My name is Ryan}, "Got first string");
like($string, qr{create several FKPs for testing purposes}, "Got second string");
like($string, qr{dsadasdasdasd}, "Got third string");

$string = get_all_text(File::Spec->catpath($volume, $directory, "test3.doc"));
ok($string, "Got text for test3.doc");
like($string, qr{Can You Release Commercial Works?}, "Got first string");
like($string, qr{Apache v2.0}, "Got second string");
like($string, qr{you want your protections to be.}, "Got third string");

$string = get_all_text(File::Spec->catpath($volume, $directory, "test4.doc"));
ok($string, "Got text test4.doc");
like($string, qr{Moli\x{e8}re}, "Got first string");
like($string, qr{L'Avare ou l'École du mensonge}, "Got second string");
like($string, qr{Les Précieuses ridicules}, "Got third string");
like($string, qr{EUR - €}, "Got fourth string");
like($string, qr{GBP - £}, "Got fifth string");

$string = get_all_text(File::Spec->catpath($volume, $directory, "test5.doc"));
ok($string, "Got text for test5.doc");
like($string, qr{This is a simple file created with Word 97-SR2.}, "Got first string");

$string = get_all_text(File::Spec->catpath($volume, $directory, "test6.doc"));
ok($string, "Got text for test6.doc");
like($string, qr{Insert interface name here}, "Got first string");
like($string, qr{Méthodes appelées}, "Got second string");
like($string, qr{Insert logic description here}, "Got third string");

$string = get_all_text(File::Spec->catpath($volume, $directory, "test9.doc"));
ok($string, "Got text for test9.doc");
like($string, qr!{This line gets read fine}!, "Got first string");
like($string, qr{Ooops, where are the \( opening \( brackets\?}, "Got second string");

1;
