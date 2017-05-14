# ABSTRACT: Simple interface for making FQL requests.
package WWW::Facebook::FQL::Simple;


use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use URI::Encode qw( uri_encode );
use Carp qw/croak/;

my $API_BASE = 'http://api.facebook.com/method/fql.query?format=json&query=';


sub query {
    my $class = shift;
    my $args  = shift;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->get( uri_encode( $API_BASE . $args->{query} ) );

    if ( $response->is_success ) {
        return decode_json $response->content;
    }
    else {
        croak $response->status_line;
    }

}


1;

__END__
=pod

=head1 NAME

WWW::Facebook::FQL::Simple - Simple interface for making FQL requests.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use WWW::Facebook::FQL::Simple;

    WWW::Facebook::FQL::Simple->query({
        query => 'SELECT like_count FROM link_stat WHERE url="http://twitter.com"'
    });

=head1 DESCRIPTION

A no nonesense, dead simple interface for making FQL requests. This module
does not handle sessions or authentication so presumably some requests will not
work.

If your needs are more complex, you probably need L<WWW::Facebook::API> or
L<WWW::Facebook::FQL>.

=head1 METHODS

=head2 query

    WWW::Facebook::FQL::Simple->query({
        query => 'SELECT like_count FROM link_stat WHERE url="http://twitter.com"'
    });

Returns a hash reference of the JSON returned from the API.

=head1 SEE ALSO

L<Facebook>, L<WWW::Facebook::API>, L<WWW::Facebook::FQL>

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

