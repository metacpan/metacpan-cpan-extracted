package WWW::WTF::UserAgent::LWP;

use common::sense;

use Moose;

use Cache::FastMmap;
use Digest::SHA qw(sha1_hex);
use LWP::UserAgent;

use WWW::WTF::HTTPResource;
use WWW::WTF::UserAgent::LWP::Iterator;

extends 'WWW::WTF::UserAgent';

has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {

        return LWP::UserAgent->new( timeout => 10 );
    },
);

has 'cache' => (
    is      => 'ro',
    isa     => 'Maybe[Cache::FastMmap]',
    lazy    => 1,
    default => sub {

        return unless $ENV{WTF_CACHE};

        return Cache::FastMmap->new( share_file => $ENV{WTF_CACHE}, unlink_on_exit => 0 );
    },
);

sub get {
    my ($self, $uri) = @_;

    confess "$uri is not an URI object" unless (ref($uri) =~ /^URI::https?$/);

    my $http_resource;

    my $checksum = sha1_hex($uri);

    if ($self->cache) {
        $http_resource = $self->cache->get("get/$checksum");
    }

    unless ($http_resource) {
        my $response = $self->ua->get($uri->as_string);

        $http_resource = WWW::WTF::HTTPResource->new(
            headers     => $response->headers,
            content     => $response->content,
            successful  => ($response->is_success ? 1 : 0),
            request_uri => $uri,
        );

        $self->cache->set("get/$checksum", $http_resource) if $self->cache;
    }

    return $http_resource;
}

sub recurse {
    my ($self, $sitemap_uri) = @_;

    confess "$sitemap_uri is not an URI object" unless (ref($sitemap_uri) =~ /^URI::https?$/);

    return WWW::WTF::UserAgent::LWP::Iterator->new( sitemap_uri => $sitemap_uri, ua => $self );
}

__PACKAGE__->meta->make_immutable;

1;
