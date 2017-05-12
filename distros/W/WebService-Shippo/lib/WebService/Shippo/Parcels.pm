use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Parcels;
require WebService::Shippo::Parcel;
use base qw(
    WebService::Shippo::Collection
    WebService::Shippo::Create
    WebService::Shippo::Fetch
);

sub item_class () { 'WebService::Shippo::Parcel' }

sub collection_class () { __PACKAGE__ }

BEGIN {
    no warnings 'once';
    *Shippo::Parcels:: = *WebService::Shippo::Parcels::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::Parcel - Parcels collection class

=head1 VERSION

version 0.0.21

=head1 DESCRIPTION

Parcel objects are used for creating shipments, obtaining rates and printing
labels. Thus they are one of the fundamental building blocks of the Shippo 
API. Parcel objects are created with their basic dimensions and weight.

=head1 API DOCUMENTATION

For more information about Parcels, consult the Shippo API documentation:

=over 2

=item * L<https://goshippo.com/docs/#parcels>

=back

=head1 REPOSITORY

=over 2

=item * L<https://github.com/cpanic/WebService-Shippo>

=item * L<https://github.com/cpanic/WebService-Shippo/wiki>

=back

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Iain Campbell.

You may distribute this software under the terms of either the GNU General
Public License or the Artistic License, as specified in the Perl README
file.


=cut
