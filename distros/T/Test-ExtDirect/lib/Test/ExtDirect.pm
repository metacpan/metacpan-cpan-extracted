package Test::ExtDirect;

use strict;
use warnings;

use Carp;
use Data::Dumper; # for cloning
use Exporter;

use Test::More;

use RPC::ExtDirect::Server;
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Client;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    maybe_start_server
    start_server
    stop_server

    get_extdirect_api

    call_extdirect
    submit_extdirect
    poll_extdirect

    call_extdirect_ok
    submit_extdirect_ok
    poll_extdirect_ok

    call
    submit
    poll

    call_ok
    submit_ok
    poll_ok
);

our %EXPORT_TAGS = (
    DEFAULT => [qw/
        start_server stop_server call_extdirect call_extdirect_ok
        submit_extdirect submit_extdirect_ok poll_extdirect
        poll_extdirect_ok get_extdirect_api maybe_start_server
    /],

    all => [qw/
        start_server stop_server call_extdirect call_extdirect_ok
        submit_extdirect submit_extdirect_ok poll_extdirect
        poll_extdirect_ok call submit poll call_ok submit_ok poll_ok
        get_extdirect_api maybe_start_server
    /],
);

our @EXPORT = qw(
    maybe_start_server
    start_server
    stop_server

    get_extdirect_api
    call_extdirect
    call_extdirect_ok
    submit_extdirect
    submit_extdirect_ok
    poll_extdirect
    poll_extdirect_ok
);

our $VERSION = '1.01';

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Starts testing HTTP server and returns the host and port
# the server is listening on.
#

*start_server = *RPC::ExtDirect::Server::Util::start_server;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Stops the running HTTP server instance
#

*stop_server = *RPC::ExtDirect::Server::Util::stop_server;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Potentially starts an instance of a Server.
#

*maybe_start_server = *RPC::ExtDirect::Server::Util::maybe_start_server;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Return Ext.Direct API published by the server as RPC::ExtDirect::Client::API
# object
#

sub get_extdirect_api {
    my (%params) = @_;
    
    # We assume that users want remoting API by default
    my $api_type = delete $params{type} || 'remoting';
    
    my $client = _get_client(%params);
    my $api    = $client->get_api($api_type);

    return $api;
}

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Instantiate a new RPC::ExtDirect::Client and make a request call
# returning the data
#

sub call_extdirect {
    my (%params) = @_;

    my $action_name = delete $params{action};
    my $method_name = delete $params{method};
    my $arg         = _clone( delete $params{arg} );

    my $client = _get_client(%params);
    
    # This is a backward compatibility measure; until RPC::ExtDirect 3.0 the
    # calling code wasn't required to pass any arg to the client when calling
    # a method with ordered parameters. It is now an error to do so, and
    # for a good reason: starting with version 3.0, it is possible to
    # define a method with no strict argument checking, which defaults to
    # using named parameters. To avoid possible problems stemming from this
    # change, we strictly check the existence of arguments for both ordered
    # and named conventions in RPC::ExtDirect::Client.
    #
    # Having said that, I don't think that this kind of strict checking is
    # beneficial for Test::ExtDirect since the test code that calls
    # Ext.Direct methods is probably focusing on other aspects than strict
    # argument checking that happens in the transport layer.
    #
    # As a side benefit, we also get an early warning if something went awry
    # and we can't even get a reference to the Action or Method in question.
    
    if ( !$arg ) {
        my $api = $client->get_api('remoting');
        
        croak "Can't get remoting API from the client" unless $api;
    
        my $method = $api->get_method_by_name($action_name, $method_name);
        
        croak "Can't resolve ${action_name}->${method_name} method"
            unless $method;
        
        if ( $method->is_ordered ) {
            $arg = [];
        }
        elsif ( $method->is_named ) {
            $arg = {};
        }
    }
    
    my $data = $client->call(
        action => $action_name,
        method => $method_name,
        arg    => $arg,
        %params,
    );

    return $data;
}

*call = \&call_extdirect;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Run call_extdirect wrapped in eval and fail the test if it dies
#

sub call_extdirect_ok {
    local $@;
    
    my $result = eval { call_extdirect(@_) };

    _pass_or_fail(my $err = $@);

    return $result;
}

*call_ok = \&call_extdirect_ok;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Submit a form to Ext.Direct method
#

sub submit_extdirect {
    my (%params) = @_;

    my $action = delete $params{action};
    my $method = delete $params{method};
    my $arg    = _clone( delete $params{arg}    );
    my $upload = _clone( delete $params{upload} );

    my $client = _get_client(%params);
    my $data   = $client->submit(action => $action, method => $method,
                                 arg    => $arg,    upload => $upload,
                                 %params);

    return $data;
}

*submit = \&submit_extdirect;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Run submit_extdirect wrapped in eval, fail the test if it dies
#

sub submit_extdirect_ok {
    local $@;
    
    my $result = eval { submit_extdirect(@_) };

    _pass_or_fail(my $err = $@);

    return $result;
}

*submit_ok = \&submit_extdirect_ok;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Poll Ext.Direct event provider and return data
#

sub poll_extdirect {
    my (%params) = @_;

    my $client = _get_client(%params);
    my $data   = $client->poll(%params);

    return $data;
}

*poll = \&poll_extdirect;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Run poll_extdirect wrapped in eval, fail the test if it dies
#

sub poll_extdirect_ok {
    local $@;
    
    my $result = eval { poll_extdirect(@_) };

    _pass_or_fail(my $err = $@);

    return $result;
}

*poll_ok = \&poll_extdirect_ok;

############## PRIVATE METHODS BELOW ##############

### PRIVATE PACKAGE SUBROUTINE ###
#
# Initializes RPC::ExtDirect::Client instance
#

sub _get_client {
    my (%params) = @_;

    my $class = delete $params{client_class} || 'RPC::ExtDirect::Client';

    eval "require $class" or croak "Can't load package $class";

    $params{static_dir} ||= '/tmp';

    my ($host, $port) = maybe_start_server(%params);

    my $client = $class->new(host => $host, port => $port, %params);

    return $client;
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Pass or fail a test depending on $@
#

sub _pass_or_fail {
    my ($err) = @_;

    my ($calling_sub) = (caller 0)[3];

    if ( $err ) {
        fail "$calling_sub failed: $err";
    }
    else {
        pass "$calling_sub successful";
    };
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Create a deep copy (clone) of the passed data structure.
# We're not much concerned with performance here, and this
# custom implementation allows to avoid a depedency like
# Clone or Storable, which is overkill here.
#

sub _clone {
    my $data = shift;
    
    # Faster than calling instance methods
    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Deepcopy = 1;
    
    return eval Dumper($data);
}

1;
