package URL::Social::Facebook;
use Moose;
use namespace::autoclean;

extends 'URL::Social::BASE';

=head1 NAME

URL::Social::Facebook - Interface to the Facebook API.

=head1 DESCRIPTION

Do not use this module directly. Access it from L<URL::Social> instead;

    use URL::Social;

    my $social = URL::Social->new(
        url => '...',
    );

    print $social->facebook->share_count . "\n";
    print $social->facebook->like_count  . "\n";

    # ...

=head1 METHODS

=cut

has 'data'          => ( isa => 'Maybe[HashRef]', is => 'ro', lazy_build => 1 );
has 'share_count'   => ( isa => 'Maybe[Int]',     is => 'ro', lazy_build => 1 );
has 'like_count'    => ( isa => 'Maybe[Int]',     is => 'ro', lazy_build => 1 );
has 'comment_count' => ( isa => 'Maybe[Int]',     is => 'ro', lazy_build => 1 );
has 'click_count'   => ( isa => 'Maybe[Int]',     is => 'ro', lazy_build => 1 );
has 'total_count'   => ( isa => 'Maybe[Int]',     is => 'ro', lazy_build => 1 );

sub _build_data {
    my $self = shift;

    my $url = 'https://graph.facebook.com/fql?q=SELECT like_count, total_count, share_count, click_count, comment_count FROM link_stat WHERE url = "' . $self->url . '"';

    if ( my $json = $self->get_url_json($url) ) {
        if ( my $data = $json->{data}->[0] ) {
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

=head2 share_count

Returns the number of times the URL in question has been shared among Facebook
users.

Returns undef if it fails to retrieve the data from Facebook.

=cut

sub _build_share_count {
    my $self = shift;

    return $self->data->{share_count};
}

=head2 like_count

Returns the number of times the URL in question has been liked among Facebook
users.

Returns undef if it fails to retrieve the data from Facebook.

=cut

sub _build_like_count {
    my $self = shift;

    return $self->data->{like_count};
}

=head2 comment_count

Returns the number of times the URL in question has been commented on among
Facebook users.

Returns undef if it fails to retrieve the data from Facebook.

=cut

sub _build_comment_count {
    my $self = shift;

    return $self->data->{comment_count};
}

=head2 click_count

Returns the number of times the URL in question has been click on among Facebook
users.

Returns undef if it fails to retrieve the data from Facebook.

=cut

sub _build_click_count {
    my $self = shift;

    return $self->data->{click_count};
}

=head2 total_count

Returns the total number of shares, likes, comments and clicks for the URL in
question.

Returns undef if it fails to retrieve the data from Facebook.

=cut

sub _build_total_count {
    my $self = shift;

    return $self->data->{total_count};
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