#!/usr/bin/env perl
use strict;
use warnings;
use Web::Library::Item;
use Test::More;
subtest 'Item with default version', sub {
    my $item = Web::Library::Item->new(name => 'Foo');
    is $item->name,    'Foo',    'The item has the provided name';
    is $item->version, 'latest', 'The item has the default version';
    is $item->get_package, 'Web::Library::Foo', 'get_package() works';
    isa_ok $item->get_distribution_object, 'Web::Library::Foo';
    is $item->include_path, '/path/to/latest', 'include_path() works';
};
subtest 'Item with given version', sub {
    my $item = Web::Library::Item->new(name => 'Foo', version => '1.2.3');
    is $item->version, '1.2.3', 'The item has the provided version';
    is $item->include_path, '/path/to/1.2.3', 'include_path() works';
};
done_testing;

package Web::Library::Foo;
sub new { bless {}, shift }
sub get_dir_for { "/path/to/$_[1]" }
