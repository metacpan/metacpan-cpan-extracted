#!perl

use Test::More tests => 6;
use Text::Amuse;
use Text::Amuse::Compile;
use Data::Dumper;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $xelatex = $ENV{TEST_WITH_LATEX};
my $c = Text::Amuse::Compile->new(tex => 1,
                                  pdf => $xelatex,
                                  html => 1,
                                  extra => {
                                            mainfont => 'TeX Gyre Pagella',
                                            papersize => 'a5',
                                           });

diag "Try to compile";

my $wd = Path::Tiny->tempdir;

my $testdir = path(qw/t check-compile/);
foreach my $src ($testdir->children(qr{\.muse})) {
    my $basename = $src->basename;
    my $target = $wd->child($basename);
    $src->copy($target);
    $c->compile("$target");
    
    $basename =~ s/\.muse$//;
    ok $wd->child($basename . '.html')->exists, "HTML ok";
    ok $wd->child($basename . '.tex')->exists, "TeX ok";
  SKIP: {
        skip "PDF not required", 1 unless $xelatex;
        ok $wd->child($basename . '.pdf')->exists, "PDF ok";
    };
}

