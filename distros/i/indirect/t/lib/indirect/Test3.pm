no indirect ":fatal";
my $x;
if ($x) {
my $y = qq{abcdef
 @{[new $x]}
 };
}
1;
