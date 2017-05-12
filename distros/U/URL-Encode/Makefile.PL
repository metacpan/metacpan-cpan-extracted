use strict;
use inc::Module::Install;

name           'URL-Encode';
perl_version   '5.008001';
all_from       'lib/URL/Encode.pm';
repository     'http://github.com/chansen/p5-url-encode';
readme_from    'lib/URL/Encode.pod';

requires       'Carp'             => '0';
requires       'Exporter'         => '0';
requires       'XSLoader'         => '0';
test_requires  'Test::More'       => '0.88';
makemaker_args INC => '-I.';

tests 't/*.t t/*/*.t';

WriteAll;

