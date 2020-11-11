package cPanel::APIClient::Request::UAPIFromWHM1;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use parent qw( cPanel::APIClient::Request::WHM1 );

use cPanel::APIClient::Utils::JSON    ();
use cPanel::APIClient::Response::UAPI ();

sub HTTP_RESPONSE_CLASS { return 'cPanel::APIClient::Response::UAPI' }

sub new {
    my ($class, $cpusername, $module, $fn, $args_hr, $metaargs_hr) = @_;

    die 'Need username!' if !defined $cpusername || !length $cpusername;
    die 'Need module!' if !defined $module || !length $module;
    die 'Need function name!' if !defined $fn || !length $fn;

    my %args = (
        cpanel_jsonapi_apiversion => 3,
        cpanel_jsonapi_module     => $module,
        cpanel_jsonapi_func       => $fn,
        cpanel_jsonapi_user       => $cpusername,
        $args_hr ? %$args_hr : (),
    );

    return $class->SUPER::new( 'cpanel', \%args, $metaargs_hr );
}

sub _EXTRACT_RESPONSE {

    # Ordinarily our response looks thus:
    #
    # {
    #   "module": "Email",
    #   "func": "list_pops",
    #   "result": {
    #     "metadata": {
    #       "transformed": 1
    #     },
    #     "warnings": null,
    #     "data": [
    #       {
    #         "suspended_incoming": 0,
    #         "email": "mail@proxied.tld",
    #         "suspended_login": 0,
    #         "login": "mail@proxied.tld"
    #       },
    #       {
    #         "suspended_login": 0,
    #         "email": "proxied",
    #         "suspended_incoming": 0,
    #         "login": "Main Account"
    #       }
    #     ],
    #     "messages": null,
    #     "errors": null,
    #     "status": 1
    #   },
    #   "apiversion": 3
    # }

    return $_[1]->{'result'} if 'HASH' eq ref $_[1]->{'result'};

    # If the given username fails authn, though, an error like this is
    # returned:
    #
    # {
    #   "data": {
    #       "reason": "User parameter is invalid or was not supplied",
    #       "result": "0"
    #   },
    #   "type": "text",
    #   "error": "User parameter is invalid or was not supplied"
    # }

    die cPanel::APIClient::X->create('API', $_[1]->{'error'}) if $_[1]->{'error'};

    # This shouldn’t happen …
    require Data::Dumper;
    die "$_[0]: Received invalid payload: " . Data::Dumper::Dumper($_[1]);
}

1;
