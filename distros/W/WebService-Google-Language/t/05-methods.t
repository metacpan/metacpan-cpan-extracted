#!perl -T

use strict;
use warnings;

use Test::More tests => 29;

use WebService::Google::Language;

use constant NO_INTERNET => q{Can't reach Google (no internet access?)};
use constant FORCE_TESTS => 'Set $ENV{WGL_FORCE_LIVE_TESTS} to enable live tests';
use constant REFERER     => 'http://search.cpan.org/dist/WebService-Google-Language/';
use constant WHITESPACE  => " \n \t ";

my $service = WebService::Google::Language->new(REFERER);



#
#  ping
#

can_ok $service, 'ping';
my $internet = $service->ping;
ok     defined $internet, 'ping returned defined';



#
#  translate
#

can_ok $service, 'translate';

my @ret = $service->translate;
ok ! @ret, 'Call to translate without text returned nothing';

@ret = $service->translate(WHITESPACE);
ok ! @ret, 'Call to translate with whitespace-only text returned nothing';

SKIP: {
  skip FORCE_TESTS, 14 unless $ENV{WGL_FORCE_LIVE_TESTS};
  skip NO_INTERNET, 14 unless $internet;

  my $result = eval { $service->translate('Hallo Welt') };

  ok     defined $result, 'translate returned something'
           or skip 'no result (translate failed)', 13;
  isa_ok $result, 'WebService::Google::Language::Result';
  ok     !$result->error, 'Google could handle translate request';
  is     lc $result->translation, 'hello world', 'Translation is correct';
  is     $result->language, 'de', 'Detected language is correct';

  $result = eval { $service->translate('Hallo Welt', src => 'de') };
  ok     defined $result, 'translate returned something'
           or skip 'no result (translate failed)', 8;
  ok     !defined $result->language, 'No language detection';

  $result = eval { $service->translate('Hallo Welt', src => 'xx') };

  ok     defined $result, 'translate returned something'
           or skip 'no result (translate failed)', 6;
  isa_ok $result, 'WebService::Google::Language::Result';
  ok     $result->error, 'Google returned an error as expected';
  isnt   $result->code, 200, 'Returned code indicates an error';
  ok     $result->message, 'Error message provided';

  $result = eval { $service->translate('Hallo Welt', dest => 'fr') };

  ok     defined $result, 'translate returned something'
           or skip 'no result (translate failed)', 1;
  is     lc $result->translation, 'bonjour tout le monde', 'French translation is correct';
}



#
#  detect
#

can_ok $service, 'detect';
can_ok $service, 'detect_language';

@ret = $service->detect;
ok ! @ret, 'Call to detect without text returned nothing';

@ret = $service->detect(WHITESPACE);
ok ! @ret, 'Call to detect with whitespace-only text returned nothing';

SKIP: {
  skip FORCE_TESTS, 6 unless $ENV{WGL_FORCE_LIVE_TESTS};
  skip NO_INTERNET, 6 unless $internet;

  my $result = eval { $service->detect( q{Bonjour tout le monde! Comment allez-vous aujourd'hui?} ) };

  ok     defined $result, 'detect returned something'
           or skip 'no result (detect failed)', 5;
  isa_ok $result, 'WebService::Google::Language::Result';
  ok     !$result->error, 'Google could handle detect request';
  is     $result->language, 'fr', 'Detected language is correct';
  ok     defined $result->is_reliable, 'Detected language has defined reliability';
  ok     $result->confidence > 0.1, 'There is enough confidence';
}
