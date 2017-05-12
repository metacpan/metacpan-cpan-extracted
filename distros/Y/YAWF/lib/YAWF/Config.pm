package YAWF::Config;

=pod

=head1 NAME

YAWF::Config - Configuration for YAWF

=head1 SYNOPSIS

  my $object = YAWF::Config->new(
      domain => $domain,
      yawf   => $SINGLETON,
  );
  
=head1 DESCRIPTION

The YAWF configuration is done per-domain with a fallback structure.

This module holds the configuration of the current request.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use YAML::Tiny;

use YAWF;

use Class::XSAccessor accessors => {
    yawf                 => 'yawf',
    domain               => 'domain',
    handlerprefix        => 'handlerprefix',
    template_dir         => 'template_dir',
    tt_config            => 'tt_config',
    database             => 'database',
    requesthandler       => 'requesthandler',
    session              => 'session',
    setup_enabled        => 'setup_enabled',
    setup_password       => 'setup_password',
    capcha              => 'capcha',
    no_default_templates => 0,
};

our $VERSION = '0.01';

my %CONFIG_CACHE;

=pod

=head2 new

  my $object = YAWF::Config->new(
      domain => 'www.foo.bar',
      yawf   => $SINGLETON,
  );

Loads the configuration for the specified domain.

Falls back through the domain levels if no config is found:
   www.foo.bar
   *.foo.bar
   foo.bar
   *.bar
   bar
   *

Returns the configuration object or undef in case of an error.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    $args{yawf} ||= YAWF->SINGLETON;

    my $documentroot =
      ( defined( $args{yawf} ) and defined( $args{yawf}->request ) )
      ? $args{yawf}->request->documentroot
      : '.';

    # Set the defaults
    my $self = bless {
        domain        => '*',
        handlerprefix => 'YAWF::Handler', # Don't set empty for security reasons
        tt_config     => {},
        session       => {},
        setup_enabled => 0,
        capcha => {},
        template_dir => defined($documentroot)
        ? $documentroot . '/templates'
        : undef,
    }, $class;

    if ( defined($documentroot) ) {
        my $config;
        my $config_file = $documentroot . '/yawf.yml';
        my $domain =
          defined( $args{yawf}->request )
          ? lc( $args{yawf}->request->domain )
          : $ENV{YAWF_DOMAIN};
        $domain ||= '*';
        my $cache_key  = $documentroot . chr(0) . $domain;
        my $file_mtime = ( stat($config_file) )[9];

        # Use cache
        if ( defined( $CONFIG_CACHE{$cache_key} )
            and ( $CONFIG_CACHE{$cache_key}->{file} == $file_mtime ) )
        {
            $config = $CONFIG_CACHE{$cache_key}->{config};
            $CONFIG_CACHE{$cache_key}->{used} = time;
        }
        else {

            my $yaml = YAML::Tiny->read($config_file);
            if ( defined($yaml) ) {
                for my $part ( @{$yaml} ) {
                    my $domain = $domain;
                    while ( $domain ne '' ) {
                        if ( defined( $part->{$domain} ) ) {
                            $config = $part->{$domain};
                            last;
                        }
                        $domain =~ s/^\*\.?// or $domain =~ s/^[\w\-]+/\*/;
                    }
                    $config ||= $part if defined( $part->{domain} );
                    last if defined($config);
                }
                if ( defined($config) ) {
                    $CONFIG_CACHE{$cache_key} = {
                        config => $config,
                        used   => time,
                        file   => $file_mtime,
                    };
                }
            }
        }

        if ( defined($config) ) {
            for ( keys( %{$config} ) ) {
                $self->{$_} = $config->{$_};
            }
        }
    }

    $self->session->{timeout}      ||= 21600;
    $self->session->{cookie}       ||= 1;
    $self->session->{cookiedomain} ||= 'auto';

    return $self;
}

#=pod
#
#=head2 dummy
#
#This method does something... apparently.
#
#=cut
#
#sub dummy {
#    my $self = shift;
#
#    # Do something here
#
#    return 1;
#}

1;

=pod

=head1 SAMPLE

Here is a full example of a config file:

    ---
    foo.bar:
        domain: www.foo.bar
        database:
            dbi: dbi:SQLite:dbname=/var/db/foo.bar
            username: none
            password: none
            database: /var/db/foo.bar
            class: Foo::DB
        handlerprefix: FooBarWeb
        template_dir: /var/www/foo.bar/templates
        no_default_templates: 1
        session:
            cookie: 1
            timeout: 86400


=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2010 Sebastian Willing.

=cut
