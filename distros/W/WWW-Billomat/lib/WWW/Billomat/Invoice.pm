package WWW::Billomat::Invoice;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;

=head1 NAME

WWW::Billomat::Invoice - Billomat Invoice object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WWW::Billomat;

    my $invoice = $billomat->get_invoice('RE123');
    say "Status: ", $invoice->status;

=cut

class_has api_resource => (
	is => 'ro',
	isa => 'Str',
	default => 'invoices',
);

class_has api_item_tag => (
	is => 'ro',
	isa => 'Str',
	default => 'invoice',
);

class_has api_container_tag => (
	is => 'ro',
	isa => 'Str',
	default => 'invoices',
);

=head1 SUBROUTINES/METHODS

None.

=head1 PROPERTIES

A WWW::Billomat::Invoice object has the following properties.
Type is string, except where otherwise specified.

=over 4

=item * id (Int)

=item * client_id (Int)

=item * created

=item * invoice_number

=item * number (Int)

=item * number_pre

=item * status

=item * date

=item * supply_date

=item * supply_date_type

=item * due_date

=item * due_days (Int)

=item * address

=item * discount_rate (Num)

=item * discount_date

=item * discount_days (Int)

=item * discount_amount (Num)

=item * label

=item * intro

=item * note

=item * total_gross (Num)

=item * total_net (Num)

=item * reduction

=item * total_gross_unreduced (Num)

=item * total_net_unreduced (Num)

=item * currency_code

=item * quote (Num)

=item * offer_id

=item * confirmation_id

=item * recurring_id

=item * taxes

=item * payment_type

=back

Please refer to the Billomat API documentation for their meaning.

=cut

has id                          => ( is => 'rw', isa => 'Int' );
has client_id                   => ( is => 'rw', isa => 'Int' );
has created                     => ( is => 'rw', isa => 'Str' );
has invoice_number              => ( is => 'rw', isa => 'Str' );
has number                      => ( is => 'rw', isa => 'Int' );
has number_pre                  => ( is => 'rw', isa => 'Str' );
has status                      => ( is => 'rw', isa => 'Str' );
has date                        => ( is => 'rw', isa => 'Str' );
has supply_date                 => ( is => 'rw', isa => 'Str' );
has supply_date_type            => ( is => 'rw', isa => 'Str' );
has due_date                    => ( is => 'rw', isa => 'Str' );
has due_days                    => ( is => 'rw', isa => 'Int' );
has address                     => ( is => 'rw', isa => 'Str' );
has discount_rate               => ( is => 'rw', isa => 'Num' );
has discount_date               => ( is => 'rw', isa => 'Str' );
has discount_days               => ( is => 'rw', isa => 'Int' );
has discount_amount             => ( is => 'rw', isa => 'Num' );
has label                       => ( is => 'rw', isa => 'Str' );
has intro                       => ( is => 'rw', isa => 'Str' );
has note                        => ( is => 'rw', isa => 'Str' );
has total_gross                 => ( is => 'rw', isa => 'Num' );
has total_net                   => ( is => 'rw', isa => 'Num' );
has reduction                   => ( is => 'rw', isa => 'Str' );
has total_gross_unreduced       => ( is => 'rw', isa => 'Num' );
has total_net_unreduced         => ( is => 'rw', isa => 'Num' );
has currency_code               => ( is => 'rw', isa => 'Str' );
has quote                       => ( is => 'rw', isa => 'Num' );
has offer_id                    => ( is => 'rw', isa => 'Str' );
has confirmation_id             => ( is => 'rw', isa => 'Str' );
has recurring_id                => ( is => 'rw', isa => 'Str' );
has taxes                       => ( is => 'rw', isa => 'Str' ); # ARRAY
has payment_type                => ( is => 'rw', isa => 'Str' );

=head1 SEARCH PARAMETERS

The following fields can be used when searching for invoices:

=over 4

=item * client_id

=item * invoice_number

=item * status

=item * payment_type

=item * from

=item * to

=item * label

=item * intro

=item * note

=item * tags

=back

=cut

class_has search_params => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { [ qw/
		client_id invoice_number status
		payment_type from to label intro		
		note tags		
	/ ] },
);

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

1; # End of WWW::Billomat::Invoice
