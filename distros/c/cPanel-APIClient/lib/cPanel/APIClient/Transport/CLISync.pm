package cPanel::APIClient::Transport::CLISync;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

cPanel::APIClient::Transport::CLISync

=head1 SYNOPSIS

Call cPanel as an unprivileged user:

    my $cp = cPanel::APIClient->create(
        service = 'cpanel',
        transport => ['CLISync'],
    );

Call cPanel for C<bob> as root:

    my $cp = cPanel::APIClient->create(
        service = 'cpanel',
        transport => ['CLISync'],
        credentials => { username => 'bob' },
    );

Call WHM as root:

    my $cp = cPanel::APIClient->create(
        service = 'whm',
        transport => ['CLISync'],
    );

Call WHM for reseller C<sue> as root:

    my $cp = cPanel::APIClient->create(
        service = 'whm',
        transport => ['CLISync'],
        credentials => { username => 'sue' },
    );

=head1 DESCRIPTION

This module implements synchronous local transport (via cPanel & WHM’s
CLI API commans) for API requests.

=cut

#----------------------------------------------------------------------

use parent qw( cPanel::APIClient::Transport );

use cPanel::APIClient::X ();

use IPC::Run ();

#----------------------------------------------------------------------

sub NEEDS_CREDENTIALS { 0 }

our $_DEFAULT_TIMEOUT = 60;

sub new {
    my ( $class, $authn, %opts ) = @_;

    if ( $authn && !$authn->isa('cPanel::APIClient::Authn::Username') ) {
        die( __PACKAGE__ . ": Only username authentication is allowed!" );
    }

    my $svcname = $opts{'service_name'};
    if ( $svcname ne 'whm' && !$authn && _is_admin() ) {
        die "$svcname requires a username when accessed locally as administrator!$/";
    }

    return bless {
        authn   => $authn,
        timeout => $opts{'timeout'} || $_DEFAULT_TIMEOUT,
    }, $class;
}

# Does this work on non-UNIX platforms?
sub _is_admin {
    return !$>;
}

sub request {
    my ( $self, $service_obj, $request_obj ) = @_;

    my @cmd = $request_obj->get_cli_command( $self->{'authn'} );

    my $out = q<>;

    IPC::Run::run(
        \@cmd,
        \q<>,
        \$out,
        \*STDERR,
        IPC::Run::timeout( $self->{'timeout'} ),
    ) or die cPanel::APIClient::X->create( 'CommandFailed', \@cmd, $? );

    return $request_obj->parse_cli_response($out);
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
