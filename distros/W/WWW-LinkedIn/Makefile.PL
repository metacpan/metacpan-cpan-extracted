use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'WWW-LinkedIn';
perl_version '5.008001';
license 'perl';
all_from 'lib/WWW/LinkedIn.pm';

test_requires 'Test::More'  => '0';

requires 'Carp' => 0;
requires 'Net::OAuth' => 0;
requires 'LWP::UserAgent' =>  0;
requires 'HTTP::Request::Common' => 0;
requires 'Digest::MD5' => 0;
requires 'Digest::HMAC_SHA1' => 0;
requires 'MIME::Base64' => 0;
requires 'Crypt::SSLeay' => 0;

tests_recursive();
WriteAll();

