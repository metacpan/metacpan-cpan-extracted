#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 2;
use cPanel::TaskQueue;

my $tmpdir = './tmp';

# Make sure we are clean to start with.
File::Path::rmtree( $tmpdir );
File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";

eval {
    cPanel::TaskQueue->new();
};
ok( defined $@, "Cannot create TaskQueue with no directory." );

eval {
    cPanel::TaskQueue->new( { state_dir => $tmpdir } );
};
ok( defined $@, "Cannot create TaskQueue with no name." );

File::Path::rmtree( $tmpdir );
