#!/usr/bin/perl

# Regression test for GitHub issue #234:
# Parameter entity references must be routed to the Default handler when
# no declaration handlers are set and ParseParamEnt is not enabled.
# This is the pattern XML::Twig relies on for DTD round-tripping.
#
# Also verifies that declaration handlers still work correctly with PEs
# (the fix for GH #53) by checking that implicit PE parsing activation
# via declaration handler registration routes subsequent declarations to
# their dedicated handlers rather than the Default handler.

use strict;
use warnings;

use Test::More tests => 13;
use XML::Parser;

# DTD pattern from XML::Twig's failing test case (GH #234)
my $xml_with_pe = <<'EOF';
<!DOCTYPE doc [
<!ENTITY % bar1 PUBLIC "toto1" "tata1">
%bar1;
<!ENTITY bar2 PUBLIC "toto2" "tata2">
]>
<doc/>
EOF

# Test 1-3: Without declaration handlers, PE references go to Default handler
{
    my @default_strings;

    my $p = XML::Parser->new(
        Handlers => {
            Default => sub { push @default_strings, $_[1] },
        },
    );

    $p->parse($xml_with_pe);

    my $default_text = join('', @default_strings);
    like($default_text, qr/%bar1;/,
        'No decl handlers: PE reference %bar1; appears in Default handler output');
    like($default_text, qr/<!ENTITY % bar1/,
        'No decl handlers: PE declaration appears in Default handler output');
    like($default_text, qr/<!ENTITY bar2/,
        'No decl handlers: subsequent entity declaration appears in Default handler output');
}

# Test 4-7: With Entity declaration handler, PE reference text is still routed
# to the Default handler (for DTD round-tripping), while subsequent declarations
# fire their dedicated handlers (GH #53)
{
    my @entity_decls;
    my @default_strings;

    my $p = XML::Parser->new(
        NoExpand => 1,
        Handlers => {
            Entity  => sub {
                my ($xp, $name, $val, $sysid, $pubid, $notation, $isparam) = @_;
                push @entity_decls, { name => $name, isparam => $isparam };
            },
            Default => sub { push @default_strings, $_[1] },
        },
    );

    $p->parse($xml_with_pe);

    my @param_ents = grep { $_->{isparam} } @entity_decls;
    ok(scalar @param_ents >= 1,
        'With Entity handler: PE declaration handler fired for %bar1');

    my @regular_ents = grep { !$_->{isparam} && $_->{name} eq 'bar2' } @entity_decls;
    is(scalar @regular_ents, 1,
        'With Entity handler: bar2 entity routed to Entity handler (not Default)');

    my $default_text = join('', @default_strings);
    unlike($default_text, qr/<!ENTITY bar2/,
        'With Entity handler: bar2 declaration not in Default handler output');

    like($default_text, qr/%bar1;/,
        'With Entity handler: PE reference %bar1; still in Default handler output');
}

# Test 7-8: With Attlist declaration handler, PE is consumed and subsequent
# ATTLIST declarations fire their dedicated handler
{
    my $xml_pe_attlist = <<'EOF';
<!DOCTYPE mytype [
<!ENTITY % common SYSTEM "common.txt">
%common;
<!ATTLIST mytype foo CDATA "bar">
]>
<mytype foo="bar"/>
EOF

    my @attlist_calls;
    my @default_strings;

    my $p = XML::Parser->new(
        NoExpand => 1,
        Handlers => {
            Attlist => sub {
                my ($xp, $elname, $attname, $type, $default, $fixed) = @_;
                push @attlist_calls, { elname => $elname, attname => $attname };
            },
            Default => sub { push @default_strings, $_[1] },
        },
    );

    $p->parse($xml_pe_attlist);

    is(scalar @attlist_calls, 1,
        'With Attlist handler: ATTLIST fired after PE reference');
    is($attlist_calls[0]{attname}, 'foo',
        'With Attlist handler: correct attribute name');
}

# Test 10-11: XML::Twig DTD round-trip pattern (from xmltwig t/test_3_30.t tests 59-61)
# Default handler must reproduce the full DTD including PE declarations,
# PE references, and subsequent entity declarations as literal text.
{
    my $xml_twig_doc = q{<!DOCTYPE foo [<!ENTITY % bar1 PUBLIC "toto1" "tata1">%bar1;<!ENTITY bar2 PUBLIC "toto2" "tata2">%bar2;]><d><elt/></d>};

    my @default_strings;
    my @element_parts;

    my $p = XML::Parser->new(
        Handlers => {
            Default => sub { push @default_strings, $_[1] },
            Start   => sub { shift; push @element_parts, "<$_[0]>" },
            End     => sub { shift; push @element_parts, "</$_[0]>" },
            Char    => sub { },  # suppress
        },
    );

    $p->parse($xml_twig_doc);

    my $default_text = join('', @default_strings);
    like($default_text, qr/<!ENTITY % bar1 PUBLIC "toto1" "tata1"/,
        'XML::Twig round-trip (no Entity handler): PE declaration preserved in Default');
    like($default_text, qr/%bar1;/,
        'XML::Twig round-trip (no Entity handler): PE reference preserved in Default');
}

# Test 12-13: XML::Twig pattern WITH Entity handler (the actual XML::Twig code path).
# XML::Twig registers Entity + Default handlers. PE references must still appear
# in Default handler output for DTD round-tripping, even though pe_implicit is set.
{
    my $xml_twig_doc = q{<!DOCTYPE foo [<!ENTITY % bar1 PUBLIC "toto1" "tata1">%bar1;<!ENTITY bar2 PUBLIC "toto2" "tata2">%bar2;]><d><elt/></d>};

    my @default_strings;
    my @entity_decls;

    my $p = XML::Parser->new(
        Handlers => {
            Entity  => sub {
                my ($xp, $name, $val, $sysid, $pubid, $notation, $isparam) = @_;
                push @entity_decls, $name;
            },
            Default => sub { push @default_strings, $_[1] },
            Start   => sub { },
            End     => sub { },
        },
    );

    $p->parse($xml_twig_doc);

    my $default_text = join('', @default_strings);
    like($default_text, qr/%bar1;/,
        'XML::Twig round-trip (with Entity handler): PE reference preserved in Default');
    ok(scalar(grep { $_ eq 'bar2' } @entity_decls),
        'XML::Twig round-trip (with Entity handler): bar2 routed to Entity handler');
}
