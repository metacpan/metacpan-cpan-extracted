BEGIN { $| = 1; print "1..3\n"; }

# Test that we can load the module
END {print "not ok 1\n" unless $loaded;}
use Want;
$loaded = 1;
print "ok 1\n";

sub foo :lvalue {
    rreturn 23;
    return;
}

sub bar :lvalue {
    lnoreturn;
    return;
}

eval { foo() = 7 };
print ($@ =~ /Can't rreturn in lvalue context/ ? "ok 2\n" : "not ok 2\n");

eval { bar() };
print ($@ =~ /Can't lnoreturn except in ASSIGN context/ ? "ok 3\n" : "not ok 3\n");
