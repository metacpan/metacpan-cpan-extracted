use inc::Module::Install;

name           'Tie-DataUUID';
all_from       'lib/Tie/DataUUID.pm';

requires       'Data::UUID'          => 0;
test_requires  'Test::More'          => 0;

license 'perl';
githubmeta;
author_tests('xt');
readme_from 'lib/Tie/DataUUID.pm';

WriteAll;
