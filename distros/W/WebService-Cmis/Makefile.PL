use inc::Module::Install;
use strict;
use warnings;

name     'WebService-Cmis';
license_from 'lib/WebService/Cmis.pm';
all_from 'lib/WebService/Cmis.pm';
readme_from 'lib/WebService/Cmis.pm';

author   q{Michael Daum <daum@michaeldaumconsulting.com>};

requires 'Error' => 0;
requires 'File::MMagic' => 0;
requires 'LWP::UserAgent' => 0;
requires 'REST::Client' => 0;
requires 'URI' => 0;
requires 'XML::LibXML' => 0;
test_requires 'Cache::FileCache' => 0;
test_requires 'Test::Class' => 0;
test_requires 'Test::DistManifest' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
test_requires 'Test::Signature' => 0;
test_requires 'XML::SemanticDiff' => 0;
sign;
WriteAll;
