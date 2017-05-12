use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::CarrierAccount;
use Carp         ( 'confess' );
use Scalar::Util ( 'blessed' );
use base qw(
    WebService::Shippo::Item
    WebService::Shippo::Create
    WebService::Shippo::Fetch
    WebService::Shippo::Update
);

sub api_resource () { 'carrier_accounts' }

sub collection_class () { 'WebService::Shippo::CarrierAccounts' }

sub item_class () { __PACKAGE__ }

sub activate
{
    my ( $invocant, $object_id ) = @_;
    $object_id = $invocant->{object_id}
        if blessed( $invocant ) && !$object_id;
    confess 'Expected an object id'
        unless $object_id;
    my $upd = __PACKAGE__->update( $object_id, active => 1 );
    return $upd
        unless blessed( $invocant ) && $invocant->id eq $object_id;
    $invocant->refresh_from( $upd );
}

sub deactivate
{
    my ( $invocant, $object_id ) = @_;
    $object_id = $invocant->{object_id}
        if blessed( $invocant ) && !$object_id;
    confess 'Expected an object id'
        unless $object_id;
    my $upd = __PACKAGE__->update( $object_id, active => 0 );
    return $upd
        unless blessed( $invocant ) && $invocant->id eq $object_id;
    $invocant->refresh_from( $upd );
}

sub enable_test_mode
{
    my ( $invocant, $object_id ) = @_;
    $object_id = $invocant->{object_id}
        if blessed( $invocant ) && !$object_id;
    confess 'Expected an object id'
        unless $object_id;
    my $upd = __PACKAGE__->update( $object_id, test => 1 );
    return $upd
        unless blessed( $invocant ) && $invocant->id eq $object_id;
    return $invocant->refresh_from( $upd );
}

sub enable_production_mode
{
    my ( $invocant, $object_id ) = @_;
    $object_id = $invocant->{object_id}
        if blessed( $invocant ) && !$object_id;
    confess 'Expected an object id'
        unless $object_id;
    my $upd = __PACKAGE__->update( $object_id, test => 0 );
    return $upd
        unless blessed( $invocant ) && $invocant->id eq $object_id;
    return $invocant->refresh_from( $upd );
}

BEGIN {
    no warnings 'once';
    *Shippo::CarrierAccount:: = *WebService::Shippo::CarrierAccount::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::CarrierAccount - Carrier Account class

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
