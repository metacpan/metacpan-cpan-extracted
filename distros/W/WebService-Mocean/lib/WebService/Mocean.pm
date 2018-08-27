package WebService::Mocean;

use utf8;

use Moo;
use Types::Standard qw(Str);

use strictures 2;
use namespace::clean;

with 'Role::REST::Client';

our $VERSION = '0.01';

has api_url => (
    isa => Str,
    is => 'rw',
    default => sub { 'https://rest.moceanapi.com/rest/1' },
);

has api_key => (
    isa => Str,
    is => 'rw',
    required => 1
);

has api_secret => (
    isa => Str,
    is => 'rw',
    required => 1
);

sub BUILD {
    my ($self, $args) = @_;

    $self->set_persistent_header('User-Agent' => __PACKAGE__ . q| |
          . ($WebService::Mocean::VERSION || q||));

    $self->server($self->api_url);
    $self->api_key($args->{api_key});
    $self->api_secret($args->{api_secret});

    return $self;
}

sub send_mt_sms {
    my ($self, $to, $from, $text) = @_;

    my $params = {
        'mocean-api-key' => $self->api_key,
        'mocean-api-secret' => $self->api_secret,
        'mocean-to' => $to,
        'mocean-from' => $from,
        'mocean-text' => $text,
        'mocean-resp-format' => 'json',
        'mocean-charset' => 'UTF-8',
        'mocean-dlr-mask' => 1
    };

    return $self->_request('sms', $params, undef, undef, 'post');
}

sub _request {
    my ($self, $command, $queries, $format, $method) = @_;

    $command ||= q||;
    $queries ||= {};
    $format ||= 'xml';
    $method ||= 'get';

    # In case the api_url was updated.
    $self->server($self->api_url);
    $self->type(qq|application/$format|);

    # Do not append '/' at the end of URL. Otherwise you will get HTTP 406
    # error.
    my $path = "/" . $command;

    my $response;
    if ($self->can($method)) {
        $response = $self->$method($path, $queries);
    }
    else {
        die "No such HTTP method: $method";
    }

    return $response->data;
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Mocean - Perl library for integration with MoceanSMS gateway,
https://moceanapi.com.

=head1 SYNOPSIS

  use WebService::Mocean;
  my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');

=head1 DESCRIPTION

WebService::Mocean is Perl library for integration with MoceanSMS gateway,
https://moceanapi.com.

=head1 DEVELOPMENT

Source repo at L<https://github.com/kianmeng/webservice-mocean|https://github.com/kianmeng/webservice-mocean>.

=head2 Docker

If you have Docker installed, you can build your Docker container for this
project.

    $ docker build -t webservice-mocean .
    $ docker run -it -v $(pwd):/root webservice-restcountries bash
    # cpanm --installdeps --notest .

=head2 Milla

Setting up the required packages.

    $ milla authordeps --missing | cpanm
    $ milla listdeps --missing | cpanm

Check you code coverage.

    $ milla cover

Several ways to run the test.

    $ milla test
    $ milla test --author --release
    $ AUTHOR_TESTING=1 RELEASE_TESTING=1 milla test
    $ AUTHOR_TESTING=1 RELEASE_TESTING=1 milla run prove t/01_instantiation.t
    $ LOGGING=1 milla run prove t/t/02_request.t

Release the module.

    $ milla build
    $ milla release

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

=head2 send_mt_sms($to, $from, $text)

Send Mobile Terminated (MT) message, which means the message is sent from
mobile SMS provider and terminated at the to the mobile phone.

    # Send sample SMS.
    my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');
    $mocean_api->send_mt_sms('0123456789', 'ACME Ltd.', 'Hello');

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>
