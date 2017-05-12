#!/usr/bin/perl

# Test the cPanel::StateFile module.
#

use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();
use cPanel::FakeLogger;

use Test::More tests => 4;
my $logger;
BEGIN {
    $logger = cPanel::FakeLogger->new;
};

use cPanel::StateFile ( '-logger' => $logger );

# test bad new calls.
eval {
    my $cf = cPanel::StateFile->new();
};
like( $@, qr/state filename/, 'Cannot create StateFile without parameters' );
like( ($logger->get_msgs())[0], qr/throw.*?state filename/, 'Logged correctly.' );

# Put a logger on the specific StateFile
my $tmpdir = './tmp';
my $cfile = "$tmpdir/wade.state";

my $logger2 = cPanel::FakeLogger->new;
eval {
    my $cf = cPanel::StateFile->new( { state_file => $cfile, data_obj => {}, logger => $logger2 } );
};
like( $@, qr/required interface/, 'Cannot create CachFile with bad data object.' );
like( ($logger2->get_msgs())[0], qr/throw.*?required interface/, 'Logged correctly.' );

File::Path::rmtree( $tmpdir );
