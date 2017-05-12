#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Test::Module::Used;
use File::Spec::Functions qw(catfile);

my $used = Test::Module::Used->new(
    meta_file => catfile('testdata', 'META.yml'),
);
$used->_read_meta();
is_deeply( [$used->_build_requires()],
           ['ExtUtils::MakeMaker', 'Test::More'] );

is_deeply( [$used->_requires()],
           ['Module::Used', 'PPI::Document'] );#perl 5.8.0 isn't return
is($used->_version_from_meta(), "5.008000");
is($used->_version, "5.008000");

my $used2 = Test::Module::Used->new(
    meta_file => catfile('testdata', 'META2.yml'),
);
$used2->_read_meta();
is_deeply( [$used2->_build_requires()],
           ['ExtUtils::MakeMaker', 'Test::Class', 'Test::More' ] );

is_deeply( [$used2->_requires()],
           ['Module::Used', 'Test::Module::Used'] );#perl 5.8.0 isn't return


# exclude
my $used3 = Test::Module::Used->new(
    meta_file => catfile('testdata', 'META2.yml'),
    exclude_in_build_requires => ['Test::Class'],
    exclude_in_requires       => ['Module::Used'],
);
$used3->_read_meta();
is_deeply( [$used3->_build_requires()],
           ['ExtUtils::MakeMaker', 'Test::More' ] );

is_deeply( [$used3->_requires()],
           ['Test::Module::Used'] );#perl 5.8.0 isn't return


done_testing;
