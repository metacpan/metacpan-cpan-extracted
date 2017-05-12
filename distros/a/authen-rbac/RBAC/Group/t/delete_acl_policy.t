# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Authen::RBAC::Group;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $group = new  Authen::RBAC::Group; 

print "ok 2\n" if defined $group;

print "ok 3\n" if $group->set_group_name("test");

print "ok 4\n" if ($group->get_group_name() eq 'test');

print "ok 5\n" if ($group->add_acl("test acl","PERMIT"));

print "ok 6\n" if ($group->add_acl_policy("test acl","Hostmask","core.*"));

print "ok 7\n" if ($group->add_acl_policy("test acl","Permit","show",["run.*","int.*"]));

print "ok 8\n" if ( scalar (@{$group->get_policies_in_acl("test acl")}) ==4 );

print "ok 9\n" if ($group->delete_acl_policy("test acl","Permit","show"));

print "ok 10\n" if ( scalar (@{$group->get_policies_in_acl("test acl")}) ==2 );

