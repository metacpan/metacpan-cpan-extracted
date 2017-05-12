BEGIN { $| = 1; print "1..4\n"; }
use warnings;
use strict;

# Test that we can load the module
my $loaded;
END {print "not ok 1\n" unless $loaded;}
use Want;
$loaded = 1;
print "ok 1\n";

# Test for Joshua Goodall's bug #26847

sub method {
	my (undef, $t, $expected) = @_;
        my @ctx;
        for my $test (qw(VOID SCALAR REF REFSCALAR CODE HASH
		ARRAY GLOB OBJECT BOOL LIST Infinity LVALUE ASSIGN RVALUE))
	{
	    # print "Trying $test\n";
	    push @ctx, $test if Want::want($test);
        }
	if ("@ctx" eq $expected) {
	    print "ok $t\n"
	}
	else {
	    print "not ok $t\t#got @ctx, expected $expected\n"
	}
	return (want("ARRAY") ? [] : want("HASH") ? {} : 1);
}

my $obj = bless {};
$obj->method(2, "VOID RVALUE");

my @b = @{$obj->method(3, "SCALAR REF ARRAY RVALUE")};
my %b = %{$obj->method(4, "SCALAR REF HASH RVALUE")};