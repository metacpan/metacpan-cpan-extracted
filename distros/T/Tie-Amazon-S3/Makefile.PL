use inc::Module::Install;

name     'Tie-Amazon-S3';
all_from 'lib/Tie/Amazon/S3.pm';
author   'Zak B. Elep <zakame@cpan.org>';
license  'MIT';

requires       'Carp';
requires       'Net::Amazon::S3';
build_requires 'Test::More';

auto_install;

WriteAll;

