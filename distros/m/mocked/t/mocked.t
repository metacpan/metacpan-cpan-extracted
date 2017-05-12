#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;
use t::TestUtils;

BEGIN { # test setup
    use lib 'lib';
    use mocked 'Foo::Bar' => qw/$awesome/;
    require Foo::Moose;
    import Foo::Moose;
    use mocked [qw(Foo::Baz t/ERK/)];

    use Foo::Other;
    throws_ok {
      mocked->import(q{Foo::WhatWeWant});
    } qr{Attempting to mock}, q{ensure we die on preloaded package};
    
    use Foo::PreLoaded;
    throws_ok {
      mocked->import(q{Foo::PreLoaded});
    } qr{Attempting to mock}, q{ensure we die on preloaded module};

    use mocked 'Foo::NestedMocked';
}

Load_mocked_library: {
    is $Foo::Bar::VERSION, 'Mocked', "Mocked module loaded";
    is $awesome, 'like, totally', "We're awesome";
    is Foo::Bar::module_filename(), 't/lib/Foo/Bar.pm';

    is $Foo::Moose::VERSION, '0.01', 'Real moose loaded';
    is Foo::Moose::module_filename(), 'lib/Foo/Moose.pm';

    is $Foo::Baz::VERSION, 'Mocked', "Mocked module loaded";
    is $awesome, 'like, totally', "We're awesome";
    is Foo::Baz::module_filename(), 't/ERK/Foo/Baz.pm';
}

Nested_mocks: {
    # Foo::NestedMocked does a "use mocked 'Foo::Nestee'"
    # which _should_ DTRT - load the Foo::Nestee in t/lib.
    # Foo::Nestee should then be able to "use unmocked 'Data::Dumper'"
    # and that should work fine.
    is $Foo::NestedMocked::VERSION, 'Mocked';
    is $Foo::NestedMocked::FNV, 'Mocked';
    is $Foo::NestedMocked::FNV2, '0.01';
    ok $Foo::Nestee::DDV;
}
