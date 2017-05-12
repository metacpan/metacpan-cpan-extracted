package WWW::NZPost::Tracking::Detail;

use strict;
use warnings;

use Moose;

our $VERSION = '0.01';

=head1 NAME

WWW::NZPost::Tracking::Detail - 

=head1 DESCRIPTION

Object representing a New Zealand Post event. Not used directly, refer to L<WWW::NZPost::Tracking::Package> for details.

=head1 METHODS

=head2 flag

=head2 time

=head2 date

=head2 description

=cut

has flag        => ( is => 'rw', isa => 'Str' );
has time        => ( is => 'rw', isa => 'Str' );
has date        => ( is => 'rw', isa => 'Str' );
has description => ( is => 'rw', isa => 'Str' );

1;

