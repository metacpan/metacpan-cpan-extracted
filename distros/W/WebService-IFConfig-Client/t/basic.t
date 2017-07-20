use strict;
use warnings;
use 5.10.0;
use feature qw/switch/;

use Test::More;

# A lot of this copied from Rest::Client-273 t/basic.t

# Check testing prereqs
my $run_tests = 1;
eval {
    die "HTTP::Server::Simple misbehaves on Windows" if $^O =~ /MSWin/;
    require HTTP::Server::Simple;
};
if ($@) {
    diag("Won't run tests because: $@");
    $run_tests = 0;
}

my $port        = 7657;
my $test_server;
my $client;

SKIP: {
    skip('test prereqs not met') unless $run_tests;

    $test_server = WebService::IFConfig::TestServer->new($port);
    my $pid         = $test_server->background();

    eval {
        BEGIN {
            unshift @INC, "../lib";
            use_ok( 'WebService::IFConfig::Client',
                'Can use WebService::IFConfig::Client' );
        }

        my $class = 'WebService::IFConfig::Client';

        my %correct = (
            'ip'         => qq/192.0.2.0/,
            'ip_decimal' => qq/3221225984/,
            'country'    => qq/Freedonia/,
            'city'       => qq/Sunnydale/,
            'hostname'   => qq/this.is.a.test/
        );

        subtest 'Can create client' => sub {
            plan tests => 3;
            $client = WebService::IFConfig::Client->new( 'run' => 0 );
            isa_ok $client, 'WebService::IFConfig::Client', 'Client';

            ok( $client, "Client returned from new()" );

            ok( ref($client) =~ /$class/,
                "Client returned from new() is blessed" );
            undef $client;
        };

        # We never test against the canonical implementation
        #ok( $client->get_server eq 'https://ifconfig.co/json' );

        my $local_server = "http://127.0.0.1:${port}";

        # Valid local server
        my $local_url = "${local_server}/json";
        $client = WebService::IFConfig::Client->new( 'server' => $local_url );

        # Poor coding using sleep. One of my pet hates, in fact.
        # I don't know how to check for local server being ready.

        sleep 5;

        subtest 'Connection to local server works' => sub {
            plan tests => 2;
            is( $client->get_server, $local_url, 'Server correct' );
            ok( $client->get_status, 'Status OK' );
        };

        subtest 'Values from local server are correct' => sub {
            plan tests => 5;
            is( $client->get_ip, $correct{'ip'}, 'IP correct' );
            is( $client->get_ip_decimal, $correct{'ip_decimal'},
                'IP Decimal correct' );
            is( $client->get_country, $correct{'country'},
                'Country correct' );
            is( $client->get_city, $correct{'city'}, 'City correct' );
            is( $client->get_hostname, $correct{'hostname'},
                'Hostname correct' );
        };

        undef $client;
        $client = WebService::IFConfig::Client->new(
            'server' => $local_url,
            'run'    => 0
        );

        # Test invalid local server
        # 400
        $local_url = "${local_server}/error";
        $client->set_server($local_url);
        $client->request;

        ok( not $client->get_status );

        # 404
        my @chars = ( "a" .. "z" );
        $local_url = $local_server . '/' . join "",
            map { @chars[ rand @chars ] } 1 .. 64;
        $client->set_server($local_url);
        $client->request;

        ok( not $client->get_status );
        undef $client;
    };

    warn "Tests died: $@" if $@;
    kill 'TERM', $pid;
}

done_testing();
exit;

# Almost a direct copy of REST::Client::TestServer Rest::Client-273 t/basic.t
package WebService::IFConfig::TestServer;

use parent 'HTTP::Server::Simple::CGI';

sub new {
    my $class = shift;
    my ( $path, $data ) = @_;

    my $self = $class->SUPER::new(@_);

    # whether to include various output in the answer

    $self->reset();
    return $self;
}

sub reset {
    my $self = shift;

    $self->enable('ip');
    $self->enable('ip_decimal');
    $self->enable('country');
    $self->enable('city');
    $self->enable('hostname');
}

sub enable {
    my ( $self, $element ) = @_;
    $self->{$element} = 1;
}

sub disable {
    my ( $self, $element ) = @_;
    $self->{$element} = 0;
}

sub current_json {
    my $self = shift;

    # KISS - no use of JSON module;

    my @inner;
    $self->{'ip'}         and push @inner, qq/"ip":"192.0.2.0"/;
    $self->{'ip_decimal'} and push @inner, qq/"ip_decimal":3221225984/;
    $self->{'country'}    and push @inner, qq/"country":"Freedonia"/;
    $self->{'city'}       and push @inner, qq/"city":"Sunnydale"/;
    $self->{'hostname'}   and push @inner, qq/"hostname":"this.is.a.test"/;

    return sprintf( "{%s}", join ",", @inner );
}

sub handle_request {
    my ( $self, $cgi ) = @_;

    my $return;
    my $path = $cgi->path_info();
    if ( $path =~ /json/ ) {
        my $json = $self->current_json;

        $return = <<"EOF";
HTTP/1.0 200 OK

$json
EOF
    }
    elsif ( $path =~ /error/ ) {
        $return = "HTTP/1.0 400 ERROR\r\n";
    }
    else {
        $return = <<'EOF';
HTTP/1.0 404 NOT FOUND

404 page not found
EOF
    }
    print $return;
}

1;
