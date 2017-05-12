use inc::Module::Install;

name 'Tree-Trie';
all_from 'Trie.pm';
license 'perl';
perl_version '5.008';

build_requires('Test::Pod' => 1.26);
build_requires('Test::Pod::Coverage' => 1.08);
build_requires('Pod::Coverage' => 0.18);

auto_install;
WriteAll;
