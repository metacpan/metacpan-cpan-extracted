#!perl -T

use strict;
use warnings;

BEGIN {
 if ("$]" >= 5.008_004 and "$]" <= 5.008_005) {
  require Test::More;
  Test::More::plan(skip_all
                       => 'goto may segfault randomly on perl 5.8.4 and 5.8.5');
 }
}

BEGIN { $ENV{PERL_TEST_LEANER_USES_TEST_MORE} = 1 }

use Test::Leaner;

BEGIN {
 my $loaded;
 if ($INC{'Test/More.pm'}) {
  $loaded = 1;
 } else {
  $loaded = 0;
  require Test::More;
  Test::More->import;
 }
 Test::More::plan(tests => 1 + 4 * 15 + 3 * 3 + 2 * 8);
 Test::More::is($loaded, 1, 'Test::More has been loaded');
}

use lib 't/lib';
use Test::Leaner::TestImport qw<
 get_subroutine has_test_more_version default_exports
>;

my $leaner_stash = \%Test::Leaner::;
my $more_stash   = \%Test::More::;
my $this_stash   = \%main::;

my @exported = default_exports;

for (@exported) {
 my $more_variant     = get_subroutine($more_stash, $_);

 my $leaner_variant   = get_subroutine($leaner_stash, $_);
 Test::More::ok(defined $leaner_variant,
                                       "Test::Leaner variant of $_ is defined");
 my $imported_variant = get_subroutine($this_stash, $_);
 Test::More::ok(defined $imported_variant, "imported variant of $_ is defined");

 SKIP: {
  Test::More::skip('Need leaner and imported variants to be defined' => 2)
                   unless defined $leaner_variant
                      and defined $imported_variant;

  if (defined $more_variant) {
   Test::More::is($leaner_variant, $more_variant,
                  "Test::Leaner variant of $_ is Test::More variant");
   Test::More::is($imported_variant, $more_variant,
                  "imported variant of $_ is Test::More variant");
  } else {
   Test::More::is($imported_variant, $leaner_variant,
                  "imported variant of $_ is Test::Leaner variant");
   {
    local $@;
    eval { $leaner_variant->() };
    Test::More::like($@, qr/^\Q$_\E is not implemented.*at \Q$0\E line \d+/,
                         "Test::Leaner of $_ variant croaks");
   }
  }
 }
}

my @only_in_test_leaner = qw<
 tap_stream
 diag_stream
 THREADSAFE
>;

for (@only_in_test_leaner) {
 Test::More::ok(exists $leaner_stash->{$_},
                "$_ still exists in Test::Leaner");
 Test::More::ok(!exists $more_stash->{$_},
                "$_ was not imported into Test::More");
 Test::More::ok(!exists $this_stash->{$_},
                "$_ was not imported into main");
}

SKIP:
{
 Test::More::skip('Test::More::plan exports stuff on Test::More <= 0.51'
                                 => 2 * 8) unless has_test_more_version('0.51');

 my @only_in_test_more = qw<
  use_ok
  require_ok
  can_ok
  isa_ok
  new_ok
  subtest
  explain
  todo_skip
 >;

 for (@only_in_test_more) {
  my $more_variant = get_subroutine($more_stash, $_);

  SKIP: {
   Test::More::skip("$_ is not implemented in this version of Test::More" => 2)
                    unless defined $more_variant;

   Test::More::ok(!exists $leaner_stash->{$_},
                  "$_ was not imported into Test::Leaner");
   Test::More::ok(!exists $this_stash->{$_},
                  "$_ was not imported into main");
  }
 }
}
