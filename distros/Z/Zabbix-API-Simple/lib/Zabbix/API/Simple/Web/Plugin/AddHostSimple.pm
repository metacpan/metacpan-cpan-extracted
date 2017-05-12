package Zabbix::API::Simple::Web::Plugin::AddHostSimple;
{
  $Zabbix::API::Simple::Web::Plugin::AddHostSimple::VERSION = '0.01';
}
BEGIN {
  $Zabbix::API::Simple::Web::Plugin::AddHostSimple::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Example plugin for adding an host

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'Zabbix::API::Simple::Web::Plugin';
# has ...
has 'group_id' => (
    'is'    => 'rw',
    'isa'   => 'ArrayRef[Num]',
    'default' => sub { [] },
);

has 'proxy_id' => (
    'is'    => 'rw',
    'isa'   => 'Num',
    'default' => 0,
);

has 'template_id' => (
    'is'    => 'rw',
    'isa'   => 'ArrayRef[Num]',
    'default' => sub { [] },
);

has 'macros' => (
    'is'    => 'rw',
    'isa'   => 'HashRef',
    'default' => sub { {} },
);
# with ...
# initializers ...
sub _init_fields { return [qw(hostname)]; }

sub _init_alias { return 'add_host_simple'; }

# your code here ...
sub execute {
    my $self = shift;
    my $request = shift;

    return unless $request->{'hostname'};
    my $hostname = $request->{'hostname'};

    my $data = {};

    $data->{'dns'} = $hostname;
    $data->{'ip'}  = '0.0.0.0';
    $data->{'port'} = 10_050;
    $data->{'useip'} = 0;
    $data->{'status'} = 1; # 1 == disabled, i.e. not monitored

    if($self->group_id()) {
        foreach my $group_id (@{$self->group_id()}) {
            push(@{$data->{'groups'}}, {
                'groupid'   => $group_id,
            });
        }
    }

    if($self->template_id()) {
        foreach my $tpl_id (@{$self->template_id()}) {
            push(@{$data->{'templates'}}, {
                'templateid'   => $tpl_id,
            });
        }
    }

    if($self->proxy_id()) {
        $data->{'proxy_hostid'} = $self->proxy_id();
    }

    if($self->macros()) {
        foreach my $mname (keys %{$self->macros()}) {
            my $key = $self->macros()->{$mname}->{'key'};
            my $value = $self->macros()->{$mname}->{'value'};

            push(@{$data->{'macros'}}, {
                'macro'     => $key,
                'value'     => $value,
            });
        }
    }

    if($self->sapi()->host_update($hostname,$data)) {
        $self->logger()->log( message => 'Created host: '.$hostname, level => 'debug', );
        return 1;
    } else {
        $self->logger()->log( message => 'Failed to create host: '.$hostname, level => 'error', );
        return;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Zabbix::API::Simple::Web::Plugin::AddHostSimple - Example plugin for adding an host

=head1 DESCRIPTION

This class shows the implementation of a simple host addition class.

=head1 NAME

Zabbix::API::Simple::Web::API::Plugin::AddHostSimple - Simple host example

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
