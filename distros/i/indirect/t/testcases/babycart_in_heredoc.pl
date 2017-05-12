no indirect hook => sub { exit("$_[0] $_[1]" eq "X new" ? 0 : 1) };
<<"FOO";
abc @{[ new X ]} def
FOO
BEGIN { exit 2 }
