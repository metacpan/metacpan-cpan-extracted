use strict;
use warnings;

use Tree::BPTree;

use vars '&test';

our $teststr = <<'EOF';
And now says the LORD who formed Me from the womb to be His Servant,
To bring Jacob back to Him, in order that Israel might be gathered to Him
(For I am honored in the sight of the LORD,
And My God is My strength),
He says, "It is too small a thing that You should be My Servant
To raise up the tribes of Jacob and to restore the preserved ones of Israel;
I will also make You a light of the nations
So that My salvation may reach to the end of the earth."
-- Isaiah 49:5,6
EOF

$teststr =~ tr/,()".-:/       /;
our @splitstr = split /[\b\s]/, $teststr;

sub runtests {
	for my $n (3 .. 50) {
		my $i = 0;
		my $tree = Tree::BPTree->new(-n => $n);

		$tree->insert($_, $i++) for (@splitstr);

		&test($tree);
	}
}

1
