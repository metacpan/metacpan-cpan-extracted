#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use Config;

{
    local %ENV = %ENV;
    my @p5lib = split($Config{'path_sep'}, $ENV{'PERL5LIB'});
    $ENV{'PERL5LIB'} = join($Config{'path_sep'},
        File::Spec->rel2abs(
            File::Spec->catdir(
                File::Spec->curdir(),
                "t", "lib", "run-test-1",
            )
        ), @p5lib);

    # TEST
    ok (
        !system($^X, "-MXML::Grammar::Screenplay::App::ToHTML",
            "-e", "run()",
            "--",
            "-o", "temp.xhtml",
            File::Spec->catdir(File::Spec->curdir(),
                "t", "screenplay", "data", "xml", "nested-s.xml"
            )
        ),
        "Testing App::ToHTML",
    );

    unlink("temp.xhtml");
}

1;

