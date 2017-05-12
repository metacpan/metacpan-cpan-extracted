#!/usr/bin/env perl -T
use strict;
use warnings;

use Test::More tests => 4;
use POSIX qw/setlocale LC_ALL/;

BEGIN {
	use_ok( 'XML::OPML::SimpleGen' );
}

setlocale(LC_ALL, "ru_RU.utf8");

my $data = XML::OPML::SimpleGen->new()->as_string;

like($data, qr/<dateCreated>[a-z]{3}, {1,2}\d{1,2} [a-z]{3} \d{4} \d\d:\d\d:\d\d/i);
#was <dateCreated>Сбт, 31 Окт 2009 15:51:22 +0300</dateCreated>
#
{
  diag('RT77725');
  my $opml = XML::OPML::SimpleGen->new;
  { my $lt   = [ localtime(1328097661) ]; #2012-02-01 12:01:01
    my $res = $opml->_date( dateCreated => $lt );
    like($res, qr{[a-z]{3}, {1,2}\d{1,2} [a-z]{3} \d{4} \d\d:\d\d:\d\d}i );
  }
  { my $lt  = [ localtime(1330516861) ]; # 2012-02-28 12:01:01
    my $res = $opml->_date( dateModified => $lt );
    like($res, qr{[a-z]{3}, {1,2}\d{1,2} [a-z]{3} \d{4} \d\d:\d\d:\d\d}i );
  }
}

done_testing;
