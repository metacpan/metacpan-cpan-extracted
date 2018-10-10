package WebService::Mattermost::V4::API::Request;

use Mojo::URL;
use Mojo::Util 'url_escape';
use Moo;
use Types::Standard qw(Any ArrayRef Bool Enum InstanceOf Str);

with 'WebService::Mattermost::Role::Logger';

################################################################################

has base_url => (is => 'ro', isa => Str,                              required => 1);
has endpoint => (is => 'ro', isa => Str,                              required => 1);
has method   => (is => 'ro', isa => Enum [ qw(DELETE GET POST PUT) ], required => 1);
has resource => (is => 'ro', isa => Str,                              required => 1);

# Some endpoints require parameters as a HashRef, some as an ArrayRef
has debug      => (is => 'ro', isa => Bool,     default => 0);
has ids        => (is => 'ro', isa => ArrayRef, default => sub { [] });
has parameters => (is => 'ro', isa => Any,      default => sub { {} });

has url => (is => 'ro', isa => InstanceOf['Mojo::URL'], lazy => 1, builder => 1);

################################################################################

sub _build_url {
    my $self = shift;

    my $base_url = $self->base_url;
    my $resource = $self->resource;
    my $endpoint = $self->endpoint;

    $base_url .= '/' if $base_url !~ /\/$/;
    $resource .= '/' if $self->endpoint ne '' && $resource !~ /\/$/;

    my @ids = map { url_escape($_) } @{$self->ids};

    $endpoint = sprintf($endpoint, @ids);

    my $url = sprintf('%s%s%s', $base_url, $resource, $endpoint);

    $self->logger->debug($url) if $self->debug;

    return Mojo::URL->new($url);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Request

=head1 DESCRIPTION

A request to be sent to the Mattermost API.

=head2 USAGE

See C<WebService::Mattermost::V4::API::Resource::_call()>.

=head2 ATTRIBUTES

=over 4

=item C<base_url>

=item C<endpoint>

=item C<method>

HTTP method.

=item C<resource>

The API endpoint's namespace.

=item C<parameters>

Data to be sent to the API.

=item C<ids>

IDs to replace into the URL with C<sprintf>.

=item C<url>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

