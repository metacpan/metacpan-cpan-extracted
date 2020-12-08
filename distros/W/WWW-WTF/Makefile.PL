use inc::Module::Install;

name 'WWW-WTF';
license 'perl';
version '0.7';

requires 'common::sense';
requires 'Cache::FastMmap';
requires 'Digest::SHA';
requires 'Export::Attrs';
requires 'File::Basename';
requires 'File::Find::Rule';
requires 'File::Path';
requires 'File::Temp';
requires 'File::Slurper';
requires 'HTML::TokeParser';
requires 'HTTP::Headers';
requires 'List::Util';
requires 'LWP::UserAgent';
requires 'Moose';
requires 'URI';
requires 'Test::LongString';
requires 'WWW::Mechanize';
requires 'XML::Simple';

requires_external_bin 'pdfimages';
requires_external_bin 'zbarimg';

recommends 'WWW::WebKit2' => 0.127;

test_requires 'Plack';
test_requires 'Test2::Suite';

auto_install;
WriteAll;
