#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use FindBin '$Bin';
use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use constant TEST_COUNT => 20;
use Test::More tests => TEST_COUNT;
use EC2TestSupport;

$SIG{TERM} = $SIG{INT} = sub { exit 0 };  # run the termination

use constant GROUP => 'VM::EC2 Test Group';
use constant GROUP_DESCRIPTION => 'Test group created by VM::EC2; do not use!!';

# this script tests the security groups
my ($ec2);

use_ok('VM::EC2',':standard');
SKIP: {

skip "account information unavailable",TEST_COUNT-1 unless setup_environment();

$ec2 = VM::EC2->new(-region=>'us-east-1') or BAIL_OUT("Can't load VM::EC2 module");

# in case it was here from a previous invocation
$ec2->delete_security_group(-name=>GROUP);

$ec2->print_error(1);

my $g = $ec2->create_security_group(-name        => GROUP,
				    -description => GROUP_DESCRIPTION);
ok($g,'create_security_group');
is($g->groupName,GROUP,'created group name is correct');
is($g->groupDescription,GROUP_DESCRIPTION,'created group description is correct');
$g->add_tag(Role=>'VM::EC2 Testing');
my $gg = $ec2->describe_security_groups(-filter=>{'tag:Role'=>'VM::EC2 Testing'});
is ($g,$gg,'group tagging and retrieval');

# newly created groups should contain no permissions
my @perm = $g->ipPermissions;
is (scalar @perm,0,'firewall rules initially empty');

# let's add some
ok($g->authorize_incoming(-protocol=>'tcp',-port=>22,-source=>'any'),
   'authorize incoming using source "any"');
ok($g->authorize_incoming(-protocol=>'tcp',
			  -port=>'23..29',
			  -source=>['192.168.0.0/24','192.168.1.0/24']),
   'authorize incoming using a list of sources');
ok($g->authorize_incoming(-protocol=>'udp',
			  -port    => 'discard',
			  -groups  => [$g->groupId,'default','979382823631/default']),
   'authorize incoming using a list of groups');
@perm = $g->ipPermissions;
is (scalar @perm,0,"permissions don't change until update()");
ok($g->update,"update() successful");

@perm = $g->ipPermissions;
is(scalar @perm,3,"expected number of firewall rules defined");
@perm = sort @perm;
is($perm[0],'tcp(22..22) FROM CIDR 0.0.0.0/0','firewall rule one correct');
is($perm[1],'tcp(23..29) FROM CIDR 192.168.0.0/24,192.168.1.0/24','firewall rule two correct');
$gg = $ec2->describe_security_groups(-name=>'default');
my $from = join (',',sort ($gg->name,$g->name,'979382823631/default'));
is($perm[2],"udp(9..9) GRPNAME $from",'firewall rule three correct');

# try revoking
ok($g->revoke_incoming(-protocol=>'tcp',
		       -port    => '23..29',
		       -source=>['192.168.0.0/24','192.168.1.0/24']),
   'revoke with explicit rule');
ok($g->revoke_incoming($perm[0]),'revoke with IpPermissions object');
ok($g->update,'update with revocation');
@perm = sort $g->ipPermissions;
is(scalar @perm,1,'revoke worked');
is($perm[0],"udp(9..9) GRPNAME $from",'correct firewall rules revoked');
}

exit 0;


END {
    print STDERR "# deleting test security group...\n";
    $ec2->delete_security_group(-name=>GROUP)
	if $ec2;
}
