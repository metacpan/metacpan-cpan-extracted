use strict;
use inc::Module::Install;

name('WebService-Livedoor-Auth');
all_from('lib/WebService/Livedoor/Auth.pm');

requires('URI');
requires('Digest::HMAC_SHA1');
requires('Scalar::Util');
requires('Params::Validate');
requires('LWP::UserAgent');
requires('Class::Accessor::Fast');
requires('Class::ErrorHandler');

build_requires('Test::More');
auto_include;
WriteAll;
