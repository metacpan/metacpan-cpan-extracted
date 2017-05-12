#!/usr/bin/env perl

# ABSTRACT: Changes the collector for all hosts in a group

use v5.16.3;
use warnings;
use Getopt::Long qw/:config no_ignore_case bundling/;
use WebService::LogicMonitor;

my $opt = {};

GetOptions $opt, 'debug|d!', 'group|g=s', 'old_agent_id=i', 'new_agent_id=i'
  or die "Commandline error\n";

if ($ENV{LOGICMONITOR_DEBUG} || $opt->{debug}) {
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr');
}

my $lm = WebService::LogicMonitor->new(
    username => $ENV{LOGICMONITOR_USER},
    password => $ENV{LOGICMONITOR_PASS},
    company  => $ENV{LOGICMONITOR_COMPANY},
);

my $host_groups = $lm->get_groups(fullPath => $opt->{group});
my $host_group  = shift @$host_groups;
my $hosts       = $lm->get_hosts($host_group->id);

foreach my $host (@$hosts) {
    if ($opt->{old_agent_id}) {
        say $host->name . ' uses old collector'
          if $host->agent_id == $opt->{old_agent_id};
    } else {
        say $host->name . ' uses collector ' . $host->agent_id;
    }

    if ($opt->{new_agent_id}) {
        if ($host->agent_id == $opt->{new_agent_id}) {
            say $host->name . ' already uses new collector';
        } else {
            $host->agent_id($opt->{new_agent_id});
            $host->update;
        }
    }

}
