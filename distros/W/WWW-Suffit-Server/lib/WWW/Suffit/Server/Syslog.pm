package WWW::Suffit::Server::Syslog;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::Syslog - A plugin for enabling logging to syslog for Suffit servers

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    # in your startup
    $self->plugin('WWW::Suffit::Server::CommonHelpers');

=head1 DESCRIPTION

This plugin for enabling logging to syslog for Suffit servers

=head1 METHODS

Internal methods

=head2 register

Do not use directly. It is called by Mojolicious.

=head1 OPTIONS

=head2 enable

Need to be true to activate this plugin.
Default to true if "mode" in Mojolicious is something else than "development"

=head2 facility

The syslog facility to use. Default to "user"

=head2 ident

The syslog ident to use. Default to "moniker" in Mojolicious

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>, L<Mojolicious::Plugin::Syslog>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '1.00';

use Sys::Syslog qw//;

use constant {
    LOGOPTS         => 'ndelay,pid', # For Sys::Syslog
    SEPARATOR       => ' ',
    LOGFORMAT       => '%s',
};
my %LOGLEVELS = (
    'debug'   => Sys::Syslog::LOG_DEBUG,    # debug-level message
    'info'    => Sys::Syslog::LOG_INFO,     # informational message
    'warn'    => Sys::Syslog::LOG_WARNING,  # warning conditions
    'error'   => Sys::Syslog::LOG_ERR,      # error conditions
    'fatal'   => Sys::Syslog::LOG_CRIT,     # critical conditions
);


sub register {
    my ($self, $app, $config) = @_;
    return 1 unless $config->{enable} // $app->mode ne 'development';

    # Correct plugin config
    $config->{facility} ||= Sys::Syslog::LOG_USER;
    $config->{ident}    ||= $app->moniker;
    $config->{logopt}   ||= LOGOPTS;

    # Open sys log socket
    Sys::Syslog::openlog($config->{ident}, $config->{logopt}, $config->{facility});

    # Unsubscribe
    $app->log->unsubscribe('message');
    $app->log->unsubscribe(message => \&_to_syslog);

    # Subscribe
    $app->log->on(message => \&_to_syslog);
}
sub _to_syslog {
    my ($log, $level, @msg) = @_;
    my $lvl = $LOGLEVELS{$level} // Sys::Syslog::LOG_DEBUG;
    Sys::Syslog::syslog($lvl, LOGFORMAT, join(SEPARATOR, @msg));
}

1;

__END__

