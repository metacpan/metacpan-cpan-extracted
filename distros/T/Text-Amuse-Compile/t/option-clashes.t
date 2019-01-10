#!perl
use strict;
use warnings;
use Text::Amuse::Compile;
use Test::More tests => 2;
use Path::Tiny;


my $muse = <<'MUSE';
#title My title

* Test

** Test

MUSE

my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
my $file = $wd->child("text.muse");
$file->spew_utf8($muse);
my $c = Text::Amuse::Compile->new(
                                  tex => 1,
                                  pdf => $ENV{TEST_WITH_LATEX},
                                  extra => {
                                            continuefootnotes => 1,
                                            nocoverpage => 1,
                                           },
                                 );
$c->compile("$file");
ok $wd->child("text.tex")->exists;

SKIP: {
    skip "No pdf required", 1 unless $ENV{TEST_WITH_LATEX};
    ok $wd->child("text.pdf")->exists;
}
  
