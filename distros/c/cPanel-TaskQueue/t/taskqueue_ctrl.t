#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Temp;
use File::Path;
use Cwd;

use Test::More tests => 86;
use Test::Exception;
use cPanel::TaskQueue::Ctrl;

my $tmpdir = File::Temp->newdir();
my $statedir = "$tmpdir/state_test";
File::Path::mkpath( $statedir );

throws_ok { cPanel::TaskQueue::Ctrl->new( 'fred' ); } qr/not a hashref/, 'Ctrl::new requires a hashref.';
throws_ok { cPanel::TaskQueue::Ctrl->new( { qname => 'test' } ); } qr/required 'qdir'/, 'Required qdir test.';
throws_ok { cPanel::TaskQueue::Ctrl->new( { qdir => $statedir } ); } qr/required 'qname'/, 'Required qname test.';

my $output;
my $ctrl = cPanel::TaskQueue::Ctrl->new( { qdir => $statedir, qname => 'test', out => \$output } );
isa_ok( $ctrl, 'cPanel::TaskQueue::Ctrl' );

my @commands = sort qw/queue pause resume unqueue schedule unschedule list find
                       plugins commands status convert info process
                       flush_scheduled_tasks delete_unprocessed_tasks/;
foreach my $cmd (@commands) {
    my @ret = $ctrl->synopsis( $cmd );
    like( $ret[0], qr/^$cmd/, "$cmd: Found synopsis" );
    is( $ret[1], '', "$cmd: spacer" );

    @ret = $ctrl->help( $cmd );
    like( $ret[0], qr/^$cmd/, "$cmd: Found synopsis" );
    isnt( $ret[1], '', "$cmd: found help text" );
    is( $ret[2], '', "$cmd: spacer" );
}

{
    my @synopsis = $ctrl->synopsis();
    is( scalar(@synopsis), 2*@commands, 'The right number of lines are returned for synopsis' );
    my @help = $ctrl->help();
    is( scalar(@help), 3*@commands, 'The right number of lines are returned for help' );
}
