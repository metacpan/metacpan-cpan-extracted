#!perl
use inc::Module::Install 0.87;

use strict;
use warnings;

name 'Test-WWW-Mechanize-Catalyst';
perl_version '5.008004';
all_from 'lib/Test/WWW/Mechanize/Catalyst.pm';

requires 'Catalyst'                                 => '5.90';
requires 'Class::Load'                              => '0.19';
requires 'LWP'                                      => '5.816';
requires 'Test::WWW::Mechanize'                     => '1.14';
requires 'WWW::Mechanize'                           => '1.54';
requires 'Moose'                                    => '0.67';
requires 'namespace::clean'                         => '0.09';

test_requires 'Catalyst::Plugin::Session::State::Cookie' => '0';
test_requires 'Catalyst::Plugin::Session::Store::Dummy'  => '0';
test_requires 'Test::Exception'                          => '0';
test_requires 'Test::More'                               => '0.88';
test_requires 'Test::utf8'                               => '0';

if ($Module::Install::AUTHOR) {
  system('pod2text lib/Test/WWW/Mechanize/Catalyst.pm > README');
}


resources repository => 'git://git.shadowcat.co.uk/catagits/Test-WWW-Mechanize-Catalyst.git';

WriteAll;
