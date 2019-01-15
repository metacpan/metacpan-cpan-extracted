#!/usr/bin/perl

use strict;
use warnings;

use Capture::Tiny ':all';
use File::Basename;
use File::Spec;
use File::Copy qw(copy);
use Test::More;
use TypeLibrary::FromXSD;

my $output = File::Spec->catfile( dirname(__FILE__), 'TestLibrary.pm' );
my $orig   = File::Spec->catfile( dirname(__FILE__), 'check.txt' );

copy $orig, $output;

my $tl     = TypeLibrary::FromXSD->new(
    xsd         => File::Spec->catfile( dirname(__FILE__), 'test.xsd' ),
    namespace   => 'Test::Library',
    output      => $output,
    version_add => 0.02,
);

$tl->run;

my $generated_code = do{ local (@ARGV, $/) = $output; <> };

like $generated_code, qr/\$VERSION = 0.04/;

unlink $output;

done_testing();

