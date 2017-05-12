#!perl

use strict;
use warnings;
use Test::More;
use File::Temp;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Spec::Functions qw/catfile/;
use Cwd;
use Data::Dumper;
use Text::Amuse::Compile;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Templates;

my $xelatex = $ENV{TEST_WITH_LATEX};
if ($xelatex) {
    plan tests => 27;
    diag "Testing with XeLaTeX";
}
else {
    diag "No TEST_WITH_LATEX environment variable found, avoiding use of xelatex";
    plan tests => 22;
}



my $dirh = File::Temp->newdir(CLEANUP => 1);
my $wd = $dirh->dirname;

my $home = getcwd;

my $target = catfile($wd, 'test.muse');

chdir $wd;

write_file("test.muse", "#title test\n\nblablabla\n");

# we we call ->tex, normally the oneside/twoside/bcor are ignored,
# because it's used only on imposed ones, unless we set standalone to
# true.

my $templates = Text::Amuse::Compile::Templates->new;
my $muse = Text::Amuse::Compile::File->new(name => 'test',
                                           suffix => '.muse',
                                           options => {
                                                       oneside => 0,
                                                       twoside => 1,
                                                       bcor => '12mm',
                                                      },
                                           templates => $templates);

my $tex = read_file($muse->tex);

check_overriden($tex);

# but with arguments, bcor and sides are obeyed.
$tex = read_file($muse->tex(dummy => 1));

check_no_overriden($tex);


$muse = Text::Amuse::Compile::File->new(name => 'test',
                                        suffix => '.muse',
                                        standalone => 1,
                                        options => {
                                                    oneside => 0,
                                                    twoside => 1,
                                                    bcor => '12mm',
                                                   },
                                        templates => $templates);

$tex = read_file($muse->tex);

check_no_overriden($tex);

chdir $home;

my $c = Text::Amuse::Compile->new(tex => 1,
                                  extra => {
                                            oneside => 0,
                                            twoside => 1,
                                            bcor => '12mm',
                                           });

ok ($c->standalone, "Is standalone") or (diag Dumper($c) and exit);


$c->compile($target);

$tex = read_file(catfile($wd, 'test.tex'));

check_no_overriden($tex);

$c = Text::Amuse::Compile->new(tex => 1,
                               a4_pdf => 1,
                               extra => {
                                         oneside => 0,
                                         twoside => 1,
                                         bcor => '12mm',
                                        });

ok (!$c->standalone, "it's not standalone");

exit unless $xelatex;

$c->compile($target);

$tex = read_file(catfile($wd, 'test.tex'));

check_overriden($tex);

sub check_overriden {
    my $tex = shift;
    like $tex, qr/blablabla/, "Found the body";
    like $tex, qr/oneside/, "Found oneside";
    like $tex, qr/bcor=0mm/i, "Found bcor=0";
    unlike $tex, qr/twoside/, "Not found twoside";
    unlike $tex, qr/bcor=12mm/i, "Not found bcor=12mm";
}

sub check_no_overriden {
    my $tex = shift;
    like $tex, qr/blablabla/, "Found the body";
    like $tex, qr/twoside/, "Found twoside";
    like $tex, qr/bcor=12mm/i, "Found bcor=12mm";
    unlike $tex, qr/oneside/, "Not found oneside";
    unlike $tex, qr/bcor=0mm/i, "Not found bcor=0";
}


