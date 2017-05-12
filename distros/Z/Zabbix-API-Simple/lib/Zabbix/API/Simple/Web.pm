package Zabbix::API::Simple::Web;
{
  $Zabbix::API::Simple::Web::VERSION = '0.01';
}
BEGIN {
  $Zabbix::API::Simple::Web::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a plack based webinterface to Zabbix::API::Simple

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
use Module::Pluggable;

use Plack::Request;

# extends ...
# has ...
has '_key'  => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'lazy'  => 1,
    'builder' => '_init_key',
);

has '_fields' => (
    'is'      => 'rw',
    'isa'     => 'ArrayRef',
    'lazy'    => 1,
    'builder' => '_init_fields',
);

has '_finder' => (
    'is'       => 'rw',
    'isa'      => 'Module::Pluggable::Object',
    'lazy'     => 1,
    'builder'  => '_init_finder',
    'accessor' => 'finder',
);

has '_plugins' => (
    'is'       => 'rw',
    'isa'      => 'HashRef[Zabbix::API::Simple::Web::Plugin]',
    'lazy'     => 1,
    'builder'  => '_init_plugins',
    'accessor' => 'plugins',
);

# with ...
with qw(Config::Yak::LazyConfig Log::Tree::Logger);

sub _log_facility { return 'zbx-api-simple-web'; }
sub _config_locations { return [qw(conf /etc/zbx-api-simple)]; }
# initializers ...
sub _init_fields {
    return [qw(mode key v)];
}

sub _init_key {
    my $self = shift;

    return $self->config()->get('Zabbix::API::Simple::key');
}

sub _init_finder {
    my $self = shift;

    # The finder is the class that finds our available plugins
    my $Finder = Module::Pluggable::Object::->new( 'search_path' => 'Zabbix::API::Simple::Web::Plugin' );

    return $Finder;
} ## end sub _init_finder

sub _init_plugins {
    my $self = shift;

    my $plugin_ref = {};
  PLUGIN: foreach my $class_name ( $self->finder()->plugins() ) {
        ## no critic (ProhibitStringyEval)
        my $eval_status = eval "require $class_name;";
        ## use critic
        if ( !$eval_status ) {
            $self->logger()->log( message => 'Failed to require ' . $class_name . ': ' . $@, level => 'warning', );
            next;
        }
        my $arg_ref = $self->config()->get($class_name);
        $arg_ref->{'logger'} = $self->logger();
        $arg_ref->{'config'} = $self->config();
        if ( $arg_ref->{'disabled'} ) {
            $self->logger()->log( message => 'Skipping disabled plugin: ' . $class_name, level => 'debug', );
            next PLUGIN;
        }
        try {
            my $Plugin = $class_name->new($arg_ref);

            my $alias = $Plugin->alias();
            if ( $alias && !exists( $plugin_ref->{$alias} ) ) {
                $plugin_ref->{$alias} = $Plugin;
                $self->logger()->log( message => 'Initialized Plugin: ' . $class_name . ' as ' . $alias, level => 'debug', );
                foreach my $field ( @{ $Plugin->fields() } ) {
                    push( @{ $self->_fields() }, $field );
                }
            } ## end if ( $alias && !exists...)
        } ## end try
        catch {
            $self->logger()->log( message => 'Failed to initialize plugin ' . $class_name . ' w/ error: ' . $_, level => 'warning', );
        };
    } ## end foreach my $class_name ( $self...)

    return $plugin_ref;
} ## end sub _init_plugins

sub BUILD {
    my $self = shift;

    # init param filter list
    $self->plugins();

    return 1;
} ## end sub BUILD

# your code here ...
sub run {
    my $self = shift;
    my $env  = shift;

    my $plack_request = Plack::Request::->new($env);
    my $request       = $self->_filter_params($plack_request);

    # log request and ip
    $self->_log_request($request);

    return $self->_handle_request($request);
} ## end sub run

sub _filter_params {
    my $self    = shift;
    my $request = shift;

    my $params = $request->parameters();

    my $request_ref = {};
    foreach my $key ( @{ $self->_fields() } ) {
        if ( defined( $params->{$key} ) ) {
            $request_ref->{$key} = $params->{$key};
        }
    }

    # add the remote_addr
    $request_ref->{'remote_addr'} = $request->address();

    return $request_ref;
} ## end sub _filter_params

sub _handle_request {
    my $self    = shift;
    my $request = shift;

    my $mode = $request->{'mode'};
    my $key  = $request->{'key'};
    my $ver  = $request->{'v'};

    # Check requested API version
    if(!$ver || $ver ne '1') {
        return [ 400, [ 'Content-Type', 'text/plain' ], ['Bad Request - Invalid version'] ];
    }

    # Check API key
    if(!$self->_key()) {
        return [ 500, [ 'Content-Type', 'text/plain' ], ['Bad Configuration'] ];
    }
    if(!$key || $key ne $self->_key()) {
        return [ 400, [ 'Content-Type', 'text/plain' ], ['Bad Request - Invalid key'] ];
    }

    # Handle request
    if ( $mode && $self->plugins()->{$mode} && ref( $self->plugins()->{$mode} ) ) {
        if ( $self->plugins()->{$mode}->execute($request) ) {
            return [ 200, [ 'Content-Type', 'text/plain' ], ['OK'] ];
        }
        else {
            return [ 500, [ 'Content-Type', 'text/plain' ], ['Processing Error'] ];
        }
    } ## end if ( $mode && $self->plugins...)
    else {
        return [ 400, [ 'Content-Type', 'text/plain' ], ['Bad Request - Command not found'] ];
    }

    return 1;
} ## end sub _handle_request

sub _log_request {
    my $self        = shift;
    my $request_ref = shift;

    my $remote_addr = $request_ref->{'remote_addr'};

    # turn key => value pairs into smth. like key1=value1,key2=value2,...
    my $args = join( q{,}, map { $_ . q{=} . $request_ref->{$_} } keys %{$request_ref} );

    $self->logger()->log( message => 'New Request from ' . $remote_addr . '. Args: ' . $args, level => 'debug', );

    return 1;
} ## end sub _log_request

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Zabbix::API::Simple::Web - a plack based webinterface to Zabbix::API::Simple

=head1 NAME

Zabbix::API::Simple::Web - a plack based webinterface to Zabbix::API::Simple

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
