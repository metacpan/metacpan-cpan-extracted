package Wireguard::WGmeta::Cli::Commands::Remove;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use Wireguard::WGmeta::Wrapper::Config;
use parent 'Wireguard::WGmeta::Cli::Commands::Command';


sub entry_point($self) {
    if ($self->_retrieve_or_die($self->{input_args}, 0) eq 'help') {
        $self->cmd_help();
    }
    $self->check_privileges();
    $self->_run_command();
}


sub _run_command($self) {
    my $interface = $self->_retrieve_or_die($self->{input_args}, 0);
    my $identifier = $self->_retrieve_or_die($self->{input_args}, 1);
    $identifier = $self->wg_meta->try_translate_alias($interface, $identifier);
    $self->wg_meta->remove_peer($interface, $identifier);

    if (defined $ENV{IS_TESTING}) {
        # omit header
        $self->wg_meta->commit(1, 1);
    }
    else {
        $self->wg_meta->commit(1, 0);
    }
}


sub cmd_help($self) {
    print "Usage: wg-meta removepeer <interface> {alias | public-key} \n";
    exit;
}

1;