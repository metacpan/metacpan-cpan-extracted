package URL::Social::StumbleUpon;
use Moose;
use namespace::autoclean;

extends 'URL::Social::BASE';

=head1 NAME

URL::Social::StumbleUpon - Interface to the StumbleUpon API.

=head1 DESCRIPTION

Do not use this module directly. Access it from L<URL::Social> instead;

    use URL::Social;

    my $social = URL::Social->new(
        url => '...',
    );

    print $social->stumbleupon->view_count . "\n";

=head1 METHODS

=cut

has 'data'       => ( isa => 'Maybe[HashRef]', is => 'ro', lazy_build => 1 );
has 'view_count' => ( isa => 'Maybe[Int]',     is => 'ro', lazy_build => 1 );

sub _build_data {
    my $self = shift;

    my $url = 'http://www.stumbleupon.com/services/1.01/badge.getinfo?url=' . $self->url;

    if ( my $json = $self->get_url_json($url) ) {
        if ( my $data = $json->{result} ) {
            return $data;
        }
        else {
            return undef;
        }
    }
    else {
        return undef;
    }
}

=head2 view_count

Returns the number of times the URL in question has been view among StumbleUpon
users.

Returns undef if it fails to retrieve the data from StumbleUpon.

=cut

sub _build_view_count {
    my $self = shift;

    return $self->data->{views};
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.