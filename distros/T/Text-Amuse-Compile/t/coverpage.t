#!perl

use strict;
use warnings;
use Test::More tests => 14;
use File::Temp;
use File::Copy qw/copy/;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);

my $target = catfile($tmpdir, 'default.muse');
my $tex = catfile($tmpdir, 'default.tex');
my $muse =<<'MUSE';
#title Test
#cover prova.png
#coverwidth 0.5

Hello there
MUSE

my $c = Text::Amuse::Compile->new(tex => 1);

write_file($target, $muse);

$c->compile($target);

ok(-f $tex);

my $texbody = read_file($tex);

like($texbody, qr/\{scrbook\}/);
unlike($texbody, qr/\\let\\chapter\\section/);
unlike($texbody, qr/prova\.png/);

copy(catfile(qw/t manual logo.png/), catfile($tmpdir, "prova.png"));

$c->compile($target);

$texbody = read_file($tex);

like($texbody, qr/0\.5\\textwidth.*prova\.png/, "Found the cover with coverwidth from file");

SKIP: {
    skip "Not needed", 2 unless $ENV{TEST_WITH_LATEX};
    $c = Text::Amuse::Compile->new(tex => 1, pdf => 1, epub => 1);
    $c->compile($target);
    my $pdf = $tex;
    $pdf =~ s/\.tex/.pdf/;
    my $epub = $tex;
    $epub =~ s/\.tex/.epub/;
    ok (-f $pdf, "$pdf found");
    ok (-f $epub, "$epub found");
}


$c = Text::Amuse::Compile->new(tex => 1, extra => { nocoverpage => 1 });

$c->compile($target);
$texbody = read_file($tex);

like($texbody, qr/\{scrartcl\}/, "Passing nocoverpage as extra changes the class");

$muse =<<'MUSE';
#title Test
#nocoverpage 1
#cover prova.png

Hello there
MUSE

write_file($target, $muse);
$c = Text::Amuse::Compile->new(tex => 1);
$c->compile($target);
$texbody = read_file($tex);
unlike($texbody, qr/prova\.png/, "No cover set because of nocoverpage");
like($texbody, qr/\{scrartcl\}/, "Passing nocoverpage in header changes the class");

$muse =<<'MUSE';
#title Test
#nocoverpage 1

** Hello there

Blablabla

MUSE

write_file($target, $muse);
$c = Text::Amuse::Compile->new(tex => 1);
$c->compile($target);
$texbody = read_file($tex);
like($texbody, qr/\{scrartcl\}/,
     "Passing nocoverpage in header, but with toc, changes the class nevertheless");
like($texbody, qr/\\let\\chapter\\section/);

$muse =<<'MUSE';
#title Test
#cover prova.png

** Hello there

Blablabla

MUSE

write_file($target, $muse);
$c = Text::Amuse::Compile->new(tex => 1, extra => { cover => 'mytest.png',
                                                    coverwidth => '0.2'
                                                  });
$c->compile($target);
$texbody = read_file($tex);
like $texbody, qr/0\.2\\textwidth.*mytest.png/;

write_file($target, $muse);
$c = Text::Amuse::Compile->new(tex => 1, extra => { cover => '',
                                                    coverwidth => '0.2'
                                                  });
$c->compile($target);
$texbody = read_file($tex);
unlike $texbody, qr/(mytest|prova).png/;
