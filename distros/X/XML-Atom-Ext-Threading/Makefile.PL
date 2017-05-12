use inc::Module::Install;

name('XML-Atom-Ext-Threading');
all_from('lib/XML/Atom/Ext/Threading.pm');

requires('XML::Atom' => 0.28);

build_requires 'Test::More';
use_test_base;

auto_include;
auto_install;
WriteAll;
