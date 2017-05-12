package WWW::Billomat::Client;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;

=head1 NAME

WWW::Billomat::Client - Billomat Client object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WWW::Billomat;

    my $client = $billomat->get_client(123);
    say "Name: ", $client->name;

=cut

class_has api_resource => (
    is => 'ro',
    isa => 'Str',
    default => 'clients',
);

class_has api_item_tag => (
    is => 'ro',
    isa => 'Str',
    default => 'client',
);

class_has api_container_tag => (
    is => 'ro',
    isa => 'Str',
    default => 'clients',
);

=head1 SUBROUTINES/METHODS

None.

=head1 PROPERTIES

A WWW::Billomat::Client object has the following properties.
Type is string, except where otherwise specified.

=over 4

=item * id (Int)

=item * created

=item * client_number

=item * number

=item * number_pre

=item * name

=item * salutation

=item * first_name

=item * last_name

=item * street

=item * zip 

=item * city

=item * state

=item * country_code

=item * phone

=item * fax 

=item * mobile

=item * email

=item * www 

=item * tax_number

=item * vat_number

=item * bank_account_number

=item * bank_account_owner

=item * bank_number

=item * bank_name

=item * bank_swift

=item * bank_iban

=item * tax_rule

=item * discount_rate_type

=item * discount_rate (Num)

=item * discount_days_type

=item * discount_days (Num)

=item * due_days_type

=item * due_days (Int)

=item * reminder_due_days_type

=item * reminder_due_days (Int)

=item * offer_validity_days_type

=item * offer_validity_days (Int)

=item * price_group

=item * note

=item * revenue_gross (Num)

=item * revenue_net (Num)

=back

Please refer to the Billomat API documentation for their meaning.

=cut

has id                          => ( is => 'rw', isa => 'Int' );
has created                     => ( is => 'rw', isa => 'Str' );
has client_number               => ( is => 'rw', isa => 'Str' );
has number                      => ( is => 'rw', isa => 'Str' );
has number_pre                  => ( is => 'rw', isa => 'Str' );
has name                        => ( is => 'rw', isa => 'Str' );
has salutation                  => ( is => 'rw', isa => 'Str' );
has first_name                  => ( is => 'rw', isa => 'Str' );
has last_name                   => ( is => 'rw', isa => 'Str' );
has street                      => ( is => 'rw', isa => 'Str' );
has zip                         => ( is => 'rw', isa => 'Str' );
has city                        => ( is => 'rw', isa => 'Str' );
has state                       => ( is => 'rw', isa => 'Str' );
has country_code                => ( is => 'rw', isa => 'Str' );
has phone                       => ( is => 'rw', isa => 'Str' );
has fax                         => ( is => 'rw', isa => 'Str' );
has mobile                      => ( is => 'rw', isa => 'Str' );
has email                       => ( is => 'rw', isa => 'Str' );
has www                         => ( is => 'rw', isa => 'Str' );
has tax_number                  => ( is => 'rw', isa => 'Str' );
has vat_number                  => ( is => 'rw', isa => 'Str' );
has bank_account_number         => ( is => 'rw', isa => 'Str' );
has bank_account_owner          => ( is => 'rw', isa => 'Str' );
has bank_number                 => ( is => 'rw', isa => 'Str' );
has bank_name                   => ( is => 'rw', isa => 'Str' );
has bank_swift                  => ( is => 'rw', isa => 'Str' );
has bank_iban                   => ( is => 'rw', isa => 'Str' );
has tax_rule                    => ( is => 'rw', isa => 'Str' );
has discount_rate_type          => ( is => 'rw', isa => 'Str' );
has discount_rate               => ( is => 'rw', isa => 'Num' );
has discount_days_type          => ( is => 'rw', isa => 'Str' );
has discount_days               => ( is => 'rw', isa => 'Num' );
has due_days_type               => ( is => 'rw', isa => 'Str' );
has due_days                    => ( is => 'rw', isa => 'Int' );
has reminder_due_days_type      => ( is => 'rw', isa => 'Str' );
has reminder_due_days           => ( is => 'rw', isa => 'Int' );
has offer_validity_days_type    => ( is => 'rw', isa => 'Str' );
has offer_validity_days         => ( is => 'rw', isa => 'Int' );
has price_group                 => ( is => 'rw', isa => 'Str' );
has note                        => ( is => 'rw', isa => 'Str' );
has revenue_gross               => ( is => 'rw', isa => 'Num' );
has revenue_net                 => ( is => 'rw', isa => 'Num' );

=head1 SEARCH PARAMETERS

The following fields can be used when searching for clients:

=over 4

=item * name

=item * client_number

=item * email

=item * first_name

=item * last_name

=item * country_code

=item * note

=item * invoice_id

=item * tags

=back

=cut

class_has search_params => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [ qw/
        name client_number email 
        first_name last_name country_code 
        note invoice_id tags
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

1; # End of WWW::Billomat::Client
