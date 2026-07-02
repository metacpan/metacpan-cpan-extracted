#!/bin/false
# ABSTRACT: IPsec manual SPD (Security Policy Database) controller
# PODNAME: WebService::OPNsense::IPsec::ManualSpd
use strictures 2;

package WebService::OPNsense::IPsec::ManualSpd;
$WebService::OPNsense::IPsec::ManualSpd::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/manual_spd';
}

with 'WebService::OPNsense::Role::Crud';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::ManualSpd - IPsec manual SPD (Security Policy Database) controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $mspd = $opn->ipsec_manual_spd;

    my $results = $mspd->search;
    $mspd->add({ spd => { ... } });

=head1 DESCRIPTION

Manages manual IPsec Security Policy Database entries.

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search

    my $results = $ctrl->search( %params );

Searches for manual SPD entries.

=head2 get

    my $spd = $ctrl->get( $uuid );

Returns a single manual SPD entry by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 set

    my $result = $ctrl->set( $uuid, $spd_data );

Updates manual SPD entry by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add

    my $result = $ctrl->add( $spd_data );

Creates manual SPD entry.

=head2 del

    my $result = $ctrl->del( $uuid );

Deletes a manual SPD entry by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle

    my $result = $ctrl->toggle( $uuid, $enabled );

Enables or disables a manual SPD entry.  Throws if C<$uuid> is not a valid UUID.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Crud>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
