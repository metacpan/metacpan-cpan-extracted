#!/usr/bin/env perl
use Test::More tests => 42;
use re::engine::Plan9;

=pod

Copied from F<t/op/subst.t> in core

=cut

$x = 'foo';
$_ = "x";
s/x/\$x/;
ok( $_ eq '$x', ":$_: eq :\$x:" );

$_ = "x";
s/x/$x/;
ok( $_ eq 'foo', ":$_: eq :foo:" );

$_ = "x";
s/x/\$x $x/;
ok( $_ eq '$x foo', ":$_: eq :\$x foo:" );

#$b = 'cd';
#($a = 'abcdef') =~ s<(b${b}e)>'\n$1';
#ok( $1 eq 'bcde' && $a eq 'a\n$1f', ":$1: eq :bcde: ; :$a: eq :a\\n\$1f:" );

$a = 'abacada';
ok( ($a =~ s/a/x/g) == 4 && $a eq 'xbxcxdx' );

ok( ($a =~ s/a/y/g) == 0 && $a eq 'xbxcxdx' );

ok( ($a =~ s/b/y/g) == 1 && $a eq 'xyxcxdx' );

#$_ = 'ABACADA';
#ok( /a/i && s///gi && $_ eq 'BCD' );

$_ = '\\' x 4;
ok( length($_) == 4 );
$snum = s/\\/\\\\/g;
ok( $_ eq '\\' x 8 && $snum == 4 );

$_ = '\/' x 4;
ok( length($_) == 8 );
$snum = s/\//\/\//g;
ok( $_ eq '\\//' x 4 && $snum == 4 );
ok( length($_) == 12 );

$_ = 'aaaXXXXbbb';
s/^a//;
ok( $_ eq 'aaXXXXbbb' );

$_ = 'aaaXXXXbbb';
s/a//;
ok( $_ eq 'aaXXXXbbb' );

$_ = 'aaaXXXXbbb';
s/^a/b/;
ok( $_ eq 'baaXXXXbbb' );

$_ = 'aaaXXXXbbb';
s/a/b/;
ok( $_ eq 'baaXXXXbbb' );

$_ = 'aaaXXXXbbb';
s/aa//;
ok( $_ eq 'aXXXXbbb' );

$_ = 'aaaXXXXbbb';
s/aa/b/;
ok( $_ eq 'baXXXXbbb' );

$_ = 'aaaXXXXbbb';
s/b$//;
ok( $_ eq 'aaaXXXXbb' );

$_ = 'aaaXXXXbbb';
s/b//;
ok( $_ eq 'aaaXXXXbb' );

$_ = 'aaaXXXXbbb';
s/bb//;
ok( $_ eq 'aaaXXXXb' );

$_ = 'aaaXXXXbbb';
s/aX/y/;
ok( $_ eq 'aayXXXbbb' );

$_ = 'aaaXXXXbbb';
s/Xb/z/;
ok( $_ eq 'aaaXXXzbb' );

$_ = 'aaaXXXXbbb';
s/aaX.*Xbb//;
ok( $_ eq 'ab' );

$_ = 'aaaXXXXbbb';
s/bb/x/;
ok( $_ eq 'aaaXXXXxb' );

# now for some unoptimized versions of the same.

$_ = 'aaaXXXXbbb';
$x ne $x || s/^a//;
ok( $_ eq 'aaXXXXbbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/a//;
ok( $_ eq 'aaXXXXbbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/^a/b/;
ok( $_ eq 'baaXXXXbbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/a/b/;
ok( $_ eq 'baaXXXXbbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/aa//;
ok( $_ eq 'aXXXXbbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/aa/b/;
ok( $_ eq 'baXXXXbbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/b$//;
ok( $_ eq 'aaaXXXXbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/b//;
ok( $_ eq 'aaaXXXXbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/bb//;
ok( $_ eq 'aaaXXXXb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/aX/y/;
ok( $_ eq 'aayXXXbbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/Xb/z/;
ok( $_ eq 'aaaXXXzbb' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/aaX.*Xbb//;
ok( $_ eq 'ab' );

$_ = 'aaaXXXXbbb';
$x ne $x || s/bb/x/;
ok( $_ eq 'aaaXXXXxb' );

$_ = 'abc123xyz';
s/([0-9]+)/$1*2/e;              # yields 'abc246xyz'
ok( $_ eq 'abc246xyz' );
s/([0-9]+)/sprintf("%5d",$1)/e; # yields 'abc  246xyz'
ok( $_ eq 'abc  246xyz' );
s/([a-z0-9])/$1 x 2/eg;            # yields 'aabbcc  224466xxyyzz'
is( $_, 'aabbcc  224466xxyyzz' );

$_ = "abcd";
s/(..)/$x = $1, m#.#/eg;
ok( $x eq "cd", 'a match nested in the RHS of a substitution' );

$_ = "ab";
ok( s/a/b/ == 1 );
