
=head1 NAME

Weasel::Element::Document -

=head1 VERSION

0.01

=head1 SYNOPSIS



=head1 DESCRIPTION

=cut

package Weasel::Element::Document;

use strict;
use warnings;

use Moose;
extends 'Weasel::Element';

=head1 ATTRIBUTES

=over

=item _id

=cut

has '+_id' => (required => 0,
               default => '/html');

=back

=cut

1;
