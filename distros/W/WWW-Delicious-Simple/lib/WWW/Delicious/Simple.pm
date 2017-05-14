# ABSTRACT: Simple interface to the Delicious API
package WWW::Delicious::Simple;


use strict;
use warnings;

use JSON;

my $API_BASE = 'http://feeds.delicious.com/v2/json/urlinfo/data?url=';


sub get_url_info {
    my ( $class, $args ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->get( $API_BASE . $args->{url} );

    if ( $response->is_success ) {
        return decode_json $response->content;
    }
    else {
        die $response->status_line;
    }
}


1;

__END__
=pod

=head1 NAME

WWW::Delicious::Simple - Simple interface to the Delicious API

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use WWW::Delicious::Simple;

    WWW::Delicious::Simple->get_url_info({ url => 'http://www.twitter.com' });

=head1 DESCRIPTION

A very simple interface, into a very small portion, of the Delicious (V2) API.
Patches welcome to support more of the API.

Returns decoded json returned from the API.

Possibly very unstable; may have future backwards incompatible releases, if
anyone sends any patches.

=head1 METHODS

=head2 get_url_info

    my $data = WWW::Delicious::Simple->get_url_info({ url => $url });

Returns the data Delicious has stored for the URL specified.

=head1 SEE ALSO

L<Net::Delicious>, L<http://www.delicious.com/help/json>

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

