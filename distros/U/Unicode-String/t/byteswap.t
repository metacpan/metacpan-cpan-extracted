print "1..5\n";

use Unicode::String qw(latin1 byteswap2 byteswap4);

$a = "12345678";
$b = "abcdefg";

my $warn = 0;
$SIG{__WARN__} = sub { print @_; $warn++; };


@a = byteswap2($a, $b);

print "not " unless @a == 2 &&
                    $a eq "12345678" &&
		    $b eq "abcdefg" &&
		    $a[0] eq "21436587" &&
		    $a[1] eq "badcfeg" &&
		    $warn == ($^W ? 1 : 0);
print "ok 1\n";
$warn = 0;

@a = byteswap4($a, $b);

print "not " unless @a == 2 &&
                    $a eq "12345678" &&
		    $b eq "abcdefg" &&
		    $a[0] eq "43218765" &&
		    $a[1] eq "dcbaefg" &&
		    $warn == ($^W ? 1 : 0);
print "ok 2\n";

# Try in-place change
byteswap2($a);
print "not " unless $a eq "21436587";
print "ok 3\n";

print "not " unless byteswap2(byteswap2($a)) eq $a;
print "ok 4\n";

# Try object method

$u = latin1("abc");
#print $u->hex, "\n";
$u->byteswap;
#print $u->hex, "\n";

print "not " unless $u->ucs2 eq "a\0b\0c\0";
print "ok 5\n";
