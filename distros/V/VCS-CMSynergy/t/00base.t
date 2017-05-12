#!/usr/bin/perl

use Test::More tests => 8;
use strict;

BEGIN { use_ok('VCS::CMSynergy'); }
BEGIN { use_ok('VCS::CMSynergy::Client'); }

use Config;
use File::Spec;

# repeat sanity check from Makefile.PL
my $ccm_exe = File::Spec->catfile($ENV{CCM_HOME}, "bin", "ccm$Config{_exe}");
ok(-x $ccm_exe || ($^O eq 'cygwin' && -e $ccm_exe), q[sanity check (executable $CCM_HOME/bin/ccm)]);

# test VCS::CMSynergy::Client
my $client = VCS::CMSynergy::Client->new(
    CCM_HOME	=> $ENV{CCM_HOME},
    PrintError	=> 0,
    RaiseError	=> 1,
);

my ($ccm_addr, $web_mode);

isa_ok($client, "VCS::CMSynergy::Client");
is($client->ccm_home, $ENV{CCM_HOME}, q[CCM_HOMEs match]);


my $ps = $client->ps;
isa_ok($ps, "ARRAY", q[return value of ps()]);
ok((grep { $_->{process} eq "router" } @$ps) == 1, q[ps: found router]);
ok((grep { $_->{process} eq "objreg" } @$ps) > 0, q[ps: found object registrar(s)]);

exit 0;
