use strict;
use Test;

# Test a basic use statement

BEGIN { plan tests => 2 };
use VMware::API::LabManager;
ok(1);

# Test loading the module

my $labman = new VMware::API::LabManager (
  qw/username password localhost orgname workspace/
);

ok(defined $labman);
