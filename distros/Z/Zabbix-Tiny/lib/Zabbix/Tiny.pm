package Zabbix::Tiny;
use strict;
use warnings;
use Moo;
use Carp;
use LWP;
use JSON;
use version;

our $VERSION = "2.0.1";

has 'server' => (
    is       => 'rw',
    required => 1,
);
has 'user' => (
    is       => 'rw',
    required => 1,
);
has 'password' => (
    is       => 'rw',
    required => 1,
);
has 'zabbix_method'   => ( is => 'ro' );
has 'zabbix_params'   => ( is => 'ro' );
has 'auth'            => ( is => 'ro' );
has 'ua'              => (
    is      => 'ro',
    lazy    => 1,
    default => sub { LWP::UserAgent->new },
);
has 'id'              => ( is => 'ro', default => sub { 1 } );
has 'post_response'   => ( is => 'ro' );
has 'last_response'   => ( is => 'ro' );
has 'json_request'    => ( is => 'ro' );
has 'json_response'   => ( is => 'ro' );
has 'verify_hostname' => ( is => 'rw', default => sub { 1 } );
has 'ssl_opts'        => ( is => 'rw' );
has 'delay'           => ( is => 'rw' );
has 'request'         => ( is => 'ro' );
has 'json_prepared'   => ( is => 'ro' );
has 'json_executed'   => ( is => 'ro', default => sub { 0 } );
has 'redo'            => ( is => 'ro' );
has 'version'         => ( is => 'lazy' );

my @content_type = ( 'content-type', 'application/json', );

sub BUILD {
    my $self      = shift;
    my $ua        = $self->ua;
    my $url       = $self->server;

    my $json_data = {
        jsonrpc => '2.0',
        id      => $self->id,
        method  => 'user.login',
        params  => {
            user     => $self->user,
            password => $self->password,
        },
    };

    if ( $self->verify_hostname == 0 ) {
        $ua->ssl_opts( verify_hostname => 0 );
    }

    if ( $self->ssl_opts ) {
        $ua->ssl_opts( %{ $self->{ssl_opts} } );
    }
}


sub _build_version {
    my $self      = shift;
    my $id        = $self->id;
    my $ua        = $self->ua;
    my $url       = $self->server;

    my $json_data = {
        jsonrpc => '2.0',
        id      => $self->id,
        method  => 'apiinfo.version',
        params  => {
        },
    };

    my $encoded_json = encode_json ($json_data);

    my $post_response = $ua->post(
        $self->server, 
        @content_type,
        Content => $encoded_json
    );

    _validate_http_response($post_response);

    my $response_content = decode_json( $post_response->{_content} );

    if ( $response_content->{error} ) {
        my $error = $response_content->{error}->{data};
        croak("Error: $error");
    }
    else {
        my $version = version->new($response_content->{'result'});
        return($version);
    }
}


sub login {
    my $self      = shift;
    my $id        = $self->id;
    my $ua        = $self->ua;
    my $url       = $self->server;

    my $json_data =  {
        jsonrpc => '2.0',
        id      => $id,
        method  => 'user.login',
    };

    if ( $self->version lt "6.0" ) {
        $json_data->{params} = {
            user     => $self->user,
            password => $self->password,
        };
    } else {
        $json_data->{params} = {
            username => $self->user,
            password => $self->password,
        };
    }

    my $json = encode_json($json_data);
    my $response = $ua->post( $url, @content_type, Content => $json );

    _validate_http_response($response);

    my $content = decode_json( $response->{_content} ) or die($!);

    if ( $content->{error} ) {
        my $error_data = $content->{error}->{data};
        my $error_msg  = $content->{error}->{message};
        my $error_code = $content->{error}->{code};
        my $error = "Error from Zabbix (code $error_code): $error_msg  $error_data";
        croak($error);
    }

    $self->{auth} = $content->{'result'};
}


sub _validate_http_response {
    my $response = shift;

    if ( $response->{_rc} !~ /2\d\d/ ) {
        my $error_message = "HTTP error ";
        $error_message   .= "(code $response->{_rc}) ";
        $error_message   .= $response->{_msg} // q{};
        croak($error_message);
    }
}

sub prepare {
    my $self   = shift;
    my $method = shift;
    $self->{ id }++;
    if ($method) {
        $self->{zabbix_method} = $method;
        undef $self->{zabbix_params};
        my @args = @_;
        if ( scalar @args == 1 ) {
            $self->{zabbix_params} = $args[0];
        }
        else {
            my %params = @args;
            $self->{zabbix_params} = \%params;
        }
    }
    unless ($self->{zabbix_method} eq 'apiinfo.version') {
        login($self) if ( !$self->auth );
    }
    if ( !$self->zabbix_method ) {
        croak("No Zabbix API method defined");
    }
    $self->{request} = {
        jsonrpc => '2.0',
        id      => $self->id,
        method  => $self->zabbix_method,
        params  => $self->zabbix_params,
    };
    unless ($self->{zabbix_method} eq 'apiinfo.version') {
        $self->{request}->{auth} = $self->auth;
    }
    $self->{json_prepared} = encode_json( $self->request ) or die($!);
}

sub execute {
    my $self = shift;
    my $ua   = $self->ua;
    $self->{post_response} = $ua->post( $self->server, @content_type,
        Content => $self->json_prepared );
    $self->{json_request}  = $self->{post_response}->{'_request'}->{_content};
    $self->{json_response} = $self->post_response->{_content};
    if ( $self->post_response->{_content} eq q{} ) {
        croak( "Empty response received from the Zabbix API. This can indicate an error on the API side like running out of memory." );
    }
    $self->{last_response} = decode_json( $self->{post_response}->{_content} );
    my $method = $self->zabbix_method;
    my $params = $self->zabbix_params;
    prepare($self); ## Rerun prepare to get the new request id.
}

sub do {
    my $self   = shift;
    my $method = shift;
    my @args   = @_;
    if ($method) {
        prepare( $self, $method, @args );
    }
    execute($self);
    if ( $self->{last_response}->{error} ) {
        my $error = $self->{last_response}->{error}->{data};
        if (   ( !$self->{redo} )
            && ( $error eq 'Session terminated, re-login, please.' ) )
        {
            $self->{redo}++;
            delete( $self->{auth} );
            prepare($self);
            &do($self);    ## Need to use "&" because "do" is a perl keyword.
        }
        else {
            croak("Error: $error");
        }
    }
    else {
        delete( $self->{redo} ) if $self->redo;
        $self->{json_executed} = 1;
        return $self->{last_response}->{'result'};
    }
}

sub DEMOLISH {
    my $self      = shift;
    my $method    = shift;
    my $ua        = $self->ua;
    my $auth      = $self->auth;
    my $url       = $self->server;
    
    return unless ($ua);
    
    my $json_data = {
        jsonrpc => '2.0',
        id      => ++$self->{ id },
        method  => 'user.logout',
        auth    => $auth,
    };
    my $json = encode_json($json_data);
    $self->{post_response} = $ua->post( $url, @content_type, Content => $json );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Zabbix::Tiny - A small module to eliminate boilerplate overhead when using the Zabbix API

=head1 SYNOPSIS

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
  print $zabbix->json_prepared . "\n";    # Get the JSON query without actually executing it.
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
  print "Prepared JSON:\n" . $zabbix->json_prepared . "\n\n"; # Print the JSON that will be sent if $zabbix->do is called.
  print "Auth is: ". $zabbix->auth . "\n";

  print "\$zabbix->last_response:\n";
  print Dumper $zabbix->last_response;

  print "\$zabbix->post_response:\n";
  print Dumper $zabbix->post_response; # Very verbose.  Probably unnecessary.

Note that as of version 1.0.6, creation of the Zabbix::Tiny object does not automatically log into the Zabbix server.
The object will login to the Zabbix server on the first call to the C<prepare> or C<do> method.  If these methods fail
to connect with an invalid auth ID (for example, becasuse the user's log in timed out between the prevous call and this
call, the module will make an attempt to log in again to get a new auth ID.  This makes the module suitable for long
running scripts.

=head1 DESCRIPTION

This module functions as a simple wrapper to eliminate boilerplate that might otherwise need to be created when interfacing with the Zabbix API.  Login to the Zabbix server is handled with the constructor. Beyond that, the primary method is the C<do> method. The user.logout method is implemented  in the object deconstructor as well, so there should be no need to explicitly logout of Zabbix.

This module is currently developed against Zabbix 3.2.  It is expected to work with Zabbix 3.0, 2.4, 2.2, and likely 2.0 as well.  It is much less certain it will work with Zabbix 1.8.  Please refer to the API section of the Zabbix manual for details on its methods.

=head1 METHODS

=head2 PRIMARY METHODS

=over 4

=item my $zabbix = Zabbix::Tiny->new( server => $url, password => $password, user => $username, [ssl_opts => {%ssl_opts}]);

The constructor requires server, user, and password.  It will create the Zabbix::Tiny object, and log in to the server all at once.  The C<ssl_opts> argument can be set to set the LWP::UserAgent ssl_opts attribute when connecting to https with a self-signed or otherwise un-trusted certificate (see note about untrusted certificates below).

=item $zabbix->prepare('zabbix.method', $params );

This creates the json string to be sent to the Zabbix server.  It can then be executed with the C<execute> method.

=item my $hosts = $zabbix->do('zabbix.method', ... );

 my $hosts = $zabbix->do;
 my $hosts = $zabbix->do('zabbix.method', {%params});
 my $hosts = $zabbix->do('zabbix.method', [@params]);
 my $hosts = $zabbix->do('zabbix.method', %params); ## Depricated

This will execute any defined Zabbix method, with the corresponding params.  Refer to the Zabbix manual for a list of available methods.  If the Zabbix method is of a *.get flavor, the return is an arrayref data structure containing the response from the Zabbix server.  Calling C<do> without any arguments will use the currently prepared json string.  It also calls C<prepare> immediately after executing. This not only allows for a statement to be prepared, then examined, then executed for debugging purposes.  It also allows for the same query to be run multiple times in a row.


=back

=head2 DEPRICATED METHODS

 my $hosts = $zabbix->do('zabbix.method', %params);

Starting with v1.05, it is preferred to pass parameters as a hashref or an arrayref, since a few Zabbix API methods take an array, rather than a hash of parameters.  Support for params as a hash are still supported for backwards compatibility.


=head2 DEBUGGING METHODS

The Zabbix::Tiny C<do> method contains a very succinct arrayref that should contain only the data needed for interacting with the Zabbix server, so there should be little need to worry about serializing json, managing the Zabbix auth token, etc., however these methods are provided for convenience.

=over 4

=item my $auth = $zabbix->auth;

The main purpose of this module is to hide away the need to track the authentication token in the script.  With that in mind, the token used can be retrieved with this method if needed.

=item my $json_request = $zabbix->json_request;

Used to retrieve the last raw json message sent to the Zabbix server, including the "jsonrpc", "id", and "auth".

=item my $json_response = $zabbix->json_response;

Used to retrieve the last raw json message from the zabbix server,  including the "jsonrpc", "id", and "auth".

=item my $json_prepared = $zabbix->json_prepared;

Used to retrieve the raw json message ready to be sent to Zabbix server, including the "jsonrpc", "id" and "auth".

=item my $verbose = $zabbix->last_response;

Similar to json_response, but the last response message as a perl data structure (hashref).

=item my $post_response = $zabbix->post_response;

The L<HTTP::Response> from the Zabbix server for the most recent request.

=back

=head1 BUGS and CAVEATS

Probably bugs.

=head1 NOTES

=head2 Untrusted Certificates

In many cases it is expected that zabbix servers may be using self-signed or otherwise 'untrusted' certificates.  The ssl_opts argument in the constructor can be set to any valid values for LWP::UserAgent to disallow certificate checks.  For example:

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


=head1 See Also

Zabbix API Documentation: L<https://www.zabbix.com/documentation/3.2/manual/api>

=head1 COPYRIGHT

Zabbix::Tiny is Copyright (C) 2016, Ben Kaufman.

=head1 License Information

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.

This program is distributed in the hope that it will be useful, but it is provided 'as is' and without any express or implied warranties.

=head1 AUTHORS

Ben Kaufman

Richlv

Ihor Siroshtan
