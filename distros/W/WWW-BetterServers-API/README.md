WWW-BetterServers-API
=====================

WWW::BetterServers::API is an easy-to-use wrapper for the
BetterServers REST API. Provide the constructor your API id and API
secret (available in the BetterServers portal area after signup), and
you can now create, list, destroy your BetterServers VM instances:

    my $api_id    = '(your api id here)';
    my $auth_type = '(your auth type here)';
    my $secret    = '(your secret here)';

    my $api = new WWW::BetterServers::API(api_id     => $api_id,
                                          api_secret => $secret,
                                          auth_type  => $auth_type);

    my $resp = $api->request(method  => "GET",
                             uri     => "/v1/accounts/$api_id/plans");

    my $plan_id = $resp->json('/plans/0/plan_id');

    $resp = $api->request(method  => "POST",
                          uri     => "/v1/accounts/$api_id/instances",
                          payload => { plan_id => $plan_id,
                                       display_name => "my new vm" });

    if( $resp->code == 201 ) {
        say "Your new server id is " . $resp->json('/id');
    }

## INSTALLATION ##

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

See the POD with this module for help running the test with your own
API credentials.

## DEPENDENCIES ##

This module requires these other modules and libraries:

  Mojolicious
  IO::Socket::SSL

## COPYRIGHT AND LICENCE ##

Copyright (C) 2013, 2014 by BetterServers, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
