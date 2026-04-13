#!/usr/bin/false
# ABSTRACT: Base class for Bugzilla API objects
# PODNAME: WebService::Bugzilla::Object

# See https://bmo.readthedocs.io/en/latest/api/core/v1/index.html

package WebService::Bugzilla::Object 0.001;
use strictures 2;
use Moo;
use Carp qw(croak);
use namespace::clean;

has client => (
    is => 'ro',
    required => 1,
    weak_ref => 1,
);

has id => (
    is => 'ro',
    lazy => 1,
    builder => '_build_id',
    predicate => 1,
);

has _api_data => (
    is       => 'ro',
    init_arg => '_data',
    writer   => '_set_api_data',
);

has _is_loaded => (
    is       => 'rw',
    default  => 0,
);

sub _build_id {
    my ($self) = @_;
    croak 'id not available - object not loaded'
        unless $self->_api_data;
    return $self->_api_data->{id};
}

sub _fetch_full {
    my ($self, $uri) = @_;
    return if $self->_is_loaded;
    return if $self->_api_data && %{$self->_api_data};
    $self->_is_loaded(1);
    my $res = $self->client->get($uri);
    $self->_set_api_data($self->_unwrap($res));
}

sub _mkuri {
    my ($self, @paths) = @_;
    return join('/', @paths);
}

sub _simple_get {
    my ($self, $path) = @_;
    return $self->client->get($self->_mkuri($path));
}

sub _unwrap {
    my ($self, $res) = @_;
    return $res unless ref $res eq 'HASH';
    my $key = $self->_unwrap_key;
    if ($key && exists $res->{$key} && ref $res->{$key} eq 'ARRAY') {
        return $res->{$key}[0] // {};
    }
    return $res;
}

sub _unwrap_key { undef }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Object - Base class for Bugzilla API objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

This module is not used directly.  All service objects in this distribution
inherit from it.

    package WebService::Bugzilla::Bug;
    use Moo;
    extends 'WebService::Bugzilla::Object';

=head1 DESCRIPTION

Base class for all Bugzilla API objects.  It provides common attributes
(C<client>, C<id>, raw API data) and helper methods used by every service
class in this distribution.

See L<https://bmo.readthedocs.io/en/latest/api/core/v1/index.html> for the
upstream API documentation.

=head1 ATTRIBUTES

=over 4

=item C<client>

B<Required.>  The L<WebService::Bugzilla> client instance that owns this
object.  Stored as a weak reference.

=item C<id>

The numeric object ID.  Lazy-built from C<_api_data> on first access.

=back

=head1 METHODS

=head2 has_id

    if ($obj->has_id) { ... }

L<Moo> predicate for C<id>.  Returns true when an ID is available.

=head1 SEE ALSO

L<WebService::Bugzilla> - the client that creates these objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/index.html> - Bugzilla REST API documentation

=for Pod::Coverage has_id

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
