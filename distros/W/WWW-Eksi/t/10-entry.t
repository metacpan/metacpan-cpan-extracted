use warnings;
use strict;

use Test::More;
use Test::RequiresInternet ('www.eksisozluk.com' => 80);
use WWW::Eksi;

my $e = WWW::Eksi->new;
isa_ok($e, 'WWW::Eksi');

my $entry    = $e->download_entry(1);
my $expected = {
  author_id      => 8097,
  author_name    => 'ssg',
  author_url     => 'https://eksisozluk.com/biri/ssg',
  body_processed => 'gitar calmak icin kullanilan minik plastik garip nesne.',
  body_raw       => 'gitar calmak icin kullanilan minik plastik garip nesne.',
  body_text      => 'gitar calmak icin kullanilan minik plastik garip nesne.',
  entry_url      => 'https://eksisozluk.com/entry/1',
  time_as_seen   => '15.02.1999',
  topic_title    => 'pena',
  topic_url      => 'https://eksisozluk.com/pena--31782',
};

foreach my $key (keys %$expected){
  $key =~ /^body/
       ? like ($entry->{$key}, qr/$expected->{$key}/, "correct $key")
       : is ($entry->{$key}, $expected->{$key}, "correct $key");
}

ok($entry->{fav_count} > 0, "correct fav_count");
ok(scalar($entry->{topic_channels})>0, "correct topic_channels");
is($entry->{create_time}->ymd,'1999-02-15', "correct create_time");

done_testing;
