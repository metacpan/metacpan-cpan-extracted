#!/usr/bin/perl
#
# Xymon::Plugin::Server sample script
#
#
# HOW TO RUN
# ==========
#
# Add "test=devmon" to variable TEST2RRD in xymonserver.cfg.
# (hobbitserver.cfg in Xymon 4.2)
#
#   TEST2RRD="cpu=la,disk,inode,qtree,...,test=devmon"
#
# (After editing this file, restart xymon.)
#
# Add graph definition to graphs.cfg. (hobbitgraph.cfg in Xymon 4.2)
# Definition exists in "add-graph.cfg" in same directory.
#
# Add test name "test" (see Xymon::Plugin::Server::Dispatch constructor
# in this script) at the your host entry in hosts.cfg. (bb-hosts in Xymon 4.2)
#
#   ex.
#     127.0.0.1   localhost.localdomain      # yourtest1 yourtest2 test
#
#  Add etnry to tasks.cfg (hobbitlaunch.cfg in Xymon 4.2) for this script
#  like following:
#
#   [test]
#         ENVFILE $XYMONHOME/etc/hobbitserver.cfg
#         CMD perl /your/path/to/this/script/test.pl
#         LOGFILE $XYMONSERVERLOGS/test.log
#         INTERVAL 5m
#
#   (in Xymon 4.2, "XYMON" is "BB" in variable names)
#
# After all, wait for few minuts...

use strict;

use lib './blib/lib';
use lib '../blib/lib';

use Xymon::Plugin::Server::Dispatch;

package MyMonitor;

use Xymon::Plugin::Server;
use Xymon::Plugin::Server::Status qw(:colors);
use Xymon::Plugin::Server::Devmon;

sub new {
    my $class = shift;
    my ($host, $test, $ip) = @_;

    my $self = {
	host => $host,
	test => $test,
	ip => $ip,
    };

    print "test for $host($ip).$test\n";
    bless $self, $class;
}

sub run {
    my $self = shift;

    my $status = Xymon::Plugin::Server::Status
	->new($self->{host}, $self->{test});

    my $devmon = Xymon::Plugin::Server::Devmon
	->new(ds0 => 'GAUGE:600:0:U',
	      ds1 => 'GAUGE:600:0:U');

    $devmon->add_data(MyData => { ds0 => 0, ds1 => 3 });
    $devmon->add_data(YourData => { ds0 => 8, ds1 => 2 });

    $status->add_status(GREEN, "test1");
    $status->add_status(GREEN, "test2");

    $status->add_message("Hello world!\nThis is a test message\n");

    $status->add_devmon($devmon);

    $status->add_graph("test");

    $status->report;
}


package main;

my $dispatch = Xymon::Plugin::Server::Dispatch
    ->new('test' => 'MyMonitor');

$dispatch->run;
