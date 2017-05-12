#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
  eval "use Digest::MD5";
  if ($@) {
      Test::More::plan(
          skip_all => "Digest::MD5 required to test example"
      );
  }
}

use Test::More tests => 1;

use XML::Easy qq(xml10_write_document);
use XML::Easy::ProceduralWriter;
use Digest::MD5 qw(md5_hex);

is(md5_hex(xml10_write_document(xml_element {
  element "song", title => "Green Bottles", contains {
    foreach my $bottles (reverse (1..10)) {
      element "verse", contains {
        element "line", contains {
          text "$bottles green bottle";
          text "s" unless $bottles == 1;
          text " hanging on the wall";
        } for (1..2);
        element "line", contains {
          text "if 1 green bottle should accidentally fall";
        };
        element "line", contains {
          text "then they'd be ".($bottles > 1 ? $bottles-1 : "no")." green bottle";
          text "s" unless $bottles-1 == 1;
          text " hanging on the wall";
        };
      };
    }
  }
}, "UTF-16BE")), "0f5bd6f73e6d5d21886056e0c43c3d72", "matches");

