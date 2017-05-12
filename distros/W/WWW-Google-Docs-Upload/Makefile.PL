use inc::Module::Install;
name 'WWW-Google-Docs-Upload';
all_from 'lib/WWW/Google/Docs/Upload.pm';

build_requires 'Test::More';

requires 'Moose';
requires 'WWW::Mechanize';

use_test_base;
auto_include;
WriteAll;
