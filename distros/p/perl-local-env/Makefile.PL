use inc::Module::Install;
use Module::Install::ReadmeFromPod;
use Module::Install::Repository;
name 'perl-local-env';
all_from 'bin/perl-local-env';
requires 'local::lib';
build_requires 'Test::More';
auto_set_repository;
WriteAll;
