use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::CarrierAccounts;
require WebService::Shippo::CarrierAccount;
use base qw(
    WebService::Shippo::Collection
    WebService::Shippo::Create
    WebService::Shippo::Fetch
    WebService::Shippo::Update
);

sub item_class () { 'WebService::Shippo::CarrierAccount' }

sub collection_class () { __PACKAGE__ }

BEGIN {
    no warnings 'once';
    *Shippo::CarrierAccounts:: = *WebService::Shippo::CarrierAccounts::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::CarrierAccounts - Carrier Account collection class

=head1 VERSION

version 0.0.21

=head1 DESCRIPTION

Carrier accounts are used as credentials to retrieve shipping rates
and purchase labels from a shipping provider.

=head1 API DOCUMENTATION

For more information about Carrier Accounts, consult the Shippo API
documentation:

=over 2

=item * L<https://goshippo.com/docs/#carrier-accounts>

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
