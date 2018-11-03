#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 248;
use Text::Amuse::Compile;
use Text::Amuse::Compile::TemplateOptions;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Temp;
use File::Spec;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $tmpdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});

diag "Working on $tmpdir";

my $random = <<LOREM;

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum."

Sed ut perspiciatis unde omnis iste natus error sit voluptatem
accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae
ab illo inventore veritatis et quasi architecto beatae vitae dicta
sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit
aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos
qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui
dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed
quia non numquam eius modi tempora incidunt ut labore et dolore magnam
aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum
exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex
ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in
ea voluptate velit esse quam nihil molestiae consequatur, vel illum
qui dolorem eum fugiat quo voluptas nulla pariatur?

LOREM

my $muse =<< "MUSE";
#title My title
#subtitle My subtitle
#author My author

* This is a part

$random

** This is a chapter

$random

*** this is a section

$random

**** this is a subsection

$random

* This is a part (2)

$random

** This is a chapter (2)

$random

*** this is a section (2)

$random

**** this is a subsection (2)

$random


MUSE

foreach my $spec (Text::Amuse::Compile::TemplateOptions->all_headings) {
    foreach my $titleonly (0..1) {
        foreach my $twoside (0..1) {
        my $c = Text::Amuse::Compile->new(tex => 1,
                                          pdf => !!$ENV{TEST_WITH_LATEX},
                                          extra => {
                                                    headings => $spec->{name},
                                                    papersize => 'b6',
                                                    twoside => $twoside,
                                                   });
        diag "Testing <$spec->{name}> : $spec->{desc} headings";

        my $basename = "test-" . $spec->{name};
        $basename =~ s/_/-/g;
        $basename =~ s/-$//;
        my $musebody = $muse;
        if ($twoside) {
            $basename .= '-2side';
        }
        if ($titleonly) {
            $basename .= '-titleonly';
            $musebody =~ s/^#(subtitle|author).*$//mg;
        }
        my $target = File::Spec->catfile($tmpdir, $basename . '.muse');
        my $tex = File::Spec->catfile($tmpdir, $basename . '.tex');
        my $pdf = File::Spec->catfile($tmpdir, $basename . '.pdf');
        write_file($target, $musebody);
        $c->compile($target);
        ok (-f $tex, "$tex found");

        my $texbody = read_file($tex);
        if (!$spec->{name}) {
            like($texbody, qr{headinclude\=false\,\%}, "headinclude is false");
            like($texbody, qr!\\pagestyle\{plain\}!, "plain pagestyle");
            unlike($texbody, qr!\\pagestyle\{scrheadings\}!, "not custom pagestyle");
        } else {
            like($texbody, qr{headinclude\=true\,\%}, "headinclude is true");
            unlike($texbody, qr!\\pagestyle\{plain\}!, "not a plain pagestyle");
            like($texbody, qr!\\pagestyle\{scrheadings\}!, "custom pagestyle");
            if ($twoside) {
                like($texbody, qr/(\\rehead\{[^\\].+\}|\\automark)/, "heading definition found");
                like($texbody, qr/(\\lohead\{[^\\].+\}|\\automark)/, "heading definition found");
                while ($texbody =~ m/\\((re|lo)head)\{(.*)\}/g) {
                    diag "$1 = $3";
                }
            }
            else {
                like($texbody, qr/(\\chead\{[^\\].*\}|\\automark)/, "heading definition found");
                while ($texbody =~ m/\\((c)head)\{(.*)\}/g) {
                    diag "$1 = $3";
                }
            }
        }

      SKIP: {
            skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
            ok(-f $pdf, "$pdf created");
        }
    }
    }
}
