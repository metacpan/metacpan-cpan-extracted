# ABSTRACT: Perl wrapper for the SEOmoz API
package WWW::SEOmoz;


use Moose;
use namespace::autoclean;

use LWP::UserAgent;
use DateTime;
use URI::Escape;
use JSON;
use Carp        qw( croak );
use Digest::SHA qw( hmac_sha1_base64 );

use WWW::SEOmoz::URLMetrics;
use WWW::SEOmoz::Links;

our $VERSION = '0.03'; # VERSION

has access_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has secret_key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has api_url => (
    is  => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

has ua => (
    is  => 'ro',
    isa => 'LWP::UserAgent',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

my $API_BASE = 'http://lsapi.seomoz.com/';

sub _build_ua {
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    return $ua;
}

sub _build_api_url {
    my $self = shift;

    return $API_BASE . 'linkscape/';
}

sub _generate_authentication {
    my $self = shift;

    my $epoch = DateTime->now->add( seconds => 60 )->epoch; # A bit in the future
    my $sig = hmac_sha1_base64(
        $self->access_id . "\n" . $epoch, $self->secret_key
    );

    # Pad the base_64 encoding, if required
    while (length($sig) % 4) {
        $sig .= '=';
    }

    $sig = uri_escape( $sig );

    return '?AccessID='.$self->access_id.'&Expires='.$epoch.'&Signature='.$sig;
}

sub _make_api_call {
    my $self = shift;
    my $url  = shift || croak 'API URL required';

    my $res = $self->ua->get( $url );

    if ( $res->is_success ) {
        return from_json $res->content;
    }

    croak $res->content;

}


# XXX should allow people to request the metrics they want
sub url_metrics {
    my $self = shift;
    my $url  = shift || croak 'URL required';

    my $api_url = $self->api_url
        . 'url-metrics/'
        . uri_escape($url)
        . $self->_generate_authentication
        . "&Cols=133712314365"; # MAGIC - see the API docs (http://apiwiki.seomoz.org/url-metrics)

    my $url_metrics = WWW::SEOmoz::URLMetrics->new_from_data(
        $self->_make_api_call( $api_url )
    );

    return $url_metrics;
}


sub links {
    my $self = shift;
    my $url  = shift || croak 'URL required';
    my $limit = shift || 30;

    my $api_url = $self->api_url
        . 'links/'
        . uri_escape($url)
        . $self->_generate_authentication
        . '&SourceCols=4'
        . '&TargetCols=4'
        . '&Scope=page_to_page'
        . '&Sort=page_authority'
        . '&Limit=20';

    return WWW::SEOmoz::Links->new_from_data(
        $self->_make_api_call( $api_url )
    );

}


1;

__END__
=pod

=head1 NAME

WWW::SEOmoz - Perl wrapper for the SEOmoz API

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use WWW::SEOmoz;

    my $seomoz = WWW::SEOmoz->new({ access_id => 'foo', secret_key => 'bar' });
    my $url_metrics = $seomoz->url_metrics( 'www.seomoz.org' );
    my $links = $seomoz->links( 'wwww.seomoz.org', 100 );

=head1 DESCRIPTION

WWW::SEOmoz is a simple Perl wrapper for the SEOmoz API. It currently supports the
URL Metrics and Link methods of the API. Patches welcome if you'd like more of the
API supported.

=head1 METHODS

=head2 new

    my $seomoz = WWW::SEOmoz->new({ access_id => 'foo', secret_key => 'bar });

Returns a new L<WWW::SEOmoz> object. The access id and secret key can be obtained
by signing up for an API account.

=head2 url_metrics

    my $url_metrics = $seomoz->url_metrics( 'www.seomoz.org' );

Returns a L<WWW::SEOmoz::URLMetrics> object, which encapsulates the data returned
from the API for the URL passed in.

Note that the API seems to prefer URLs with the URL protocol ('http://') removed.

=head2 links

    my $links = $seomoz->links( 'www.seomoz.org', 30 );
    warn $links->all_links;

Returns a L<WWW::SEOmoz::Links> object, which encapsulates information about the
links pointing to a domain.

The second paramater is a limit to the number of results returned; if not provided
it will default to thirty.

Note that the API seems to prefer URLs with the URL protocol ('http://') removed.

Also, this method call is likely to change in the future to make it more flexible
and allow it to support this part of the API properly.

=head1 SEE ALSO

L<http://www.seomoz.org/api>
L<http://apiwiki.seomoz.org/>

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

