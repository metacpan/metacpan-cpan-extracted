#!/usr/bin/perl

# Test the cPanel::TaskQueue::PluginManager module.
#

use strict;
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

use Test::More tests => 13;
use cPanel::TaskQueue::PluginManager;

eval { cPanel::TaskQueue::PluginManager::load_plugins(); };
like( $@, qr/No directory/, 'won\'t load without directory' );

eval { cPanel::TaskQueue::PluginManager::load_plugins(''); };
like( $@, qr/No directory/, 'won\'t load with empty directory string' );

eval { cPanel::TaskQueue::PluginManager::load_plugins('/xyzzy'); };
like( $@, qr/not exist/, 'won\'t load non-directory' );

eval { cPanel::TaskQueue::PluginManager::load_plugins('/'); };
like( $@, qr/include path/, 'directory must be part of @INC' );

my $plugindir = "$FindBin::Bin/mocks";
eval { cPanel::TaskQueue::PluginManager::load_plugins($plugindir); };
like( $@, qr/No namespace/, 'Must have a namespace' );

eval { cPanel::TaskQueue::PluginManager::load_plugins( $plugindir, '' ); };
like( $@, qr/No namespace/, 'Must have a non-empty namespace' );

eval { cPanel::TaskQueue::PluginManager::load_plugins( $plugindir, 'This is not a namespace' ); };
like( $@, qr/not a valid/, 'Namespace must have valid form' );

# Capture STDERR so Logger doesn't go to screen.
my $tmp_dumpfile = "$tmpdir/qpm_test.log";
open( my $olderr, '>&STDERR' ) or die "Can't dupe STDERR: $!";
close(STDERR);
open( STDERR, '>', $tmp_dumpfile ) or die "Unable to redirect STDERR: $!";

cPanel::TaskQueue::PluginManager::load_plugins( $plugindir, 'cPanel::FakeTasks' );

# Verify that a directory with no plugins is allowed.
cPanel::TaskQueue::PluginManager::load_plugins( $plugins, 'cPanel::FakeTasks' );

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

my $loaded_plugins = cPanel::TaskQueue::PluginManager::get_plugins_hash();
my $expected       = {
    'cPanel::FakeTasks::A' => ['donothing'],
    'cPanel::FakeTasks::B' => [qw/helloworld hello/],
    'cPanel::FakeTasks::C' => ['bye'],
};
is_deeply( $loaded_plugins, $expected, 'Plugins and commands match' );

sub slurp {
    my ($filename) = @_;

    local $/;
    open( my $fh, '<', $filename ) or die "Unable to read '$filename': $!\n";
    return <$fh>;
}
