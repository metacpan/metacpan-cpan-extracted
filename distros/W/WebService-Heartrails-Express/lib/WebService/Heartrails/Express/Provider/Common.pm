package WebService::Heartrails::Express::Provider::Common;
use strict;
use warnings;
use utf8;

use constant  API_ENDPOINT => 'http://express.heartrails.com/api/json?';
use JSON;
use Encode;
use URI;

sub call{
  my($class,$sub_url) = @_;
  my $uri = URI->new(API_ENDPOINT);
  $uri->query_form(%$sub_url);
  my $res = $class->furl->get($uri);
  my $content = $res->content;
  return $content;
}

1;




