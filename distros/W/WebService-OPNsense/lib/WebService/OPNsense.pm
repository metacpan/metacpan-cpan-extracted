#!/bin/false
# ABSTRACT: Perl client library for the OPNsense REST API
# PODNAME: WebService::OPNsense
use strictures 2;

package WebService::OPNsense;
$WebService::OPNsense::VERSION = '0.003';
use Carp         qw( croak );
use English      qw( -no_match_vars );
use MIME::Base64 qw( encode_base64 );
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

has '+content_type' => (
    is      => 'ro',
    default => $EMPTY_STR,
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

    my $token = encode_base64(
        join( q{:}, $self->username, $self->password ),
        $EMPTY_STR,
    );
    $self->ua->default_header(
        'Authorization' => 'Basic ' . $token,
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

# Unwrap WebService::Client::Response objects and throw
# WebService::OPNsense::Exception on non-2xx status codes.
around req => sub {
    my ( $orig, $self, $req, %args ) = @_;
    my $res = $self->$orig( $req, %args );

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
        return $self->_build_opn_object('WebService::OPNsense::Diagnostics');
    },
);

has 'firewall' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Firewall');
    },
);

has 'firewall_alias' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Firewall::Alias');
    },
);

has 'firewall_category' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Firewall::Category');
    },
);

has 'firewall_filter' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Firewall::Filter');
    },
);

has 'firewall_d_nat' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Firewall::DNat');
    },
);

has 'firewall_npt' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Firewall::Npt');
    },
);

has 'firewall_one_to_one' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Firewall::OneToOne');
    },
);

has 'firewall_source_nat' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Firewall::SourceNat');
    },
);

has 'interfaces' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Interfaces');
    },
);

has 'routes' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Routes');
    },
);

has 'system' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::System');
    },
);

has 'backup' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Backup');
    },
);

has 'captive_portal_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::CaptivePortal::Settings');
    },
);

has 'captive_portal_session' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::CaptivePortal::Session');
    },
);

has 'captive_portal_access' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::CaptivePortal::Access');
    },
);

has 'captive_portal_voucher' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::CaptivePortal::Voucher');
    },
);

has 'captive_portal_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::CaptivePortal::Service');
    },
);

has 'cron_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Cron::Settings');
    },
);

has 'cron_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Cron::Service');
    },
);

has 'dnsmasq_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Dnsmasq::Settings');
    },
);

has 'dnsmasq_leases' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Dnsmasq::Leases');
    },
);

has 'dnsmasq_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Dnsmasq::Service');
    },
);

has 'hasync' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::HASync');
    },
);

has 'ids_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IDS::Settings');
    },
);

has 'ids_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IDS::Service');
    },
);

has 'ipsec_connections' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Connections');
    },
);

has 'ipsec_key_pairs' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::KeyPairs');
    },
);

has 'ipsec_leases' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Leases');
    },
);

has 'ipsec_manual_spd' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::ManualSpd');
    },
);

has 'ipsec_pools' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Pools');
    },
);

has 'ipsec_pre_shared_keys' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::PreSharedKeys');
    },
);

has 'ipsec_sad' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Sad');
    },
);

has 'ipsec_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Service');
    },
);

has 'ipsec_sessions' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Sessions');
    },
);

has 'ipsec_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Settings');
    },
);

has 'ipsec_spd' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Spd');
    },
);

has 'ipsec_tunnel' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Tunnel');
    },
);

has 'ipsec_vti' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::IPsec::Vti');
    },
);

has 'kea_dhcpv4' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Kea::Dhcpv4');
    },
);

has 'kea_dhcpv6' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Kea::Dhcpv6');
    },
);

has 'kea_leases' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Kea::Leases');
    },
);

has 'kea_ddns' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Kea::Ddns');
    },
);

has 'kea_ctrl_agent' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Kea::CtrlAgent');
    },
);

has 'kea_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Kea::Service');
    },
);

has 'openvpn_instances' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::OpenVPN::Instances');
    },
);

has 'openvpn_client_overwrites' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::OpenVPN::ClientOverwrites');
    },
);

has 'openvpn_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::OpenVPN::Service');
    },
);

has 'openvpn_export' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::OpenVPN::Export');
    },
);

has 'trafficshaper_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::TrafficShaper::Settings');
    },
);

has 'trafficshaper_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::TrafficShaper::Service');
    },
);

has 'unbound_settings' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Unbound::Settings');
    },
);

has 'unbound_overview' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Unbound::Overview');
    },
);

has 'unbound_diagnostics' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Unbound::Diagnostics');
    },
);

has 'unbound_service' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return $self->_build_opn_object('WebService::OPNsense::Unbound::Service');
    },
);

sub _build_opn_object {
    my ( $self, $module ) = @_;
    ( my $file = "$module.pm" ) =~ s{::}{/}g;
    require $file;
    return $module->new( client => $self );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense - Perl client library for the OPNsense REST API

=head1 VERSION

version 0.003

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

=head2 C<content_type>

HTTP Content-Type header value.  Defaults to empty string to avoid sending
C<application/json> on GET requests (which OPNsense rejects with 400
"Invalid JSON syntax").

=head2 C<interfaces>

Lazy accessor returning a L<WebService::OPNsense::Interfaces> instance.

=head1 METHODS

=head2 BUILD

L<Moo> lifecycle hook.  Validates and normalizes C<base_url>, configures
preemptive HTTP Basic Auth credentials (via C<Authorization> header),
and sets a descriptive C<User-Agent> string.

=head2 req

    my $data = $opn->req($http_request, %args);

C<around> modifier wrapping L<WebService::Client/req>.  Unwraps the
response object and throws a L<WebService::OPNsense::Exception> on
non-2xx status codes.

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
