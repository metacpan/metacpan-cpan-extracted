package VPNDetectionTest::Origin;

use strict;
use warnings;

use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojolicious;

# A real HTTP origin on an ephemeral port, sharing the singleton event loop with
# the client under test.
#
# A stub user agent would be cheaper and would prove less: it cannot show that a
# redirect was NOT followed, that a bogon issued no request, or how many
# transfers were genuinely in flight at once.
sub new {
    my ($class, $handler) = @_;

    my $self = bless {
        handler => $handler,
        requests => [],
        in_flight => 0,
        peak_in_flight => 0,
    }, $class;

    my $app = Mojolicious->new;
    $app->log->level('fatal');
    $app->routes->any('/*rest' => sub {
        my $c = shift;
        push @{ $self->{requests} }, {
            path => $c->req->url->path->to_string,
            query => $c->req->url->query->to_hash,
            headers => $c->req->headers->to_hash,
        };
        $self->{in_flight}++;
        $self->{peak_in_flight} = $self->{in_flight} if $self->{in_flight} > $self->{peak_in_flight};
        $c->on(finish => sub { $self->{in_flight}-- });
        $self->{handler}->($c, $self);
    });

    $self->{daemon} = Mojo::Server::Daemon->new(
        app => $app, listen => ['http://127.0.0.1'], silent => 1,
    )->start;
    $self->{port} = $self->{daemon}->ports->[0];
    return $self;
}

sub url {
    return "http://127.0.0.1:$_[0]{port}";
}

sub requests {
    return @{ $_[0]{requests} };
}

sub count {
    return scalar @{ $_[0]{requests} };
}

sub peak_in_flight {
    return $_[0]{peak_in_flight};
}

sub paths {
    return map { $_->{path} } @{ $_[0]{requests} };
}

sub reset {
    my ($self) = @_;
    @{ $self->{requests} } = ();
    $self->{peak_in_flight} = 0;
    return $self;
}

# Renders after a delay, so requests genuinely overlap and the peak in flight
# measures something. An immediate render would let a serial client look
# concurrent.
sub slow_json {
    my ($c, $body, $delay) = @_;
    $c->render_later;
    Mojo::IOLoop->timer($delay || 0.05 => sub { $c->render(json => $body) });
}

# The answer a batch gets from an origin that has nothing to say about any
# address: every address in the body, answered with `is_vpn`. A POST /batch
# carries its addresses in the body rather than the path, so this is where they
# are read.
sub batch_body {
    my ($c, $is_vpn) = @_;
    my $json = $c->req->json;
    my $ips = ref $json eq 'HASH' && ref $json->{ips} eq 'ARRAY' ? $json->{ips} : [];
    return {
        results => { map { $_ => { ip => $_, is_vpn => $is_vpn ? \1 : \0 } } @$ips },
        errors => {},
    };
}

1;
