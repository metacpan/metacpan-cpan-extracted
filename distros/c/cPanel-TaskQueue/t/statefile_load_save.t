#!/usr/bin/perl

# Test the cPanel::StateFile module.
#

use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 24;
use cPanel::StateFile;
use MockCacheable;

my $tmpdir = './tmp';
my $dir = "$tmpdir/state_test";
my $file = "$dir/state_dir/state_file";
my $lockname = "$file.lock";

# TODO: Need to testing for timeout logic, but it would slow down the tests.
#   Decide how I would like to turn it on provisionally: cmdline, env, etc.

# clean up if last run failed.
cleanup();
File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";

# test valid creation
my $mock_obj = MockCacheable->new;

my $state = cPanel::StateFile->new( { state_file => $file, data_obj => $mock_obj } );
isa_ok( $state, 'cPanel::StateFile' );

ok( -e $file, "Cache file should have been created." );

ok( !$mock_obj->{load_called}, "File didn't exist, should not have loaded." );
is( $mock_obj->{save_called}, 1, "File didn't exist, should have saved." );

ok( !-e $lockname, "File not locked at this time." );

{
    my $msg;
    local $SIG{__WARN__} = sub { $msg = join( ' ', @_ ); };
    $state->warn( "This is a warning\n" );
    is( $msg, "This is a warning\n", 'warn method works.' );

    $state->info( "This is an info message\n" );
    is( $msg, "This is an info message\n", 'info method works.' );
}

# Test re-synch when file hasn't changed.
# Lock the file for update.
{
    my $guard = $state->synch();
    ok( -e $lockname, "File is locked." );

    is( $mock_obj->{load_called}, 0, "memory up-to-date, don't load." );
    $guard->update_file();
    is( $mock_obj->{save_called}, 2, "update calls save." );
}
ok( !-e $lockname, "File is unlocked." );

# Test empty file case
{
    # Recreating file, so delete it first.
    unlink $file;
    open( my $fh, '>', $file ) or die "Unable to create empty state file: $!";
    close( $fh );

    my $state = cPanel::StateFile->new( { state_file => $file, data_obj => $mock_obj } );
    isa_ok( $state, 'cPanel::StateFile' );

    ok( !-z $file, "Cache file should be filled." );

    is( $mock_obj->{load_called}, 0, "File was empty, should not have loaded." );
    is( $mock_obj->{save_called}, 3, "File was empty, should have saved." );

    ok( !-e $lockname, "File not locked at this time." );
}

{
    open( my $fh, '<', $file ) or die "Unable to read state file: $!\n";
    my $file_data = <$fh>;
    is( $file_data, 'Save string: 3 0', 'state_file is correct.' );
}

# Update state file directly.
{
    open( my $fh, '>', $file ) or die "Unable to write state file: $!\n";
    print $fh 'This is the updated state file.';
    close( $fh );
}

ok( $state->synch(), 'Synch occured.' );
ok( !-e $lockname, "File is not locked." );

is( $mock_obj->{load_called}, 1, "file changed, load." );
is( $mock_obj->{data}, 'This is the updated state file.', 'Correct data is loaded.' );

# Test that we don't reload after the last synch
ok( $state->synch(), 'Synch occured.' );
is( $mock_obj->{load_called}, 1, "don't load again." );
is( $mock_obj->{data}, 'This is the updated state file.', 'Correct data is loaded.' );

cleanup();

# Discard temporary files that we don't need any more.
sub cleanup {
    unlink $file if -e $file;
    unlink $lockname if -e $lockname;
    File::Path::rmtree( $tmpdir ) if -d $tmpdir;
}
