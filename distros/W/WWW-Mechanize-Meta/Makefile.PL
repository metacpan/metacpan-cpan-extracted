use strict;
use warnings;
use inc::Module::Install;

name 'WWW-Mechanize-Meta';
all_from 'lib/WWW/Mechanize/Meta.pm';
requires 'WWW::Mechanize' => 1.20;
requires 'HTTP::Headers';
requires 'HTML::HeadParser';
repository 'http://developers.rambler.ru/svn/perlmodules/WWW-Mechanize-Meta';

WriteAll();
