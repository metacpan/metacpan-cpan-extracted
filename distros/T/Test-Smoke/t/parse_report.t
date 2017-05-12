#! /usr/bin/perl -w
use strict;

# $Id$

use Test::More;

my @eg;
BEGIN {
    @eg  = (
        { plevel => 19000, os => 'linux', osvers => '2.4.18-4g',
          arch => 'i686/1 cpu', sum => 'PASS', version => '5.00504' },
        { plevel => 19001, os => 'MSWin32', osvers => '5.',
          arch => 'x86/1 cpu', sum => 'PASS', version => '5.9.0' },
        { plevel => 19002, os => 'aix', osvers => '4.3.1.0',
          arch => 'PPC_64/8 cpus', sum => 'PASS', version => '5.9.0' },
        { plevel => 19003, os => 'linux', osvers => '2.4.20-1jv.7.x',
          arch => 'i686/1 cpu', sum => 'PASS', version => '5.9.0' },
        { plevel => 19004, os => 'dec_osf', osvers => '5.1a',
          arch => 'alpha/1 cpu', sum => 'FAIL(F)', version => '5.9.0' },
        { plevel => 19005, os => 'linux', osvers => '2.4.23-sparc-r1 [gentoo]',
          arch => 'sparc64/1 cpu', sum => 'FAIL(F)', version => '5.8.3',
          cpu => 'TI UltraSparc I (SpitFire)' },
        { plevel => 19006, os => 'netbsd', osvers => '1.5',
          arch => 'i386/1 cpu', sum => 'FAIL(F)', version => '5.8.3',
          ccvers => 'egcs-2.91.66 19990314 (egcs-1.1.2 release)',
          cpu => 'Intel Pentium II (Deschutes) (686-class)' },
        { plevel => 19007, os => 'solaris', osvers => '2.9',
          arch => 'sparc-LP64/1 cpu', sum => 'FAIL(F)', version => '5.8.3',
          cpu => 'UltraSPARC-IIe (502MHz)' },
        { plevel => 19008, os => 'linux', osvers => '2.4.21-1 [redhat]',
          arch => 'i686/1 cpu', sum => 'FAIL(F)', version => '5.8.3',
          cpu => 'Pentium III (Coppermine) (GenuineIntel 731MHz)' },
        { plevel => 19009, os => 'AIX 5.1.0.0/ML04/32', osvers => '',
          arch => 'PPC/32/1 cpu', sum => 'FAIL(F)', version => '5.8.3',
          cpu => 'PPC_604' },
    );
    plan tests => 1 + @eg;
}

BEGIN { use_ok( 'Test::Smoke::Util', 'parse_report_Config' ); }

foreach my $eg ( @eg ) {
    my $ccvers = $eg->{ccvers} || 42;
    my $cpu = $eg->{cpu} || 'A very long(R) archstring(C) (999MHz)';
    my $os_info = $eg->{os} || 'unknown';
    $os_info .= " - $eg->{osvers}" if $eg->{osvers};
    my $report = <<__EOR__;
Automated smoke report for $eg->{version} patch $eg->{plevel}
host: $cpu ($eg->{arch})
    on        $eg->{os} - $eg->{osvers}
    using     cc version $ccvers
    smoketime 42 minutes 42 seconds

Summary: $eg->{sum}
__EOR__

    my %conf;

    @conf{qw( version plevel os osvers arch sum ) } = 
        parse_report_Config( $report );
    $conf{ccvers} = $ccvers if $eg->{ccvers};
    $conf{cpu} = $cpu if $eg->{cpu};
    my $subject = "Smoke [$eg->{version}] $eg->{plevel} $eg->{sum} $eg->{os}" .
                  " $eg->{osvers} ($eg->{arch})";
    is_deeply( \%conf, $eg, $subject );
}
