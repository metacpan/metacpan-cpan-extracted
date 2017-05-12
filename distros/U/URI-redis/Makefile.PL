#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

use Module::Install::AuthorRequires 0.02;
use Module::Install::ReadmeFromPod 0.06;
use Module::Install::Repository 0.06;
use Module::Install::ExtraTests 0.006;

name 'URI-redis';
all_from 'lib/URI/redis.pm';
readme_from 'lib/URI/redis.pm' => 'clean';
auto_set_repository;

requires 'URI'                        => 0;

test_requires 'Test::Most'            => '0.21';

author_requires 'Test::Pod'           => '1.22';
author_requires 'Test::Pod::Coverage' => '1.08';
author_requires 'Pod::Coverage'       => '0.18';
author_requires 'Test::Perl::Critic'  => '1.01';

extra_tests;

auto_install;

WriteAll;
