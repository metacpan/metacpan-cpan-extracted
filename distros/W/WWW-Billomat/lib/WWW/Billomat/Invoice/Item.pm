package WWW::Billomat::Invoice::Item;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;

=head1 NAME

WWW::Billomat::Invoice::Item - Billomat Invoice Item object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WWW::Billomat;

    my @items = $billomat->get_invoice_items('RE123');

=cut

class_has api_resource => (
	is => 'ro',
	isa => 'Str',
	default => 'invoice-items',
);

class_has search_params => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { [ qw/
		invoice_id
	/ ] },
);

class_has api_item_tag => (
	is => 'ro',
	isa => 'Str',
	default => 'invoice-item',
);

class_has api_container_tag => (
	is => 'ro',
	isa => 'Str',
	default => 'invoice-items',
);

=head1 SUBROUTINES/METHODS

None.

=head1 PROPERTIES

A WWW::Billomat::Invoice::Item object has the following properties.
Type is string, except where otherwise specified.

=over 4

=item * id (Int)

=item * article_id (Int)

=item * invoice_id (Int)

=item * position (Int)

=item * unit

=item * quantity (Num)

=item * unit_price (Num)

=item * tax_name

=item * tax_rate (Num)

=item * title

=item * description

=item * total_gross (Num)

=item * total_net (Num)

=item * reduction

=item * total_gross_unreduced (Num)

=item * total_net_unreduced (Num)

=back

Please refer to the Billomat API documentation for their meaning.

=cut

has id                          => ( is => 'rw', isa => 'Int' );
has article_id                  => ( is => 'rw', isa => 'Int' );
has invoice_id                  => ( is => 'rw', isa => 'Int' );
has position                    => ( is => 'rw', isa => 'Int' );
has unit                        => ( is => 'rw', isa => 'Str' );
has quantity                    => ( is => 'rw', isa => 'Num' );
has unit_price                  => ( is => 'rw', isa => 'Num' );
has tax_name                    => ( is => 'rw', isa => 'Str' );
has tax_rate                    => ( is => 'rw', isa => 'Num' );
has title                       => ( is => 'rw', isa => 'Str' );
has description                 => ( is => 'rw', isa => 'Str' );
has total_gross                 => ( is => 'rw', isa => 'Num' );
has total_net                   => ( is => 'rw', isa => 'Num' );
has reduction                   => ( is => 'rw', isa => 'Str' );
has total_gross_unreduced       => ( is => 'rw', isa => 'Num' );
has total_net_unreduced         => ( is => 'rw', isa => 'Num' );

=head1 SEE ALSO

L<WWW::Billomat>.

=head1 AUTHOR

Aldo Calpini, C<< <dada at perl.it> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Aldo Calpini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;

1; # End of WWW::Billomat::Invoice::Item
