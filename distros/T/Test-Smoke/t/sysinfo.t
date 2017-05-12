#! /usr/bin/perl -w
use strict;
$|++;

use Test::More tests => 57;
use Test::NoWarnings;
my $verbose = 0;

my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;

BEGIN { use_ok "Test::Smoke::SysInfo", qw( sysinfo tsuname ) }

ok defined &sysinfo, "sysinfo() imported";
ok defined &tsuname, "tsuname() imported";

{
    local $^O = 'Generic';
    my $si = Test::Smoke::SysInfo->new;

    isa_ok $si => 'Test::Smoke::SysInfo::Base';
    ok $si->cpu_type, $si->cpu_type;
    ok $si->cpu, $si->cpu;
    is $si->ncpu, '', "no ncpu";
    ok $si->os, $si->os;
    ok $si->host, $si->host;
}

{
    my $si = Test::Smoke::SysInfo->new;

    my ($counter, $expect) = (0, 4);

    isa_ok($si, 'Test::Smoke::SysInfo::Base');
    $counter += ok($si->cpu_type, "cpu_type: " . $si->cpu_type);
    $counter += ok($si->cpu,      "cpu: " . $si->cpu);
    SKIP: {
        $si->ncpu or skip "No #cpu code for this platform", 1;
        $counter += ok($si->ncpu,     "number of cpus: " . $si->ncpu);
        $expect++;
    }
    $counter += ok($si->os, $si->os);
    $counter += ok($si->host, $si->host);

    my $sysinfo = sysinfo();
    is join( " ", @{ $si }{map "_$_" => qw( host os cpu_type )} ),
       $sysinfo, "test sysinfo() $sysinfo";

    is($counter, $expect, "sysinfo: $sysinfo");
}

{
    my $si = Test::Smoke::SysInfo->new;
    isa_ok $si, 'Test::Smoke::SysInfo::Base';

    my $tsuname = join " ", map $si->$_ => qw(
        host os cpu ncpu cpu_type
    );
    is $si->tsuname(), $tsuname,       "tsuname()";
    is $si->tsuname(), $si->tsuname( 'a' ), "tsuname(a)";
    is $si->tsuname( 'rubbish' ), $tsuname, "tsuname( rubbish )";


    is $si->tsuname( 'n' ), $si->{_host},     "tsuname(n)";
    is $si->tsuname( 's' ), $si->{_os},       "tsuname(s)";
    is $si->tsuname( 'm' ), $si->{_cpu},      "tsuname(m)";
    is $si->tsuname( 'c' ), $si->{_ncpu},     "tsuname(c)";
    is $si->tsuname( 'p' ), $si->{_cpu_type}, "tsuname(p)";

    is $si->tsuname(qw( n s )), "$si->{_host} $si->{_os}", "tsuname(  n, s )";
    is $si->tsuname(qw( n s )), $si->tsuname( 'n s' ),
       "tsuname( 'n s' )";
    is $si->tsuname(qw( s n )), $si->tsuname( 'n s' ),
       "tsuname( 's n' )";

    is $si->tsuname(qw( n m )), "$si->{_host} $si->{_cpu}", "tsuname(  n, m )";
    is $si->tsuname(qw( n m )), $si->tsuname( 'n m' ),
       "tsuname( 'n m' )";
    is $si->tsuname(qw( m n )), $si->tsuname( 'n m' ),
       "tsuname( 'm n' )";

    is $si->tsuname(qw( n c )), "$si->{_host} $si->{_ncpu}",
       "tsuname(  n, c )";
    is $si->tsuname(qw( n c )), $si->tsuname( 'n c' ),
       "tsuname( 'n c' )";
    is $si->tsuname(qw( c n )), $si->tsuname( 'n c' ),
       "tsuname( 'c n' )";

    is $si->tsuname(qw( n p )), "$si->{_host} $si->{_cpu_type}",
       "tsuname(  n, p )";
    is $si->tsuname(qw( n p )), $si->tsuname( 'n p' ),
       "tsuname( 'n p' )";
    is $si->tsuname(qw( p n )), $si->tsuname( 'n p' ),
       "tsuname( 'p n' )";

    is $si->tsuname(qw( s m )), "$si->{_os} $si->{_cpu}",
       "tsuname(  s, m )";
    is $si->tsuname(qw( s m )), $si->tsuname( 's m' ),
       "tsuname( 's m' )";
    is $si->tsuname(qw( m s )), $si->tsuname( 's m' ),
       "tsuname( 'm s' )";

    is $si->tsuname(qw( s c )), "$si->{_os} $si->{_ncpu}",
       "tsuname(  s, c )";
    is $si->tsuname(qw( s c )), $si->tsuname( 's c' ),
       "tsuname( 's c' )";
    is $si->tsuname(qw( c s )), $si->tsuname( 's c' ),
       "tsuname( 'c s' )";

    is $si->tsuname(qw( s p )), "$si->{_os} $si->{_cpu_type}",
       "tsuname(  s, p )";
    is $si->tsuname(qw( s p )), $si->tsuname( 's p' ),
       "tsuname( 's p' )";
    is $si->tsuname(qw( p s )), $si->tsuname( 's p' ),
       "tsuname( 'p s' )";

    is $si->tsuname(qw( m c )), "$si->{_cpu} $si->{_ncpu}",
       "tsuname(  m, c )";
    is $si->tsuname(qw( m c )), $si->tsuname( 'm c' ),
       "tsuname( 'm c' )";
    is $si->tsuname(qw( c m )), $si->tsuname( 'm c' ),
       "tsuname( 'c m' )";

    is $si->tsuname(qw( m p )), "$si->{_cpu} $si->{_cpu_type}",
        "tsuname(  m, p )";
    is $si->tsuname(qw( m p )), $si->tsuname( 'm p' ),
       "tsuname( 'm p' )";
    is $si->tsuname(qw( p m )), $si->tsuname( 'm p' ),
       "tsuname( 'p m' )";

    is $si->tsuname(qw( c p )), "$si->{_ncpu} $si->{_cpu_type}",
       "tsuname(  c, p )";
    is $si->tsuname(qw( c p )), $si->tsuname( 'c p' ),
       "tsuname( 'c p' )";
    is $si->tsuname(qw( p c )), $si->tsuname( 'c p' ),
       "tsuname( 'c p' )";
}
