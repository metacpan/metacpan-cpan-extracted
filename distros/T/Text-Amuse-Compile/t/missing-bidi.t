#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Path::Tiny;
use Test::More tests => 4;

my $c = Text::Amuse::Compile->new(extra => {
                                            notoc => 1,
                                            mainfont => 'Amiri',
                                           },
                                  pdf => !!$ENV{TEST_WITH_LATEX},
                                  tex => 1);

my $muse =<<EOF;
#lang en

This i just a test. <[fa]>به ویکی‌پدیا خوش‌آمدید</[fa]>
EOF

my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
my $target = $wd->child('rtl.muse');
$target->spew_utf8($muse);
$c->compile("$target");
my $tex = $wd->child('rtl.tex');
my $pdf = $wd->child('rtl.pdf');
  

SKIP:
{
    skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
    ok($pdf->exists, "$pdf created");
}

ok $tex->exists;
my $tex_body = $tex->slurp_utf8;
like $tex_body, qr/\\usepackage\{bidi\}|bidi=default|bidi=basic|bidi=bidi-(l|r)/;
like $tex_body, qr/\\foreignlanguage\{persian\}\{به ویکی‌پدیا خوش‌آمدید\}/;
