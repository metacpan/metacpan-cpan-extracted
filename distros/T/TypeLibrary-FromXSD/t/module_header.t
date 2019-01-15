#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use Capture::Tiny qw(capture_stdout);
use Test::More;
use TypeLibrary::FromXSD;

{
    my $file = File::Spec->catfile( dirname(__FILE__), 'MyTestOutput.pm' );

    my $tl = TypeLibrary::FromXSD->new(
        xsd         => File::Spec->catfile( dirname(__FILE__), 'test.xsd' ),
        version_add => 0.02,
        output      => $file,
    );

    my $code = $tl->_module_header( 'MyTestOutput', '0.02', 'Hallo' );

    like $code, qr/package MyTestOutput;/;
    like $code, qr/VERSION = 0.02/;
}

done_testing();
