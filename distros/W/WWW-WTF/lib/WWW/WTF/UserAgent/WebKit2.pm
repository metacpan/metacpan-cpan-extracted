package WWW::WTF::UserAgent::WebKit2;

use common::sense;

use Moose;

use HTTP::Headers;

use WWW::WTF::HTTPResource;
use WWW::WTF::UserAgent::WebKit2::Browser;
use WWW::WTF::UserAgent::WebKit2::Iterator;

extends 'WWW::WTF::UserAgent';

has 'ua' => (
    is      => 'ro',
    isa     => 'WWW::WTF::UserAgent::WebKit2::Browser',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $wkit = WWW::WTF::UserAgent::WebKit2::Browser->new( callbacks => $self->callbacks );

        $wkit->init;

        return $wkit;
    },
);

has 'callbacks' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

sub get {
    my ($self, $uri) = @_;

    confess "$uri is not an URI object" unless (ref($uri) =~ /^URI::https?$/);

    $self->ua->open($uri->as_string);

    my $resource = $self->ua->view->get_main_resource();

    my $response = $resource->get_response;

    my $http_resource = WWW::WTF::HTTPResource->new(
        headers     => HTTP::Headers->new( Content_Type => $response->get_mime_type ),
        content     => $self->ua->get_html_source,
        successful  => ($response->get_status_code =~ m/^2\d\d$/ ? 1 : 0),
        request_uri => $uri,
    );

    return $http_resource;
}

sub recurse {
    my ($self, $sitemap_uri) = @_;

    confess "$sitemap_uri is not an URI object" unless (ref($sitemap_uri) =~ /^URI::https?$/);

    return WWW::WTF::UserAgent::WebKit2::Iterator->new( sitemap_uri => $sitemap_uri, ua => $self );
}

__PACKAGE__->meta->make_immutable;

1;
