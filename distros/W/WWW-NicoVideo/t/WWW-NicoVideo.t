# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-NicoVideo.t'

use Test::More tests => 4;

BEGIN {
  use_ok("WWW::NicoVideo");
  use_ok("WWW::NicoVideo::Entry");
  use_ok("WWW::NicoVideo::Scraper");
  use_ok("WWW::NicoVideo::URL");
}
