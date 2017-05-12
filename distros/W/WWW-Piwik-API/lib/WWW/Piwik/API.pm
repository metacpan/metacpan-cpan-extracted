package WWW::Piwik::API;

use 5.010001;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Str Object Int/;
use JSON::MaybeXS;
use URI;
use LWP::UserAgent;

=head1 NAME

WWW::Piwik::API - Tracking module for Piwik using the Tracking API

=head1 VERSION

Version 0.011

=cut

our $VERSION = '0.011';


=head1 SYNOPSIS

my $tracker = WWW::Piwik::API->new(endpoint => $ENV{PIWIK_URL} || 'http://localhost/piwik.php',
                                   idsite => $ENV{PIWIK_IDSITE} || 1,
                                   token_auth => $ENV{PIWIK_TOKEN_AUTH},
                                  );
# see https://developer.piwik.org/api-reference/tracking-api for params
$tracker->track(%data)

=head1 ACCESSORS

They are read-only and need to be set in the constructor.

=head2 endpoint

The endpoint of piwik. Required.

=head2 idsite

The ID of the site being tracked. You can look this up in the piwik console.

=head2 token_auth

The authentication token (you need an admin account for this, and the
token can be looked up under Personal settings/API.

=head2 ua

The user agent, which defaults to L<LWP::UserAgent> with a timeout of
5 seconds.

=cut

has endpoint => (is => 'ro', isa => Str, required => 1);

has idsite => (is => 'ro', isa => Int, required => 1);

has token_auth => (is => 'ro', isa => Str);

has ua => (is => 'ro',
           isa => Object,
           default => sub {
               my $ua = LWP::UserAgent->new;
               $ua->timeout(5);
               return $ua;
           });

sub track {
    my ($self, %data) = @_;
    my $uri = $self->track_uri(%data);
    my $res = $self->ua->get($uri->as_string);
    return $res;
}

sub track_uri {
    my ($self, %data) = @_;
    my %params = (bots => 1,
                  rec => 1,
                  idsite => $self->idsite,
                  token_auth => $self->token_auth,
                 );
    my $json = JSON::MaybeXS->new(ascii => 1);
    foreach my $k (keys %data) {
        my $v = $data{$k};
        if (defined $v) {
            if (ref($v)) {
                $params{$k} ||= $json->encode($v);
            }
            else {
                $params{$k} ||= $v;
            }
        }
    }
    my $uri = URI->new($self->endpoint);
    $uri->query_form(%params);
    return $uri;
}


=head1 METHODS

=head2 track(%data)

Build an URI and do a call against it, serializing the parameters and
adding the default one set in the constructor.

=head2 track_uri(%data)

The URI against which track will be called.

=head1 AUTHOR

Stefan Hornburg, C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/interchange/WWW-Piwik-API/issues>.

=head1 SEE ALSO

L<https://developer.piwik.org/api-reference/tracking-api>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Stefan Hornburg.

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


=cut

1; # End of WWW::Piwik::API
