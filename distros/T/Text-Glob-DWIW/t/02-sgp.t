#! /usr/bin/perl -Tw
use warnings; use strict;
use Test::More tests => 28;                  BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};


#test pattern partly borrowed from String::Glob::Permute tests
use Text::Glob::DWIW 'tg_expand';

{ my $pattern = "host{foo,bar}[2-4]"; # orignat style
  my @hosts = tg_expand( $pattern );
  is($hosts[0], "hostfoo2");
  is($hosts[3], "hostbar2"); # 1
  is($hosts[1], "hostfoo3"); # 2
  is($hosts[4], "hostbar3"); # 3
  is($hosts[2], "hostfoo4"); # 4
  is($hosts[5], "hostbar4");
  is(scalar @hosts, 6);
}

my $sec='sgp'; my $p;

is_deeply [tg_expand $p='host{foo,bar}[2-4]'],
          [qw'hostfoo2 hostfoo3 hostfoo4 hostbar2 hostbar3 hostbar4'], "$sec: $p";
#$pattern = "host{1-3,5,10}"; # "host[1-3,5,10]";
is_deeply [tg_expand $p='host{1-3,5,10}'],[qw'host1 host2 host3 host5 host10'],"$sec: $p";
#is($hosts[0], "host1");
#is($hosts[4], "host10");
is_deeply [tg_expand $p='host[1-3]',{mell=>1}],[qw'host1 host2 host3'],"$sec: $p (mell=1)";
is_deeply [tg_expand $p='host[123]',{mell=>1}],[qw'host1 host2 host3'],"$sec: $p (mell=1)";
is_deeply [tg_expand $p='host[1-3,5]',{mell=>1}],[qw'host1 host2 host3 host5'],"$sec: $p (mell=1)";
is_deeply [tg_expand $p='host[1-3,59]',{mell=>1}],
          [qw'host1 host2 host3 host5 host9'],"$sec: $p (mell=1)";
is_deeply [tg_expand $p='host[9-11]',{mell=>1}],[qw'host9 host10 host11'],"$sec: $p (mell=1)";
is_deeply [tg_expand $p='host[123,9-11]',{mell=>1}],
          [qw'host1 host2 host3 host9 host10 host11'],"$sec: $p (mell=1)";
is_deeply [tg_expand $p='host[1-3,9-11]',{mell=>1}],
          [qw'host1 host2 host3 host9 host10 host11'],"$sec: $p (mell=1)";

is_deeply [tg_expand $p='host[1-359]'],[qw'host1 host2 host3 host5 host9'],"$sec: $p"; # +
is_deeply [tg_expand $p='host[13-59]'],[qw'host1 host3 host4 host5 host9'],"$sec: $p"; # +
is_deeply [tg_expand $p='host[137-9]'],[qw'host1 host3 host7 host8 host9'],"$sec: $p"; # +

is_deeply [tg_expand $p="host{08-09,10}"],[qw'host08 host09 host10'],"$sec: $p";
is_deeply [tg_expand $p="host{08,09-10}"],[qw'host08 host09 host10'],"$sec: $p"; # +
is_deeply [tg_expand $p="host{08-10}"],   [qw'host08 host09 host10'],"$sec: $p"; # +
#@hosts = tg_expand( "host{08-09,10}" ); #"host[08-09,10]"
#is($hosts[0], "host08");
#is($hosts[1], "host09");
#is($hosts[2], "host10");

is_deeply [tg_expand $p="host{8-9,10}"],    [qw'host8 host9 host10'],"$sec: $p";
is_deeply [tg_expand $p="host{8,9-10}"],    [qw'host8 host9 host10'],"$sec: $p"; # +
is_deeply [tg_expand $p="host{8-10}"],      [qw'host8 host9 host10'],"$sec: $p"; # +
is_deeply [tg_expand $p="host{[89],10}"],   [qw'host8 host9 host10'],"$sec: $p"; # +
is_deeply [tg_expand $p="host{[89],10-10}"],[qw'host8 host9 host10'],"$sec: $p"; # +

had_no_warnings();