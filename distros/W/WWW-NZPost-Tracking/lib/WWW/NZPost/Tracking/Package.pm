package WWW::NZPost::Tracking::Package;

use strict;
use warnings;

use Moose;

our $VERSION = '0.01';

=head1 NAME

WWW::NZPost::Tracking::Package - 

=head1 DESCRIPTION

Object representing a New Zealand Post package. Not used directly, refer to L<WWW::NZPost::Tracking::Package> for details.

=head1 METHODS

=head2 tracking_number

=head2 short_description

=head2 detail_description

=head2 events

=head2 source

=cut

has tracking_number    => ( is => 'rw' );
has short_description  => ( is => 'rw' );
has detail_description => ( is => 'rw' );
has source             => ( is => 'rw' );
has events             => ( is => 'rw' );

1;

