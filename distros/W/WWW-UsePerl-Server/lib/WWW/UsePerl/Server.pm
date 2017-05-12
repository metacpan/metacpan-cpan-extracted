package WWW::UsePerl::Server;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use Data::Pageset;
use DateTime::Format::MySQL;
use Template::Plugin::Comma;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    /;

extends 'Catalyst';

our $VERSION = '0.36';

# Configure the application.
#
# Note that settings in www_useperl_server.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'WWW::UsePerl::Server',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1, # Send X-Catalyst header
);

# Start the application
__PACKAGE__->setup();

=head1 NAME

WWW::UsePerl::Server - Serve use.perl.org content

=head1 SYNOPSIS

    script/www_useperl_server_server.pl

=head1 DESCRIPTION

use.perl.org was a Perl-specific blogging website created by Chris Nandor and
hosted at Geeknet. It was up from early 2001 until late 2010. This is project
along the lines of Archive Team (http://www.archiveteam.org) to save historical
Perl websites and keep the content going. Using this module you can host your
own use.perl.org mirror.

You'll need a MySQL server. Update www_useperl_server.conf with the database
connection details. Then import the (26MB compressed, 94MB uncompressed)
database dump from:

    https://s3.amazonaws.com/useperl/useperl-2012-04-29.sql.bz2

And run script/www_useperl_server_server.pl.

=head1 SEE ALSO

L<WWW::UsePerl::Server::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Leon Brocard, acme@astray.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
