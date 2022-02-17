#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 6;
use Text::Amuse::Compile;
use Path::Tiny;

my $testdir = path(qw/t asian/);

my $c = Text::Amuse::Compile->new(
                                  fontspec => $testdir->child('fontspec.json')->absolute->stringify,
                                  extra => {
                                            papersize => 'a6',
                                            mainfont => "Linux Libertine O",
                                           },
                                  tex => 1,
                                  pdf => $ENV{TEST_WITH_LATEX},
                                 );

my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NO_CLEANUP});
foreach my $file ($testdir->children(qr{\.muse$})) {
    my $basename = $file->basename(qr{\.muse});
    my $target = $wd->child($basename . '.muse');
    $file->copy($target);
    $c->compile("$target");
    my $body = $wd->child($basename . '.tex')->slurp_utf8;
    $body =~ s/\r//g; # windows
    my $exp = $testdir->child($basename . '.tex')->slurp_utf8;
    like $body, qr{\Q$exp\E};
  SKIP: {
        skip "No pdf required", 1 unless $c->pdf;
        ok $wd->child($basename . '.pdf')->exists;
    }
}
