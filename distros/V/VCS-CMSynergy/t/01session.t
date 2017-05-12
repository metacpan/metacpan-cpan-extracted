#!/usr/bin/perl

use Test::More $ENV{CCM_TEST_DB} 
    ? ( tests => 21 )
    : ( skip_all => "no test database specified (set CCM_TEST_DB)" );
use t::util;
use strict;

BEGIN { use_ok('VCS::CMSynergy'); }

use Config;
use File::Spec;
use IPC::Run3;

my ($ccm_addr, $web_mode);

{
    # create a new Synergy session
    my $ccm = VCS::CMSynergy->new(%::test_session);
    isa_ok($ccm, "VCS::CMSynergy");
    diag("using coprocess") if defined $ccm->{coprocess};
    $ccm_addr = $ccm->ccm_addr;
    $web_mode = $ccm->web_mode;

    # new session should show up in `ccm ps'
    my $ps = VCS::CMSynergy->ps(rfc_address => $ccm_addr);
    is(@$ps, 1, 
       qq[ps(rfc_address => $ccm_addr) is array of length 1]);
    is($ps->[0]->{database}, $ccm->database,
       q[database gleaned from ps should match that from session]);

    # create another session object reusing the Synergy session
    my $ccm2 = VCS::CMSynergy->new(CCM_ADDR => $ccm_addr);
    isa_ok($ccm2, "VCS::CMSynergy");
    is($ccm2->ccm_addr, $ccm_addr, 
       qq[re-used session has same CCM_ADDR as original session $ccm_addr]);

    # destroy session object 
    $ccm2 = undef;

    # check that the Synergy session is still there
    # Note: When using web mode there's a lag between "ccm stop" exiting and
    # the session disappearing from "ccm ps"
    sleep(5) if $web_mode;
    ok(@{ VCS::CMSynergy->ps(rfc_address => $ccm_addr) } > 0,
       qq[original session $ccm_addr is still registered]);

    # $ccm goes out of scope and session should be stopped
}

# session should no longer show up in `ccm ps'
sleep(5) if $web_mode;
ok(@{ VCS::CMSynergy->ps(rfc_address => $ccm_addr) } == 0,
   qq[original session $ccm_addr is not registered any more]);

# test that VCS::CMSynergy::DESTROY doesn't mangle script's exit() value
{
    my @exit_check = (
	$^X, "-Mblib", "-MVCS::CMSynergy", "-e",
	q[my $ccm = VCS::CMSynergy->new(@ARGV); print $ccm->ccm_addr; exit(42);], 
	%::test_session);
    my ($out, $err);
    local $?;
    run3(\@exit_check, \undef, \$out, \$err, 
	{ binmode_stdout => 1, binmode_stderr => 1 });
    my $rc = $?;
    is($rc >> 8, 42, q[exit() value preserved]);

    sleep(5) if $web_mode;
    ok(@{ VCS::CMSynergy->ps(rfc_address => $out) } == 0,
       qq[session $out is not registered any more]);
}

{
    # create a new Synergy session with KeepSession on
    my $ccm = VCS::CMSynergy->new(%::test_session, KeepSession => 1);
    isa_ok($ccm, "VCS::CMSynergy");
    $ccm_addr = $ccm->ccm_addr;
    ok(@{ VCS::CMSynergy->ps(rfc_address => $ccm_addr) } > 0,
       qq[new session $ccm_addr with KeepSession "on" is registered]);

    # destroy session object
    $ccm = undef;

    # check that the Synergy session is still there
    sleep(5) if $web_mode;
    ok(@{ VCS::CMSynergy->ps(rfc_address => $ccm_addr) } > 0,
       qq[session $ccm_addr is still registered]);

    # create another session object reusing the Synergy session
    my $ccm2 = VCS::CMSynergy->new(CCM_ADDR => $ccm_addr);
    isa_ok($ccm2, "VCS::CMSynergy");
    is($ccm2->ccm_addr, $ccm_addr, 
       qq[attached session has same CCM_ADDR as original session $ccm_addr]);

    # destroy session object 
    $ccm2 = undef;

    # check that the Synergy session is still there
    sleep(5) if $web_mode;
    ok(@{ VCS::CMSynergy->ps(rfc_address => $ccm_addr) } > 0,
       qq[original session $ccm_addr is still registered]);
    # destroy it and check that the Synergy session is still there

    # create another session object reusing the Synergy session,
    # but with KeepSession off
    my $ccm3 = VCS::CMSynergy->new(CCM_ADDR => $ccm_addr, KeepSession => 0);
    isa_ok($ccm3, "VCS::CMSynergy");
    is($ccm3->ccm_addr, $ccm_addr, 
       qq[attached session has same CCM_ADDR as original session $ccm_addr]);

    # $ccm3 goes out of scope and session should be stopped
}

# session should no longer show up in `ccm ps'
sleep(5) if $web_mode;
ok(@{ VCS::CMSynergy->ps(rfc_address => $ccm_addr) } == 0,
   qq[original session $ccm_addr is not registered any more]);

# create session using VCS::CMSynergy::Client::start()
my $client = VCS::CMSynergy::Client->new(
    CCM_HOME	=> $::test_session{CCM_HOME},
    PrintError	=> $::test_session{PrintError},
    RaiseError	=> $::test_session{RaiseError},
);

delete @::test_session{qw(CCM_HOME PrintError RaiseError)};
my $ccm_from_client = $client->start(%::test_session);
isa_ok($ccm_from_client, "VCS::CMSynergy");
ok(@{ $client->ps(rfc_address => $ccm_from_client->ccm_addr) } > 0,
   q[session from VCS::CMSynergy::Client::start is registered]);

exit 0;
