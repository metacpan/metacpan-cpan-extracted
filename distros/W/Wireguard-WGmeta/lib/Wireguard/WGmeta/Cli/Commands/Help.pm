package Wireguard::WGmeta::Cli::Commands::Help;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use parent 'Wireguard::WGmeta::Cli::Commands::Command';


sub entry_point($self) {
    $self->cmd_help();
}

sub cmd_help($self) {
    print "wg-meta - An approach to add meta data to the Wireguard configuration\n";
    print "Usage: wg-meta <cmd> [<args>]\n";
    print "Available subcommands:\n";
    print "\t show: Shows the current configuration paired with available metadata\n";
    print "\t set:  Sets configuration attributes\n";
    print "\t enable:  Enables a peer\n";
    print "\t disable:  Disables a peer\n";
    print "\t addpeer:  Adds a (basic) peer and prints the client config to std_out\n";
    print "\t apply:  Just a shorthand for `wg syncconf <iface> <(wg-quick strip <iface>)`\n";
    print "You may pass `help` to any of these subcommands to view their usage\n";
    exit();
}
1;