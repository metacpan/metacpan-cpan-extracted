#!/usr/bin/perl
# yaml-multi-document.t
#
# Tests for YAML 1.0 multi-document streams:
#   - Multiple documents separated by ---
#   - Document end marker (...)
#   - Load in list context vs scalar context
#   - Dump with multiple arguments
#
# Spec reference: https://yaml.org/spec/1.0/#id2561631

use strict;
use warnings;
use Test::More;
use YAML::Syck;

# --- Multiple documents: inline scalars after --- ---

{
    my $yaml = "--- foo\n--- bar\n--- baz\n";
    my @docs = Load($yaml);
    is_deeply( \@docs, [ 'foo', 'bar', 'baz' ],
        'Load in list context returns multiple inline-scalar documents' );
}

{
    my $yaml = "--- foo\n--- bar\n";
    my $first = Load($yaml);
    is( $first, 'foo',
        'Load in scalar context returns first document only' );
}

# --- Multiple documents: mappings ---

{
    my $yaml = "---\nfoo: 1\n---\nbar: 2\n";
    my @docs = Load($yaml);
    is( scalar @docs, 2, 'two mapping documents parsed' );
    is( $docs[0]->{foo}, 1, 'first mapping document' );
    is( $docs[1]->{bar}, 2, 'second mapping document' );
}

# --- Multiple documents: sequences ---

{
    my $yaml = "---\n- a\n- b\n---\n- c\n- d\n";
    my @docs = Load($yaml);
    is( scalar @docs, 2, 'two sequence documents parsed' );
    is_deeply( $docs[0], ['a', 'b'], 'first sequence document' );
    is_deeply( $docs[1], ['c', 'd'], 'second sequence document' );
}

# --- Dump multiple documents ---

{
    my $yaml = Dump( 'foo', 'bar', 'baz' );
    my @docs = Load($yaml);
    is_deeply( \@docs, [ 'foo', 'bar', 'baz' ],
        'Dump with multiple args roundtrips through Load in list context' );
}

{
    my $yaml = Dump( { a => 1 }, { b => 2 } );
    my @docs = Load($yaml);
    is_deeply( \@docs, [ { a => 1 }, { b => 2 } ],
        'Dump/Load roundtrip with multiple hash documents' );
}

# --- Mixed document types ---

{
    my $yaml = Dump( 'scalar', [1, 2, 3], { key => 'value' } );
    my @docs = Load($yaml);
    is_deeply( \@docs, [ 'scalar', [1, 2, 3], { key => 'value' } ],
        'Dump/Load roundtrip with mixed document types' );
}

# --- Document end marker (...) ---

{
    my $yaml = "--- foo\n...\n--- bar\n...\n";
    my @docs = Load($yaml);
    is_deeply( \@docs, [ 'foo', 'bar' ],
        'document end marker (...) separates documents' );
}

{
    my $yaml = "--- hello\n...\n";
    my $data = Load($yaml);
    is( $data, 'hello',
        'single document with ... end marker' );
}

# --- Empty documents (undef/null) ---

{
    my $yaml = "--- ~\n--- ~\n";
    my @docs = Load($yaml);
    is( scalar @docs, 2,
        'two null documents parsed' );
    ok( !defined($docs[0]) && !defined($docs[1]),
        'null documents return undef' );
}

# --- Inline value after --- ---

{
    my $yaml = "--- foo\n--- bar\n";
    my @docs = Load($yaml);
    is( $docs[0], 'foo', 'inline value after --- (first doc)' );
    is( $docs[1], 'bar', 'inline value after --- (second doc)' );
}

# --- Complex multi-document ---

{
    my $yaml = <<'YAML';
---
name: doc1
items:
  - a
  - b
---
name: doc2
items:
  - c
  - d
YAML
    my @docs = Load($yaml);
    is( scalar @docs, 2, 'two complex documents parsed' );
    is( $docs[0]->{name}, 'doc1', 'first complex document content' );
    is( $docs[1]->{name}, 'doc2', 'second complex document content' );
    is_deeply( $docs[0]->{items}, ['a', 'b'], 'first document items' );
    is_deeply( $docs[1]->{items}, ['c', 'd'], 'second document items' );
}

# --- Plain scalar on next line after --- (known parser limitation) ---

{
    my $yaml = "---\nfoo\n---\nbar\n";
    my @docs = Load($yaml);
    is( scalar @docs, 2,
        'plain scalars on next line after --- parsed as separate documents' );
    is( $docs[0], 'foo', 'first plain scalar document' );
    is( $docs[1], 'bar', 'second plain scalar document' );
}

# --- Plain scalar terminated by document end marker (...) ---

{
    my $yaml = "---\nfoo\n...\n---\nbar\n";
    my @docs = Load($yaml);
    is( scalar @docs, 2,
        'plain scalar terminated by ... then new document' );
    is( $docs[0], 'foo', 'first doc before ...' );
    is( $docs[1], 'bar', 'second doc after ...' );
}

# --- Multi-line plain scalar should still work ---

{
    my $yaml = "---\nfoo\n  bar\n  baz\n";
    my @docs = Load($yaml);
    is( scalar @docs, 1,
        'indented continuation lines remain single document' );
    is( $docs[0], 'foo bar baz',
        'multi-line plain scalar folds correctly' );
}

# --- Three plain scalar documents ---

{
    my $yaml = "---\nalpha\n---\nbeta\n---\ngamma\n";
    my @docs = Load($yaml);
    is( scalar @docs, 3, 'three plain scalar documents' );
    is( $docs[0], 'alpha', 'first of three' );
    is( $docs[1], 'beta',  'second of three' );
    is( $docs[2], 'gamma', 'third of three' );
}

done_testing();
