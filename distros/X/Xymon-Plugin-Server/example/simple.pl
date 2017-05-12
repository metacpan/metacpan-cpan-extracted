#!/usr/bin/perl
#
# Xymon::Plugin::Server sample script
#
#
# HOW TO RUN
# ==========
#
# Add test name "simple" (see Xymon::Plugin::Server::Dispatch constructor
# in this script) at the your host entry in hosts.cfg. (bb-hosts in Xymon 4.2)
#
#   ex.
#     127.0.0.1   localhost.localdomain      # yourtest1 yourtest2 simple
#
#  Add etnry to tasks.cfg (hobbitlaunch.cfg in Xymon 4.2) for this script
#  like following:
#
#   [test]
#         ENVFILE $XYMONHOME/etc/hobbitserver.cfg
#         CMD perl /your/path/to/this/script/simple.pl
#         LOGFILE $XYMONSERVERLOGS/simplelog
#         INTERVAL 5m
#
#   (in Xymon 4.2, "XYMON" is "BB" in variable names)
#
# After all, wait for few minuts...

use strict;

use lib './blib/lib';
use lib '../blib/lib';

use Xymon::Plugin::Server::Dispatch;
use Xymon::Plugin::Server::Status qw(:colors);

sub simple_test {
    my ($host, $test, $ip) = @_;

    my $status = Xymon::Plugin::Server::Status->new($host, $test);
    $status->add_status(GREEN, "simple test ok!");
    $status->report;
}

my $dispatch = Xymon::Plugin::Server::Dispatch
    ->new(simple => \&simple_test);

$dispatch->run;
