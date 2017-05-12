package ZipTie::Client;

use strict;
use warnings;
use vars qw($AUTOLOAD $VERSION);

=head1 NAME

ZipTie::Client - Webservice client for the ZipTie server

=head1 VERSION

Version 1.3

=cut

$VERSION = "1.3";

=head1 SYNOPSIS

use ZipTie::Client;

my $client = ZipTie::Client->new(username => 'admin', password => 'password', host => 'localhost:8080', );

$client->devices()->createDevice('10.1.2.1', 'Default', 'ZipTie::Adapters::Cisco::IOS');

$client->devicetags()->addTag('HQ');
$client->devicetags()->tagDevices('HQ', '10.1.2.1@Default');

=head1 DESCRIPTION

C<ZipTie::Client> is a simple webservice client for a ZipTie server.

=head1 PUBLIC SUB-ROUTINES

=over

=item $client = ZipTie::Client->new( %options )
Creates the client.

  username:  The ZipTie server username
  password:  The ZipTie server password
  host:      The ZipTie server host and port.  (Defaults to 'localhost:8080')
  scheme:    The protocol scheme to use to connect to the server.  (Defaults to 'https')
  on_fault:  The method that will be called when there is an error from the server.  (Default will call C<die()>)

If no username is specified the ZipTie::Client will try to use $ENV{'ZIPTIE_AUTHENTICATION'} to authenticate.  This 
environment variable is set by the ZipTie server when running script tools.  Authors of script tools my simply create
an instance of the ZipTie::Client with no options and the authentication will be handled automatically.

=cut
sub new
{
    my ( $proto, %params ) = @_;
    my $package = ref($proto) || $proto;

    my $self = {
        username => undef,
        password => undef,
        host => 'localhost:8080',
        scheme => 'https',
        on_fault => undef,
    };

    foreach my $key ( keys %params )
    {
        $self->{$key} = $params{$key};
    }

    bless($self, $package);
}

=item C<port>
Gets an instance of a webservice endpoint.  As a shortcut ports can be accessed directly with a method named
the same as the port name.

  # These two lines do the same thing.
  $port = $client->port("devices");
  $port = $client->devices();

=cut
sub port
{
    my $self = shift;
    my $portname = shift or die('No port specified');

    my $portkey = "port_$portname";
    my $port = $self->{$portkey};
    if ($port)
    {
        return $port;
    }

    my $primary_url = '';
    if ($self->{username})
    {
        $primary_url = $self->{scheme}. '://' . $self->{host} . '/server/';
    }
    else
    {
        # Token should be of the form '<scheme>://<user>:<auth-pass>@<host>[:<port>]'
        my $token = $ENV{'ZIPTIE_AUTHENTICATION'};
        if ($token)
        {
            $primary_url = $token;
        }
        else
        {
            confess("Must specify a username and password.");
        }
    }

    my $proxy_url = $primary_url . $portname;

    my $ns_url = 'http://www.ziptie.org/server/' . $portname;

    $port = ZipTie::Client::Port->new($self, $proxy_url, $ns_url, $self->{on_fault});

    $self->{$portkey} = $port;

    return $port;
}

=item logout
Logout the client session from the server.  This should always be called for good-housekeeping when you 
are finished with the client so the server can free resources more quickly.

  $client->logout();

=cut
sub logout
{
    my $self = shift;

    $self->port("security")->logoutCurrentUser();
}

sub AUTOLOAD
{
    my $self = shift;
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
    return if $method eq 'DESTROY';

    $self->port($method, @_);
}

1;

package ZipTie::Client::Port;

use strict;
use warnings;
use vars qw($AUTOLOAD $VERSION);

use Carp;
use HTTP::Cookies;
use HTTP::Response;
use SOAP::Lite 0.69;
use LWP::UserAgent;

use constant DEBUG => 0;

$VERSION = "1.3";

sub new
{
    my ($pkg, $client, $proxy_url, $ns_url, $on_fault) = @_;

    my $cookie_jar = HTTP::Cookies->new(ignore_discard => 1);

    my $auth = $client->{scheme} . '://' . $client->{host} . '/server';
    if ($client->{username})
    {
        $auth .= '?j_username=' . $client->{username} . '&j_password=' . $client->{password};

        my $ua = LWP::UserAgent->new(cookie_jar => $cookie_jar);
        my $response = $ua->head($auth);
        if (!$response->is_success)
        {
            die $response->status_line;
        }
    }

    my $proxy = SOAP::Lite
        -> proxy($proxy_url, cookie_jar => $cookie_jar)
        -> uri($ns_url);

    $proxy->on_fault($on_fault || \&_on_fault);
    $proxy->ns($ns_url, 'ns1');

    my $self = {
        "proxy" => $proxy,
    };

    bless($self, $pkg);
}

sub _convert_args
{
    my $self = shift;

    my %args = ();
    if (@_ eq 1 and ref($_[0]) eq 'HASH')
    {
        %args = %{$_[0]};
    } 
    elsif (@_ % 2)
    {
        confess("Arguments to must be name=>value pairs");
    }
    else
    {
        %args = @_;
    }

    my @params;

    foreach my $key (keys(%args))
    {
        my $name = $key;
        my $value = $args{$key};

        my $ref = ref($value);
        if ($ref eq 'HASH')
        {
            print("A Hash\n") if (DEBUG);
            my @converted = $self->_convert_args($value);
            push(@params, SOAP::Data->name($name)->value(\@converted));
        }
        elsif ($ref eq 'ARRAY')
        {
            print("An Array\n") if (DEBUG);

            foreach my $entry (@$value)
            {
                $ref = ref($entry);
                if ($ref eq 'HASH')
                {
                    my @converted = $self->_convert_args(%$entry);
                    push(@params, SOAP::Data->name($name)->value(\@converted));
                }
                else
                {
                    push(@params, SOAP::Data->name($name)->value($entry));
                }
            }
        }
        else
        {
            print("Name: $name\nValue: $value\n") if (DEBUG);
            push(@params, SOAP::Data->name($name)->value($value));
        }
    }

    @params;
}

sub _call
{
    my $self = shift or die;
    my $method = shift or die;

    my @args = $self->_convert_args(@_);

    my $proxy = $self->{"proxy"};
    my $result = $proxy->$method(@args);

    wantarray ? $result->paramsall() : $result->result();
}

sub _on_fault
{
    my($soap, $res) = @_;
    die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
}

sub AUTOLOAD
{
    my $self = shift;
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
    return if $method eq 'DESTROY';

    # Generate the requested method.  This AUTOLOAD will only be called the first time the method is called. 
    # All subsequent calls will call the generated method directly.
    eval("sub $method { my \$self = shift; \$self->_call('$method', \@_); }");

    $self->$method(@_);
}

1;

=back

=head1 LICENSE

The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS"
basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations
under the License.

The Original Code is ZipTie.

The Initial Developer of the Original Code is AlterPoint.
Portions created by AlterPoint are Copyright (C) 2007-2008,
AlterPoint, Inc. All Rights Reserved.

=head1 AUTHOR

lbayer (lbayer@ziptie.org)

=head1 BUGS

Please report any bugs or feature requests through the ziptie bugzilla
web interface at L<http://bugs.ziptie.org/>.

=cut
