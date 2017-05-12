package Vote;

use strict;
use warnings;
use Config::YAML;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use Catalyst qw/
    ConfigLoader
    Static::Simple
    Session
    Session::Store::DBI
    Session::State::Cookie
    /;

our $VERSION = '1.00';

# Configure the application. 
#
# Note that settings in Vote.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'Vote' );

# Config file, in tree, else should be in /etc

__PACKAGE__->config(
    'Plugin::ConfigLoader' => {
        file => -f __PACKAGE__->path_to('epoll.yml')
            ? __PACKAGE__->path_to('epoll.yml')
            : '/etc/epoll.yml',
    }
);

__PACKAGE__->config->{session} = {
    expires   => 1800,
    dbi_table => 'sessions',
    dbi_dsn => 'noo',
};


# Start the application
__PACKAGE__->setup;

# This is after because db config is in config file
__PACKAGE__->config->{session}{dbi_dsn} = 'dbi:Pg:' . __PACKAGE__->config->{db};


=head1 NAME

Vote - Catalyst based application

=head1 SYNOPSIS

    script/vote_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Vote::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Thauvin Olivier

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
