# vim: set sw=4 ts=4 et si ai:
#
package WebService::IdoitAPI;

use 5.006;
use strict;
use warnings;

use Carp;
use JSON::RPC::Legacy::Client;

our $VERSION = 'v0.2.2';

my @CONFIG_VARS = qw(apikey password url username);

sub new {
    my ($class,$config) = @_;
    my $self = {
        config => {},
        version => '2.0',
    };

    bless($self, $class);
    if (defined $config) {
        for my $cv (@CONFIG_VARS) {
            if (exists $config->{$cv}) {
                $self->{config}->{$cv} = $config->{$cv};
            }
        }
        $self->_test_minimum_config();
    }
    return $self;
} # new()

sub DESTROY {
    my $self = shift;

    if ($self->is_logged_in()) {
        $self->logout();
    }
    return;
} # DESTROY()

sub request {
    my ($self,$request) = @_;
    if (defined $request) {
        my $client;
        if (exists $self->{client}) {
            $client = $self->{client};
        }
        else {
            $client = new JSON::RPC::Legacy::Client;
            $self->{client} = $client;
            if ($self->{session_id}) {
                $client->{ua}->default_header('X-RPC-Auth-Session' => $self->{session_id});
            }
            else {
                if (defined $self->{config}->{password}) {
                    $client->{ua}->default_header( 'X-RPC-Auth-Password' => $self->{config}->{password} );
                }
                if (defined $self->{config}->{username}) {
                    $client->{ua}->default_header( 'X-RPC-Auth-Username' => $self->{config}->{username} );
                }
            }
        }
        $request->{version} = "2.0"
            unless (defined $request->{version});
        $request->{id} = 1
            unless (defined $request->{id});
        $request->{params}->{language} = 'en'
            unless (defined $request->{params}->{language});
        $request->{params}->{apikey} = $self->{config}->{apikey};

        my $res = do {
            local $@;
            my $ret;
            eval { $ret = $client->call($self->{config}->{url},$request); 1};
            if ( $@ ) {
                my $status_line = $self->{client}->{status_line};
                if ( $status_line !~ /^2[0-9]{2} / ) {
                    die "Connection problem: $status_line";
                }
                die "JSON RPC client failed: $@";
            }
            $ret;
        };
        return $res;
    }
    return;
} # request()

sub login {
    my ($self,$user,$pass) = @_;

    $user = $self->{config}->{username} unless ($user);
    $pass = $self->{config}->{password} unless ($pass);

    my $client = new JSON::RPC::Legacy::Client;
    $client->{ua}->default_header( 'X-RPC-Auth-Password' => $pass );
    $client->{ua}->default_header( 'X-RPC-Auth-Username' => $user );
    $self->{client} = $client;

    my $res = $self->request( { method => 'idoit.login' } );
    if ($res->{is_success}) {
        my $h = $self->{client}->{ua}->default_headers();
        $h->header('X-RPC-Auth-Session' => $res->{content}->{result}->{'session-id'});
        $h->remove_header('X-RPC-Auth-Username');
        $h->remove_header('X-RPC-Auth-Password');
        $self->{session_id} = $res->{content}->{result}->{'session-id'};
        return $res;
    }
    return;
} # login()

sub logout {
    my $self = shift;

    my $res = $self->request( { method => 'idoit.login' } );
    delete $self->{session_id};
    delete $self->{client}; # grab a fresh client next time
    return $res;
} # logout()

sub is_logged_in {
    return exists $_[0]->{session_id};
} # is_logged_in()

sub read_config {
    my $fname = shift;

    my $known_paths = [ # some known paths of other configuration files
        "$ENV{HOME}/.idoitcli/config.json",
    ];

    unless ( $fname ) {
        for ( @$known_paths ) {
            if ( -r $_ ) {
                $fname = $_;
                last;
            }
        }
    }
    open(my $fh, '<', $fname)
      or die "Can't open config file '$fname': $!";

    my $config = _read_config_fh($fh);

    close($fh);

    $config->{config_file} = $fname;

    return $config;
} # read_config()

sub _read_config_fh {
    my $fh = shift;

    my $config = {};
    my %valid = map { $_ => 1 } qw(
        apikey key password url username
    );

    while (<$fh>) {
        if ( /^\s*(\S[^:=]+)[:=]\s*(\S.+)$/ ) {
            my ($key, $val) = ($1, $2);
            for ($key, $val) {
                s/\s+$//;
                s/[,;]$//;
                s/^"(.*)"$/$1/;
                s/^'(.*)'$/$1/;
            }
            next unless ( $valid{$key} );
            $config->{$key} = $val;
        }
    }

    $config->{apikey} = $config->{key} unless ( exists $config->{apikey} );
    unless ( $config->{url} =~ m|/src/jsonrpc[.]php$| ) {
        $config->{url} =~ s#/?$#/src/jsonrpc.php#;
    }

    return $config;
} # _read_config_fh()

sub _test_minimum_config {
    my $self = shift;
    croak "configuration is missing the API key"
        unless ( $self->{config}->{apikey} );
    croak "configuration is missing the URL for the API"
        unless ( $self->{config}->{url} );
} # _test_minimum_config()

1; # End of WebService::IdoitAPI

__DATA__

=head1 NAME

WebService::IdoitAPI - a library to access the i-doit JSON RPC API

=head1 VERSION

Version v0.2.2

=head1 SYNOPSIS

Allow access to the JSON-RPC-API of i-doit using Perl data structures.

    use WebService::IdoitAPI;

    my $config = {
        apikey => 'your_key_here',
        password => 'your_password_here',
        url => 'full_url_to_json_rpc_api',
        username => 'your_username_here',
    };

    my $idoitapi = WebService::IdoitAPI->new( $config );

    my $request = {
        method => $idoit_method,
        params => {
            # your params here
        }
    };
    my $reply = $idoitapi->request($request);

=head1 SUBROUTINES/METHODS

=head2 new

    my $config = {
        apikey => 'your_key_here',
        password => 'your_password_here',
        username => 'your_username_here',
        url => 'full_url_to_json_rpc_api',
    };

    my $idoitapi = WebService::IdoitAPI->new( $config );

Create a new C<WebService::IdoitAPI> object
and provide it with the credentials and location to access the JSON-RPC-API.

Depending on the configuration of your i-doit instance,
you may need a username and password and an API key,
or the key may suffice.

This function throws an exception
when either C<< $config->{apikey} >> or C<< $config->{url} >> is missing.

=head2 request

    my $req = {
        method => $idoit_method,
        params => {
            # your params here
        }
    };
    my $res = $idoitapi->request($req);

    if ($res) {
        if ($res->is_error) {
            print "Error : ", $res->error_message;
        }
        else {
            # you can find the reply in $res->result
        }
    }
    else {
        print $idoitapi->{client}->status_line;
    }

Sends the given request as JSON-RPC-API call
to the configured i-doit instance.

C<$request->{method}> can be any method supported by the i-doit JSON-RPC-API.
C<$request->{params}> must match that method.

In case of error, the method returns C<undef>.
Otherwise it returns a JSON::RPC::Legacy::ReturnObject.

The method automatically adds
the JSON parameters C<version>, C<id> and C<params.language>
if they are not provided in C<$request>.
It takes care to add the credentials,
that were given in the configuration hash to method C<new()>.

=head2 login

    my $res = $idoitapi->login($username, $password);

or

    my $res = $idoitapi->login();

Sends an C<idoit.login> API call to create a session.
If the call is successful,
the returned session ID is used henceforth
instead of username and password;

If you don't provide C<$username> and C<$password>,
the method takes the values
given in the configuration hash to the method C<new()>.

=head2 logout

    my $res = $idoitapi->logout();

Sends an C<idoit.logout> API call to close a session.
A previous used session ID is deleted.

If the C<$idoitapi> object is logged in
when it is destroyed - for instance because it goes out of scope -
this method is automatically called
to close the session on the server.

=head2 is_logged_in

    if (not $idoitapi->is_logged_in()) {
        $idoitapi->login($username,$password);
    }

Tests if the WebService::IdoitAPI object has a session ID -
that means it is logged in.

=head2 read_config

    my $config = WebService::IdoitAPI::read_config($path);
    my $api = WebService::IdoitAPI->new( $config );

This is a convenience function,
that tries to extract the necessary keys (C<< apikey password url username >>)
from the file whose name is given by C<< $path >>.

If C<< $path >> is not given or C<< undef >>,
the function tries some known paths of configuration files.
Currently there is only known path:

=over 4

=item C<< $ENV{HOME}/.idoitcli/config.json >>

the configuration file used by the PHP CLI client I<< idoitcli >>.

=back

=head1 AUTHOR

Mathias Weidner, C<< <mamawe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests
to C<bug-webservice-idoitapi at rt.cpan.org>,
or through the web interface
at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-IdoitAPI>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::IdoitAPI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-IdoitAPI>

=item * Search CPAN

L<https://metacpan.org/release/WebService-IdoitAPI>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Mathias Weidner.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

