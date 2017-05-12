# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok( 'URL::Signature::Google::Maps::API' ); }

{
  my $signer = URL::Signature::Google::Maps::API->new (client=>""); #turn off Enterpirse Signing
  is($signer->url("http://server" => "/path?query"), "http://server/path?query", 'simple pass through when no client');
}

{
  my $signer = URL::Signature::Google::Maps::API->new (config_filename=>"not_going_to_find_it.ini");
  is($signer->url("http://server" => "/path?query"), "http://server/path?query", 'simple pass through when no client');
}

{
  my $signer = URL::Signature::Google::Maps::API->new (config_paths=>["bad_path"]);
  is($signer->url("http://server" => "/path?query"), "http://server/path?query", 'simple pass through when no client');
}
