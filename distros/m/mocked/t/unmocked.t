#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use t::TestUtils;

BEGIN { # test setup
    use lib 'lib';
    # this module uses URI.pm, hopefully it loads
    use mocked 'Foo::UsingUnmocked';
}

Load_mocked_library_with_unmocked_dependency: {
    is $Foo::UsingUnmocked::VERSION, 'Mocked', 'Mocked module loaded';
    is Foo::UsingUnmocked::foo(), 'awesnob.com', 'could use real module';
}
