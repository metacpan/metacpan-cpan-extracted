#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 12;
use Text::Amuse::Compile;

use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Temp;
use File::Spec;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $muse =<<LOREM;
#title No bold
#subtitle No subtitle bold
#author No bold author

* Part [1]

** Chapter

*** Section {1}

**** Subsection [2]

 term :: Lorem ipsum dolor sit amet, consectetur adipisci elit, sed eiusmod
tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrum exercitationem ullam corporis suscipit


 - list
 - list

 a. list
 b. list

***** Sub sub section {2}

Lorem ipsum dolor sit amet, consectetur adipisci elit, sed eiusmod
tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrum exercitationem ullam corporis suscipit
laboriosam, *nisi ut aliquid ex **ea** commodi consequatur. Quis* aute iure
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint obcaecat cupiditat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

[1] Lorem ipsum dolor sit amet, consectetur adipisci elit, sed eiusmod
    tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim
    veniam, **quis** nostrum exercitationem ullam corporis suscipit
    laboriosam, nisi ut aliquid ex ea commodi consequatur. Quis aute
    iure reprehenderit in voluptate velit esse cillum dolore eu fugiat
    nulla pariatur. Excepteur sint obcaecat cupiditat non proident,
    sunt in culpa qui officia deserunt mollit anim id est laborum. {3} [1]

Hello {4}

{1} Prova [1] {1}

{2} Prova

{3} Prova

[2] Prova

{4} Hello [1] {1}

LOREM

my $tmpdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});

foreach my $nobold (0..1) {
    my $basename = "nobold-$nobold";
    my $target = File::Spec->catfile($tmpdir, $basename . '.muse');
    my $tex = File::Spec->catfile($tmpdir, $basename . '.tex');
    my $pdf = File::Spec->catfile($tmpdir, $basename . '.pdf');
    write_file($target, $muse);
    my $c = Text::Amuse::Compile->new(tex => 1,
                                      pdf => !!$ENV{TEST_WITH_LATEX},
                                      extra => { nobold => $nobold });
    $c->compile($target);
    ok (-f $tex);
  SKIP: {
        skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
        ok(-f $pdf, "$pdf created");
    }
    my $texbody = read_file($tex);
    my $re = qr{\\let\\textbf\\emph\s*\\let\\bfseries\\normalfont}s;
    if ($nobold) {
        like $texbody, $re, "$re found";
    }
    else {
        unlike $texbody, $re, "$re not found";
    }
}

foreach my $start_with_empty_page (0..1) {
    my $basename = "empty-start-$start_with_empty_page";
    my $target = File::Spec->catfile($tmpdir, $basename . '.muse');
    my $tex = File::Spec->catfile($tmpdir, $basename . '.tex');
    my $pdf = File::Spec->catfile($tmpdir, $basename . '.pdf');
    write_file($target, $muse);
    my $c = Text::Amuse::Compile->new(tex => 1,
                                      pdf => !!$ENV{TEST_WITH_LATEX},
                                      extra => { start_with_empty_page => $start_with_empty_page });
    $c->compile($target);
    ok (-f $tex);
  SKIP: {
        skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
        ok(-f $pdf, "$pdf created");
    }
    my $texbody = read_file($tex);
    my $re = qr{^% start with an empty page}m;
    if ($start_with_empty_page) {
        like $texbody, $re, "$re found";
    }
    else {
        unlike $texbody, $re, "$re not found";
    }
}
