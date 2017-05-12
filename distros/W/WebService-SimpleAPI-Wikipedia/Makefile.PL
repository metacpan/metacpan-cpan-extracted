use inc::Module::Install;
 
name 'WebService-SimpleAPI-Wikipedia';
all_from 'lib/WebService/SimpleAPI/Wikipedia.pm';

build_requires 'Test::More';

requires $_ for (qw/LWP::UserAgent URI Class::Accessor::Fast XML::Simple DateTime::Format::W3CDTF /);

use_test_base;
auto_include;
auto_install;
WriteAll;
