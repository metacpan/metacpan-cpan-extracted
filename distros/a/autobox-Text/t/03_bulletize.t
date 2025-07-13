use Test::More;
use autobox::Text;

$\ = "\n"; $, = "\t";

my $t = <<EOF
uno
due
tre
EOF
;

my @t = (
	 <<EOF
- uno
- due
- tre
EOF
	 ,
	 <<EOF
1. uno
2. due
3. tre
EOF
	 ,
	 <<EOF
01. uno
02. due
03. tre
EOF
	);

is ($t->bulletize, (shift @t)->trim, "unordered list");
is ($t->bulletize(1), (shift @t)->trim, "ordered list");
is ($t->bulletize(1, "%02i. %s"), (shift @t)->trim, "custom format");


is ($t->bulletize->unbulletize, $t->trim, "unbulletize unordered list");
is ($t->bulletize(1)->unbulletize, $t->trim, "unbulletize ordered list");


done_testing()
