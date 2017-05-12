# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Authen::RBAC();
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $database = new  Authen::RBAC(conf=>'.' ); 

print "ok 2\n" if defined $database;

print "ok 3\n" if $database->add_group("test");

print "ok 4\n" if $database->add_acl_to_group("test","test acl","DENY");

print "ok 5\n" if $database->add_acl_to_group("test","test acl2","DENY");

print "ok 6\n" if ( scalar (@{$database->get_acls_in_group("test")}) ==2 );

