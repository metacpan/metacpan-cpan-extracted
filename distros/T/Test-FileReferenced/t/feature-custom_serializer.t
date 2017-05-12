#!/usr/bin/perl

use strict; use warnings;

use Test::More tests => 6;
use Test::Exception;
use Test::FileReferenced;

# Crash tests, to make sure We can detect common problems:

dies_ok {
    Test::FileReferenced::set_serializer();
} "Crash test - no parameters";

dies_ok {
    Test::FileReferenced::set_serializer("test");
} "Crash test - de-serializer missing";
dies_ok {
    Test::FileReferenced::set_serializer("test", "Foo");
} "Crash test - de-serializer not a CODE-ref";

dies_ok {
    Test::FileReferenced::set_serializer("test", sub {});
} "Crash test - serializer missing";
dies_ok {
    Test::FileReferenced::set_serializer("test", sub {}, "Bar");
} "Crash test - serializer not a CODE-ref";


# This will (finally) work :)
Test::FileReferenced::set_serializer(
    'dumper',
    sub {
        my ( $path ) = @_;

        my $fh;
        open $fh, q{<}, $path;

        my $content = join "", <$fh>;
        $content =~ s{^\$VAR\d+\s*=\s*}{}s;
        my $data = eval $content;

        return $data;
    },
    sub { return; }, # <-- test will (hopefully) pass, so this will not be used.
);

is_referenced_ok(
    {
        foo => 'Foo',
        bar => 'Bar',
        baz => 'Baz',
    },
    'Custom de-serializer',
);

# vim: fdm=marker
