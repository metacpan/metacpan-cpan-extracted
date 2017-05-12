package WebService::Walmart::Taxonomy;
use strict;
use warnings;
$WebService::Walmart::Taxonomy::VERSION = '0.01';
use Moose;
use namespace::autoclean;

# from https://developer.walmartlabs.com/docs/read/Taxonomy_API
has api_version         => ( is => 'ro', default => 24);
has id                  => ( is => 'ro');
has 'name'              => ( is => 'ro');
has children            => ( is => 'ro');

__PACKAGE__->meta->make_immutable;
1;

=pod


=head1 SYNOPSIS

This module represents the metadata associated with the taxonomy.

You probably shouldn't be calling this directly

=cut