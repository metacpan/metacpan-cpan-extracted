#!/usr/bin/env perl
# SUMMARY: Create a new bug on a Bugzilla instance (DRY RUN).
#
# NOTE: This script is a DRY RUN. It prints the bug data that would be
#       submitted but does NOT call the API. Uncomment the create call
#       to actually file a bug.
#
# USAGE:
#   BUGZILLA_API_KEY=xxx BUGZILLA_BASE_URL=https://bugs.freebsd.org \
#     perl examples/06-create-bug.pl
#
# EXAMPLES:
#   curl -X POST -H "X-BUGZILLA-API-KEY: $API_KEY" \
#     -H "Content-Type: application/json" \
#     -d '{"product":"Base System","component":"kern",...}' \
#     "https://bugs.freebsd.org/bugzilla/rest/bug"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);
use JSON::MaybeXS qw(encode_json);

my $bz = get_client(default_url => 'https://bugs.freebsd.org');

my %bug_data = (
    product     => 'Base System',
    component   => 'kern',
    version     => 'CURRENT',
    summary     => 'Test bug filed via WebService::Bugzilla API',
    description => 'This is a test bug filed via the Perl API client.'
                . ' Please close or ignore.',
    severity    => 'Test',
    op_sys      => 'Any',
    platform    => 'Any',
);

say "Would file a new bug with:";
for my $key (sort keys %bug_data) {
    say "  $key = $bug_data{$key}";
}

say "";
say "LIVE curl command:";
say "  curl -X POST \\";
say "    -H 'X-BUGZILLA-API-KEY: \$BUGZILLA_API_KEY' \\";
say "    -H 'Content-Type: application/json' \\";
say "    -d '", encode_json(\%bug_data), "' \\";
say "    'https://bugs.freebsd.org/bugzilla/rest/bug'";
say "";

# Uncomment to actually create the bug:
# my $new_bug = $bz->bug->create(%bug_data);
# say "Created bug #", $new_bug->id;
say "(dry run — no bug was filed)";
