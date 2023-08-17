use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Path::Tiny;
use Test::More tests => 12;

my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
diag "Working in $wd";
foreach my $use_luatex (0..1) {
    my $c = Text::Amuse::Compile->new(extra => {
                                                notoc => 1,
                                                mainfont => 'Amiri',
                                               },
                                      pdf => !!$ENV{TEST_WITH_LATEX},
                                      luatex => $use_luatex,
                                      tex => 1);
    foreach my $lang (qw/en fa/) {
        my $muse =<<EOF;
#title Test
#lang $lang

<[en]>
This i just a test.
</[en]>

<[fa]>
به ویکی‌پدیا خوش‌آمدید
</[fa]>
EOF
        my $prefix = $use_luatex ? "lua" : "xe";
        my $basename = $prefix . "-$lang-ltr";
        my $target = $wd->child("$basename.muse");
        $target->spew_utf8($muse);
        $c->compile("$target");
        my $tex = $wd->child("$basename.tex");
        my $pdf = $wd->child("$basename.pdf");
      SKIP:
        {
            skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
            ok($pdf->exists, "$pdf created");
        }
        ok $tex->exists;
        my $tex_body = $tex->slurp_utf8;
        if ($use_luatex) {
            like $tex_body, qr/bidi=basic/;
        }
        elsif ($lang eq 'en') {
            like $tex_body, qr/bidi=bidi-l/;
        }
        elsif ($lang eq 'fa') {
            like $tex_body, qr/bidi=bidi-r/;
        }
        else {
            die "Not reached";
        }
    }
}
