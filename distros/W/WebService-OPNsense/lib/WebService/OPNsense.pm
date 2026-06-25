#!/bin/false
# ABSTRACT: Perl client library for the OPNsense REST API
# PODNAME: WebService::OPNsense
use strictures 2;

package WebService::OPNsense;
$WebService::OPNsense::VERSION = '0.001';
use Carp    qw( croak );
use English qw( -no_match_vars );
use Moo;
use Ref::Util   qw( is_arrayref is_hashref );
use URI::Escape qw( uri_escape_utf8 );

with 'WebService::Client';

use namespace::clean;

my $EMPTY_STR = q();

has '+base_url' => (
    is      => 'ro',
    default => sub { croak 'base_url is required' },
);

has '+json' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require JSON::MaybeXS;
        JSON::MaybeXS->new( pretty => 0, utf8 => 1 );
    },
);

has '+mode' => (
    is      => 'ro',
    default => 'v2',
);

has username => (
    is       => 'ro',
    required => 1,
);

has password => (
    is       => 'ro',
    required => 1,
);

sub BUILD {
    my ($self) = @_;

    my $url = $self->base_url;
    $url =~ s{/+$}{};
    $self->{base_url} = $url;

    my $auth = $self->_uri_authority($url);
    $self->ua->credentials(
        $auth,
        $EMPTY_STR,
        $self->username,
        $self->password,
    );

    $self->ua->default_header(
        'User-Agent' => sprintf(
            'WebService::OPNsense %s (perl %s; %s)',
            $WebService::OPNsense::VERSION,
            $PERL_VERSION,
            $OSNAME,
        ),
    );

    return;
}

# Unwrap WebService::Client::Response objects, throw Exception on non-2xx,
# and return undef for GET 404/410 (resource not found / gone).
around req => sub {
    my ( $orig, $self, $req, %args ) = @_;
    my $res = $self->$orig( $req, %args );

    if ( !$res->ok && $req->method eq 'GET' ) {
        my $code = $res->code;
        return if $code eq '404' || $code eq '410';
    }

    if ( !$res->ok ) {
        require WebService::OPNsense::Exception;
        my $response_data = eval { $res->data }     // {};
        my $error         = $response_data->{error} // $response_data->{message} // $res->status_line;
        WebService::OPNsense::Exception->throw(
            http_status => $res->code,
            message     => $error,
            response    => $res,
        );
    }

    return unless $res->content;

    my $response_data = eval { $res->data };
    return $response_data if defined $response_data;
    return;
};

# URL-encode all query parameter values before they reach
# WebService::Client::get, which interpolates them raw into the URL.
around get => sub {
    my ( $orig, $self, $path, $params, @rest ) = @_;
    if ( $params && is_hashref($params) ) {
        my %encoded;
        for my $k ( keys %{$params} ) {
            my $v = $params->{$k};
            if ( is_arrayref($v) ) {
                $encoded{$k} = [ map { uri_escape_utf8($_) } @{$v} ];
            }
            else {
                $encoded{$k} = uri_escape_utf8($v);
            }
        }
        $params = \%encoded;
    }
    return $self->$orig( $path, $params, @rest );
};

sub _uri_authority {
    my ( $self, $url ) = @_;
    ( my $auth = $url ) =~ s{^[a-z]+://([^/?#]+).*}{$1}i;
    croak "Cannot parse authority from URL: $url"
        if $auth eq $url;
    return $auth;
}

has 'diagnostics' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Diagnostics;
        return WebService::OPNsense::Diagnostics->new( client => $self );
    },
);

has 'firewall' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall;
        return WebService::OPNsense::Firewall->new( client => $self );
    },
);

has 'firewall_alias' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::Alias;
        return WebService::OPNsense::Firewall::Alias->new( client => $self );
    },
);

has 'firewall_category' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::Category;
        return WebService::OPNsense::Firewall::Category->new( client => $self );
    },
);

has 'firewall_filter' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::Filter;
        return WebService::OPNsense::Firewall::Filter->new( client => $self );
    },
);

has 'firewall_d_nat' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::DNat;
        return WebService::OPNsense::Firewall::DNat->new( client => $self );
    },
);

has 'firewall_npt' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::Npt;
        return WebService::OPNsense::Firewall::Npt->new( client => $self );
    },
);

has 'firewall_one_to_one' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::OneToOne;
        return WebService::OPNsense::Firewall::OneToOne->new( client => $self );
    },
);

has 'firewall_source_nat' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::SourceNat;
        return WebService::OPNsense::Firewall::SourceNat->new( client => $self );
    },
);

has 'interfaces' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Interfaces;
        return WebService::OPNsense::Interfaces->new( client => $self );
    },
);

has 'routes' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Routes;
        return WebService::OPNsense::Routes->new( client => $self );
    },
);

has 'system' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::System;
        return WebService::OPNsense::System->new( client => $self );
    },
);

has 'backup' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Backup;
        return WebService::OPNsense::Backup->new( client => $self );
    },
);

has 'captive_portal_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::CaptivePortal::Settings;
        return WebService::OPNsense::CaptivePortal::Settings->new( client => $self );
    },
);

has 'captive_portal_session' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::CaptivePortal::Session;
        return WebService::OPNsense::CaptivePortal::Session->new( client => $self );
    },
);

has 'captive_portal_access' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::CaptivePortal::Access;
        return WebService::OPNsense::CaptivePortal::Access->new( client => $self );
    },
);

has 'captive_portal_voucher' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::CaptivePortal::Voucher;
        return WebService::OPNsense::CaptivePortal::Voucher->new( client => $self );
    },
);

has 'captive_portal_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::CaptivePortal::Service;
        return WebService::OPNsense::CaptivePortal::Service->new( client => $self );
    },
);

has 'cron_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Cron::Settings;
        return WebService::OPNsense::Cron::Settings->new( client => $self );
    },
);

has 'cron_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Cron::Service;
        return WebService::OPNsense::Cron::Service->new( client => $self );
    },
);

has 'dnsmasq_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Dnsmasq::Settings;
        return WebService::OPNsense::Dnsmasq::Settings->new( client => $self );
    },
);

has 'dnsmasq_leases' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Dnsmasq::Leases;
        return WebService::OPNsense::Dnsmasq::Leases->new( client => $self );
    },
);

has 'dnsmasq_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Dnsmasq::Service;
        return WebService::OPNsense::Dnsmasq::Service->new( client => $self );
    },
);

has 'hasync' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::HASync;
        return WebService::OPNsense::HASync->new( client => $self );
    },
);

has 'ids_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IDS::Settings;
        return WebService::OPNsense::IDS::Settings->new( client => $self );
    },
);

has 'ids_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IDS::Service;
        return WebService::OPNsense::IDS::Service->new( client => $self );
    },
);

has 'ipsec_connections' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Connections;
        return WebService::OPNsense::IPsec::Connections->new( client => $self );
    },
);

has 'ipsec_key_pairs' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::KeyPairs;
        return WebService::OPNsense::IPsec::KeyPairs->new( client => $self );
    },
);

has 'ipsec_leases' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Leases;
        return WebService::OPNsense::IPsec::Leases->new( client => $self );
    },
);

has 'ipsec_manual_spd' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::ManualSpd;
        return WebService::OPNsense::IPsec::ManualSpd->new( client => $self );
    },
);

has 'ipsec_pools' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Pools;
        return WebService::OPNsense::IPsec::Pools->new( client => $self );
    },
);

has 'ipsec_pre_shared_keys' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::PreSharedKeys;
        return WebService::OPNsense::IPsec::PreSharedKeys->new( client => $self );
    },
);

has 'ipsec_sad' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Sad;
        return WebService::OPNsense::IPsec::Sad->new( client => $self );
    },
);

has 'ipsec_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Service;
        return WebService::OPNsense::IPsec::Service->new( client => $self );
    },
);

has 'ipsec_sessions' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Sessions;
        return WebService::OPNsense::IPsec::Sessions->new( client => $self );
    },
);

has 'ipsec_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Settings;
        return WebService::OPNsense::IPsec::Settings->new( client => $self );
    },
);

has 'ipsec_spd' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Spd;
        return WebService::OPNsense::IPsec::Spd->new( client => $self );
    },
);

has 'ipsec_tunnel' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Tunnel;
        return WebService::OPNsense::IPsec::Tunnel->new( client => $self );
    },
);

has 'ipsec_vti' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::IPsec::Vti;
        return WebService::OPNsense::IPsec::Vti->new( client => $self );
    },
);

has 'kea_dhcpv4' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Kea::Dhcpv4;
        return WebService::OPNsense::Kea::Dhcpv4->new( client => $self );
    },
);

has 'kea_dhcpv6' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Kea::Dhcpv6;
        return WebService::OPNsense::Kea::Dhcpv6->new( client => $self );
    },
);

has 'kea_leases' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Kea::Leases;
        return WebService::OPNsense::Kea::Leases->new( client => $self );
    },
);

has 'kea_ddns' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Kea::Ddns;
        return WebService::OPNsense::Kea::Ddns->new( client => $self );
    },
);

has 'kea_ctrl_agent' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Kea::CtrlAgent;
        return WebService::OPNsense::Kea::CtrlAgent->new( client => $self );
    },
);

has 'kea_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Kea::Service;
        return WebService::OPNsense::Kea::Service->new( client => $self );
    },
);

has 'openvpn_instances' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::OpenVPN::Instances;
        return WebService::OPNsense::OpenVPN::Instances->new( client => $self );
    },
);

has 'openvpn_client_overwrites' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::OpenVPN::ClientOverwrites;
        return WebService::OPNsense::OpenVPN::ClientOverwrites->new( client => $self );
    },
);

has 'openvpn_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::OpenVPN::Service;
        return WebService::OPNsense::OpenVPN::Service->new( client => $self );
    },
);

has 'openvpn_export' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::OpenVPN::Export;
        return WebService::OPNsense::OpenVPN::Export->new( client => $self );
    },
);

has 'trafficshaper_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::TrafficShaper::Settings;
        return WebService::OPNsense::TrafficShaper::Settings->new( client => $self );
    },
);

has 'trafficshaper_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::TrafficShaper::Service;
        return WebService::OPNsense::TrafficShaper::Service->new( client => $self );
    },
);

has 'unbound_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Unbound::Settings;
        return WebService::OPNsense::Unbound::Settings->new( client => $self );
    },
);

has 'unbound_overview' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Unbound::Overview;
        return WebService::OPNsense::Unbound::Overview->new( client => $self );
    },
);

has 'unbound_diagnostics' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Unbound::Diagnostics;
        return WebService::OPNsense::Unbound::Diagnostics->new( client => $self );
    },
);

has 'unbound_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Unbound::Service;
        return WebService::OPNsense::Unbound::Service->new( client => $self );
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense - Perl client library for the OPNsense REST API

=head1 VERSION

version 0.001

=for :stopwords OPNsense API OPNsense

=head1 SYNOPSIS

    use WebService::OPNsense;


    my $opn = WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'your-api-key',
        password => 'your-api-secret',
    );

    # Search firewall rules
    my $rules = $opn->firewall_filter->search_rule;
    for my $rule (@{$rules->{rows}}) {
        say $rule->{description};
    }

    # Get system information
    my $info = $opn->system->status;
    say $_->{name} for @{$info->{rows}};

=head1 DESCRIPTION

L<WebService::OPNsense> is a L<Moo>-based client for the
L<OPNsense REST API|https://docs.opnsense.org/development/api.html>.
It consumes the L<WebService::Client> role and provides lazy accessors for
each OPNsense API controller.

Authentication is handled via HTTP Basic Auth using an API key/secret pair.

=head1 ALPHA STATUS

This release should be considered an alpha release. Please adjust your
expectations accordingly.

Your feedback is very welcomed. Patches are even more welcome.

=head1 ATTRIBUTES

=head2 C<base_url>

B<Required.>  Base URL of the OPNsense instance (e.g.
C<https://opnsense.example.com>).

=head2 C<username>

B<Required.>  API key for authentication.

=head2 C<password>

B<Required.>  API secret for authentication.

=head2 C<firewall>

Lazy accessor returning a L<WebService::OPNsense::Firewall> instance.

=head2 C<firewall_filter>

Lazy accessor returning a L<WebService::OPNsense::Firewall::Filter> instance.

=head2 C<firewall_alias>

Lazy accessor returning a L<WebService::OPNsense::Firewall::Alias> instance.

=head2 C<firewall_category>

Lazy accessor returning a L<WebService::OPNsense::Firewall::Category> instance.

=head2 C<system>

Lazy accessor returning a L<WebService::OPNsense::System> instance.

=head2 C<diagnostics>

Lazy accessor returning a L<WebService::OPNsense::Diagnostics> instance.

=head2 C<routes>

Lazy accessor returning a L<WebService::OPNsense::Routes> instance.

=head2 C<backup>

Lazy accessor returning a L<WebService::OPNsense::Backup> instance.

=head2 C<captive_portal_settings>

Lazy accessor returning a L<WebService::OPNsense::CaptivePortal::Settings> instance.

=head2 C<captive_portal_session>

Lazy accessor returning a L<WebService::OPNsense::CaptivePortal::Session> instance.

=head2 C<captive_portal_access>

Lazy accessor returning a L<WebService::OPNsense::CaptivePortal::Access> instance.

=head2 C<captive_portal_voucher>

Lazy accessor returning a L<WebService::OPNsense::CaptivePortal::Voucher> instance.

=head2 C<captive_portal_service>

Lazy accessor returning a L<WebService::OPNsense::CaptivePortal::Service> instance.

=head2 C<cron_settings>

Lazy accessor returning a L<WebService::OPNsense::Cron::Settings> instance.

=head2 C<cron_service>

Lazy accessor returning a L<WebService::OPNsense::Cron::Service> instance.

=head2 C<dnsmasq_settings>

Lazy accessor returning a L<WebService::OPNsense::Dnsmasq::Settings> instance.

=head2 C<dnsmasq_leases>

Lazy accessor returning a L<WebService::OPNsense::Dnsmasq::Leases> instance.

=head2 C<dnsmasq_service>

Lazy accessor returning a L<WebService::OPNsense::Dnsmasq::Service> instance.

=head2 C<firewall_d_nat>

Lazy accessor returning a L<WebService::OPNsense::Firewall::DNat> instance.

=head2 C<firewall_npt>

Lazy accessor returning a L<WebService::OPNsense::Firewall::Npt> instance.

=head2 C<firewall_one_to_one>

Lazy accessor returning a L<WebService::OPNsense::Firewall::OneToOne> instance.

=head2 C<firewall_source_nat>

Lazy accessor returning a L<WebService::OPNsense::Firewall::SourceNat> instance.

=head2 C<hasync>

Lazy accessor returning a L<WebService::OPNsense::HASync> instance.

=head2 C<ids_settings>

Lazy accessor returning a L<WebService::OPNsense::IDS::Settings> instance.

=head2 C<ids_service>

Lazy accessor returning a L<WebService::OPNsense::IDS::Service> instance.

=head2 C<ipsec_connections>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Connections> instance.

=head2 C<ipsec_key_pairs>

Lazy accessor returning a L<WebService::OPNsense::IPsec::KeyPairs> instance.

=head2 C<ipsec_leases>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Leases> instance.

=head2 C<ipsec_manual_spd>

Lazy accessor returning a L<WebService::OPNsense::IPsec::ManualSpd> instance.

=head2 C<ipsec_pools>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Pools> instance.

=head2 C<ipsec_pre_shared_keys>

Lazy accessor returning a L<WebService::OPNsense::IPsec::PreSharedKeys> instance.

=head2 C<ipsec_sad>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Sad> instance.

=head2 C<ipsec_service>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Service> instance.

=head2 C<ipsec_sessions>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Sessions> instance.

=head2 C<ipsec_settings>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Settings> instance.

=head2 C<ipsec_spd>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Spd> instance.

=head2 C<ipsec_tunnel>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Tunnel> instance.

=head2 C<ipsec_vti>

Lazy accessor returning a L<WebService::OPNsense::IPsec::Vti> instance.

=head2 C<kea_dhcpv4>

Lazy accessor returning a L<WebService::OPNsense::Kea::Dhcpv4> instance.

=head2 C<kea_dhcpv6>

Lazy accessor returning a L<WebService::OPNsense::Kea::Dhcpv6> instance.

=head2 C<kea_leases>

Lazy accessor returning a L<WebService::OPNsense::Kea::Leases> instance.

=head2 C<kea_ddns>

Lazy accessor returning a L<WebService::OPNsense::Kea::Ddns> instance.

=head2 C<kea_ctrl_agent>

Lazy accessor returning a L<WebService::OPNsense::Kea::CtrlAgent> instance.

=head2 C<kea_service>

Lazy accessor returning a L<WebService::OPNsense::Kea::Service> instance.

=head2 C<openvpn_instances>

Lazy accessor returning a L<WebService::OPNsense::OpenVPN::Instances> instance.

=head2 C<openvpn_client_overwrites>

Lazy accessor returning a L<WebService::OPNsense::OpenVPN::ClientOverwrites> instance.

=head2 C<openvpn_service>

Lazy accessor returning a L<WebService::OPNsense::OpenVPN::Service> instance.

=head2 C<openvpn_export>

Lazy accessor returning a L<WebService::OPNsense::OpenVPN::Export> instance.

=head2 C<trafficshaper_settings>

Lazy accessor returning a L<WebService::OPNsense::TrafficShaper::Settings> instance.

=head2 C<trafficshaper_service>

Lazy accessor returning a L<WebService::OPNsense::TrafficShaper::Service> instance.

=head2 C<unbound_settings>

Lazy accessor returning a L<WebService::OPNsense::Unbound::Settings> instance.

=head2 C<unbound_overview>

Lazy accessor returning a L<WebService::OPNsense::Unbound::Overview> instance.

=head2 C<unbound_diagnostics>

Lazy accessor returning a L<WebService::OPNsense::Unbound::Diagnostics> instance.

=head2 C<unbound_service>

Lazy accessor returning a L<WebService::OPNsense::Unbound::Service> instance.

=head2 C<interfaces>

Lazy accessor returning a L<WebService::OPNsense::Interfaces> instance.

=head1 METHODS

=head2 BUILD

L<Moo> lifecycle hook.  Validates and normalizes C<base_url>, configures
HTTP Basic Auth credentials, and sets a descriptive C<User-Agent> string.

=head2 req

    my $data = $opn->req($http_request, %args);

C<around> modifier wrapping L<WebService::Client/req>.  Unwraps the
response object, returns C<undef> for GET 404/410 responses, and throws a
L<WebService::OPNsense::Exception> on other non-2xx status codes.

=head2 get

    my $data = $opn->get($path, \%params);

C<around> modifier wrapping L<WebService::Client/get>.  URL-encodes all
query-parameter values before dispatch.

=head1 SEE ALSO

L<WebService::Client> - role consumed by this class

L<WebService::OPNsense::Exception> - exception objects thrown on errors

L<https://docs.opnsense.org/development/api.html> - OPNsense API documentation

=head1 API COMPATIBILITY

The OPNsense REST API does not use versioned paths, headers, or content
negotiation.  Endpoints change between OPNsense releases without formal
deprecation notices.  This module follows the API spec as it appears and
may require updates when the firewall is upgraded.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
