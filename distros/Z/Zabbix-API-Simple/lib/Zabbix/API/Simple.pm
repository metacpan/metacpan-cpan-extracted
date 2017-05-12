package Zabbix::API::Simple;
{
  $Zabbix::API::Simple::VERSION = '0.01';
}
BEGIN {
  $Zabbix::API::Simple::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: A simple abstraction of the Zabbix::API

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
use Try::Tiny;
use Zabbix::API;
use Zabbix::API::Host;

# extends ...
# has ...
has 'username' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);

has 'password' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);

has 'url' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);

has 'logger' => (
    'is'      => 'ro',
    'isa'     => 'Log::Tree',
    'required'    => 1,
);

has '_api' => (
    'is'    => 'ro',
    'isa'   => 'Zabbix::API',
    'lazy'  => 1,
    'builder' => '_init_api',
);
# with ...
# initializers ...
sub _init_api {
    my $self = shift;

    my $API = Zabbix::API::->new(
        'server'    => $self->url(),
        'verbosity' => 0,
    );

    try {
        $API->login(
            user        => $self->username(),
            password    => $self->password(),
        );
        1;
    } catch {
        $self->logger()->log( message => 'Login to Zabbix failed: '.$_, level => 'error', );
    };

    return $API;
}

sub DEMOLISH {
    my $self = shift;

    $self->_api()->logout();

    return 1;
}

# your code here ...
sub host_create {
    my $self = shift;
    my $hostname = shift;
    my $data = shift;

    $data->{'host'} = $hostname;

    my $success = try {
        my $Host = Zabbix::API::Host::->new(
            'root'  => $self->_api(),
            'data'  => $data,
        );
        $Host->push()
            or die('Could not push host to server');
        1;
    } catch {
        $self->logger()->log( message => 'Failed to create host: '.$_, level => 'error', );
    };

    if($success) {
        return 1;
    } else {
        return;
    }
}

sub host_delete {
    my $self = shift;
    my $hostname = shift;
    my $search = shift || {};

    my $params = {};
    $params->{'filter'}->{'host'} = $hostname; # primary search field!

    # additional search parameters
    # see http://www.zabbix.com/documentation/1.8/api/host/get
    foreach my $key (qw(nodeids groupids hostids templateids itemids triggerids graphids proxyids)) {
        if(defined($search->{$key})) {
            $params->{$key} = $search->{$key};
        }
    }

    my $success = try {
        my $Host = $self->_api()->fetch('Host', params => $params)->[0];

        if($Host) {
            if($Host->name() ne $hostname) {
                die('Got wrong host from Zabbix: '.$Host->name().' instead of '.$hostname);
            }

            $Host->delete()
                or die('Could not delete host on server');
            $self->logger()->log( message => 'Deleted '.$hostname, level => 'debug', );
        } else {
            die('Host '.$hostname.' not found on Zabbix Server');
        }
        1;
    } catch {
        $self->logger()->log( message => 'Failed to delete host: '.$_, level => 'error', );
    };

    if($success) {
        return 1;
    } else {
        return;
    }
}

sub host_update {
    my $self = shift;
    my $hostname = shift;
    my $data = shift;

    $data->{'host'} = $hostname;

    my $success = try {
        my $Host = Zabbix::API::Host::->new(
            'root'  => $self->_api(),
            'data'  => $data,
        );
        $Host->push()
            or die('Could not push host to server');
        1;
    } catch {
        $self->logger()->log( message => 'Failed to update host: '.$_, level => 'error', );
    };

    if($success) {
        return 1;
    } else {
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

Zabbix::API::Simple - A simple abstraction of the Zabbix::API

=head1 NAME

Zabbix::API::Simple -  A simple abstraction of the Zabbix::API

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
