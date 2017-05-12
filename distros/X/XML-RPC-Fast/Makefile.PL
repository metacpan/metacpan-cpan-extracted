my $MI  = $Module::Install::MAIN;
use 5.008003; # I want Encode to work
use inc::Module::Install;

name     'XML-RPC-Fast';
all_from 'lib/XML/RPC/Fast.pm';
#version   my $v = '0.6';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';
build_requires 'Test::NoWarnings';
build_requires 'lib::abs', '0.90';
build_requires 'Encode';

# requires 'Encode';
requires 'LWP::UserAgent';
requires 'HTTP::Request';
requires 'HTTP::Response';
requires 'HTTP::Headers';

requires 'XML::LibXML', '1.58';
requires 'XML::Hash::LX' , '0.05';

recommends 'Sub::Name';
recommends 'MIME::Base64';
recommends 'DateTime::Format::ISO8601';
recommends 'AnyEvent', '5.0';
recommends 'AnyEvent::HTTP';
recommends 'WWW::Curl';

if (!eval { my $x = pack 'q', -1; 1 }) {
	requires 'Math::BigInt';
}

auto_provides;
auto_install;

WriteAll;
print STDERR "Generated makefile for ".$MI->load('name')->name."-".$MI->load('version')->version."\n";
