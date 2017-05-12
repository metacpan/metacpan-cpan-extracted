use strict;
use warnings;
use lib 'lib';
use WebService::Simple::Cabinet;
use Cache::File;
use YAML;

my $config = Load( do { local $/;<DATA> } );

my $api_key = "your_api_key";
my $cache   = Cache::File->new(
    cache_root      => '/tmp/mycache',
    default_expires => '30 min',
);

my $echo = WebService::Simple::Cabinet->new(
    $config,
    cache   => $cache,
    api_key => $api_key,
);
my $ref = $echo->echo(name => 'echo data');
print $ref->{name} . "\n";

#use Data::Dumper;
#warn Dumper($echo->response);

__DATA__
global:
  name: flickr_echo
  package: FlickrEcho
  base_url: http://api.flickr.com/services/rest/
  params:
    api_key:
  
method:
  - name: echo
    params:
      method: flickr.test.echo
      name:
    options:
