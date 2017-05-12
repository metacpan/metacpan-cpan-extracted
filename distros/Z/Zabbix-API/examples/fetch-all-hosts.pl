#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Zabbix::API;
use YAML::Any qw/Dump LoadFile/;

## This script loads all hosts from the server and dumps their data to YAML
## documents.

my $config = LoadFile("$ENV{HOME}/.zabbixrc");

my $zabber = Zabbix::API->new(server => $config->{host});

eval { $zabber->login(user => $config->{user}, password => $config->{password}) };

if ($@) {

    my $error = $@;
    die "Could not log in: $error";

}

print Dump($_->data) foreach @{$zabber->fetch('Host')};

eval { $zabber->logout };
if ($@) {

    my $error = $@;

    given ($error) {

        when (/Invalid method parameters/) {

            # business as usual

        }

        default {

            die "Unexpected exception while logging out: $error";

        }

    }

}

