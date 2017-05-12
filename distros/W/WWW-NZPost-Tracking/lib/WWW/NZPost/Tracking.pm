package WWW::NZPost::Tracking;

use strict;
use warnings;

use Carp;
use JSON;
use LWP::UserAgent;
use Moose;

use WWW::NZPost::Tracking::Detail;
use WWW::NZPost::Tracking::Package;

our $VERSION = '0.01';

=head1 NAME

WWW::NZPost::Tracking - Perl interface to the New Zealand Post tracking service

=head1 SYNOPSIS

  use WWW::NZPost::Tracking;

  my $nzp = WWW::NZPost::Tracking->new(
      license_key     => '12345678',
      user_ip_address => '127.0.0.1',
  );

  my ($package) = $nzp->track( tracking_number => 'XY123456789NZ' );

=head1 DESCRIPTION

This module provides an object-oriented Perl interface to the New Zealand Post tracking service.

=head1 METHODS

=head2 new

Returns a new WWW::NZPost::Tracking object. Takes the following parameters as a hash:

=over 4

=item * B<license_key>

Your New Zealand Post license key.

=item * B<user_ip_address>

The IP address of the end user.

=item * B<mock>

If set, returns dummy data as documented in the NZ Post API documentation.

=back

=cut

has 'mock'            => ( is => 'rw', isa => 'Bool' );
has 'license_key'     => ( is => 'rw', isa => 'Str' );
has 'user_ip_address' => ( is => 'rw', isa => 'Str' );

=head2 track

Tracks a package. Takes the following parameters as a hash, returns an array of WWW::NZPost::Tracking::Package objects.

=over 4

=item * B<tracking_number>

String representing one tracking number, or an array reference of up to 10 tracking numbers.

=item * B<include_signature_data>

Set if you would like the API to return signature data.

=back

=cut

sub track
{
    my ($self, $tracking_number, %params) = @_;

    my @tracking_numbers =
        (ref $tracking_number and ref $tracking_number eq 'ARRAY')
        ? (@$tracking_number)
        : ($tracking_number);

    croak "You may only track 10 shipments at once"
        if (scalar(@tracking_numbers) > 10);

    my $uri = 'http://api.nzpost.co.nz/tracking/track';
    my $ret = $self->api_call(
        $uri,
        tracking_code          => \@tracking_numbers,
        include_signature_data => $params{include_signature_data} || 0,
    );

    for my $tracking_number (keys %$ret)
    {
        return WWW::NZPost::Tracking::Package->new(
            tracking_number    => $tracking_number,
            short_description  => $ret->{$tracking_number}{short_description},
            detail_description => $ret->{$tracking_number}{detail_description},
            source             => $ret->{$tracking_number}{source},
            events             => map { WWW::NZPost::Tracking::Detail->new( $_ ) }
                                      @{ $ret->{$tracking_number}{events} || [] },
        );
    }
}

sub api_call
{
    my ($self, $uri, %params) = @_;

    my $lwp = LWP::UserAgent->new;

    my $ret = $lwp->post( $uri, {
        %params,
        license_key     => $self->{license_key},
        user_ip_address => $self->{user_ip_address},
        format          => 'json',
        mock            => $self->{mock},
    });

    my @packages;
    if ($ret->is_success)
    {
        my $ret = decode_json($ret->content);
        return $ret;
    }
    else
    {
        croak "Can't retrieve data from the NZ Post API: " .
            $ret->status_line;
    }
}

=head1 DEPENDENCIES

L<JSON>, L<LWP::UserAgent>, L<Moose>

=head1 BUGS

=head1 DISCLAIMER

The author of this module is not affiliated in any way with New Zealand Post. It is provided as a courtesy to other users of the services provided by New Zealand Post.

Users must follow all terms and requirements associated with use of the New Zealand Post web services.

Documentation can be found at <http://www.nzpost.co.nz/products-services/iphone-apps-apis/tracking-api/track-method>

=head1 LICENSE

This code is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Authored by Michael Aquilina <aquilina@cpan.org> for the Bizowie ERP <http://bizowie.com> platform.

=cut

1;

