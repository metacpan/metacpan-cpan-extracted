package Wireguard::WGmeta::Cli::Commands::Apply;
use strict;
use warnings FATAL => 'all';

use experimental 'signatures';

use parent 'Wireguard::WGmeta::Cli::Commands::Command';

use Wireguard::WGmeta::Wrapper::Bridge;


sub entry_point($self) {
    if ($self->_retrieve_or_die($self->{input_args}, 0) eq 'help') {
        $self->cmd_help();
    }
    $self->check_privileges();
    $self->_run_command();
}

sub _run_command($self){
    my $interface = $self->_retrieve_or_die($self->{input_args}, 0);

    # please note that there ar potential problems with this commend as mentioned here: https://github.com/WireGuard/wireguard-tools/pull/3
    my $cmd_line = "su -c 'wg syncconf $interface <(wg-quick strip $interface)'";
    run_external($cmd_line);
}

sub cmd_help($self) {
    print "Usage: wg-meta apply <interface>\n";
    exit;
}

1;