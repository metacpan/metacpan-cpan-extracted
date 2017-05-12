use strict;
use inc::Module::Install;

name           'URL-Encode-XS';
perl_version   '5.008001';
all_from       'lib/URL/Encode/XS.pm';
repository     'http://github.com/chansen/p5-url-encode-xs';
readme_from    'lib/URL/Encode/XS.pm';

requires       'Carp'             => '0';
requires       'Exporter'         => '0';
requires       'XSLoader'         => '0';
requires       'URL::Encode'      => '0.03';
test_requires  'Test::More'       => '0.88';
makemaker_args INC => '-I.';

tests 't/*.t t/*/*.t';

ppport;
requires_external_cc;

WriteAll;

