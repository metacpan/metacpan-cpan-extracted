use inc::Module::Install;

name        'URI-BNode';
all_from    'lib/URI/BNode.pm';
readme_from 'lib/URI/BNode.pm';
author      q{Dorian Taylor <dorian@cpan.org>};
license     'apache';

requires 'URI';
requires 'Data::GUID::Any'    => '0.004';
requires 'Data::UUID::NCName' => '0.03';
requires 'URI::urn::uuid'     => '0.03';

build_requires 'Test::More';

auto_install;

WriteAll;

