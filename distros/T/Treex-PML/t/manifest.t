#!perl -T

use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;

# Remove backups created by previous tests
for my $backup (glob(File::Spec->catfile('test_data','pml','*~'))) {
    # un-taint
    $backup =~ /^(.*\bexample[0-9]+.xml~)$/;
    $backup = $1;

    unlink $backup;
}

ok_manifest();
