package WebService::Reactio;
use 5.008001;
use strict;
use warnings;

use Carp;
use Furl;
use JSON;

our $VERSION = "0.03";

use parent qw/
    WebService::Reactio::Incident
/;

sub new {
    my ($class, %params) = @_;

    my $api_key      = $params{api_key};
    my $organization = $params{organization};
    my $domain       = $params{domain} || 'reactio.jp';
    Carp::croak '[ERROR] API key is required' unless $api_key;
    Carp::croak '[ERROR] Organization is required' unless $organization;

    bless {
        api_key  => $api_key,
        host     => "$organization.$domain",
        client   => Furl->new(
            agent   => "WebService::Reactio/$WebService::Reactio::VERSION",
            timeout => 10,
        ),
    }, $class;
}

sub _request {
    my ($self, $method, $path, $content) = @_;

    my $response = $self->{client}->request(
        method     => $method,
        scheme     => 'https',
        host       => $self->{host},
        path_query => $path,
        headers    => [
            'X-Api-Key'    => $self->{api_key},
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        content    => $content ? encode_json($content) : undef,
    );
    return decode_json($response->content);
}

1;

__END__

=encoding utf-8

=head1 NAME

WebService::Reactio - API client for Reactio

=head1 SYNOPSIS

    use WebService::Reactio;

    my $client = WebService::Reactio->new(
        api_key      => '__API_KEY__',
        organization => '__ORGANIZATION__',
    );

    my $incidents = $client->incidents;

=head1 DESCRIPTION

WebService::Reactio is API client for Reactio (L<https://reactio.jp/>).

=head1 METHODS

=head2 new(%params)

Create instance of WebService::Reactio.

I<%params> must have following parameter:

=over 4

=item api_key

API key of Reactio.
You can get API key on project setting page.

=item organization

Organization ID of Reactio.
This is the same as the subdomain in your organization of Reactio.
If you can use Reactio in the subdomain called L<https://your-organization.reactio.jp/>, your Organization ID is C<your-organization>.

=back

I<%params> optional parameters are:

=over 4

=item domain

Domain of Reactio.
The default is C<reactio.jp>.

=back

=head2 create_incident($name, [\%options])

Create new incident.

You must have following parameter:

=over 4

=item $name

Incident name.

=back

I<%options> is optional parameters.
Please refer API official guide if you want to get details.

=head2 notify_incident($incident_id, $notification_text, [\%options])

Send notificate to specified incident.

You must have following parameter:

=over 4

=item $incident_id

Incident ID.

=item $notification_text

Notification text.

=back

I<%options> is optional parameters.
Please refer API official guide if you want to get details.

=head2 incident($incident_id)

Get incident details.

You must have following parameter:

=over 4

=item $incident_id

Incident ID.

=back

=head2 incidents([\%options])

Get incident list.

I<%options> is optional parameters.
Please refer API official guide if you want to get details.

=over 4

=back

=head2 send_message($incident_id, $text)

Send message to specified incident's timeline.

You must have following parameter:

=over 4

=item $incident_id

Incident ID.

=item $text

Timeline message.

=back

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Reactio API Official Guide L<https://reactio.jp/development/api>

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

