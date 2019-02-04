package WebService::IPAPI;

our $VERSION = '0.01';

use namespace::clean;
use strictures 2;
use utf8;

use Carp qw(confess);
use Moo;
use MooX::Enumeration;
use Types::Standard qw(Str Enum);

with 'Role::REST::Client';

has api_key => (
    isa => sub {
        confess "API key must be length of 32 characters!" if (length $_[0] != 32);
    },
    is => 'rw',
    required => 1
);

has api_plan => (
    is => 'rw',
    isa => Enum[qw(free standard business business_pro)],
    handles => [qw/ is_free is_standard is_business is_business_pro /],
    default => sub { 'free' },
);

has api_url => (
    isa => Str,
    is => 'ro',
    default => sub {
        my $protocol = (shift->is_free) ? 'http' : 'https';
        return qq|$protocol://api.ipapi.com/api/|
    },
);

sub lookup {
    my ($self, $ip, $params) = @_;

    return $self->_request($ip, $params);
}

sub bulk_lookup {
    my ($self, $ips, $params) = @_;

    confess "Expect an array of IP address" if (ref $ips ne 'ARRAY');

    if (!$self->is_business || !$self->is_business_pro) {
        confess "Bulk IP lookup only for Business or Business Pro subscription plan"
    }

    my $endpoint = join(",", $ips);
    return $self->_request($endpoint, $params);
}

sub check {
    my ($self, $params) = @_;

    return $self->_request('check', $params);
}

sub _request {
    my ($self, $endpoint, $params) = @_;

    if (exists($params->{security}) && !$self->is_business_pro) {
        confess "Security data only for Business Pro subscription plan"
    }

    my $format = exists($params->{output}) ? $params->{output} : 'json';

    $self->set_persistent_header('User-Agent' => __PACKAGE__ . $WebService::IPAPI::VERSION);
    $self->server($self->api_url);
    $self->type(qq|application/$format|);

    my $queries = {
        access_key => $self->api_key
    };
    $queries = {%$queries, %$params} if (defined $params);

    my $response = $self->get($endpoint, $queries);

    return $response->data;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::IPAPI - Perl library for using IPAPI, https://ipapi.com.

=head1 SYNOPSIS

  use WebService::IPAPI;

  my $ipapi = WebService::IPAPI->new(api_key => 'foobar');
  $ipapi->query('8.8.8.8');

  # Only for Pro plan.
  $ipapi->query(['8.8.8.8', '8.8.4.4']);

=head1 DESCRIPTION

WebService::IPAPI is Perl library for obtaining information on IPv4 or IPv6
address.

=head1 DEVELOPMENT

Source repo at L<https://github.com/kianmeng/webservice-ipapi|https://github.com/kianmeng/webservice-ipapi>.

How to contribute? Follow through the L<CONTRIBUTING.md|https://github.com/kianmeng/webservice-ipapi/blob/master/CONTRIBUTING.md> document to setup your development environment.

=head1 METHODS

=head2 new($api_key, $api_plan)

Construct a new WebService::IPAPI instance.

=head3 api_key

Compulsory. The API access key used to make request through web service.

=head3 api_plan

Optional. The API subscription plan used when accessing the API. There are four
subscription plans: free, standard, business, and business_pro. By default, the
subscription plan is 'free'. The main difference between free and non-free
subscription plans are HTTPS encryption protocol support and additional
information.

    # The API request URL is http://api.ipapi.com/api/
    my $ipapi = WebService::IPAPI->new(api_key => 'foo');
    print $ipapi->api_url;

    # The API request URL is https://api.ipapi.com/api/
    my $ipapi = WebService::IPAPI->new(api_key => 'foo', api_plan => 'paid');
    print $ipapi->api_url;

=head3 api_url

The default API hostname and path. The protocol depends on the subscription plan.

=head2 lookup($ip_address, [%params])

Query and get an IP address information. Optionally you can add more settings
to adjust the output.

    my $ipapi = WebService::IPAPI->new(api_key => 'foobar');
    $ipapi->query('8.8.8.8');

    # With optional parameters.
    $ipapi->query('8.8.8.8', {hostname => 1, security => 1, output => 'xml'});

=head2 bulk_lookup($ip_address, [%params])

Only for Paid subscription plan. Query and get multiple IP addresses
information. Optionally you can add more settings to adjust the output.

    my $ipapi = WebService::IPAPI->new(api_key => 'foobar', api_plan => 'paid');
    $ipapi->query(['8.8.8.8', '8.8.4.4']);

    # With optional parameters.
    $ipapi->query(['8.8.8.8', '8.8.4.4'], {language => 'zh'});

=head2 check([%params])

Look up the IP address details of the client which made the web service call.
Optionally you can add more settings to adjust the output.

    my $ipapi = WebService::IPAPI->new(api_key => 'foobar');
    $ipapi->check();

    # With optional parameters.
    $ipapi->check({hostname => 1, security => 1, output => xml});

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>

=cut
