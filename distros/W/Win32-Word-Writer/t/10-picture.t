#!perl -w
use strict;

use Test::More tests => 15;
use Test::Exception;
use File::Path;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::setup(), "Set up test harness");





use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");

my @aText;
my $text;


my $filePictureLink = "data/lolcat.jpg";
push(@aText, { pre => q|src="|, text => $text = $filePictureLink, post => q|"|});
push(@aText, { pre => "", text => "width=143", post => ""});
push(@aText, { pre => "", text => "height=107", post => ""});
is($oWriter->InsertPicture($filePictureLink), 1, "InsertPicture linked ok");



my $filePictureEmbed = "data/lolbox.jpg";
push(@aText, { pre => "", text => "width=576", post => ""});
push(@aText, { pre => "", text => "height=476", post => ""});
is($oWriter->InsertPicture($filePictureEmbed, 1), 1, "InsertPicture embedded ok");



my $file = "10-picture-link.html";
is($oWriter->SaveAs($file, format => "HTML"), 1, "SaveAs HTML ok");
my $html = WordTest::readFile($file);

for my $rhText (@aText) {
    like($html, qr/$rhText->{pre}$rhText->{text}$rhText->{post}/s, " found text ($rhText->{text}) in file") or diag("((($html)))\n");
}
unlike(
    $html,
    qr/$filePictureEmbed/,
    "Embedded file name not in the file (let's hope they don't change that in the future)",
);


$oWriter->Checkpoint();    #To release lock on file.

ok(WordTest::teardown(), "Tear down test harness");
ok( rmtree(["10-picture-link_files"]), "Cleaned up temp dir");



__END__
