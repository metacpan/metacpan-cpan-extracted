package WebService::Mocean;

use namespace::clean;
use strictures 2;
use utf8;

use Module::Runtime qw(require_module);
use Moo;
use Types::Standard qw(Str InstanceOf);

use WebService::Mocean::Client;

our $VERSION = '0.05';

has api_key => (
    isa => Str,
    is => 'rw',
    required => 1,
);

has api_secret => (
    isa => Str,
    is => 'rw',
    required => 1,
);

has api_url => (
    isa => Str,
    is => 'rw',
    default => sub { 'https://rest.moceanapi.com/rest/1' },
);

has client => (
    is => 'lazy',
    isa => InstanceOf['WebService::Mocean::Client'],
);

sub _build_client {
    my $self = shift;

    my $client = WebService::Mocean::Client->new(
        api_key => $self->api_key,
        api_secret => $self->api_secret,
        api_url => $self->api_url,
    );

    return $client;
}

has sms => (
    is => 'lazy',
    default => sub { _delegate(shift, 'Sms') },
);

has account => (
    is => 'lazy',
    default => sub { _delegate(shift, 'Account') },
);

has report => (
    is => 'lazy',
    default => sub { _delegate(shift, 'Report') },
);

sub _delegate {
    my ($self, $module) = @_;

    my $package = __PACKAGE__ . "::$module";
    require_module $package;

    return $package->new(client => $self->client);
}

1;
__END__

=encoding utf-8

=for stopwords mocean sms moceansms

=head1 NAME

WebService::Mocean - Perl library for integration with MoceanSMS gateway,
https://moceanapi.com.

=head1 SYNOPSIS

  use WebService::Mocean;
  my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');

=head1 DESCRIPTION

WebService::Mocean is Perl library for integrating with MoceanSMS gateway,
https://moceanapi.com.

=head1 DEVELOPMENT

Source repository at L<https://github.com/kianmeng/webservice-mocean|https://github.com/kianmeng/webservice-mocean>.

How to contribute? Follow through the L<CONTRIBUTING.md|https://github.com/kianmeng/webservice-mocean/blob/master/CONTRIBUTING.md> document to setup your development environment.

=head1 METHODS

=head2 new($api_key, $api_secret, [%$args])

Construct a new WebService::Mocean instance. The api_key and api_secret is
compulsory fields. Optionally takes additional hash or hash reference.

    # Instantiate the class.
    my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');

    # Alternative way.
    my $mocean_api = WebService::Mocean->new({api_key => 'foo', api_secret => 'bar'});

=head3 api_url

The URL of the API resource.

    # Instantiate the class by setting the URL of the API endpoints.
    my $mocean_api = WebService::Mocean->new({api_url => 'http://example.com/api/'});

    # Alternative way.
    my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');
    $mocean_api->api_url('http://example.com/api/');

=head2 sms->send($params)

Send Mobile Terminated (MT) message, which means the message is sent from
mobile SMS provider and terminated at the to the mobile phone.

    # Send sample SMS.
    my $response = $mocean_api->sms->send({
        'mocean-to' => '0123456789',
        'mocean-from' => 'ACME Ltd.',
        'mocean-text' => 'Hello'
    });

=head2 sms->send_verification_code($params)

Send a random code for verification to a mobile number.

    my $response = $mocean_api->sms->send_verification_code({
        'mocean-to' => '0123456789',
        'mocean-brand' => 'ACME Ltd.',
    });

=head2 sms->check_verification_code($params)

Check the verification code received from your user.

    my $response = $mocean_api->sms->check_verification_code({
        'mocean-reqid' => '395935',
        'mocean-code' => '234839',
    });

=head2 account->get_balance()

Get your Mocean account balance.

    my $response = $mocean_api->account->get_balance();

=head2 account->get_pricing()

Get your Mocean account pricing and supported destination.

    my $response = $mocean_api->account->get_pricing();

=head2 report->get_message_status($params)

Get the outbound SMS current status.

    my $response = $mocean_api->report->get_message_status({
        'mocean-msgid' => 123456
    });

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
