#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

chdir 'corpus/dist2' or die "chdir failed: $!";

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $expected_output = q{[XT::Files] Multiple default config files found: '.xtfilesrc' and 'xtfiles.ini'};
test_out("# $expected_output");
my $output = exception { CLASS()->new };
test_test('correct error message');
like( $output, qr{\Q$expected_output\E}, 'new dies if multiple default config files are present' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
