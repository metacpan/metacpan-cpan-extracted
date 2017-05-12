#!perl
# -*- coding: utf-8; -*-

use strict;
use warnings;

=head1 NAME

30-synopsis.t - Extracts the synopsis code from L<Test::Group>'s POD
documentation and runs it.

=cut

use Test::More tests => 15;  # Sorry, no_plan not portable for Perl 5.6.1!
use Test::Group;
use File::Spec;
use lib "t/lib";
use testlib;


my %snips = map { ( $_ => get_pod_snippet("synopsis-$_") ) }
    (qw(success fail die misc TODO));

# We already have a plan:
$snips{success} =~ s/(no_plan)/; # $1/;

# "/tmp/log" is not kosher in win32:
$snips{misc} =~ s|/tmp/log|File::Spec->devnull|ge;

# Instrument for test:
foreach (values %snips) {
  s/^\s*use Test::.*$//gm;
  s/^\s+test /\$results[scalar \@results] = tg_test_test /gm
      or die "Could not find any test in this snippet!";
}
my (@successes, @failures, @todos);
ok(eval <<"CODE"); die $@ if $@;
use Test::Group;

sub I_can_connect { 1 }
sub I_can_make_a_request { 1 }

my \@results;

$snips{success}
push(\@successes, \@results); \@results = ();

$snips{fail}
push(\@failures, \@results); \@results = ();

$snips{die}
push(\@failures, \@results); \@results = ();

$snips{TODO}
push(\@todos, \@results); \@results = ();

sub Network::available { 0 } # Curse France Telecom, arrrr!
$snips{misc}
push(\@successes, \@results); \@results = ();

1;
CODE

grep {
     my $success = $_;
     ok(! $success->is_failed, "success is_failed");
     ok($success->prints_OK, "success prints_OK");
} @successes;

grep {
     my $failure = $_;
     ok($failure->is_failed, "failure is_failed");
     ok(! $failure->prints_OK, "failure prints_OK");
} @failures;

grep {
     my $todo = $_;
     ok(! $todo->is_failed, "todo is_failed");
     ok(! $todo->prints_OK, "todo prints_OK");
} @todos;
