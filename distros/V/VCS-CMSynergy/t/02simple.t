#!/usr/bin/perl -w

use Test::More $ENV{CCM_TEST_DB} 
    ? ( tests => 4 )
    : ( skip_all => "no test database specified (set CCM_TEST_DB)" );
use t::util;
use strict;

BEGIN 
{ 
    use_ok('VCS::CMSynergy', ':cached_attributes'); 
    ok(VCS::CMSynergy::use_cached_attributes(), q[using :cached_attributes]);
}


my $ccm = VCS::CMSynergy->new(%::test_session);
isa_ok($ccm, "VCS::CMSynergy");

$ccm->{RaiseError} = 0;

my $got = $ccm->query_object([ type => "project" ], qw( status ));
ok($got, "got any projects?");
my $ngot = @$got;
diag("your database contains $ngot project versions...");

my %status;
$status{ $_->get_attribute("status") }++ foreach @$got;
diag("  $status{$_} with status $_") foreach sort keys %status;

exit 0;

