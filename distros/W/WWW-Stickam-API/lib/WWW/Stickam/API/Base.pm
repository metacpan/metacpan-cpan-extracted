package WWW::Stickam::API::Base;

use strict;
use warnings;
use LWP::UserAgent;
use URI;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/error content/);

sub call {
    my $s        = shift;
    my $args     = shift  || {};

    my $uri = '';
    eval {
        $uri = $s->uri( $args );
    };

    if( $@ ) {
        $s->{error} = $@;
        return ;
    }

    my $u = URI->new( $uri );
    $u->query_form( $args ); 

    my $ua = LWP::UserAgent->new();

    my $response = $ua->get( $u->as_string );

    if( $response->is_success ) {
        if( length $response->content && $s->response_check( $response->content ) ) {
            $s->{content} = $response->content;
            return 1;
        }
        else {
            # the site return empty when no found, should have been return reason you know.
            $s->{error} = "I guess data is not found";
            return ;
        }
    }else {
        $s->{error} = $response->status_line;
        return ;
    }

}

sub response_check { 1; }

1;

=head1 NAME

WWW::Stickam::API::Base - API base class

=head1 DESCRIPTION

Base module for API.

=head1 METHOD

=head2 call

=head2 response_check

=head1 AUTHOR

Tomohiro Teranishi<tomohiro.teranishi@gmail.com>

=cut

