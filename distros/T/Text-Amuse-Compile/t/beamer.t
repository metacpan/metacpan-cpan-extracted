#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec::Functions qw/catdir catfile/;
use File::Temp;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile;
use Cwd;

use constant {
    TEST_WITH_LATEX => $ENV{TEST_WITH_LATEX},
};


plan tests => (TEST_WITH_LATEX ? 78 : 68);

my $basename = "slides";
my $workingdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});
diag "Using " . $workingdir->dirname;

my %compiler_args = (sl_tex => !TEST_WITH_LATEX, slides => !!TEST_WITH_LATEX);

my $muse_body = <<'MUSE';
#title Slides

*** Text::Slides {2}

 - first
 - second

{2} footnotes

*** Section ignored

; noslide

*** Ignored section

Text ignored

; noslide

This is ignored

*** Second Text::Slides [1]

 - third
 - fourth
 Term :: Definition

[1] Footnote

MUSE

my @falses = (undef, '', '0', 'no', 'NO', 'false', 'FALSE');
my (@compile, @nocompile);
foreach my $false (@falses) {
    my $suffix = $false;
    my $body;
    if (!defined($false)) {
        $suffix = 'undefined';
        $body = $muse_body;
    }
    else {
        $body = "#slides $false\n" . $muse_body;
    }
    if (!length($suffix)) {
        $suffix = 'empty';
    }
    my $name = $basename . '-'. $suffix;
    my $target = catfile($workingdir->dirname, $name . '.muse');
    write_file($target, $body);
    push @nocompile, $target;
}

foreach my $true ($basename) {
    my $target = catfile($workingdir->dirname, $basename . '.muse');
    write_file($target, "#slides yes\n" . $muse_body);
    push @compile, $target;
}

foreach my $noc (@nocompile) {
    my $c = Text::Amuse::Compile->new(%compiler_args);
    my $out_tex = my $out_pdf = $noc;
    $out_tex =~ s/muse$/sl.tex/;
    $out_pdf =~ s/muse$/sl.pdf/;
    $c->purge($noc);
    ok(!$c->file_needs_compilation($noc), "$noc doesn't need compilation");
    ok ((! -f $out_tex), "No sl.tex present for $noc");
    ok ((! -f $out_pdf), "No slides present for $noc");
    $c->compile($noc);
    ok ((! -f $out_tex), "No sl.tex generated for $noc");
    if (TEST_WITH_LATEX) {
        ok ((! -f $out_pdf), "No slides generated for $noc");
    }
    my $header = Text::Amuse::Compile->parse_muse_header($noc);
    ok (!$header->wants_slides, "Doesn't want slides");
    is ($header->language, 'en');
}

foreach my $comp (@compile) {
    my $out_tex = my $out_pdf = $comp;
    $out_tex =~ s/muse$/sl.tex/;
    $out_pdf =~ s/muse$/sl.pdf/;
    my $c = Text::Amuse::Compile->new(%compiler_args);
    $c->purge($comp);
    ok($c->file_needs_compilation($comp), "$comp needs compilation");
    ok ((! -f $out_tex), "No sl.tex present for $comp");
    ok ((! -f $out_pdf), "No slides present for $comp");
    $c->compile($comp);
    ok ((-f $out_tex), "TeX file for slides for $comp");
    my $texbody = read_file($out_tex);
    unlike ($texbody, qr/Section ignored/, "No ignore part found");
    unlike ($texbody, qr/Ignored section/, "No ignore part found");
    unlike ($texbody, qr/This is ignored/, "No ignore part found");
    unlike ($texbody, qr/Text ignored/, "No ignore part found");
    like ($texbody, qr/begin\{frame\}.+first.+second.+end\{frame\}/s,
          "Found a frame");
    if (TEST_WITH_LATEX) {
        ok ((-f $out_pdf), "No slides generated for $comp");
    }
    ok(!$c->file_needs_compilation($comp), "$comp doesn't need compilation");
    my $header = Text::Amuse::Compile->parse_muse_header($comp);
    ok ($header->wants_slides, "File wants slides");
    is ($header->language, 'en');
}

my %extra = (
             sansfont => 'Iwona',
             beamertheme => 'Madrid',
             beamercolortheme => 'wolverine',
            );
{
    my $c = Text::Amuse::Compile->new(%compiler_args);
    my $muse = catfile(qw/t testfile slides.muse/);
    my $tex = catfile(qw/t testfile slides.sl.tex/);
    my $pdf = catfile(qw/t testfile slides.sl.pdf/);
    $c->purge($muse);
    $c->compile($muse);
    ok (-f $tex, "TeX $tex generated");
    if (TEST_WITH_LATEX) {
        ok (-f $pdf, "PDF generated");
    }
    my $content = read_file($tex);
    like $content, qr/sansfont\{CMU Sans/, "Sans font as default";
    like $content, qr/colortheme\{dove/, "colortheme is dove";
    like $content, qr/usetheme\{default/, "theme is default";
    unlike $content, qr/ignored/, "Ignored sections are skipped";
    $c = Text::Amuse::Compile->new(%compiler_args, extra => \%extra);
    $c->purge($muse);
    $c->compile($muse);
    ok (-f $tex, "TeX $tex generated");
    ok (!$c->file_needs_compilation($muse), "File $muse doesn't need compilation");
    ok (-f $pdf, "PDF $pdf generated") if TEST_WITH_LATEX;
    $content = read_file($tex);
    like $content, qr/sansfont\{Iwona\}/, "Sans font as default";
    like $content, qr/colortheme\{wolverine/, "colortheme is dove";
    like $content, qr/usetheme\{Madrid/, "theme is default";
    $c->purge($muse);
    ok (! -f $pdf, "$pdf purged");
    ok (! -f $tex, "$tex purged");
    ok (-f $muse,  "$muse still here");
    ok ($c->file_needs_compilation($muse), "File $muse needs compilation");
}

