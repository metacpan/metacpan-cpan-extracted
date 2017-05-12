package WebService::Walmart::Store;
use strict;
use warnings;
$WebService::Walmart::Store::VERSION = '0.01';
use Moose;
use namespace::autoclean;

has 'no'            => ( is => 'ro');
has 'name'          => ( is => 'ro');
has country       => ( is => 'ro');
has coordinates   => ( is => 'ro');
has streetAddress => ( is => 'ro');
has city          => ( is => 'ro');
has stateProvCode => ( is => 'ro');
has zip           => ( is => 'ro');
has phoneNumber   => ( is => 'ro');
has sundayOpen    => ( is => 'ro');
has timezone      => ( is => 'ro');


__PACKAGE__->meta->make_immutable();
1;

=pod


=head1 SYNOPSIS

This module represents the metadata associated with a store.

You probably shouldn't be calling this directly

=cut