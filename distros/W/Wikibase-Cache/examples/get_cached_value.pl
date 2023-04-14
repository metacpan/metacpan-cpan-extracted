#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Cache;

if (@ARGV < 1) {
        print STDERR "Usage: $0 qid_or_pid\n";
        exit 1;
}
my $qid_or_pid = $ARGV[0];

# Object.
my $obj = Wikibase::Cache->new;

# Get translated QID.
my $translated_qid_or_pid = $obj->get('label', $qid_or_pid) || $qid_or_pid;

# Print out.
print $translated_qid_or_pid."\n";

# Output for nothing:
# Usage: ./get_cached_value.pl qid_or_pid

# Output for 'P31':
# instance of

# Output for 'Q42':
# Q42