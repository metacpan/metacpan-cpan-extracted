#!/usr/bin/perl

use strict;
use warnings;

use Capture::Tiny ':all';
use File::Basename;
use File::Spec;
use Test::More;
use TypeLibrary::FromXSD;

my $tl = TypeLibrary::FromXSD->new(
    xsd         => File::Spec->catfile( dirname(__FILE__), 'test.xsd' ),
    namespace   => 'Test::Library',
    version_add => 0.02,
);

my $generated_code = capture_stdout { $tl->run };
my $check = do{ local (@ARGV, $/) = File::Spec->catfile( dirname(__FILE__), 'check.txt' ); <> };

is $generated_code, $check;

is_deeply [split /\n/, $generated_code], [split /\n/, $check];

done_testing();

