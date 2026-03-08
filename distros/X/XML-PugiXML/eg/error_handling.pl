#!/usr/bin/env perl
# Error handling patterns
use strict;
use warnings;
use XML::PugiXML;

my $doc = XML::PugiXML->new;

# Parse errors set $@
if (!$doc->load_string('<root><unclosed>')) {
    warn "Parse error: $@\n";
}

# File errors
if (!$doc->load_file('/nonexistent/path.xml')) {
    warn "File error: $@\n";
}

# Save errors
$doc->load_string('<root/>') or die $@;
if (!$doc->save_file('/nonexistent/dir/out.xml')) {
    warn "Save error: $@\n";
}

# XPath syntax errors throw exceptions
eval { $doc->select_node('[invalid xpath'); };
warn "XPath error: $@\n" if $@;

# Missing nodes return undef (not an error)
my $missing = $doc->root->child('nonexistent');
printf "Missing child: %s\n", defined $missing ? 'found' : 'undef';

my $missing_attr = $doc->root->attr('nope');
printf "Missing attr: %s\n", defined $missing_attr ? 'found' : 'undef';
