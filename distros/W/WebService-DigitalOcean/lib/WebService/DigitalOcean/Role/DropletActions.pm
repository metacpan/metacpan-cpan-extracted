package WebService::DigitalOcean::Role::DropletActions;
# ABSTRACT: Droplet Actions role for DigitalOcean WebService
use utf8;
use Moo::Role;
use feature 'state';
use Types::Standard qw/Str Enum Object Dict Int Bool/;
use Type::Utils;
use Type::Params qw/compile multisig/;

requires 'make_request';

our $VERSION = '0.026'; # VERSION

sub droplet_resize {
    state $check = compile(
        Object,
        Dict[
            droplet => Int,
            disk    => Bool,
            size    => Str,
        ],
    );
    my ($self, $opts) = $check->(@_);

    $opts->{type} = 'resize';

    return $self->_droplet_action_start($opts);
}

sub droplet_change_kernel {
    state $check = compile(
        Object,
        Dict[
            droplet => Int,
            kernel  => Int,
        ],
    );
    my ($self, $opts) = $check->(@_);

    $opts->{type} = 'change_kernel';

    return $self->_droplet_action_start($opts);
}

sub droplet_rebuild {
    state $check = compile(
        Object,
        Dict[
            droplet => Int,
            image   => Str,
        ],
    );
    my ($self, $opts) = $check->(@_);

    $opts->{type} = 'rebuild';

    return $self->_droplet_action_start($opts);
}

sub droplet_restore {
    state $check = compile(
        Object,
        Dict[
            droplet => Int,
            image   => Str,
        ],
    );
    my ($self, $opts) = $check->(@_);

    $opts->{type} = 'restore';

    return $self->_droplet_action_start($opts);
}

sub droplet_rename {
    state $check = compile(
        Object,
        Dict[
            droplet => Int,
            name    => Str,
        ],
    );
    my ($self, $opts) = $check->(@_);

    $opts->{type} = 'rename';

    return $self->_droplet_action_start($opts);
}

sub droplet_snapshot {
    state $check = compile(
        Object,
        Dict[
            droplet => Int,
            name    => Str,
        ],
    );
    my ($self, $opts) = $check->(@_);

    $opts->{type} = 'snapshot';

    return $self->_droplet_action_start($opts);
}

{
    my $Check_Self_and_ID = compile( Object, Int );

    sub droplet_reboot {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'reboot',
        });
    }

    sub droplet_power_cycle {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'power_cycle',
        });
    }

    sub droplet_power_on {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'power_on',
        });
    }

    sub droplet_power_off {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'power_off',
        });
    }

    sub droplet_password_reset {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'password_reset',
        });
    }

    sub droplet_shutdown {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'shutdown',
        });
    }

    sub droplet_enable_ipv6 {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'enable_ipv6',
        });
    }

    sub droplet_enable_private_networking {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'enable_private_networking',
        });
    }

    sub droplet_disable_backups {
        my ($self, $id) = $Check_Self_and_ID->(@_);

        return $self->_droplet_action_start({
            droplet => $id,
            type    => 'disable_backups',
        });
    }
}

sub droplet_action_get {
    state $check = compile(
        Object,
        Dict[
            droplet => Int,
            action  => Int,
        ],
    );

    my ($self, $opts) = $check->(@_);

    return $self->make_request(GET => "/droplets/$opts->{droplet}/actions/$opts->{action}");
}

sub _droplet_action_start {
    my ($self, $opts) = @_;

    my $droplet = delete $opts->{droplet};

    return $self->make_request(POST => "/droplets/$droplet/actions", $opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::DigitalOcean::Role::DropletActions - Droplet Actions role for DigitalOcean WebService

=head1 VERSION

version 0.026

=head1 DESCRIPTION

Implements the droplets actions methods.

=head1 METHODS

=head2 droplet_action_get

=head2 droplet_resize

=head2 droplet_change_kernel

=head2 droplet_rebuild

=head2 droplet_restore

=head2 droplet_rename

=head2 droplet_snapshot

=head2 droplet_reboot

=head2 droplet_power_cycle

=head2 droplet_power_on

=head2 droplet_power_off

=head2 droplet_password_reset

=head2 droplet_shutdown

=head2 droplet_enable_ipv6

=head2 droplet_enable_private_networking

=head2 droplet_disable_backups

See main documentation in L<WebService::DigitalOcean>.

=head1 AUTHOR

André Walker <andre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by André Walker.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
