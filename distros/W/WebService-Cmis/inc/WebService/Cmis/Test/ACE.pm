package WebService::Cmis::Test::ACE;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;

use Test::More;
use Error qw(:try);
use WebService::Cmis qw(:collections :utils :relations :namespaces :contenttypes);
use WebService::Cmis::ACE;

sub test_ACE_empty : Test(2) {
  my $this = shift;

  my $acl = new WebService::Cmis::ACE();
  ok(defined $acl);
  isa_ok($acl, 'WebService::Cmis::ACE');
}

sub test_ACE_create : Test(8) {
  my $this = shift;

  my $ace = new WebService::Cmis::ACE(
    principalId => 'jdoe',
    direct => 'true',
    permissions => 'cmis:write'
  );

  ok(defined $ace->{principalId});
  is($ace->{principalId}, 'jdoe');

  ok(defined $ace->{direct});
  is($ace->{direct}, 'true');

  ok(defined $ace->{permissions});
  is(ref($ace->{permissions}), 'ARRAY');
  is(scalar(@{$ace->{permissions}}), 1);
  is($ace->{permissions}[0], 'cmis:write');
}

1;
