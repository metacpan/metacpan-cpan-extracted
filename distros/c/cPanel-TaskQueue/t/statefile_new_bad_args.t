#!/usr/bin/perl

use Test::More tests => 6;

use strict;
use warnings;
use File::Path ();
use cPanel::StateFile;

my $tmpdir = './tmp';

# Make sure we are clean to start with.
File::Path::rmtree( $tmpdir );
my $dir = "$tmpdir/state_test";
my $file = "$dir/state_dir/state_file";

eval {
    my $cf = cPanel::StateFile->new();
};
like( $@, qr/state filename/, "Cannot create StateFile without parameters" );

eval {
    my $cf = cPanel::StateFile->new( { data_obj => 1 } );
};
like( $@, qr/state filename/, "Cannot create StateFile without state directory" );

eval {
    my $cf = cPanel::StateFile->new( { state_file => $file } );
};
like( $@, qr/data object/, "Cannot create StateFile without a data object" );

eval {
    my $cf = cPanel::StateFile->new( { state_file => $file, data_obj => {} } );
};
like( $@, qr/required interface/, "Cannot create StateFile without a data object" );

eval {
    cPanel::StateFile->new( {logger => ''} );
};
like( $@, qr/Supplied logger/, 'Recognize bad logger.' );

eval {
    cPanel::StateFile->new( {locker => ''} );
};
like( $@, qr/Supplied locker/, 'Recognize bad locker.' );

File::Path::rmtree( $tmpdir );
