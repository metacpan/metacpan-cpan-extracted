#!/usr/bin/env perl
# SUMMARY: Fetch public server information from bugs.freebsd.org — no API key needed.
#
# USAGE:
#   perl examples/11-server-info.pl
#   (URL can be overridden with --url or BUGZILLA_BASE_URL)
#
# EXAMPLES:
#   curl -s "https://bugs.freebsd.org/bugzilla/rest/version"
#   curl -s "https://bugs.freebsd.org/bugzilla/rest/time"
#   curl -s "https://bugs.freebsd.org/bugzilla/rest/timezones"
#   curl -s "https://bugs.freebsd.org/bugzilla/rest/extensions"
#   curl -s "https://bugs.freebsd.org/bugzilla/rest/jobqueue_status"

use v5.24;
use strict;
use warnings;

use lib 'lib', 't/lib';
use Bugzilla::Examples qw(get_client);

my $bz = get_client(default_url => 'https://bugs.freebsd.org');

print "=== Bugzilla Server Info ===\n\n";

print "=== Version ===\n";
my $v = $bz->information->server_version;
for my $k (sort keys %$v) {
    print "  $k: $v->{$k}\n";
}

print "\n=== Time ===\n";
my $t = $bz->information->server_time;
for my $k (sort keys %$t) {
    my $val = $t->{$k};
    $val = $$val if ref($val) eq 'SCALAR';
    print "  $k: $val\n";
}

print "\n=== Timezones ===\n";
my $tz = $bz->information->server_timezones;
if ($tz && %$tz) {
    for my $k (sort keys %$tz) {
        my $val = $tz->{$k};
        $val = $$val if ref($val) eq 'SCALAR';
        print "  $k: $val\n";
    }
} else {
    print "  (not available on this Bugzilla version)\n";
}

print "\n=== Extensions ===\n";
my $ext = $bz->information->server_extensions;
$ext = $ext->{extensions} if ref($ext) eq 'HASH' && exists $ext->{extensions};
if ($ext && %$ext) {
    for my $name (sort keys %$ext) {
        my $e = $ext->{$name};
        print "  $name  v$e->{version}\n";
    }
} else {
    print "  (none)\n";
}

print "\n=== Jobqueue Status ===\n";
my $jq = $bz->information->server_jobqueue_status;
if ($jq && %$jq) {
    for my $k (sort keys %$jq) {
        my $val = $jq->{$k};
        $val = $$val if ref($val) eq 'SCALAR';
        print "  $k: $val\n";
    }
} else {
    print "  (not available on this Bugzilla version)\n";
}

print "\nDone.\n";
