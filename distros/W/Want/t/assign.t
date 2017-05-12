BEGIN { $| = 1; print "1..10\n"; }

# Test that we can load the module
END {print "not ok 1\n" unless $loaded;}
use Want;
$loaded = 1;
print "ok 1\n";

# Test the ASSIGN context

sub t {
    my $t = shift();
    print (want(@_) ? "ok $t\n" : "not ok $t\n");
}

my $t;
sub tl :lvalue {
    $t = shift();
    print (want(@_) ? "ok $t\n" : "not ok $t\n");
    $t;
}

sub noop {}
sub idl :lvalue {@_[0..$#_]}

t (2, qw/RVALUE !ASSIGN/);
tl(3, qw/RVALUE !ASSIGN/);
noop(tl(4, qw/LVALUE !ASSIGN/));
tl(5, qw/LVALUE ASSIGN/) = ();
tl(6, 'ASSIGN') = ();

sub backstr :lvalue {
    if (want('LVALUE')) {
	carp("Not in ASSIGN context") unless want('ASSIGN');
	my $a = want('ASSIGN');
	$_[0] = reverse $a;
	lnoreturn;
    }
    else {
	rreturn scalar reverse $_[0];
    }
    die; return;
}

my $b = backstr("qwerty");
print ($b eq "ytrewq" ? "ok 7\n" : "not ok 7\t# $b\n");
backstr(my $foo) = "robin";
print ($foo eq 'nibor' ? "ok 8\n" : "not ok 8\n");

# Try with some stuff on the stack
for(1..3) {
  backstr($foo) = 23;
}

print ($foo eq 32 ? "ok 9\n" : "not ok 9\n");

idl(tl(10, 'LVALUE', '!ASSIGN')) = ();
