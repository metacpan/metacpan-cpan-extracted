use inc::Module::Install;

name 'WWW-WTF';
license 'perl';
version '0.5';

requires 'common::sense';
requires 'Cache::FastMmap';
requires 'Digest::SHA';
requires 'Export::Attrs';
requires 'HTML::TokeParser';
requires 'HTTP::Headers';
requires 'LWP::UserAgent';
requires 'Moose';
requires 'URI';
requires 'WWW::Mechanize';
requires 'XML::Simple';
requires 'List::Util';
requires 'Test::LongString';

recommends 'WWW::WebKit2' => 0.127;

test_requires 'Plack';
test_requires 'Test2::Suite';

auto_install;
WriteAll;
