#!/usr/bin/env perl

use 5.020;
use strict;
use warnings;
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use FindBin ();

exit(main());


sub main {
    my $destination_dn=shift(@ARGV) ||
        die "Usage: $0 NEW_APPLICATION_DIRECTORY\n";
    die "Unexpected arguments\n" if @ARGV;
    $destination_dn=File::Spec->rel2abs($destination_dn);
    die "Destination already exists: $destination_dn\n" if -e $destination_dn;

    #  Stage user examples only; smoke fixtures have an independent harness.
    #
    my $source_dn=File::Spec->catdir($FindBin::Bin, '..', 'examples', 'storage');
    make_path(File::Spec->catdir($destination_dn, 'app'));
    foreach my $relative_fn (qw(package.json schema.sql app/d1.psp app/d1-api.psp app/kv.psp app/r2.psp)) {
        my $source_fn=File::Spec->catfile($source_dn, split(m{/}, $relative_fn));
        my $target_fn=File::Spec->catfile($destination_dn, split(m{/}, $relative_fn));
        copy($source_fn, $target_fn) ||
            die "Unable to copy $source_fn to $target_fn: $!\n";
    }
    print("Staged examples in $destination_dn\n");
    print("Install local runtime and extension tarballs there, then run npm run build.\n");
    return 0;
}
