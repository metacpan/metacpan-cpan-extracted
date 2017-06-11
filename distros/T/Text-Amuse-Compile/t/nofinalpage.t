#!perl

use strict;
use warnings;
use Test::More tests => 12;
use File::Temp;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;

my $tmpdir = File::Temp->newdir(CLEANUP => !$ENV{AMW_DEBUG});
diag "Working in $tmpdir";

my $target = catfile($tmpdir, 'default.muse');
my $tex = catfile($tmpdir, 'default.tex');
my $pdf = catfile($tmpdir, 'default.pdf');

my $muse =<<'MUSE';
#title Test
#notoc 1
#nocoverpage 1

*** Hello

 1. hello
 2. there

*** There

 a. hello

 b. there

*** Blah

 i. hello
 ii. there

*** Blah

 I. hello
 II. there

      1. hello
      2. there

         a. hello
         b. there

      1. hello
      2. there

         i. hello
         ii. there


Hello there
MUSE

foreach my $header (0..1) {
    foreach my $option (0..1) {
        my $c = Text::Amuse::Compile->new(tex => 1,
                                          html => 0,
                                          bare_html => 0,
                                          pdf => !!$ENV{TEST_WITH_LATEX},
                                          ($option ? (extra => { nofinalpage => 1 }) : ()));
        
        my $musebody = $header ? "#nofinalpage 1\n" . $muse : $muse;
        write_file($target, $musebody);
        $c->compile($target);
        ok(-f $tex, "$tex file is present");
        my $texbody = read_file($tex);
        if ($header || $option) {
            unlike($texbody, qr/end final page with colophon/);

        }
        else {
            like($texbody, qr/^% end final page with colophon/m);
        }
      SKIP:
        {
            skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
            ok(-f $pdf, "$pdf created");
        }
    }
}
