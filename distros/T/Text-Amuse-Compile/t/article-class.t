#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 24;
use Text::Amuse::Compile;
use Text::Amuse::Compile::TemplateOptions;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Temp;
use File::Spec::Functions qw/catfile/;
use File::Copy qw/copy/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $tmpdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});
copy (catfile(qw/t testfile attachment.png/), catfile($tmpdir, 'try.png'));
diag "Working on $tmpdir";

my $lorem = <<LOREM;

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
#cover try.png

$lorem

* Part

$lorem

** Chapter

$lorem

*** Section

$lorem

**** Subsection

$lorem

***** Subsubsection

$lorem

* Part

$lorem

** Chapter

$lorem

*** Section

$lorem

**** Subsection

$lorem

***** Subsubsection

$lorem

MUSE

foreach my $nocover (0..1) {
    foreach my $header_set (0..1) {
        my $musebody = $header_set ? "#nocoverpage 1\n" . $muse : $muse;
        my $basename = "test-nocover-$nocover-header-$header_set";
        my $target = catfile($tmpdir, $basename . '.muse');
        my $tex = catfile($tmpdir, $basename . '.tex');
        my $pdf = catfile($tmpdir, $basename . '.pdf');
        write_file($target, $musebody);
        my $c = Text::Amuse::Compile->new(tex => 1,
                                          pdf => !!$ENV{TEST_WITH_LATEX},
                                          extra => {
                                                    nocoverpage => $nocover,
                                                   });
        diag "compiling $target";
        $c->compile($target);
        ok (-f $tex) or die "No $tex produced";
        my $texbody = read_file($tex);
        like $texbody, qr/\\chapter\{/;
        if ($nocover || $header_set) {
            like $texbody, qr/\{scrartcl\}/;
            unlike $texbody, qr/try\.png/, "Cover not found";
            like $texbody, qr/\\let\\chapter\\section/;
        }
        else {
            like $texbody, qr/\{scrbook\}/;
            like $texbody, qr/try\.png/, "Cover found";
            unlike $texbody, qr/\\let\\chapter\\section/;
        }
      SKIP:
        {
            skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
            ok(-f $pdf, "$pdf created");
        }
    }
}
