package MyMechanize;
use Test::WWW::Mechanize::Driver::Util qw/ build_uri /;
use strict; use warnings;
use base qw/Test::WWW::Mechanize/;
require URI;
require YAML;

# a shared cache (over all Mech objects) will work just fine
my %cache;

# $x->my_mech_load_files( @files )
#
# fill (global) cache with data from given files
sub my_mech_load_files {
  my $x = shift;
  for (@_) {
    my ($meta, $res) = YAML::LoadFile($_) or die "YAML Load Error";
    $$meta{response} = $res;

    $$meta{uri} = [$$meta{uri}] unless ref($$meta{uri});

    # many uris may refer to the same cached page
    $cache{$_} = $meta for @{$$meta{uri}};
  }
  return scalar(keys %cache);
}


sub _make_request {
  my $x = shift;
  my $req = shift;
  my $uri = $req->uri;

  if ($req->method ne 'GET') {
    $uri = build_uri($uri, { method => $req->method });
  }

  if ($req->method eq 'POST' and $req->content) {
    $uri .= '&'.$req->content;
  }

  die "Request uri '$uri' does not exist in cache\n" unless exists $cache{$uri};
  my $res = HTTP::Response->parse( $cache{$uri}{response} );
  $res->request($req);
  return $res;
}


1;
