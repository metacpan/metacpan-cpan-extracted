[![Build Status](https://travis-ci.org/whosgonna/Zabbix-Tiny.pm.svg?branch=master)](https://travis-ci.org/whosgonna/Zabbix-Tiny.pm) [![Coverage Status](https://img.shields.io/coveralls/whosgonna/Zabbix-Tiny.pm/master.svg?style=flat)](https://coveralls.io/r/whosgonna/Zabbix-Tiny.pm?branch=master)
# NAME

Zabbix::Tiny - A small module to eliminate boilerplate overhead when using the Zabbix API

# SYNOPSIS

    use strict;
    use warnings;
    use Zabbix::Tiny;

    use Data::Dumper;

    my $username = 'zabbix_user';
    my $password = 'secretpassword';
    my $url = 'https://zabbix.domain.com/zabbix/api_jsonrpc.php';

    my $zabbix = Zabbix::Tiny->new(
        server   => $url,
        password => $password,
        user     => $username
    );

    my $params = {
        output    => [qw(hostid name host)],  # Remaining paramters to 'do' are the params for the zabbix method.
        monitored => 1,
        limit     => 2,
        ## Any other params desired
    };

    $zabbix->prepare('host.get', $params);  # Prepare the query.
    print $zabbix->prepared . "\n";         # Get the JSON query without actually executing it.
    my $host = $zabbix->do;                 # Execute the prepared query.

    # Alternately, the query can be prepared and executed in one step.
    my $hosts = $zabbix->do(
        'host.get',  # First argument is the Zabbix API method
        $params
    );

    # Run the same query again.  Could be useful for history and trend data
    my $hosts = $zabbix->do;

    # Print some of the retreived information.
    for my $host (@$hosts) {
        print "Host ID: $host->{hostid} - Display Name: $host->{name}\n";
    }

    # Debugging methods:
    print "JSON request:\n" . $zabbix->json_request . "\n\n";   # Print the json data sent in the last request.
    print "JSON response:\n" . $zabbix->json_response . "\n\n"; # Print the json data received in the last response.
    print "Auth is: ". $zabbix->auth . "\n";

    print "\$zabbix->last_response:\n";
    print Dumper $zabbix->last_response;

    print "\$zabbix->post_response:\n";
    print Dumper $zabbix->post_response; # Very verbose.  Probably unnecessary.

Note that as of version 1.0.6, creation of the Zabbix::Tiny object does not automatically log into the Zabbix server.
The object will login to the Zabbix server on the first call to the `prepare` or `do` method.  If these methods fail
to connect with an invalid auth ID (for example, becasuse the user's log in timed out between the prevous call and this
call, the module will make an attempt to log in again to get a new auth ID.  This makes the module suitable for long
running scripts.

# DESCRIPTION

This module functions as a simple wrapper to eliminate boilerplate that might otherwise need to be created when interfacing with the Zabbix API.  Login to the Zabbix server is handled with the constructor. Beyond that, the primary method is the `do` method. The user.logout method is implemented  in the object deconstructor as well, so there should be no need to explicitly logout of Zabbix.

This module is currently developed against Zabbix 3.2.  It is expected to work with Zabbix 3.0, 2.4, 2.2, and likely 2.0 as well.  It is much less certain it will work with Zabbix 1.8.  Please refer to the API section of the Zabbix manual for details on its methods.

# METHODS

## PRIMARY METHODS

- my $zabbix = Zabbix::Tiny->new( server => $url, password => $password, user => $username, \[ssl\_opts => {%ssl\_opts}\]);

    The constructor requires server, user, and password.  It will create the Zabbix::Tiny object, and log in to the server all at once.  The `ssl_opts` argument can be set to set the LWP::UserAgent ssl\_opts attribute when connecting to https with a self-signed or otherwise un-trusted certificate (see note about untrusted certificates below).

- $zabbix->prepare('zabbix.method', $params );

    This creates the json string to be sent to the Zabbix server.  It can then be executed with the `execute` method.

- my $hosts = $zabbix->do('zabbix.method', ... );

        my $hosts = $zabbix->do;
        my $hosts = $zabbix->do('zabbix.method', {%params});
        my $hosts = $zabbix->do('zabbix.method', [@params]);
        my $hosts = $zabbix->do('zabbix.method', %params); ## Depricated

    This will execute any defined Zabbix method, with the corresponding params.  Refer to the Zabbix manual for a list of available methods.  If the Zabbix method is of a \*.get flavor, the return is an arrayref data structure containing the response from the Zabbix server.  Calling `do` without any arguments will use the currently prepared json string.  It also calls `prepare` immediately after executing. This not only allows for a statement to be prepared, then examined, then executed for debugging purposes.  It also allows for the same query to be run multiple times in a row.

## DEPRICATED METHODS

    my $hosts = $zabbix->do('zabbix.method', %params);

Starting with v1.05, it is preferred to pass parameters as a hashref or an arrayref, since a few Zabbix API methods take an array, rather than a hash of parameters.  Support for params as a hash are still supported for backwards compatibility.

## DEBUGGING METHODS

The Zabbix::Tiny `do` method contains a very succinct arrayref that should contain only the data needed for interacting with the Zabbix server, so there should be little need to worry about serializing json, managing the Zabbix auth token, etc., however these methods are provided for convenience.

- my $auth = $zabbix->auth;

    The main purpose of this module is to hide away the need to track the authentication token in the script.  With that in mind, the token used can be retrieved with this method if needed.

- my $json\_request = $zabbix->json\_request;

    Used to retrieve the last raw json message sent to the Zabbix server, including the "jsonrpc", "id", and "auth".

- my $json\_response = $zabbix->json\_response;

    Used to retrieve the last raw json message from the zabbix server,  including the "jsonrpc", "id", and "auth".

- my $verbose = $zabbix->last\_response;

    Similar to json\_response, but the last response message as a perl data structure (hashref).

- my $post\_response = $zabbix->post\_response;

    The [HTTP::Response](https://metacpan.org/pod/HTTP::Response) from the Zabbix server for the most recent request.

# BUGS and CAVEATS

Probably bugs.

# NOTES

## Untrusted Certificates

In many cases it is expected that zabbix servers may be using self-signed or otherwise 'untrusted' certiifcates.  The ssl\_opts argument in the constructor can be set to any valid values for LWP::UserAgent to disallow certificate checks.  For example:

    use strict;
    use warnings;
    use Zabbix::Tiny;
    use IO::Socket::SSL;

    my $zabbix =  Zabbix::Tiny->new(
        server   => $url,
        password => $password,
        user     => $username,
        ssl_opts => {
            verify_hostname => 0,
            SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE
        },
    );

# See Also

Zabbix API Documentation: [https://www.zabbix.com/documentation/3.0/manual/api](https://www.zabbix.com/documentation/3.0/manual/api)

# COPYRIGHT

Zabbix::Tiny is Copyright (C) 2016, Ben Kaufman.

# License Information

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.20.3.

This program is distributed in the hope that it will be useful, but it is provided 'as is' and without any express or implied warranties.

# AUTHOR

Ben Kaufman
