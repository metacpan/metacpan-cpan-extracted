#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:Admin/Group.pm
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

use Test::More tests => 84;

BEGIN {
    use_ok('Tivoli::AccessManager::Admin');
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd = Tivoli::AccessManager::Admin->new(password => $pswd);
my ($resp,@groups,@names,@dns,@temp);

print "\nTESTING creation\n";
$resp = Tivoli::AccessManager::Admin::Group->create($pd, name => 'lgroup00',
				    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
				    cn => 'lgroup00',
				   );
is($resp->isok, 1, "Created lgroup00") or diag($resp->messages);
push @groups, scalar($resp->value);
push @names, 'lgroup00';
push @dns, 'cn=lgroup00,ou=groups,o=me,c=us';

$resp = Tivoli::AccessManager::Admin::Group->create($pd, name => 'lgroup00',
				    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
				    cn => 'lgroup00',
				   );
is($resp->iswarning, 1, "Couldn't create it again") or diag($resp->messages);

my $goo = Tivoli::AccessManager::Admin::Group->new($pd,
						    name => $groups[0]->name,
						  );
is($goo->exist,1,"Loaded an existing group");

for my $i (1 .. 3) {
    my $name = sprintf "lgroup%02d", $i;
    $groups[$i] = Tivoli::AccessManager::Admin::Group->new($pd, 
					  name => $name,
					  dn => "cn=$name,ou=groups,o=me,c=us",
					  cn => $name
				     );
    $resp = $groups[$i]->create();
    is($resp->isok, 1, "Created $name") or diag($resp->messages);
    push @names, $name;
    push @dns, "cn=$name,ou=groups,o=me,c=us";
}

@names = sort @names;

$resp = Tivoli::AccessManager::Admin::ProtObject->create($pd, 
							 name => "/test/foo",
							 description => 'hold me',
							 type => 11
							);
SKIP: {
    skip "Could not create test container",2 unless $resp->isok;
    my $protobj = $resp->value;

    $resp = Tivoli::AccessManager::Admin::Group->create($pd, 
				    name => 'lgroupnn',
				    dn => 'cn=lgroupnn,ou=groups,o=me,c=us',
				    cn => 'lgroupnn',
				    container => '/test/foo',
				   );
    is($resp->isok, 1, "Created group in a container");
    $goo = $resp->value;

    $goo->delete;
    $resp = $goo->groupimport(container=>'/test/foo');
    is($resp->isok, 1, "Imported group into a container");

    $goo->delete(1);

    $protobj->delete;
}

print "\nTESTING info\n";

$resp = $groups[0]->description;
is($resp->value,'','No description yet');

$resp = $groups[0]->description(description => 'Group of lusers');
is($resp->value, 'Group of lusers', "Set description");

$resp = $groups[0]->description('The next group of lusers');
is($resp->value,'The next group of lusers','Set the description w/o a hash');

$resp = $groups[0]->description;
is($resp->value,'The next group of lusers','Call w/no parameters worked');

$resp = $groups[0]->description(sillbastard => 'Some descriptive description');
is($resp->value,'The next group of lusers','Call with a silly hash was ignored');

is($resp->value,'The next group of lusers','Call w/no parameters worked');

$resp = $groups[0]->cn;
is($resp->value, 'lgroup00', "Got cn");

$resp = $groups[0]->dn;
is($resp->value, 'cn=lgroup00,ou=groups,o=me,c=us', "Got dn");

$resp = $groups[0]->exist;
is($resp, 1, "Verified the group exists");

print "\nTESTING list\n";
$resp = Tivoli::AccessManager::Admin::Group->list($pd, pattern => 'lgroup*');
is_deeply([$resp->value],\@names, "Found the groups by name as a Class method") or diag($resp->messages);

$resp = $groups[0]->list(pattern => 'lgroup*');
is_deeply([$resp->value], \@names, "Found the groups by name as an instance method") or diag($resp->messages);

$resp = $groups[0]->list(pattern => 'lgroup*', maxreturn => 100);
is_deeply([$resp->value], \@names, "Found the groups by name using maxreturn") or diag($resp->messages);

$resp = Tivoli::AccessManager::Admin::Group->list($pd, pattern => 'lgroup*', bydn => 1);
is_deeply([$resp->value], \@dns, "Found the groups by DN as a Class method") or diag($resp->messages);

$resp = $groups[0]->list(pattern => 'lgroup*', bydn => 1);
is_deeply([$resp->value], \@dns, "Found the groups by DN as an instance method") or diag($resp->messages);

$resp = $groups[0]->list();
is($resp->isok, 1, 'Searched with no parameters');
ok($resp->value > @names, 'Found more groups than we created -- that is good');

my $group = $groups[0];

print "\nTESTING membership\n";
my (@users,@who);
for my $i (0 .. 4) {
    my $name = sprintf "luser%02d", $i;

    $resp = Tivoli::AccessManager::Admin::User->create($pd, 
				       name     => $name,
				       dn       => "cn=$name,ou=users,o=me,c=us",
				       password => "Pa\$\$w0rd",
				       cn       => $name,
				       sn       => sprintf "%02d", $i);
    if ($resp->isok) {
	push @users, $resp->value;
	push @who, $name;
    }
}

$resp = $group->members(add => \@who);
is_deeply([$resp->value], \@who, "Added some users") or diag($resp->messages, Dumper($resp->value, \@who));

$resp = $group->members();
is_deeply([$resp->value], \@who, "members w/no parameters gave me the list") or diag($resp->messages), Dumper($resp->value, \@who);

$resp = $group->members(add => \@who);
is($resp->iswarning , 1, "Couldn't add them again") or diag($resp->messages);

$resp = $group->members(add => \@who, force => 1);
is($resp->iswarning , 1, "Forced the issue with warning") or diag($resp->messages);

$resp = $group->members(add => 'luser04');
is($resp->isok, 0, "Bad syntax for adding") or diag($resp->messages);

$resp = $group->members(remove => [qw/luser00 luser01 luser03/]);
is_deeply([$resp->value], [qw/luser02 luser04/], "Removed some users") or diag($resp->messages), Dumper($resp->value, \@who);

$resp = $group->members(add => [qw/luser02 luser00/], force => 1);
is_deeply([$resp->value], [qw/luser00 luser02 luser04/], "Add some users user back with overlap") 
    or diag($resp->messages), Dumper($resp->value, \@who);

$resp = $group->members(remove => [ qw/luser03 luser04/ ] );
is($resp->isok, 0, "Attempted to remove a user not in the group") or diag($resp->messages);

$resp = $group->members(remove => [ qw/luser00 luser03 luser04/ ], force => 1);
is_deeply([$resp->value], [qw/luser02/], "Forced the attempt") or diag($resp->messages, Dumper($resp->value, \@who));

$resp = $group->members(remove => [ qw/luser02/ ],
			 add    => \@who);
is_deeply([$resp->value], \@who, "Removed them all and added them again") or diag($resp->messages, Dumper($resp->value, \@who));

$resp = $group->members(remove => [ qw/sec_master/ ], force => 1);
is($resp->iswarning, 1, "Properly trapped no users to remove error") or diag($resp->messages);

$resp = $group->members(remove => 'luser04');
is($resp->isok, 0, "Bad syntax for remove") or diag(Dumper($resp));

print "\nTESTING import\n";
$resp = $group->delete(silly=>1);
is($resp->isok, 1, "Deleted lgroup00 (while ignoring a silly flag)") or diag($resp->messages);

$resp = $group->groupimport();
is($resp->isok, 1, "Imported lgroup00") or diag($resp->messages);

$resp = $group->dn;
is($resp->value, 'cn=lgroup00,ou=groups,o=me,c=us', "Imported group is valid");

$resp = $group->delete;
$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
				    cn => 'lgroup00',
				   );
$resp = $group->groupimport(name => 'lgroup00');
is($resp->isok, 1, "Imported lgroup00 by passing name to groupimport") or diag($resp->messages);
$resp = $group->dn;
is($resp->value, 'cn=lgroup00,ou=groups,o=me,c=us', "Imported group is valid");

$resp = $group->delete;

$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    name => 'lgroup00',
				    cn => 'lgroup00',
				   );
$resp = $group->groupimport(dn => 'cn=lgroup00,ou=groups,o=me,c=us');
is($resp->isok, 1, "Imported lgroup00 by passing dn to groupimport") or diag($resp->messages);
$resp = $group->dn;
is($resp->value, 'cn=lgroup00,ou=groups,o=me,c=us', "Imported group is valid");

$groups[0] = $group;

print "\nTESTING delete\n";

for my $grp (@groups) {
    $resp = $grp->delete(1);
    is($resp->isok, 1, "Deleted " . $grp->name) or diag($resp->messages);
}

$resp = $groups[0]->delete(1);
is($resp->isok, 0, "Couldn't delete a group that doesn't exist") or diag($resp->messages);

$resp = $groups[0]->description;
is($resp->isok, 0, "Couldn't get its description, either") or diag($resp->messages);

for my $user (@users) {
    $resp = $user->delete(1);
    unless ($resp->isok) {
	warn "Couldn't delete " . $user->name . $resp->messages;
    }
}

print "\nTESTING group create in strange and unusual ways\n";
$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
				    cn => 'lgroup00',
				   );
$resp = $group->create(name => 'lgroup00');
is($resp->isok, 1, "Created lgroup00 by passing name in create") or diag($resp->messages);
$resp = $group->delete(1);

$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    cn => 'lgroup00',
				   );
$resp = $group->dn;
is($resp->isok,0,'Could not get the DN back out');

$resp = $group->create(name => 'lgroup00',
		       dn => 'cn=lgroup00,ou=groups,o=me,c=us' 
		   );
is($resp->isok, 1, "Created lgroup00 by passing name and dn to create") or diag($resp->messages);
$resp = $group->delete(1);

$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    name => 'lgroup00',
				    cn => 'lgroup00',
				   );
$resp = $group->create(dn => 'cn=lgroup00,ou=groups,o=me,c=us');
is($resp->isok, 1, "Created lgroup00 by passing dn in create") or diag($resp->messages);
$resp = $group->delete(1);

$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
				    name => 'lgroup00',
				   );
$resp = $group->cn;
is($resp->isok,0,'Could not get the CN back out');

$resp = $group->create(cn => 'lgroup00');
is($resp->isok, 1, "Created lgroup00 by passing cn in create") or diag($resp->messages);
$resp = $group->delete(registry => 1);

$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
				    name => 'lgroup00',
				   );
$resp = $group->create();
is($resp->isok, 1, "Created lgroup00, letting it parse the cn from the dn") or diag($resp->messages);
$resp = $group->delete;

print "\nTESTING broken imports\n";
$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				 dn => 'cn=lgroup00,ou=groups,o=me,c=us',
			      );
$resp = $group->groupimport();
is($resp->isok, 0, "Importing lgroup00 with no name failed") or diag($resp->messages);

$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    name => 'lgroup00',
				   );
$resp = $group->groupimport();
is($resp->isok, 0, "Importing lgroup00 with no dn failed") or diag($resp->messages);

$resp = $group->groupimport(dn => 'cn=lgroup00,ou=groups,o=me,c=us');
is ($resp->isok, 1, "Final import for cleaning") or diag($resp->messages);
$group->delete(registry => 1);

print "\nTESTING broken creates\n";
$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
				   );
$resp = $group->create();
is($resp->isok,0,"Creating lgroup00 with no cn failed") or diag($resp->messages);

$group = Tivoli::AccessManager::Admin::Group->new($pd, 
				    name => 'lgroup00',
				   );
$resp = $group->create();
is($resp->isok, 0, "Creating lgroup00 with no dn and no cn failed") or diag($resp->messages);
$resp = $group->dn;
is($resp->isok, 0, "Couldn't get the dn") or diag($resp->messages);
$resp = $group->members;
is($resp->isok, 0, "The member list wasn't available");

$resp = Tivoli::AccessManager::Admin::Group->create($pd, name => 'lgroup00',
				    cn => 'lgroup00',
				   );
is($resp->isok, 0, "Creating lgroup00 with no dn failed") or diag($resp->messages);

$resp = Tivoli::AccessManager::Admin::Group->create($pd, name => 'group00');
is($resp->isok, 0, 'Could not create a group w/o a dn or cn');

$resp = Tivoli::AccessManager::Admin::Group->create($pd,
						    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
						    cn => 'lgroup00',
				                   );
is($resp->isok, 0, "Creating lgroup00 with no name failed") or diag($resp->messages);

print "\nTESTING bad parameter calls\n";

my $fbar = Tivoli::AccessManager::Admin::Group->new();
is($fbar, undef, 'Parameterless call to new did not work');

$fbar = Tivoli::AccessManager::Admin::Group->new($pd, 'one ping');
is($fbar, undef, 'Odd number of parameters to new failed');

$fbar = Tivoli::AccessManager::Admin::Group->new('one ping');
is($fbar, undef, 'Sending a non-context failed');

$resp = Tivoli::AccessManager::Admin::Group->create($pd, 'foo');
is($resp->isok, 0, 'Odd number of parameters to create failed');

$resp = Tivoli::AccessManager::Admin::Group->create($pd, name => 'lgroup00',
				    dn => 'cn=lgroup00,ou=groups,o=me,c=us',
				    cn => 'lgroup00',
				   );
$fbar = $resp->value;

$resp = $fbar->groupimport;
is($resp->isok, 0, 'Could not import an existing group');

$resp = $fbar->delete('work', 'work', 'work');
is($resp->isok, 0, 'Odd number of parameters to delete failed');

$resp = $fbar->description(qw/one two three/);
is($resp->isok,0,'Odd number of parameters to description failed');

$resp = $fbar->members('one');
is($resp->isok,0,'Odd number of parameters to members failed');

$resp = Tivoli::AccessManager::Admin::Group->list($pd,'one');
is($resp->isok,0,'Odd number of parameters to list failed');

$resp = Tivoli::AccessManager::Admin::Group->groupimport($pd,'one');
is($resp->isok,0,'Odd number of parameters to import failed');

print "\nTESTING evil\n";

$fbar->{exist} = 0;
$resp = $fbar->create;
is($resp->isok,0,"Could not create evil");

$resp = $fbar->groupimport( name => 'evil', dn => 'cn=evil,ou=groups,o=me,c=us');
is($resp->isok, 0, "Could not import evil");

$fbar->{exist} = 1;
$fbar->delete(1);

$fbar->{exist} = 1;
$resp = $fbar->delete;
is($resp->isok,0,"Could not delete evil");

$resp = $fbar->description("Evil monkey");
is($resp->isok,0,"Could not set evil's description");

$resp = $fbar->members(add => 'sec_master');
is($resp->isok, 0, "Could not add members to evil");

$resp = $fbar->members(remove => 'sec_master');
is($resp->isok, 0, "Could not add members to evil");

$resp = $fbar->members;
is($resp->isok, 0, "Could not list members of evil");

$fbar->{exist} = 0;

END {
    ReadMode 0;
}
