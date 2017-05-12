package WebService::Toggl::Request;

use HTTP::Tiny;
use MIME::Base64 qw(encode_base64);
use URI::Escape qw(uri_escape);

use Moo;
with 'Role::REST::Client';
use namespace::clean;

has api_key => (is => 'ro', required => 1,);

# extra space adds HTTPT version
has user_agent_id => (is => 'ro', default => 'WebService-Toggl ');

sub _build_user_agent {
    my ($self) = @_;
    HTTP::Tiny->new(
        agent           => $self->user_agent_id,
        default_headers => {
            'Content-Type'  => 'application/json',
            'Accept'        => 'application/json',
            'Authorization' => 'Basic ' . encode_base64($self->api_key . ':api_token', ''),
        }
    );
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Toggl::Request - Set headers and make requests to the Toggl API

=head1 DESCRIPTION

This module holds the entity that sends requests to the Toggl API.

=head1 ATTRIBUTES

This module composes L<Role::REST::Client>.  See that module for other
attributes / methods.

=head2 api_key

The API token that identifies the authorized user.

=head2 user_agent_id

The ID string for the user agent.  Defaults to 'WebService-Toggl '.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut
