package WebService::GeoIPify;

use namespace::clean;
use strictures 2;
use utf8;

use Carp qw(croak);
use Data::Validate::IP qw(is_ipv4 is_public_ipv4);
use Moo;
use Sub::Quote qw(quote_sub);
use Types::Common::String qw(StrLength);
use Types::Standard qw(InstanceOf Str);

with 'Role::Cache::LRU';
with 'Role::REST::Client';

our $VERSION = '0.03';

has api_key => (
    isa => StrLength[32],
    is => 'rw',
    required => 1,
);

has api_url => (
    isa => Str,
    is => 'ro',
    default => quote_sub(q{ 'https://geo.ipify.org/api/v1' }),
);

has api_ipify_url => (
    isa => Str,
    is => 'ro',
    default => quote_sub(q{ 'https://api.ipify.org' }),
);

sub lookup {
    my ($self, $ip) = @_;

    croak "$ip is not a public IPv4 address" if (!is_public_ipv4($ip));

    my $cached_ip_record = $self->get_cache($ip);
    return $cached_ip_record if (defined $cached_ip_record);

    $self->set_persistent_header(
        'User-Agent' => __PACKAGE__ . $WebService::GeoIPify::VERSION);
    $self->server($self->api_url);
    $self->type(q|application/json|);

    my $queries = {
        apiKey => $self->api_key,
        ipAddress => $ip,
    };

    my $response = $self->get('', $queries);

    my $ip_record = $response->data;
    $self->set_cache($ip => $ip_record);

    return $ip_record;
}

sub check {
    my ($self) = @_;

    my $ip = $self->get($self->api_ipify_url)->data;

    croak q|Cannot obtain client's public IPv4 address| if (!is_ipv4($ip));

    return $self->lookup($ip);
}

1;
__END__

=encoding utf-8

=for stopwords geoipify geolocation ipify ipv4

=head1 NAME

WebService::GeoIPify - Perl library for ipify's Geolocation API,
https://geo.ipify.org.

=head1 SYNOPSIS

  use WebService::GeoIPify;

  my $geoipify = WebService::GeoIPify->new(api_key => '1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx32');
  print $geoipify->lookup('8.8.8.8');

=head1 DESCRIPTION

WebService::GeoIPify is a Perl library for obtaining Geolocation information on
IPv4 address.

=head1 DEVELOPMENT

Source repository at L<https://github.com/kianmeng/webservice-geoipify|https://github.com/kianmeng/webservice-geoipify>.

How to contribute? Follow through the L<CONTRIBUTING.md|https://github.com/kianmeng/webservice-geoipify/blob/master/CONTRIBUTING.md> document to setup your development environment.

=head1 METHODS

=head2 new($api_key)

Construct a new WebService::GeoIPify instance.

  my $geoipify = WebService::GeoIPify->new(api_key => '1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx32');

=head3 api_key

Compulsory. The API access key used to make request through web service.

=head3 api_url

The default base URL for API calls.

=head3 api_ipify_url

The default base URL for ipify API calls to obtain the client public IP.

=head2 lookup($ip_address)

Query and get an IP address information. Only accept IPv4 public address.

    my $geoipify = WebService::GeoIPify->new(api_key => '1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx32');
    print $geoipify->lookup('8.8.8.8');

=head2 check()

Look up the public IP address of the client which made the web service call.

    my $geoipify = WebService::GeoIPify->new(api_key => '1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx32');
    print $geoipify->check();

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>

=cut
