use inc::Module::Install;

name 'XML-SemanticCompare';

# all_from 'lib/XML/SemanticCompare.pm';
author 'Edward Kawas <edward.kawas+xml-semantic-compare@gmail.com>';
version '0.92';
license 'perl';
abstract 'Compare 2 XML files semantically';

build_requires 'Test::More' => 0;
build_requires 'Test::Pod'  => 0;

# xpath testing requires
requires 'XML::LibXML'   => 0;
# semantic diff-ing requires
requires 'XML::Simple'   => '2.18';

auto_install;

WriteAll;

