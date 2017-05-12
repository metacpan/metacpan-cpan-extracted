use 5.008001;
use Test::More 0.96;
use Capture::Tiny 0.12 qw/capture/;

use lib 't/lib';

my @cases = (
    {
        label  => "warning in .t",
        file   => "t/bin/main-warn.pl",
        expect => qr/isn't numeric/,
    },
    {
        label  => "warning from module",
        file   => "t/bin/module-warn.pl",
        expect => qr/I am noisy/,
    },
    {
        label  => "warning without line",
        file   => "t/bin/warn-newline.pl",
        expect => qr/No line number/,
    },
    {
        label   => "allow_deps true",
        file    => "t/bin/allow-deps.pl",
        exit_ok => 1,
    },
    {
        label  => "allow_deps false",
        file   => "t/bin/force-deps.pl",
        expect => qr/is a Perl keyword/,
    },
    {
        label   => "allow_from",
        file    => "t/bin/allow-constant.pl",
        exit_ok => 1,
    },
);

for my $c (@cases) {
    my ( $output, $error, $rc ) = capture { system( $^X, $c->{file} ) };
    subtest $c->{label} => sub {
        if ( $c->{exit_ok} ) {
            ok( !$rc, "exit ok" )
              or diag "ERROR: $error";
        }
        else {
            ok( $rc, "nonzero exit" );
            like( $c->{stdout} ? $output : $error, $c->{expect}, "exception text" );
        }
    };
}

done_testing;
#
# This file is part of Test-FailWarnings
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:

