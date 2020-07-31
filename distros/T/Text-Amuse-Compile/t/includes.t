#!perl

use strict;
use warnings;
use Test::More;
use Text::Amuse::Compile;
use Path::Tiny;
use Data::Dumper;
use FindBin;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my @tests = (path(qw/t includes main.muse/)->stringify,
             {
              path => path(qw/t includes/)->stringify,
              files => [qw/main main-2/],
              name => 'test',
              title => 'A test for include',
             });

foreach my $allow (
                   [ allow => path($FindBin::Bin)->absolute->stringify ],
                   [ fail => "/test/blablbala" ],
                   [ fail => "t" ],
                   [ fail => undef ],
                   [ fail => '' ],
                   # this fails because the file says "includes/XXX"
                   # so the resulting would be includes/includes/XXX
                   [ deny => path(qw/t includes/)->absolute->stringify ],
                  ) {
    my $wd = Path::Tiny->tempdir;
    diag "Using $wd for $allow";
    path(qw/t includes main.muse/)->copy($wd->child('main.muse'));
    path(qw/t includes main-2.muse/)->copy($wd->child('main-2.muse'));
    if ($allow->[0] eq 'fail') {
        eval { Text::Amuse::Compile->new(include_paths => [ $allow->[1] ]) };
        ok $@, "Found error $@";
        next;
    }

    my $c = Text::Amuse::Compile->new(tex => 1,
                                      html => 1,
                                      pdf => !!$ENV{TEST_WITH_LATEX},
                                      include_paths => $allow->[1] ? [ $allow->[1] ] : [],
                                     );
    diag Dumper($c->include_paths);
    foreach my $test ($wd->child('main.muse')->stringify,
                      {
                       path => $wd->stringify,
                       files => [qw/main main-2/],
                       name => 'test',
                       title => 'A test for include',
                      }) {
        $c->compile($test);
    }
    my $tex_1 = $wd->child('main.tex')->slurp_utf8;
    my $tex_2 = $wd->child('test.tex')->slurp_utf8;
    my $html_1 = $wd->child('main.html')->slurp_utf8;
    my $html_2 = $wd->child('test.html')->slurp_utf8;

    if ($allow->[0] eq 'allow') {
        for my $out ($tex_1, $html_1, $tex_2, $html_2) {
            like $out, qr{Here we go}, "Found base text";
            like $out, qr{Sample configuration file}, "First included found";
            like $out, qr{included list}, "Second included file found";
            unlike $out, qr{file\.conf};
            unlike $out, qr{file\.muse};
            like $out, qr{passwd};
        }
        for my $out ($tex_2, $html_2) {
            like $out, qr{Just some text}, "Found second file";
        }
    }
    elsif ($allow->[0] eq 'deny') {
        # not included
        for my $out ($tex_1, $html_1, $tex_2, $html_2) {
            like $out, qr{Here we go}, "Found base text";
            unlike $out, qr{Sample configuration file}, "First included found";
            unlike $out, qr{included list}, "Second included file found";
            like $out, qr{file\.conf};
            like $out, qr{file\.muse};
            like $out, qr{passwd};
        }
        for my $out ($tex_2, $html_2) {
            like $out, qr{Just some text}, "Found second file";
        }
    }
}

done_testing;
