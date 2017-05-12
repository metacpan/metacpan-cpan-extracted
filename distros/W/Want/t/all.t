BEGIN { $| = 1; print "1..72\n"; }

# Test that we can load the module
END {print "not ok 1\n" unless $loaded;}
use Want;
$loaded = 1;
print "ok 1\n";

# Now test the private low-level mechanisms

my $xxx;
sub lv :lvalue {
    print (Want::want_lvalue(0) ? "ok 2\n" : "not ok 2\n");
    $xxx;
}

&lv = 23;

sub rv :lvalue {
    print (Want::want_lvalue(0) ? "not ok 3\n" : "ok 3\n");
    my $xxx;
}

&rv;

sub foo {
    my $t = shift();
    my $opname = Want::parent_op_name(0);
    print ($opname eq shift() ? "ok $t\n" : "not ok $t\t# $opname\n");
    ++$t;
    my $c = Want::want_count(0);
    print ($c == shift() ? "ok $t\n" : "not ok $t\t# $c\n");
    shift;
}

($x, undef) = foo(4, "aassign", 2);
$x = 2 + foo(6, "add", 1, 7);

foo(8, "(none)", 0);

print foo(10, "print", -1, "");

@x = foo (12, "aassign", -1);

# Test the public API

#  wantref()
sub wc {
    my $ref = Want::wantref();
    print ($ref eq 'CODE' ? "ok 14\n" : "not ok 14\t# $ref\n");
    sub {}
}
wc()->();

sub wh {
    my $n = shift();
    my $ref = Want::wantref();
    print ($ref eq 'HASH' ? "ok $n\n" : "not ok $n\t# $ref\n");
    {}
}
$x= wh(15)->{foo};
@x= %{wh(16)};
@x= @{wh(17)}{qw/foo bar/};

sub wg {
    my $n = shift();
    my $ref = Want::wantref();
    print ($ref eq 'GLOB' ? "ok $n\n" : "not ok $n\t# $ref\n");
    \*foo;
}
$x= *{wg(18)};
$x= *{wg(19)}{FORM};

sub wa {
    my $n = shift();
    my $ref = Want::wantref();
    print ($ref eq 'ARRAY' ? "ok $n\n" : "not ok $n\t# $ref\n");
    [];
}
@x= @{wa(20)};
wa(22)->[24] = ${wa(21)}[23];

#  howmany()

sub hm {
  my $n = shift();
  my $x = shift();
  my $h = Want::howmany();
  
  print (!defined($x) && !defined($h) || $x eq $h ? "ok $n\n" : "not ok $n\t# $h\n");
}

hm(23, 0);
@x = hm(24, undef);
(undef) = hm(25, 1);

#  want()

use Want 'want';
sub pi () {
    if    (want('ARRAY')) {
	return [3, 1, 4, 1, 5, 9];
    }
    elsif (want('LIST')) {
	return (3, 1, 4, 1, 5, 9);
    }
    else {
	return 3;
    }
}
print (pi->[2]   == 4 ? "ok 26\n" : "not ok 26\n");
print (((pi)[3]) == 1 ? "ok 27\n" : "not ok 27\n");

sub tc {
    print (want(2) && !want(3) ? "ok 28\n" : "not ok 28\n");
}

(undef, undef) = tc();

sub g :lvalue {
    my $t = shift;
    print (want(@_) ? "ok $t\n" : "not ok $t\n");
    $y;
}
sub ng :lvalue {
    my $t = shift;
    print (want(@_) ? "not ok $t\n" : "ok $t\n");
    $y;
}

(undef) =  g(29, 'LIST', 1);
(undef) = ng(30, 'LIST', 2);

$x      =  g(31, '!LIST', 1);
$x      = ng(32, '!LIST', 2);

g(33, 'RVALUE', 'VOID');
g(34, 'LVALUE', 'SCALAR') = 23;
print ($y == 23 ? "ok 35\n" : "not ok 35\n");

@x = g(36, 'RVALUE', 'LIST');
@x = \(g(37, 'LVALUE', 'LIST'));
($x) = \(scalar g(38, $] >= 5.021007 ? ('LVALUE', 'SCALAR') : 'RVALUE'));
$$x = 29;

# There used to be a test here which tested that $y != 29. However this
# is really testing the behaviour of perl itself rather than of the Want
# module, and the behaviour of perl has changed since 5.14: see
# commit bf8fb5ebd. So we don’t have to renumber all following tests,
# we just insert a dummy test 39 that always passes.
print "ok 39 # Not a real test\n";

ng(41, 'REF') = g(40, 'HASH')->{foo};
$y = sub {}; # Just to silence warning
$x = defined &{g(42, 'CODE')};
sub main::23 {}

(undef, undef,  undef) = ($x,  g(43, 2));
(undef, undef,  undef) = ($x, ng(44, 3));

($x) = ($x, ng(45, 1));

@x = g(46, 2);
%x = (1 => g(47, 'Infinity'));
@x{@x} = g(48, 'Infinity');

@x[1, 2] = g(49, 2, '!3');

%x=(1=>23, 2=>"seven", 23=>9, seven=>2);
@x{@x{1, 2}} = g(50, 2, '!3');
@x{()} = g(51, 0, '!1');

@x = (@x, g(52, 'Infinity'));
($x) = (@x, g(53, '!1'));


# Check the want('COUNT') and want('REF') synonyms

sub tCOUNT {
  my ($t, $w) = @_;
  my $a = want('COUNT');
  if (!defined $w and !defined $a) {
    print "ok $t\n";
  }
  else {
    print ($w == $a ? "ok $t\n" : "not ok $t\t# $a\n");
  }
  return
}

tCOUNT(54, 0);
$x = tCOUNT(55, 1);
(undef, $x) = tCOUNT(56, 2);

sub tREF {
  my ($t, $w) = @_;
  my $a = want('REF');
  print ($w eq $a ? "ok $t\n" : "not ok $t\t# $a\n");
}

$x = ${tREF(57, 'SCALAR')};

sub not_lvaluable {
    print (want("LVALUE") ? "not ok 58\n" : "ok 58\n");
}

sub{}->(not_lvaluable());

my @x = tCOUNT(59, undef);
@::x  = tCOUNT(60, undef);

(my $x, @x) = tCOUNT(61, undef);
($x, @::x)  = tCOUNT(62, undef);

(undef, undef, @x)    = tCOUNT(63, undef);
(undef, undef, @::x)  = tCOUNT(64, undef);

(@x, @::x) = tCOUNT(65, undef);
(@::x, @::x) = tCOUNT(66, undef);

my %x = tCOUNT(67, undef);
%::x  = tCOUNT(68, undef);

%x    = (a => 1, tCOUNT(69, undef));
%::x  = (a => 2, tCOUNT(70, undef));

sub try_rreturn : lvalue {
    rreturn @_;
    return;
}

{
    my $res;

    $res = try_rreturn(qw(a b c));
    print "not " unless $res eq "c";
    print "ok 71 # rreturn in scalar context ($res)\n";

    $res = join(':', try_rreturn(qw(a b c)));
    print "not " unless $res eq "a:b:c";
    print "ok 72 # rreturn in list context ($res)\n";
}
