# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Authen::RBAC::Group::Acl;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $acl = new Authen::RBAC::Group::Acl;

print "ok 2\n" if defined $acl;

print "ok 3\n" if $acl->set_acl_name('test');

print "ok 4\n" if $acl->set_default_policy('PERMIT');

print "ok 5\n" if $acl->add_policy('Hostmask','core.*');

print "ok 6\n" if $acl->add_policy('Permit','show',["int.*","run.*"]);

print "ok 7\n" if $acl->add_policy('Deny','show',["int.*","run.*"]);

@xml = @{ $acl->output_xml() };

print "ok 8\n" if scalar(@xml);

