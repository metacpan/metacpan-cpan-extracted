use inc::Module::Install;
name 'WWW-Favicon';
all_from 'lib/WWW/Favicon.pm';

build_requires 'Test::More';
build_requires 'Test::MockObject::Extends';

requires 'Class::Accessor::Fast';
requires 'Exporter';
requires 'LWP::UserAgent';
requires 'HTML::TreeBuilder';
requires 'HTML::ResolveLink';

use_test_base;
auto_include;
WriteAll;
