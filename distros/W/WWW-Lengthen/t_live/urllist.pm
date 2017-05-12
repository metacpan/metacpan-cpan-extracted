package #  hide from PAUSE
  t_live::urllist;

use strict;
use warnings;
use WWW::Lengthen;

my $ex    = 'http://example.com/';
my $ex_t  = 'http://example.com/test';

my %tests = (
  '0rz'        => [ $ex_t => 'http://0rz.tw/443v7' ],
  Metamark     => [ $ex   => 'http://xrl.us/bdgj9' ],
  SnipURL      => [ $ex   => 'http://snipurl.com/1vv5c' ],
  TinyURL      => [ $ex_t => 'http://tinyurl.com/4o6x2s' ],
  snurl        => [ $ex   => 'http://snurl.com/fuz4q' ],
  OneShortLink => [ $ex   => 'http://1sl.net/1239' ],
  Shorl        => [ $ex   => 'http://shorl.com/fylevihehyra' ],
  bitly        => [ $ex   => 'http://bit.ly/VDcn' ],
  isgd         => [ $ex   => 'http://is.gd/1NTB' ],
  htly         => [ $ex   => 'http://ht.ly/1Yd65' ],
  owly         => [ $ex   => 'http://ow.ly/1YdwQ' ],
  urlchen      => [ $ex   => 'http://urlchen.de/jHxzE' ],
  google       => [ $ex   => 'http://goo.gl/0pLLT' ],
);

sub basic_tests {
  return map { $_ => $tests{$_} } keys %WWW::Lengthen::KnownServices;
}

sub extra_tests {
  return map { $_ => $tests{$_} } keys %WWW::Lengthen::ExtraServices;
}

1;
