#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use File::Spec::Functions (qw/catdir catfile/);
use Text::Amuse::Compile::Devel qw/explode_epub/;
use Text::Amuse::Compile::Merged;
use Test::More tests => 37;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $c = Text::Amuse::Compile->new(
                                  pdf => $ENV{TEST_WITH_LATEX},
                                  tex => 1,
                                  epub => 1,
                                  extra => {
                                            mainfont => 'FreeSerif',
                                            monofont => 'DejaVu Sans Mono',
                                            sansfont => 'DejaVu Sans',
                                           },
                                 );

my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
my $src = path(qw/t merged-dir-2/);
foreach my $f ($src->children(qr{\.muse$})) {
    $f->copy($wd->child($f->basename));
}

{
    $c->compile({
                 path => $wd->stringify,
                 files => [qw/farsi english russian farsi english russian farsi/],
                 name => 'my-test',
                 title => 'Test multilingual',
                });
    my $base = $wd->child('my-test');
    my $epub = $base . '.epub';
    my $pdf = $base. '.pdf';
    my $tex = $base .'.tex';
    ok -f $epub, "$epub exists";
    ok -f $tex, "$tex exists";
    my $html = explode_epub($epub);
    like $html, qr{dir="rtl".*dir="ltr".*dir="rtl".*dir="ltr".*dir="rtl"}si, "html switches directions";
    like $html, qr{xml:lang="fa".*xml:lang="en"
                   .*xml:lang="ru".*xml:lang="fa"
                   .*xml:lang="en".*xml:lang="ru"
                   .*xml:lang="fa"}sxi, "langs found";
    unlike $html, qr{xml:lang=""};
  SKIP: {
        skip "No pdf required", 1 unless $ENV{TEST_WITH_LATEX};
        ok (-f $pdf, "$pdf exists");
    }
}

{
    $c->compile({
                 path => $wd->stringify,
                 files => [qw/english farsi russian farsi english russian farsi/],
                 name => 'my-test-2',
                 title => 'Test multilingual (English first)',
                });
    my $base = $wd->child('my-test-2');
    my $epub = $base . '.epub';
    my $pdf = $base. '.pdf';
    my $tex = $base .'.tex';
    ok -f $epub, "$epub exists";
    ok -f $tex, "$tex exists";
    my $html = explode_epub($epub);
    like $html, qr{dir="ltr".*dir="rtl".*dir="ltr".*dir="rtl"}si, "html switches directions";
    like $html, qr{xml:lang="en".*xml:lang="fa"
                   .*xml:lang="ru".*xml:lang="fa"
                   .*xml:lang="en".*xml:lang="ru"
                   .*xml:lang="fa"}sxi, "langs found";
    unlike $html, qr{xml:lang=""};
  SKIP: {
        skip "No pdf required", 1 unless $ENV{TEST_WITH_LATEX};
        ok (-f $pdf, "$pdf exists");
    }

}

{
    my $merged = Text::Amuse::Compile::Merged->new(files => [map { $_->stringify } $src->children ]);
    my @html = $merged->as_splat_html;
    my @structs = $merged->as_splat_html_with_attrs;
    for my $i (0..$#html) {
        is $html[$i], $structs[$i]{text};
    }
    my %langs;
    foreach my $s (@structs) {
        ok $s->{language_code};
        ok $s->{html_direction};
        $langs{$s->{html_direction}}++;
        $langs{$s->{language_code}}++;
    }
    is_deeply \%langs, { en => 2, fa => 3, ru => 3, rtl => 3, ltr => 5};
}
