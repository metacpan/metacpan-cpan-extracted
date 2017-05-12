BEGIN { $| = 1; print "1..25\n"; }

# Test that we can load the module
END {print "not ok 1\n" unless $loaded;}
use Want;
$loaded = 1;
print "ok 1\n";

# Check the low-level want_boolean() routine

sub wb {
  my ($t, $w, $r) = @_;
  my $a = Want::want_boolean(0);
  print ($w == $a ? "ok $t\n" : "not ok $t\t# $a\n");
  return $r;
}

# In older (< 0.10) versions of Want, want_boolean would return true
# even in void context. That's no longer true.
wb(2, 0);

$x = (wb(3, 1, 1) && wb(4, 0));
if (wb(5, 1)) {}

$x = (wb(6, 1) ? 17 : 23);
$x = ($x ? wb(7, 0, 1) : die);

if ($x ? wb(8, 1, 1) : die) {
  print "ok 9\n";
}
else {
  print "not ok 9\n";
}

die unless wb(10, 1, 1);

if ((wb(11,1,1) && wb(12,1,0)) || wb(13, 1)) {
  ()= $x
}

wb((wb(14,1,1) && wb(15,0,0)) || wb(16, 0, 17), 0);


# Now check that want('BOOL') is okay

sub wantt {
    my $t = shift();
    my $r = shift();
    print (Want::want(@_) ? "ok $t\n" : "not ok $t\n");
    $r
}

 wantt(18, 0, 'SCALAR', 'BOOL', '!REF') ||
!wantt(19, 0, 'SCALAR', 'BOOL', '!REF') || 1;

wantt(20, 0, '!BOOL');
$x = wantt(21, 0, '!BOOL');
@x = wantt(22, 0, qw'LIST !BOOL');

$x = (wantt(23, 0, 'BOOL') xor wantt(24, 0, 'BOOL'));
$x = !(0 + wantt(25, 1, '!BOOL'));
