#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Devel qw/explode_epub/;
use Path::Tiny;
use Test::More tests => 38;

my $muse = <<"MUSE";
#title My title
#author My author
#lang it
#pubdate 2018-09-05T13:30:34
#notes Seconda edizione riveduta e corretta: novembre 2018
MUSE

my %values = (
              isbn => '978-19-19333-15-8',
              rights => '© 2018 Pinco Pallino',
              seriesname => 'My series',
              seriesnumber => '69bis',
              publisher => 'My publisher <br> Publisher address <br> city',
              colophon => 'XXXX<br>XXXX',
             );

foreach my $k (keys %values) {
    $muse .= "#" . "$k $values{$k}\n";
}


for my $trigger_impressum (0..1) {
    my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
    my $file = $wd->child("text.muse");
    $file->spew_utf8($muse);
    my $c = Text::Amuse::Compile->new(html => 1, epub => 1, tex => 1,
                                      pdf => $ENV{TEST_WITH_LATEX},
                                      extra => { impressum => $trigger_impressum });
    $c->compile("$file");

    my $html = $wd->child("text.html")->slurp_utf8;
    foreach my $val (values %values) {
        my $str = $val;
        $str =~ s/<br>/<br \/>/g;
        like $html, qr{\Q$str\E};
    }

    my $tex = $wd->child("text.tex")->slurp_utf8;
    foreach my $val (values %values) {
        my $str = $val;
        $str =~ s/ *<br>/\\forcelinebreak /g;
        like $tex, qr{\Q$str\E};
    }
    my $epub = explode_epub($wd->child("text.epub")->stringify);
    foreach my $val (values %values) {
        my $str = $val;
        $str =~ s/<br>/<br \/>/g;
        like $epub, qr{\Q$str\E};
    }
    my $pdf = $wd->child("text.pdf");
  SKIP: {
        skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
        ok $pdf->exists;
    }
    diag $wd;
}


