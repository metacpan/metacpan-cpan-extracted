#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use Try::Tiny::Except;

sub _eval {
  local $@;
  local $Test::Builder::Level = $Test::Builder::Level + 2;
  return ( scalar(eval { $_[0]->(); 1 }), $@ );
}


sub lives_ok (&$) {
  my ( $code, $desc ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my ( $ok, $error ) = _eval($code);

  ok($ok, $desc );

  diag "error: $@" unless $ok;
}

sub throws_ok (&$$) {
  my ( $code, $regex, $desc ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my ( $ok, $error ) = _eval($code);

  if ( $ok ) {
    fail($desc);
  } else {
    like($error || '', $regex, $desc );
  }
}



throws_ok {
  local $Try::Tiny::Except::always_propagate=sub{/foo/};
  try {
    die "foo";
  };
} qr/foo/, "except w/o catch block";

throws_ok {
  local $Try::Tiny::Except::always_propagate=sub{/foo/};
  try {
    die "foo";
  } catch {die "bar"};
} qr/foo/, "except w/ catch block";



lives_ok {
  local $Try::Tiny::Except::always_propagate=sub{/foo/};
  try {
    die "bar";
  };
} "except w/o catch if \$always_propagate does not match";

throws_ok {
  local $Try::Tiny::Except::always_propagate=sub{/foo/};
  try {
    die "baz";
  } catch {die "bar"};
} qr/bar/, "except w/ catch if \$always_propagate does not match";


my $finally=0;
throws_ok {
  local $Try::Tiny::Except::always_propagate=sub{/foo/};
  try {
    die "foo";
  } finally {$finally++};
} qr/foo/, "except w/o catch w/ finally";
is $finally, 1, 'finally called';

throws_ok {
  local $Try::Tiny::Except::always_propagate=sub{/foo/};
  try {
    die "foo";
  } catch {die "bar"} finally {$finally++};
} qr/foo/, "except w/ catch w/ finally";
is $finally, 2, 'finally called';

done_testing;
