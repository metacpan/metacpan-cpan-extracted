#!/usr/bin/perl

# Test that external entity paths containing Perl IO control characters
# are rejected by file_ext_ent_handler. Without this check, a malicious
# XML document could use external entity SYSTEM identifiers to execute
# shell commands via Perl's two-argument open (e.g. "|command" or
# "command|").

use strict;
use warnings;

use Test::More tests => 5;
use XML::Parser;

# Helper: build XML with an external entity SYSTEM identifier
sub xml_with_entity_path {
    my ($path) = @_;
    return qq{<!DOCTYPE foo [\n  <!ENTITY x SYSTEM "$path">\n]>\n<foo>&x;</foo>};
}

# Force file-based handler with NoLWP — the IO control check only
# exists in file_ext_ent_handler, not in the LWP handler (which uses
# URI and is not vulnerable to two-argument open injection).

my @dangerous_paths = (
    [ '|echo pwned',    'pipe write (|cmd)' ],
    [ 'echo pwned|',    'pipe read (cmd|)' ],
    [ '>pwned.txt',     'output redirect (>file)' ],
    [ '+<pwned.txt',    'read-write (+<file)' ],
);

for my $case (@dangerous_paths) {
    my ($path, $label) = @$case;

    my $p = XML::Parser->new( NoLWP => 1 );
    eval { $p->parse( xml_with_entity_path($path) ) };
    like(
        $@, qr/IO control characters/i,
        "blocked: $label"
    );
}

# Verify that a normal relative path is NOT blocked by the check
{
    my $p = XML::Parser->new(
        NoLWP    => 1,
        Handlers => { Char => sub {} },
    );

    # This will fail to open (file doesn't exist), but it should NOT
    # trigger the IO control character error.
    eval { $p->parse( xml_with_entity_path('normal_entity_file.ent') ) };
    unlike(
        $@, qr/IO control characters/i,
        "normal path not blocked by IO control check"
    );
}
