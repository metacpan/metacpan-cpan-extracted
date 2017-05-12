package WebService::Toggl::Role::API;

use Moo::Role;

requires 'api_path';

has base_url => (is => 'ro', default => '/api/v8');

has my_url   => (is => 'ro', lazy => 1, builder => 1);
sub _build_my_url { $_[0]->base_url . '/' . $_[0]->api_path }



1;
__END__

=encoding utf-8

=head1 NAME

WebService::Toggl::API - Base Role for WebService::Toggl::API Items and Sets

=head1 DESCRIPTION

This role provide behavoir common to all C<WebService::Toggl::API::>
objects.

=head1 REQUIRES

=head2 api_path

Consuming classes must provide their endpoint on the API.
Ex. The L<WebService::Toggl::API::Project> object's C<api_path> is
C<projects>.

=head1 ATTRIBUTES

=head2 base_url

The base of the URL for the Toggl API.  Defaults to C</api/v8>.

=head2 my_url

URL for the current API object.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut
