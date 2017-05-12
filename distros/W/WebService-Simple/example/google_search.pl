use strict;
use warnings;
use WebService::Simple;
use Data::Dumper;

my $google = WebService::Simple->new(
    base_url        => "http://ajax.googleapis.com/ajax/services/search/web",
    response_parser => 'JSON',
    params          => { v => "1.0", rsz=> "large" }
);

my $response =  $google->get( { q => "cat" , start=> 0 } );
print Dumper $response->parse_response;

