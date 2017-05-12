sub author_tests {}
sub auto_set_repository {}

use inc::Module::Install;
name 'Text-MicroTemplate-DataSection';
all_from 'lib/Text/MicroTemplate/DataSection.pm';

test_requires 'Test::More' => '0.94';

requires 'Data::Section::Simple';
requires 'Text::MicroTemplate' => '0.13';
recommends 'Text::MicroTemplate::Extended' => '0.11';

author_tests('xt');
auto_set_repository;

WriteAll;
