#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Text::FindLinks 'markup_links';

my $suite = <<"CUT";
{http://www.google.com/}            # simple URL
{ftp://ftp.gnome.org/}              # simple URL with FTP schema
{https://www.google.com/}           # simple URL with HTTPS schema
{www.google.com}                    # schema-less URL
{www.google.com/?q=foo}             # URL with GET params
See {www.google.com}, will you?     # URL ending with a comma
See {www.google.com}. And...        # URL ending with a period
Seen {www.goatse.cx}?!!!            # URL ending with a question sign
CUT

my @suite = split /\n/, $suite;
plan tests => scalar @suite;

sub test_decorator
{
    my $url = shift;
    return "{$url}";
}

for my $test (@suite)
{
    my ($expect, $label) = split(/\s*#\s*/, $test);
    (my $source = $expect) =~ s/[{}]//g;
    is markup_links(text => $source, handler => \&test_decorator), $expect, $label;
}

