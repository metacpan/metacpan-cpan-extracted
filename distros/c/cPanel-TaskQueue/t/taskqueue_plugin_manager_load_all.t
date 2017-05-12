#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();
my $plugins;
my $tmpdir;

BEGIN {
    $tmpdir  = './tmp';
    $plugins = "$tmpdir/fake_plugins";
    File::Path::mkpath $plugins;
}
use lib $plugins;
END { File::Path::rmtree $tmpdir; }

use cPanel::TaskQueue::PluginManager ();

use Test::More tests => 10;

use strict;
use warnings;

my $plugindir = "$FindBin::Bin/mocks";

eval { cPanel::TaskQueue::PluginManager::load_all_plugins(); };
like( $@, qr/No directory/, 'Must supply a directory list.' );
eval { cPanel::TaskQueue::PluginManager::load_all_plugins( directories => $plugindir ); };
like( $@, qr/No directory/, 'Must supply a directory _list_.' );

eval { cPanel::TaskQueue::PluginManager::load_all_plugins( directories => [$plugindir] ); };
like( $@, qr/No namespace/, 'Must supply a directory list.' );
eval { cPanel::TaskQueue::PluginManager::load_all_plugins( directories => [$plugindir], namespaces => 'cPanel::FakeTasks' ); };
like( $@, qr/No namespace/, 'Must supply a directory _list_.' );

# Capture STDERR so Logger doesn't go to screen.

# Capture STDERR so Logger doesn't go to screen.
my $tmp_dumpfile = "$tmpdir/qpm_test.log";
open( my $olderr, '>&STDERR' ) or die "Can't dupe STDERR: $!";
close(STDERR);
open( STDERR, '>', $tmp_dumpfile ) or die "Unable to redirect STDERR: $!";

cPanel::TaskQueue::PluginManager::load_all_plugins(
    directories => [ $plugindir,          $plugins ],
    namespaces  => [ 'cPanel::FakeTasks', 'cPanel::OtherTasks' ],
);

# Restore STDERR and recover output.
open( STDERR, '>&', $olderr ) or die "Unable to restore STDERR: $!";
my $logger_output = slurp($tmp_dumpfile);
unlink $tmp_dumpfile;

# Verify error logging.
like(
    $logger_output, qr/Failed to load 'cPanel::FakeTasks::BadLoad'/,
    'BadLoad failure correctly detected.'
);
like(
    $logger_output, qr/'cPanel::FakeTasks::NoRegister' not registered, no 'to_register/,
    'NoRegister failure correctly detected.'
);
like(
    $logger_output, qr/'cPanel::FakeTasks::BadRegister2': invalid registration/,
    'BadRegister2 failure correctly detected.'
);
like(
    $logger_output, qr/'cPanel::FakeTasks::BadRegister': invalid registration/,
    'BadRegister failure correctly detected.'
);

my @loaded = sort ( cPanel::TaskQueue::PluginManager::list_loaded_plugins() );

my @expected = map { "cPanel::FakeTasks::$_" } qw/A B C/;
is_deeply( \@loaded, \@expected, 'Loaded list matches expectations.' );

# Verify that reloading is safe.
{
    # Capture STDERR so Logger doesn't go to screen.
    my $tmp_dumpfile = "$tmpdir/qpm_test.log";
    open( my $olderr, '>&STDERR' ) or die "Can't dupe STDERR: $!";
    close(STDERR);
    open( STDERR, '>', $tmp_dumpfile ) or die "Unable to redirect STDERR: $!";

    cPanel::TaskQueue::PluginManager::load_all_plugins(
        directories => [$plugindir],
        namespaces  => ['cPanel::FakeTasks'],
    );

    # Restore STDERR and recover output.
    open( STDERR, '>&', $olderr ) or die "Unable to restore STDERR: $!";
    my $logger_output = slurp($tmp_dumpfile);
    unlink $tmp_dumpfile;

    my @loaded = sort ( cPanel::TaskQueue::PluginManager::list_loaded_plugins() );

    my @expected = map { "cPanel::FakeTasks::$_" } qw/A B C/;
    is_deeply( \@loaded, \@expected, 'Loaded list matches expectations.' );
}

sub slurp {
    my ($filename) = @_;

    local $/;
    open( my $fh, '<', $filename ) or die "Unable to read '$filename': $!\n";
    return <$fh>;
}
