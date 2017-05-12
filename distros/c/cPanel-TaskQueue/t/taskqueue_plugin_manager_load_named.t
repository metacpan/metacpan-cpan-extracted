#!/usr/bin/perl

use Test::More tests => 10;
use Carp;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/mocks";

use cPanel::TaskQueue::PluginManager;

plugin_load_no_ok( 'cPanel::FakeTasks::Missing', 'Cannot load missing plugin by name' );
plugin_load_no_ok( 'cPanel::FakeTasks::BadLoad', 'Cannot load bad plugin' );
plugin_load_no_ok( 'cPanel::FakeTasks::BadRegister', 'Cannot load plugin with invalid registration' );
plugin_load_no_ok( 'cPanel::FakeTasks::NoRegister', 'Cannot load plugin that does not register' );
is_deeply( cPanel::TaskQueue::PluginManager::get_plugins_hash(), {}, 'No plugins loaded yet.' );

{
    ok( cPanel::TaskQueue::PluginManager::load_plugin_by_name( 'cPanel::FakeTasks::B' ), 'Loaded actual plugin' );
    my $plugins = cPanel::TaskQueue::PluginManager::get_plugins_hash();
    my $expected = {
        'cPanel::FakeTasks::B' => [ qw/helloworld hello/ ],
    };
    is_deeply( $plugins, $expected, 'One module: Plugins and commands match' );
}

plugin_load_no_ok( 'cPanel::FakeTasks::B', 'Cannot reload plugin' );

{
    ok( cPanel::TaskQueue::PluginManager::load_plugin_by_name( 'cPanel::FakeTasks::A' ), 'Loaded second actual plugin' );
    my $plugins = cPanel::TaskQueue::PluginManager::get_plugins_hash();
    my $expected = {
        'cPanel::FakeTasks::A' => [ 'donothing' ],
        'cPanel::FakeTasks::B' => [ qw/helloworld hello/ ],
    };
    is_deeply( $plugins, $expected, 'Both Plugins and commands match' );
}

sub plugin_load_no_ok {
    my ($module, $name) = @_;

    # Capture STDERR so Logger doesn't go to screen.
    open( my $olderr, '>&STDERR' ) or die "Can't dupe STDERR: $!";
    close( STDERR ); open( STDERR, '>', '/dev/null' ) or die "Unable to redirect STDERR: $!";

    my $status = cPanel::TaskQueue::PluginManager::load_plugin_by_name( $module );

    open( STDERR, '>&', $olderr ) or die "Unable to restore STDERR: $!";

    ok( !$status, $name );
}
