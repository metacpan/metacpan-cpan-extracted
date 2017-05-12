use strict;
use warnings;
use WebService::Simple;
use Data::Dumper;

my $flickr = WebService::Simple->new(
    base_url        => "http://api.flickr.com/services/rest/",
    response_parser => 'XML::Lite',
    params          => { api_key => $ARGV[0] }
);

my $response =
  $flickr->get( { method => "flickr.photos.search", text => $ARGV[1] || 'Cat' } );
my $format = 'http://static.flickr.com/${server}/${id}_${secret}_m.jpg';
for my $photo ($response->parse_response->select_nodes('/rsp/photos/photo')) {
    my $image = $format;
    print $image =~ s/\$\{([^{}]+)\}/$photo->{attributes}->{$1}/ge && "$image\n";
}
