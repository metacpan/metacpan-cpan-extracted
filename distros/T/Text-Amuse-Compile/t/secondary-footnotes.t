#!perl

use strict;
use warnings;
use Test::More tests => 17;
use File::Spec::Functions qw/catdir catfile/;
use File::Temp;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Text::Amuse::Compile;
# use Data::Dumper;

my $workingdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});
diag "Using " . $workingdir->dirname;

my $muse = <<'MUSE';
#title Secondary footnotes
#slides yes

This is a test

** Chapter 1 [1] {1}

Here we have [2] a footnote and a secondary {2}

[1] First {3}

[2] Second {4}

{1} sec-first

{2} sec-second

{3} sec-third

{4} sec-forth

** Chapter 2 [3] {5}

 Term :: Here we have [4] a footnote and a secondary

 - in a list  {6}

 In a table [5] | Another {11}


[3] First {7}

    Multiline {8}

[4] Second {9}

    Multiline {10}

[5] Third multi

    line

{5} 5-sec-first [1] {1}

    multiline [1] {1}

{6} 6-sec-first [1] {1}

    multiline [1] {1}

{7} 7-sec-first [1] {1}

    multiline [1] {1}

{8} 8-sec-first [1] {1}

    multiline [1] {1}

{9} 9-sec-first [1] {1}

    multiline [1] {1}

{10} 10-sec-first [1] {1}

     multiline [1] {1}

{11} 11-sec-first [1] {1}

     multiline [1] {1}

MUSE

foreach my $alpha (0,1) {
    my $source = catfile($workingdir, 'secondary-footnotes-' . $alpha);
    write_file($source . '.muse', $muse);

    my %args = (
                tex => 1,
                epub => 1,
                html => 1,
                sl_tex => 1,
                pdf => $ENV{TEST_WITH_LATEX},
                sl_pdf => $ENV{TEST_WITH_LATEX},
              );

    {
        my $c = Text::Amuse::Compile->new(%args,
                                          extra => { secondary_footnotes_alpha => $alpha },
                                         );
        # diag Dumper($c->extra_opts);
        $c->compile($source . '.muse');
        foreach my $ext (keys %args) {
            my $real = $ext;
            $real =~ s/_/./;
            my $output = $source . '.' . $real;
            if ($ext eq 'tex') {
                my $texbody = read_file($output);
                if ($alpha) {
                    like $texbody, qr{\\MakeSortedPerPage\[1\]\{footnoteB\}}, "alpha option picked up";
                    unlike $texbody, qr{\\MakeSorted\{footnoteB\}};
                }
                else {
                    unlike $texbody, qr{\\MakeSortedPerPage\[1\]\{footnoteB\}};
                    like $texbody, qr{\\MakeSorted\{footnoteB\}};
                    like $texbody, qr{\\renewcommand\*\\thefootnoteB\{\(\\arabic\{footnoteB\}\)}, "Found the (1)";
                }
            }
            if ($args{$ext}) {
                ok (-f $output, "$ext found in $output")
            } else {
              SKIP:
                {
                    skip "pdf $ext not required", 1 unless $ENV{TEST_WITH_LATEX};
                    ok(-f $output, "$ext found in $output")
                }
            }
        
        }
    }
}
