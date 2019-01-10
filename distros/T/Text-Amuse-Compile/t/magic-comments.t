#!perl

# This feature is EXPERIMENTAL.

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Path::Tiny;
use Data::Dumper;
use Test::More tests => 31;

my $muse = <<'MUSE';
#title My title

Test 

START
; :DEFAULT: \sloppy
; :c111: \fussy
; :c9: \newpage

Done

; :c9: \sloppy 10
; :c9: \vskip 10mm
; :DEFAULT: \fussy
; :c111: \sloppy
END

MUSE

foreach my $id (qw/DEFAULT c111 c1 c9/, '', 'test me', '\\') {
    my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
    my $file = $wd->child("text.muse");
    $file->spew_utf8($muse);
    my $c = Text::Amuse::Compile->new(
                                      tex => 1,
                                      pdf => $ENV{TEST_WITH_LATEX},
                                      extra => { format_id => $id }
                                     );
    $c->compile("$file");
    my $tex = $wd->child("text.tex")->slurp_utf8;
    if ($id eq 'DEFAULT') {
        like $tex, qr{START.*\\sloppy.*Done.*\\fussy.*END}ms;
    }
    elsif ($id eq 'c111') {
        like $tex, qr{START.*\\fussy.*Done.*\\sloppy.*END}ms;
    }
    else {
        unlike $tex, qr{START.*\\(fussy|sloppy).*Done.*\\(sloppy|fussy).*END/}ms;
    }
    if ($id eq 'c9') {
        like $tex, qr{^\\newpage\s*\n}ms;
        like $tex, qr{^\\vskip 10mm\s*\n}ms;
    }
    else {
        like $tex, qr{^\%.*?\\textbackslash\{\}newpage\s*\n}ms;
        like $tex, qr{^\%.*?\\textbackslash\{\}vskip 10mm\s*\n}ms;
    }
    unlike $tex, qr{\\sloppy 10};

    if ($id eq '' or $id eq '\\' or $id eq 'test me') {
        like $tex, qr{START.*\\sloppy.*Done.*\\fussy.*END}ms;
    }
}
