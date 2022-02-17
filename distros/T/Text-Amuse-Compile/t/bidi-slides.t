#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Path::Tiny;
use Test::More tests => 12;

my $c = Text::Amuse::Compile->new(extra => {
                                            sansfont => 'Amiri',
                                            monofont => 'DejaVu Sans Mono',
                                            mainfont => 'Amiri',
                                           },
                                  sl_pdf => !!$ENV{TEST_WITH_LATEX},
                                  sl_tex => 1);

my $muse_fa =<<EOF;
#lang fa
#title Slides
#slides on

** دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛

 - دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛
 - دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛
 - دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛


** دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛

 - دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛
 - دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛
 - دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛

EOF

my $muse_en = <<EOF;
#lang en
#title Slides
#slides on

** Test

 - <<<دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛>>>
 - <[fa]>دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛</[fa]>
EOF

my $muse_fa_en = <<EOF;
#lang fa
#title Slides
#slides on

** دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛

 - >>>english text, left to right<<<
 - <<<دانشنامه‌ای آزاد که همه می‌توانند آن را ویرایش کنند؛>>

EOF

my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});

my @tests = (
             {
              muse => $muse_fa,
              name => 'fa',
              bidi => 1,
              rtl => 1,
             },
             {
              muse => $muse_en,
              name => 'en',
              bidi => 1,
              rtl => 0,
             },
             {
              muse => $muse_fa_en,
              name => 'fa_mix',
              bidi => 1,
              rtl => 1,
             },
            );
foreach my $test (@tests) {
    my $target = $wd->child($test->{name} . '.muse');
    $target->spew_utf8($test->{muse});
    $c->compile("$target");
    my $tex = $wd->child($test->{name} . '.sl.tex');
    my $pdf = $wd->child($test->{name} . '.sl.pdf');
  SKIP:
    {
        skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
        ok($pdf->exists, "$pdf created");
    }
    ok $tex->exists;
    if ($test->{bidi}) {
        like $tex->slurp_utf8, qr/\\usepackage\{bidi\}|bidi=default/;
    }
    else {
        unlike $tex->slurp_utf8, qr/\\usepackage\{bidi\}|bidi=default/;
    }
    if ($test->{rtl}) {
        like $tex->slurp_utf8, qr/\{frametitle\}\[default\]\[right\]/;
    }
    else {
        unlike $tex->slurp_utf8, qr/\{frametitle\}\[default\]\[right\]/;
    }
}
