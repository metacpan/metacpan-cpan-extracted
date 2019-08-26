#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

chdir 'corpus/dist4' or die "chdir failed: $!";

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new;
isa_ok( $obj, CLASS(), 'new returned object' );

my @files = $obj->files;

is( scalar @files, 6, 'files returns 6 file objects' );
for my $i ( 0 .. $#files ) {
    isa_ok( $files[$i], 'XT::Files::File' );
}

my @file_names = map { $_->name } @files;
is_deeply( [@file_names], [ sort qw(lib/world.pm lib/world.pod bin/hello.txt bin/world.txt bin/lib/not_a_module.pl bin/lib/module.pm) ], '... with the correct names' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
