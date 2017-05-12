require XSLoader;

my $orig_load = \&XSLoader::load;
no warnings "redefine";
*XSLoader::load = sub {
	die "XS loading disabled for XML::Easy"
		if ($_[0] || "") eq "XML::Easy";
	goto &$orig_load;
};

1;
