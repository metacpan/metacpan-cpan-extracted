use Test::More tests => 52;

for $mod ("Tie::Array::Sorted", "Tie::Array::Sorted::Lazy") { 
	use_ok $mod;
	my @a;
	tie @a, $mod, sub { $_[0] <=> $_[1] };
	@a = ();

	push @a, 10;
	is($a[0], 10, "Stored");
	is($a[-1], 10, "Stored");

	push @a, 5;
	is($a[0], 5, "Sorted");
	is($a[-1], 10, "Sorted");

	push @a, 15;
	is($a[0], 5, "Still sorted");
	is($a[1], 10, "Still sorted");
	is($a[2], 15, "Still sorted");

	push @a, 12;
	is($a[0], 5, "Sorted with 12 in there too");
	is($a[1], 10, "Sorted with 12 in there too");
	is($a[2], 12, "Sorted with 12 in there too");
	is($a[3], 15, "Sorted with 12 in there too");

	push @a, 10;
	is($a[0], 5, "Sorted with duplicates");
	is($a[1], 10, "Sorted with duplicates");
	is($a[2], 10, "Sorted with duplicates");
	is($a[3], 12, "Sorted with duplicates");
	is($a[4], 15, "Sorted with duplicates");

	pop @a;
	is($a[0], 5, "Pop");
	is($a[1], 10, "Pop");
	is($a[2], 10, "Pop");
	is($a[3], 12, "Pop");
	is(@a, 4, "Pop");

	push @a, 4,5,6;
	is("@a", "4 5 5 6 10 10 12", "push");
}

{
	tie @b, "Tie::Array::Sorted";
	push @b, "beta";  is "@b", "beta", "default comparator";
	push @b, "alpha"; is "@b", "alpha beta", " is text search";
	push @b, "gamma"; is "@b", "alpha beta gamma", " and it works";
}

{
	use Class::Struct OBJ => [ id => '$' ];

	my @list;
	tie @list, "Tie::Array::Sorted", sub { $_[0]->id <=> $_[1]->id };
	my @obj = map OBJ->new(id => $_), 1 .. 3;
	is @list, 0, "Start with empty list";
	push @list, $_ for reverse @obj;
	is @list, 3, "3 objects on list";
	is $list[0]->id, "1", "Starts with 1";
}

