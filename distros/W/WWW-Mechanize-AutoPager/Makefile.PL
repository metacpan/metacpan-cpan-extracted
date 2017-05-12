use inc::Module::Install;
name 'WWW-Mechanize-AutoPager';
all_from 'lib/WWW/Mechanize/AutoPager.pm';

requires 'HTML::AutoPagerize';
requires 'WWW::Mechanize';
requires 'WWW::Mechanize::DecodedContent';
requires 'JSON' => 2.09;

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
