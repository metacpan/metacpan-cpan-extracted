use inc::Module::Install;

name 'Test-XML-RPC-Catalyst';

all_from 'lib/Test/XML/RPC/Catalyst.pm';

build_requires 'Catalyst::Runtime' => '5.7012';
build_requires 'Catalyst::Plugin::Server' => '0.24';

requires 'Test::Simple' => '0.72';
requires 'Test::WWW::Mechanize::Catalyst' => '0.41';
requires 'XML::RPC' => '0.6';

auto_install;

WriteAll;

