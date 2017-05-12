package URL::Social::Twitter;
use Moose;
use namespace::autoclean;

extends 'URL::Social::BASE';

=head1 NAME

URL::Social::Twitter - Interface to the Twitter API.

=head1 DESCRIPTION

Do not use this module directly. Access it from L<URL::Social> instead;

    use URL::Social;

    my $social = URL::Social->new(
        url => '...',
    );

    print $social->twitter->share_count . "\n";

=head1 METHODS

=cut

has 'share_count' => ( isa => 'Maybe[Int]', is => 'ro', lazy_build => 1 );

=head2 share_count

Returns the number of times the URL in question has been shared/tweeted.

Returns undef if it fails to retrieve the data from Twitter.

=cut

sub _build_share_count {
    my $self = shift;

    my $url = 'http://cdn.api.twitter.com/1/urls/count.json?url=' . $self->url;

    if ( my $share_count = $self->get_url_json($url)->{count} ) {
        return $share_count || 0;
    }
    else {
        return undef;
    }
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