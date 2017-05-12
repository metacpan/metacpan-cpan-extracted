use inc::Module::Install;

name           'Test-WWW-Mechanize-Declare';
all_from       'lib/Test/WWW/Mechanize/Declare.pm';
repository     'git://isuckatdomains.net/test-www-mechanize-declare.git';

requires       'Test::WWW::Mechanize'  => '0';
requires       'URI::URL'  => '0';

WriteAll;
