#!/usr/bin/perl -w

use strict;
use Test::More tests => 16;
use YAML::Syck qw(Load LoadBytes LoadUTF8);

# GH #164: Load()/LoadBytes()/LoadUTF8() in list context should return
# empty list for empty/undef input, not croak with
# "Can't use an undefined value as an ARRAY reference"

# Load — empty/undef
{
    my @docs = Load("");
    is( scalar @docs, 0, "Load('') in list context returns empty list" );
}
{
    my @docs = Load(undef);
    is( scalar @docs, 0, "Load(undef) in list context returns empty list" );
}

# Load — scalar context still returns undef
{
    my $doc = Load("");
    ok( !defined $doc, "Load('') in scalar context returns undef" );
}

# Load — single and multi-document
{
    my @docs = Load("--- foo\n");
    is( scalar @docs, 1, "single doc in list context returns 1 element" );
    is( $docs[0], 'foo', "single doc value is correct" );
}
{
    my @docs = Load("--- foo\n--- bar\n");
    is( scalar @docs, 2, "multi-doc in list context returns 2 elements" );
    is( $docs[0], 'foo', "first doc is correct" );
    is( $docs[1], 'bar', "second doc is correct" );
}

# LoadBytes — empty/undef
{
    my @docs = LoadBytes("");
    is( scalar @docs, 0, "LoadBytes('') in list context returns empty list" );
}
{
    my @docs = LoadBytes(undef);
    is( scalar @docs, 0, "LoadBytes(undef) in list context returns empty list" );
}

# LoadBytes — normal operation
{
    my @docs = LoadBytes("--- hello\n");
    is( scalar @docs, 1, "LoadBytes single doc in list context" );
    is( $docs[0], 'hello', "LoadBytes value is correct" );
}

# LoadUTF8 — empty/undef
{
    my @docs = LoadUTF8("");
    is( scalar @docs, 0, "LoadUTF8('') in list context returns empty list" );
}
{
    my @docs = LoadUTF8(undef);
    is( scalar @docs, 0, "LoadUTF8(undef) in list context returns empty list" );
}

# LoadUTF8 — normal operation
{
    my @docs = LoadUTF8("--- world\n");
    is( scalar @docs, 1, "LoadUTF8 single doc in list context" );
    is( $docs[0], 'world', "LoadUTF8 value is correct" );
}
