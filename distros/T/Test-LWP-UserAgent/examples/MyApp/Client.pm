package MyApp::Client;
use strict;
use warnings;

use Moose;
use LWP::UserAgent;
use JSON::MaybeXS;

has useragent => (
    is => 'ro', isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub { LWP::UserAgent->new },
);

sub get_indexes
{
    my ($self, %args) = @_;

    my $user = $args{user};

    # call our server to get the data
    my $url = "http://myserver.com/user/$user";
    my $response = $self->useragent->get($url);

    if ($response->code ne '200'
        or $response->headers->content_type ne 'application/json')
    {
        warn "network timeout when fetching $url" if $response->decoded_content =~ /time(?:d )?out/;
        return;
    }

    # parse JSON data from response
    my $data = decode_json($response->decoded_content);
    return @{$data->{post_ids} // []};
}
__PACKAGE__->meta->make_immutable;

