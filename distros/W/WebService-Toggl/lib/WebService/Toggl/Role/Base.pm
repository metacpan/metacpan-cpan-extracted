package WebService::Toggl::Role::Base;

use Module::Runtime qw(use_package_optimistically);
use Storable qw(dclone);
use WebService::Toggl::Request;

use Moo::Role;

has api_key => (is => 'ro');
has server => (is => 'ro', default => 'https://www.toggl.com');

has _request => (is => 'ro', lazy => 1, builder => 1);
sub _build__request { WebService::Toggl::Request->new({
    api_key => $_[0]->api_key, server => $_[0]->server,
}) }

sub api_get    { shift->_request->get(@_)    }
sub api_post   { shift->_request->post(@_)   }
sub api_put    { shift->_request->put(@_)    }
sub api_delete { shift->_request->delete(@_) }

sub new_item {
    my ($self, $class, $args) = @_;
    use_package_optimistically('WebService::Toggl::API' . $class)
        ->new({_request => $self->_request, %$args});
}

sub new_item_from_raw {
    my ($self, $class, $raw) = @_;
    $self->new_item($class, {raw => dclone($raw)});
}

sub new_report {
    my ($self, $class, $args) = @_;
    use_package_optimistically('WebService::Toggl::Report' . $class)
        ->new({_request => $self->_request, %$args});
}

sub new_set { shift->new_item(@_) }

sub new_set_from_raw { shift->new_item_from_raw(@_) }



1;
__END__

=encoding utf-8

=head1 NAME

WebService::Toggl::Role::Base - Common behavior for all WebService::Toggl objects

=head1 DESCRIPTION

This role provide behavior common to all C<WebService::Toggl::API::>
and C<WebService::Toggl::Report::> objects.

=head1 ATTRIBUTES

=head2 api_key

The API token used to identify the authorized user.  If you don't
provide this, you'll need to supply the C<_request> attribute.

=head2 server

The base URL for the Toggl API server.  Defaults to 'https://www.toggl.com'.

=head2 _request

The object that sets the headers and makes the requests.  Defaults to
a L<WebService::Toggl::Request> object that uses L<Role::REST::Client>.

=head1 METHODS

=head2 api_get($url, $data, $args)

=head2 api_post($url, $data, $args)

=head2 api_put($url, $data, $args)

=head2 api_delete($url, $data, $args)

These are proxy methods to the C<get>, C<post>, C<put>, and C<delete>
methods available on the C<_request> object via L<Role::REST::Client>.

=head2 new_item($class, \%args)

Creates a new object of type C<WebService::Toggl::API::$class>. The
new object receives the C<_request> attribute of the calling object,
and so does not need the C<api_key> attribute to be set.  C<\%args>
will be passed through to the constructor of the new object.

=head2 new_item_from_raw($class, \%raw)

Similar to C<new_item()> but sets the new object's C<raw> attribute to
the C<\%raw> argument.  This obviates the need for querying the API to
get the object.

=head2 new_report($class, $args)

Same as C<new_item()>, but creates an object of type
C<WebService::Toggl::Report::$class>.

=head2 new_set($class, $args)

Proxies to C<new_item()>.  If API Items and Sets are split into
different classes, this may change.

=head2 new_set_from_raw($class, $raw)

Proxies to C<new_item_from_raw()>.  If API Items and Sets are split into
different classes, this may change.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut
