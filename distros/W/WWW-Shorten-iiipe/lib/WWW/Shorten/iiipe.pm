package WWW::Shorten::iiipe;

use strict;
use warnings;
use base 'Exporter';

use LWP::UserAgent;

our @EXPORT = qw( makeashorterlink );
our $VERSION = '1.00';

my $service = 'http://iii.pe';

sub makeashorterlink($;%) {
    my ( $url, %args ) = @_;
    my $ua = LWP::UserAgent->new;
    my $resp = $ua->post( $service, { url => $url, %args } );
    return unless $resp->is_success;
    return $resp->content;
}

1;

__END__

=pod

=head1 TITLE

WWW::Shorten::iiipe

=head1 DESCRIPTION

This module provides interface for the URL shortening service http://iii.pe

=head1 SYNOPSIS

    use WWW::Shorten::iiipe;
    my $short_url = makeashorterlink( $long_url );

=head1 SUBROUTINES

=head2 makeashorterlink( $url, %args )

Takes a required C<$url> and optional arguments and returns a shortened url.
The single optional argument available is C<ttl>, specifying the shortened
link' time-to-live value in seconds. The default is 86400.

=head1 SEE ALSO

L<WWW::Shorten>

L<http:/iii.pe>

=head1 AUTHOR

Stefan G. - C<minimal at cpan dot org>

=head1 LICENCE

Perl

=cut
