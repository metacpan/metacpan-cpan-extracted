package W3C::Validator::Server;

=head1 NAME

W3C::Validator::Server - Run http://validator.w3c.org as a local instance

=head1 VERSION

0.1201

=head1 DESCRIPTION

This application is useful if you want to verify your HTML either offline
or markup that is protected on an intranet. This server should provide
the same sort of validation as L<http://validator.w3c.org>.

=head1 ENVIRONMENT VARIABLES

=head2 W3C_HOME

Will be used by both C<w3c-validator-install.sh> and
C<w3c-validator-server.psgi> to install and search for external files.
See L</INSTALLATION> for details.

=head2 W3C_VALIDATOR_CFG

Used by C<cgi-bin/check> (from w3c). Default is to look for

    $W3C_HOME/config/validator.conf

=head2 HOME

Will be used by both C<w3c-validator-install.sh> and
C<w3c-validator-server.psgi> to install and search for external files.
See L</INSTALLATION> for details.

The directory holding files will be: C<$HOME/.w3c-validator-server>

=head1 INSTALLATION

After downloading/installing this module you have to install some more
external dependencies. This can be done by using the
L<w3c-validator-install.sh> script, bundled with this package:

    $ w3c-validator-install.sh all

    # install libraries. Require sudo, apt-get and cpanm
    $ w3c-validator-install.sh libs

    # fetch files from http://validator.w3.org
    $ w3c-validator-install.sh files

    # rewrite config to defaults
    $ w3c-validator-install.sh config

The files will be installed to your home directory, or current directory
if C<Makefile.PL> is found. See L<http://validator.w3.org/docs/install.html>
for more details.

=head1 SYNOPSIS

    $ w3c-validator-server.psgi
    $ plackup /usr/bin/w3c-validator-server.psgi
    $ starman path/to/w3c-validator-server.psgi
    $ ./bin/w3c-validator-server.psgi

=cut

use strict;
use warnings;
use Plack::Builder;
use Plack::App::File;
use Plack::App::CGIBin;
use base 'Plack::Runner';

our $VERSION = eval '0.1201';

=head1 METHODS

=head2 build_app

    $app = $class->build_app({
               home => '/path/to/...', # W3C_HOME
               htdocs => '/path/to/...', # W3C_HOME/root/htdocs
               cgi_bin => '/path/to/...', # W3C_HOME/root/cgi-bin
               validator_config => '/path/to/...', # W3C_VALIDATOR_CFG
           });

Will use L<Plack::Builder> to create a plack application.

See L</ENVIRONMENT VARIABLES> for details on how to instruct this method.

=cut

sub build_app {
    my $class = shift;
    my $args = ref $_[0] eq 'HASH' ? shift : {@_};
    my $base = $args->{'home'}  ? $args->{'home'}
             : $ENV{'W3C_HOME'} ? $ENV{'W3C_HOME'}
             : -e 'Makefile.PL' ? './'
             :                    "$ENV{HOME}/.w3c-validator-server"
             ;

    my $htdocs = $args->{'htdocs'} || "$base/root/htdocs";
    my $cgi_bin = $args->{'cgi_bin'} || "$base/root/cgi-bin";

    $ENV{'W3C_VALIDATOR_CFG'} ||= $args->{'validator_config'} || "$base/config/validator.conf";

    builder {
        mount '/' => builder {
            enable sub {
                my $app = shift;
                sub {
                    $_[0]->{'PATH_INFO'} = '/index.html' if($_[0]->{'PATH_INFO'} eq '/');
                    return $app->(@_);
                };
            };
            enable 'SSI';
            Plack::App::File->new(root => $htdocs)->to_app;
        };
        mount '/check' => (
            Plack::App::WrapCGI->new(script => "$cgi_bin/check")->to_app
        );
    };
}

=head2 version_cb

See L<Plack::Runner/version_cb>.

=cut

sub version_cb {
    sub { print "W3C::Validator::Server version $VERSION\n" };
}

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen - C<< jhthorsen at cpan.org >>

=cut

'W3C::Validator::Server';
