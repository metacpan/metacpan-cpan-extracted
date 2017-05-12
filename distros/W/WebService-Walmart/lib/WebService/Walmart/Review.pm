package WebService::Walmart::Review;
use strict;
use warnings;

$WebService::Walmart::Store::VERSION = '0.01';
use Moose;
use namespace::autoclean;

# https://developer.walmartlabs.com/docs/read/Reviews_Api
has api_version     => ( is => 'ro', default => 8);

has 'name'          => ( is => 'ro');
has 'overallRating' => ( is => 'ro');
has reviewer        => ( is => 'ro');
has reviewText      => ( is => 'ro');
has submissionTime  => ( is => 'ro');
has title           => ( is => 'ro');
has upVotes         => ( is => 'ro');
has downVotes       => ( is => 'ro');

__PACKAGE__->meta->make_immutable();
1;

=pod


=head1 SYNOPSIS

This module represents the metadata associated with item reviews.

You probably shouldn't be calling this directly

=cut