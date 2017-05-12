#!perl

use strict;
use warnings;

BEGIN { delete $ENV{PATH} }

use lib 't/lib';
use VPIT::TestHelpers 'capture';

use Test::More tests => 3;

use Test::Valgrind::FakeValgrind;

SKIP: {
 my ($stat, $out, $err) = capture_perl 'BEGIN { delete $ENV{PATH} } use Test::Valgrind; 1';
 skip CAPTURE_PERL_FAILED($out) => 1 unless defined $stat;
 like $out, qr/^1\.\.0 # (?:SKIP|Skip) Empty valgrind candidates list/,
            'correctly skip when no valgrind is available';
}

SKIP: {
 my $old_vg = Test::Valgrind::FakeValgrind->new(
  exe_name => 'valgrind',
  version  => '3.0.0',
 );
 skip $old_vg => 1 unless ref $old_vg;
 my $tmp_dir = $old_vg->dir;

 my ($stat, $out, $err) = capture_perl "BEGIN { \$ENV{PATH} = q[$tmp_dir] } use Test::Valgrind; 1";
 skip CAPTURE_PERL_FAILED($out) => 1 unless defined $stat;
 like $out, qr/^1\.\.0 # (?:SKIP|Skip) No appropriate valgrind executable could be found/, 'correctly skip when no good valgrind was found';
}

SKIP: {
 my $new_vg = Test::Valgrind::FakeValgrind->new(
  exe_name => 'valgrind',
  version  => '3.4.0',
 );
 skip $new_vg => 1 unless ref $new_vg;
 my $tmp_dir = $new_vg->dir;

 my ($stat, $out, $err) = capture_perl "BEGIN { \$ENV{PATH} = q[$tmp_dir] } use Test::Valgrind no_def_supp => 1, extra_supps => [ q[t/supp/no_perl] ]; 1";
 skip CAPTURE_PERL_FAILED($out) => 1 unless defined $stat;
 like $out, qr/^1\.\.0 # (?:SKIP|Skip) No compatible suppressions available/,
            'correctly skip when no compatible suppressions were available';
}
