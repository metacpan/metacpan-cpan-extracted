BEGIN { $| = 1; print "1..7\n"; }

# Test that we can load the module
END {print "not ok 1\n" unless $loaded;}
use Want;
$loaded = 1;
print "ok 1\n";

# Test the OBJECT reference type

sub t {
    my $t = shift();
    my $opname = Want::parent_op_name(0);
    print ($opname eq shift() ? "ok $t\n" : "not ok $t\t# $opname\n");
    wantarray ? @_ : shift;
}

sub nop{}
my $obj = bless({}, "main");

t(2, "method_call", $obj)->nop("blast");
t(3, "entersub", \&nop)->("blamm!");

sub wrt {
    my $t = shift();
    my $wantref = Want::wantref();
    my $expected = shift();
    print ($wantref eq $expected ? "ok $t\n" : "not ok $t\t# $wantref\n");
    wantarray ? @_ : shift;
}

wrt(4, "OBJECT", $obj)->nop();
wrt(5, "CODE",  \&nop)->(nop());

sub wantt {
    my $t = shift();
    my $r = shift();
    print (Want::want(@_) ? "ok $t\n" : "not ok $t\n");
    $r
}

wantt(6, $obj, 'OBJECT')->nop(wantt(7, \&nop, 'CODE')->());