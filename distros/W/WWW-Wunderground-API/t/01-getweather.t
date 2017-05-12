#!perl

use Test::More tests => 16;

use_ok( 'WWW::Wunderground::API' );

my $wun = new WWW::Wunderground::API('KDCA');
isa_ok($wun,'WWW::Wunderground::API','Got a new Wunderground API object');
if ($wun->api_key) {
  is($wun->api_type,'json','API type properly defaults to JSON');
  $wun->api_type('xml');
  $wun->raw('<xml version="1.0"><temp_f>50</temp_f></xml>');
  ok(length($wun->xml),'XML test data set');
  $wun->data(Hash::AsObject->new({conditions=>&XML::Simple::XMLin($wun->xml)}));
} else {
  is($wun->api_type,'xml','API type properly defaults to XML');
  $wun->update;
  ok(length($wun->xml),'Got XML from wunderground');
}
isa_ok($wun->data,'Hash::AsObject','Parsed xml');
like($wun->conditions->temp_f, qr/\d+/, 'Read temperature of '.$wun->conditions->temp_f.'f');
is($wun->conditions->temp_f, $wun->temp_f, "Conditions data AUTOLOADing");

my $qwt = WWW::Wunderground::API->new(location=>'KDCA', auto_api=>1, cache=>$wun->cache)->temp_f;
like($qwt,qr/\d+/,'Too Much Magic works.');

my $time = $wun->cache->set('test',time);
is($time,$wun->cache->get('test'), 'BadCache "works." But don\'t use it.');

SKIP: {
  skip "API tests require WUNDERGROUND_API environment variable to be set.", 7 unless $ENV{WUNDERGROUND_API};
  my $wun = new WWW::Wunderground::API(location=>'KDCA', auto_api=>1);
  isa_ok($wun,'WWW::Wunderground::API','Got a new Wunderground API object');
  like($wun->temp_f, qr/\d+/, 'Regan National has a temperature: '.$wun->temp_f.'f');
  ok(length($wun->raw),'raw returns source data');
  isa_ok($wun->data,'Hash::AsObject','Data returns friendly object');
  my $rad_animation = $wun->animatedsatellite();
  is(substr($rad_animation,0,3),'GIF',"Animated Satellite returned a GIF");
  is($wun->lang(),'EN','Default lang is "EN"');
  $wun->lang('FR');
  $wun->api_call('forecast10day');
  like($wun->json(),qr/dimanche/i, '10 days forecast in french include "dimanche"');
}
