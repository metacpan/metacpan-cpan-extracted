package WebService::Qdrant;
use 5.020;
use strict;
use warnings;

our $VERSION = '0.0001'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY

use Moo;
use Carp qw(croak);
use URI::Escape qw(uri_escape_utf8);
use WebService::Qdrant::UA;
use JSON::MaybeXS;

has json => (
        is => 'ro',
        default => sub {
                JSON::MaybeXS->new( utf8 => 1 );
        }
);

has base_url => (
        is => 'ro',
        default => sub { 'http://localhost:6333' },
);

has api_key => (
        is => 'ro',
);

has timeout => (
        is => 'ro',
        default => sub { 30 },
);

has ua => (
        is => 'ro',
        lazy => 1,
        default => sub {
                return WebService::Qdrant::UA->new(
                        base_url => $_[0]->base_url,
                        api_key => $_[0]->api_key,
                        timeout => $_[0]->timeout
                );
        }
);



# Collection names are a single URL path segment, never a URL fragment.
sub _collection_path {
   my ($self, $name) = @_;
   croak 'collection_name must be a nonempty string'
      unless defined $name && !ref($name) && length($name);
   return '/collections/' . uri_escape_utf8($name);
}

sub collection_exists {
   my ($self, %args) = @_;
   my $url = $self->_collection_path(delete $args{collection_name});
   croak 'Unknown arguments: ' . join(', ', sort keys %args) if %args;
   return $self->ua->get(
      url => $url . '/exists',
   );
}

sub create_collection {
   my ($self, %args) = @_;
   my $url = $self->_collection_path(delete $args{collection_name});
   my %query;
   for my $key (qw(timeout)) {
      $query{$key} = delete $args{$key} if exists $args{$key};
   }
   return $self->ua->put(
      url => $url,
      query => \%query,
      data => \%args,
   );
}

sub delete_collection {
   my ($self, %args) = @_;
   my $url = $self->_collection_path(delete $args{collection_name});
   my %query;
   for my $key (qw(timeout)) {
      $query{$key} = delete $args{$key} if exists $args{$key};
   }
   croak 'Unknown arguments: ' . join(', ', sort keys %args) if %args;
   return $self->ua->delete(
      url => $url,
      query => \%query,
   );
}

sub delete_points {
   my ($self, %args) = @_;
   my $url = $self->_collection_path(delete $args{collection_name});
   my %query;
   for my $key (qw(wait ordering timeout)) {
      $query{$key} = delete $args{$key} if exists $args{$key};
   }
   return $self->ua->post(
      url => $url . '/points/delete',
      query => \%query,
      data => \%args,
   );
}

sub get_collection {
   my ($self, %args) = @_;
   my $url = $self->_collection_path(delete $args{collection_name});
   croak 'Unknown arguments: ' . join(', ', sort keys %args) if %args;
   return $self->ua->get(
      url => $url,
   );
}

sub query_points {
   my ($self, %args) = @_;
   my $url = $self->_collection_path(delete $args{collection_name});
   my %query;
   for my $key (qw(consistency timeout)) {
      $query{$key} = delete $args{$key} if exists $args{$key};
   }
   return $self->ua->post(
      url => $url . '/points/query',
      query => \%query,
      data => \%args,
   );
}

sub upsert {
   my ($self, %args) = @_;
   my $url = $self->_collection_path(delete $args{collection_name});
   my %query;
   for my $key (qw(wait ordering timeout)) {
      $query{$key} = delete $args{$key} if exists $args{$key};
   }
   return $self->ua->put(
      url => $url . '/points',
      query => \%query,
      data => \%args,
   );
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::Qdrant - Easy client for Qdrant servers

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    my $qdrant = WebService::Qdrant->new;

    my $remote = WebService::Qdrant->new(
        base_url => 'https://qdrant.example.com:6333',
        api_key  => $api_key,
        timeout  => 60,
    );

=head1 DESCRIPTION

A small synchronous client for Qdrant's collection and point APIs. All API
methods return L<WebService::Qdrant::Response>, including HTTP errors.
Transport failures and invalid local arguments throw exceptions.

Each wrapper requires C<collection_name>. Collection names are escaped as
one URL path segment. Body fields use Qdrant's API names and ordinary Perl
hashes and arrays; use JSON::MaybeXS booleans for JSON boolean values.
Body schemas are validated by Qdrant rather than duplicated in this client.

=head1 SUBROUTINES/METHODS

=head2 collection_exists

    my $response = $qdrant->collection_exists(collection_name => 'notes');
    my $exists = $response->result->{exists} if $response->is_success;

Checks existence. Returns a response object, not a bare boolean.

=head2 create_collection

    my $response = $qdrant->create_collection(
        collection_name => 'notes',
        vectors => { size => 3, distance => 'Cosine' },
        timeout => 10,
    );

Creates a collection. Optional C<timeout> goes in the URL. Remaining fields,
including named vectors, sparse vectors, and collection configuration,
are passed through as the JSON body.

=head2 delete_collection

    my $response = $qdrant->delete_collection(collection_name => 'notes');

Deletes the collection and its data. Accepts optional C<timeout>.

=head2 delete_points

    my $response = $qdrant->delete_points(
        collection_name => 'notes', points => [0, 42],
        wait => JSON::MaybeXS::true(),
    );

Deletes points selected by C<points> (IDs) or C<filter>. Optional C<wait>,
C<ordering>, and C<timeout> go in the URL. Remaining fields form the body.

=head2 get_collection

    my $response = $qdrant->get_collection(collection_name => 'notes');

Retrieves collection configuration and statistics under C<result>.

=head2 new

Constructs a client without making a network request. Accepts the attributes
below as named arguments.

=head2 query_points

    my $response = $qdrant->query_points(
        collection_name => 'notes', query => [0.1, 0.2, 0.3],
        limit => 5, with_payload => JSON::MaybeXS::true(),
    );

Queries points; matches are under C<< $response->result->{points} >>.
Optional C<consistency> and C<timeout> go in the URL. Remaining fields,
including C<query>, C<filter>, C<prefetch>, and result options, form the body.
C<query> may be omitted for Qdrant's default query behavior.

=head2 upsert

    my $response = $qdrant->upsert(
        collection_name => 'notes',
        points => [{ id => 0, vector => [0.1, 0.2, 0.3],
                     payload => { source => 'notes.md' } }],
        wait => JSON::MaybeXS::true(),
    );

Inserts or replaces points. Accepts C<points> or the Qdrant C<batch> format.
Optional C<wait>, C<ordering>, and C<timeout> go in the URL. Other fields
form the JSON body. An acknowledged operation may still be pending unless
C<wait> was requested; inspect the returned operation status.

=head1 ATTRIBUTES

=head2 base_url

Qdrant service URL. Defaults to C<http://localhost:6333>.

=head2 api_key

Optional authentication key, sent in the C<api-key> HTTP header.

=head2 timeout

HTTP timeout in seconds. Defaults to C<30>. This configures LWP::UserAgent
and is separate from Qdrant's per-operation timeout parameter.

=head2 ua

Optional transport object, normally a L<WebService::Qdrant::UA> instance.
Useful for tests or custom HTTP configuration. An injected transport is used
as supplied; configure its authentication and timeout on that object.

=head1 DIAGNOSTICS

Missing, empty, or reference-valued collection names throw before HTTP.
Collection inspection and deletion methods reject unknown arguments.
See L<WebService::Qdrant::UA> for transport errors and
L<WebService::Qdrant::Response> for HTTP errors and JSON diagnostics.

=head1 SEE ALSO

L<https://api.qdrant.tech/v-1-18-x/api-reference>,
L<WebService::Qdrant::UA>, L<WebService::Qdrant::Response>

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Easy client for Qdrant servers

