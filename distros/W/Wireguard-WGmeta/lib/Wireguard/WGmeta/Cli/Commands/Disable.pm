package Wireguard::WGmeta::Cli::Commands::Disable;
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
    # would be very nice if we can set a type hint here...possible?
    $self->{'wg_meta'} = Wireguard::WGmeta::Wrapper::Config->new($self->{wireguard_home});
    $self->_run_command();
}


sub _run_command($self) {
    my $interface = $self->_retrieve_or_die($self->{input_args}, 0);
    my $identifier = $self->_retrieve_or_die($self->{input_args}, 1);
    eval {
        $identifier = $self->{wg_meta}->translate_alias($interface, $identifier);
    };
    $self->{wg_meta}->disable($interface, $identifier);

    if (defined $ENV{IS_TESTING}) {
        # omit header
        $self->{wg_meta}->commit(1, 1);
    }
    else {
        $self->{wg_meta}->commit(1, 0);
    }
}


sub cmd_help($self) {
    print "Usage: wg-meta disable <interface> {alias | public-key} \n";
    exit;
}

1;