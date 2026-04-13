#!/usr/bin/false
# ABSTRACT: Role providing update method for Bugzilla API objects
# PODNAME: WebService::Bugzilla::Role::Updatable

package WebService::Bugzilla::Role::Updatable 0.001;
use strictures 2;
use Moo::Role;
use namespace::clean;

requires '_unwrap_key';

sub update {
    my $self = shift;
    my $key = $self->_unwrap_key;
    (my $resource = $key) =~ s{s$}{};
    my $id = ($self->_api_data && defined $self->_api_data->{id})
        ? $self->_api_data->{id}
        : shift;
    my %params = @_;
    my $res = $self->client->put($self->_mkuri("$resource/$id"), \%params);
    return $self->new(
        client => $self->client,
        _data  => $res->{$key}[0],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Role::Updatable - Role providing update method for Bugzilla API objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # Consumed by API object classes:
    with 'WebService::Bugzilla::Role::Updatable';

=head1 DESCRIPTION

A L<Moo::Role> that provides an C<update> method for Bugzilla API objects.
The consuming class must implement C<_unwrap_key>, which returns the API
response key (e.g. C<'bugs'>, C<'users'>).  The REST resource path is derived
by stripping the trailing C<s> from that key.

=head1 METHODS

=head2 update

    my $updated = $obj->update(%params);
    my $updated = $svc->update($id, %params);

Send a C<PUT> request to update an existing resource.  Can be called as an
instance method on a loaded object (uses the object's id) or as a service
method with an explicit id.

Returns a new instance of the consuming class populated with the updated data.

=head1 REQUIRES

=head2 _unwrap_key

Must return the response hash key for the resource type (e.g. C<'bugs'>).

=head1 SEE ALSO

L<WebService::Bugzilla::Attachment>, L<WebService::Bugzilla::Bug>,
L<WebService::Bugzilla::Group>, L<WebService::Bugzilla::Product>,
L<WebService::Bugzilla::User>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
