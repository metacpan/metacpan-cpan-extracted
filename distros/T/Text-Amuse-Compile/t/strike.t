#!perl

use strict;
use warnings;
use Test::More tests => 10;
use Text::Amuse::Compile;
use File::Spec;
my $with_latex = !!$ENV{TEST_WITH_LATEX};
my $c = Text::Amuse::Compile->new(pdf => $with_latex,
                                  tex => 1,
                                  epub => 1,
                                  html => 1,
                                  slides => $with_latex,
                                 );
my @exts = (qw/pdf tex epub html sl.pdf/);
my $file = File::Spec->catfile(qw/t testfile strike/);
foreach my $ext (@exts) {
    if (-f "$file.$ext") {
        unlink "$file.$ext" or die "Cannot unlink $file.$ext";
    }
    ok (!-f "$file.$ext", "$file.$ext doesn't exist");
}
$c->compile("$file.muse");

foreach my $ext (@exts) {
  SKIP: {
        skip "pdf compilation not asked", 1 if (!$with_latex and $ext =~ /pdf/);
        ok (-f "$file.$ext", "$file.$ext created");
    };
}
