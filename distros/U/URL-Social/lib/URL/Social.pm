package URL::Social;
use Moose;
use namespace::autoclean;

use URL::Social::Facebook;
use URL::Social::LinkedIn;
use URL::Social::Reddit;
use URL::Social::StumbleUpon;
use URL::Social::Twitter;

=head1 NAME

URL::Social - Helper module for retrieving social information (likes, shares
etc.) for any given URL.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 DESCRIPTION

This module makes it easy to extract social information like likes, shares
etc. for any given URL from the following services:

    * Facebook
    * LinkedIn
    * Reddit
    * StumbleUpon
    * Twitter

=head1 SYNOPSIS

    use URL::Social;

    my $social = URL::Social->new(
        url => '...',
    );

    my $facebook_shares = $social->facebook->share_count;
    my $twitter_shares  = $social->twitter->share_count;
    # ...

=head1 METHODS

=head2 new( url => $url )

Returns an instance of this class. Requires C<$url> as an argument;

    my $social = URL::Social->new(
        url => '...',
    );

=cut

has 'url' => ( isa => 'Str',  is => 'ro', required => 1, default => '' );

has 'facebook'    => ( isa => 'URL::Social::Facebook',    is => 'ro', lazy_build => 1 );
has 'linkedin'    => ( isa => 'URL::Social::LinkedIn',    is => 'ro', lazy_build => 1 );
has 'reddit'      => ( isa => 'URL::Social::Reddit',      is => 'ro', lazy_build => 1 );
has 'stumbleupon' => ( isa => 'URL::Social::StumbleUpon', is => 'ro', lazy_build => 1 );
has 'twitter'     => ( isa => 'URL::Social::Twitter',     is => 'ro', lazy_build => 1 );

=head2 facebook

Returns an instance of the L<URL::Social::Facebook> class.

=cut

sub _build_facebook {
    my $self = shift;

    return URL::Social::Facebook->new( url => $self->url );
}

=head2 linkedin

Returns an instance of the L<URL::Social::LinkedIn> class.

=cut

sub _build_linkedin {
    my $self = shift;

    return URL::Social::LinkedIn->new( url => $self->url );
}

=head2 reddit

Returns an instance of the L<URL::Social::Reddit> class.

=cut

sub _build_reddit {
    my $self = shift;

    return URL::Social::Reddit->new( url => $self->url );
}

=head2 stumbleupon

Returns an instance of the L<URL::Social::StumbleUpon> class.

=cut

sub _build_stumbleupon {
    my $self = shift;

    return URL::Social::StumbleUpon->new( url => $self->url );
}

=head2 twitter

Returns an instance of the L<URL::Social::Twitter> class.

=cut

sub _build_twitter {
    my $self = shift;

    return URL::Social::Twitter->new( url => $self->url );
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;

=head1 TODO

    * Improve tests, as the current tests do live requests.
    * Add support for more social APIs; Google+, Pinterest, Disqus etc.

=head1 BUGS

Most probably. Please report any bugs at http://rt.cpan.org/.

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