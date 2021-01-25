package Wireguard::WGmeta::Cli::Commands::Set;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use parent 'Wireguard::WGmeta::Cli::Commands::Command';
use Wireguard::WGmeta::Wrapper::Config;
use constant TRUE => 1;
use constant FALSE => 0;

sub entry_point($self) {
    if ($self->_retrieve_or_die($self->{input_args}, 0) eq 'help') {
        $self->cmd_help();
        return
    }
    else {
        $self->check_privileges();
        # would be very nice if we can set a type hint here...possible?
        $self->{'wg_meta'} = Wireguard::WGmeta::Wrapper::Config->new($self->{wireguard_home});
        $self->_run_command();
    }
}

sub _run_command($self) {
    my $interface = $self->_retrieve_or_die($self->{input_args}, 0);
    my $offset = -1;
    my $cur_start = 0;
    my @input_args = @{$self->{input_args}};
    for my $value (@{$self->{input_args}}) {
        if ($value eq 'peer') {

            # if there is just one peer we skip here
            if ($offset != 0) {
                $self->_apply_change_set($interface, @input_args[$cur_start .. $offset]);
                $cur_start = $offset;
            }
        }
        $offset++;
    }
    $self->_apply_change_set($interface, @input_args[$cur_start .. $offset]);
    if (defined $ENV{IS_TESTING}) {
        # omit header
        $self->{wg_meta}->commit(1, 1);
    }
    else {
        $self->{wg_meta}->commit(1, 0);
    }

}

# internal method to split commandline args into "change-sets".
# This method is fully* compatible with the `wg set`-syntax.
# *exception: remove
sub _apply_change_set($self, $interface, @change_set) {
    my $offset = 1;
    my $identifier;
    if ($self->_retrieve_or_die(\@change_set, 1) eq 'peer') {
        # this could be either a public key or alias
        $identifier = $self->_retrieve_or_die(\@change_set, 2);

        # try to resolve alias
        $identifier = $self->{wg_meta}->try_translate_alias($interface, $identifier);

        $offset += 2;
    }
    else {
        $identifier = $interface;
    }
    my @value_keys = splice @change_set, $offset;

    if (@value_keys % 2 != 0) {
        die "Odd number of value/key-pairs";
    }
    # parse key/value - pairs into a hash
    my %args;
    my $idx = 0;

    while ($idx < @value_keys) {
        $args{$value_keys[$idx]} = $value_keys[$idx + 1];
        $idx += 2;
    }
    #     print "Got command set:
    #     interface: $interface
    #     ident: $identifier
    #     attrs: @value_keys
    # ";

    $self->_set_values($interface, $identifier, \%args);
}
sub cmd_help($self) {
    print "Usage: wg-meta set <interface> [attr1 value1] [attr2 value2] [peer {alias|public-key}] [attr1 value1] [attr2 value2] ...\n"
}

sub _set_values($self, $interface, $identifier, $ref_hash_values) {
    for my $key (keys %{$ref_hash_values}) {
        $self->{wg_meta}->set($interface, $identifier, $key, $ref_hash_values->{$key}, TRUE, \&_forward);
    }
}

sub _forward($interface, $identifier, $attribute, $value) {
    # this is just as stub
    print("Forwarded to original wg command: `$attribute = $value`");
}

1;
