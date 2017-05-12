[![Build Status](https://travis-ci.org/tsucchi/Test-Module-Used.png?branch=master)](https://travis-ci.org/tsucchi/Test-Module-Used) [![Coverage Status](https://coveralls.io/repos/tsucchi/Test-Module-Used/badge.png?branch=master)](https://coveralls.io/r/tsucchi/Test-Module-Used?branch=master)
# NAME

Test::Module::Used - Test required module is really used and vice versa between lib/t and META.yml

# SYNOPSIS

    #!/usr/bin/perl -w
    use strict;
    use warnings;
    use Test::Module::Used;
    my $used = Test::Module::Used->new();
    $used->ok;

# DESCRIPTION

Test dependency between module and META.yml.

This module reads _META.yml_ and get _build\_requires_ and _requires_. It compares required module is really used and used module is really required.

# Important changes

Some behavior changed since 0.1.3\_01.

- perl\_version set in constructor is prior to use, and read version from META.yml(not read from use statement in \*.pm)
- deprecated interfaces are deleted. (module\_dir, test\_module\_dir, exclude\_in\_moduledir and push\_exclude\_in\_moduledir)

# methods

## new

create new instance

all parameters are passed by hash-style, and optional.

in ordinary use.

    my $used = Test::Module::Used->new();
    $used->ok();

all parameters are as follows.(specified values are default, except _exclude\_in\_testdir_)

    my $used = Test::Module::Used->new(
      test_dir     => ['t'],            # directory(ies) which contains test scripts.
      lib_dir      => ['lib'],          # directory(ies) which contains module libs.
      test_lib_dir => ['t'],            # directory(ies) which contains libs used ONLY in test (ex. MockObject for test)
      meta_file    => 'META.json' or
                      'META.yml' or
                      'META.yaml',      # META file (YAML or JSON which contains module requirement information)
      perl_version => '5.008',          # expected perl version which is used for ignore core-modules in testing
      exclude_in_testdir => [],         # ignored module(s) for test even if it is used.
      exclude_in_libdir   => [],        # ignored module(s) for your lib even if it is used.
      exclude_in_build_requires => [],  # ignored module(s) even if it is written in build_requires of META.yml.
      exclude_in_requires => [],        # ignored module(s) even if it is written in requires of META.yml.
    );

if perl\_version is not passed in constructor, this modules reads _meta\_file_ and get perl version.

_exclude\_in\_testdir_ is automatically set by default. This module reads _lib\_dir_ and parse "package" statement, then found "package" statements and myself(Test::Module::Used) is set.
_exclude\_in\_libdir_ is also automatically set by default. This module reads _lib\_dir_ and parse "package" statement, found "package" statement are set.(Test::Module::Used isn't included)

## ok()

check used modules are required in META file and required modules in META files are used.

    my $used = Test::Module::Used->new(
      exclude_in_testdir => ['Test::Module::Used', 'My::Module'],
    );
    $used->ok;

First, This module reads _META.yml_ and get _build\_requires_ and _requires_. Next, reads module directory (by default _lib_) and test directory(by default _t_), and compare required module is really used and used module is really required. If all these requirement information is OK, test will success.

It is NOT allowed to call ok(), used\_ok() and requires\_ok() in same test file.

## used\_ok()

Only check used modules are required in META file.
Test will success if unused _requires_ or _build\_requires_ are defined.

    my $used = Test::Module::Used->new();
    $used->used_ok;

It is NOT allowed to call ok(), used\_ok() and requires\_ok() in same test file.

## requires\_ok()

Only check required modules in META file is used.
Test will success if used modules are not defined in META file.

    my $used = Test::Module::Used->new();
    $used->requires_ok;

It is NOT allowed to call ok(), used\_ok() and requires\_ok() in same test file.

## push\_exclude\_in\_libdir( @exclude\_module\_names )

add ignored module(s) for your module(lib) even if it is used after new()'ed.
this is usable if you want to use auto set feature for _exclude\_in\_libdir_ but manually specify exclude modules.

For example,

    my $used = Test::Module::Used->new(); #automatically set exclude_in_libdir
    $used->push_exclude_in_libdir( qw(Some::Module::Which::You::Want::To::Exclude) );#module(s) which you want to exclude
    $used->ok(); #do test

## push\_exclude\_in\_testdir( @exclude\_module\_names )

add ignored module(s) for test even if it is used after new()'ed.
this is usable if you want to use auto set feature for _exclude\_in\_testdir_ but manually specify exclude modules.

For example,

    my $used = Test::Module::Used->new(); #automatically set exclude_in_testdir
    $used->push_exclude_in_testdir( qw(Some::Module::Which::You::Want::To::Exclude) );#module(s) which you want to exclude
    $used->ok(); #do test

# AUTHOR

Takuya Tsuchida <tsucchi@cpan.org>

# SEE ALSO

[Test::Dependencies](https://metacpan.org/pod/Test::Dependencies) has almost same feature.

# REPOSITORY

[http://github.com/tsucchi/Test-Module-Used](http://github.com/tsucchi/Test-Module-Used)

# COPYRIGHT AND LICENSE

Copyright (c) 2008-2014 Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
