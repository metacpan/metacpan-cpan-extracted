package t::DataSets;

use warnings;
use strict;

use Params::Classify qw(is_string is_ref is_strictly_blessed);
use XML::Easy::Content ();
use XML::Easy::Element ();

use parent "Exporter";
our @EXPORT_OK = map { ("COUNT_$_", "foreach_$_") } (
	(map { ("no_$_") } qw(
		string
		array
		hash
		array_or_content_object
		string_or_array_or_content_object_or_element
	)),
	(map { ("yes_$_", "ch_no_$_") } qw(
		char
		namestartchar
		namechar
	)),
	(map { ("yes_$_", "string_no_$_", "no_$_") } qw(
		name
		encname
		chardata
	)),
	(map { ("yes_$_", "hash_no_$_", "no_$_") } qw(
		attributes
	)),
	(map { ("yes_$_", "array_no_$_", "no_$_") } qw(
		content_twine
	)),
	(map { ("yes_$_", "no_$_") } qw(
		content_object
		content
		element
	)),
);

sub memoise($) {
	my($evaluate) = @_;
	my $value;
	return sub () {
		# Note perl bug (#63540): in some versions of perl,
		# including 5.8.9 and 5.10.0, this function is liable to
		# produce silly results, for reasons that are unknown at
		# the time of writing.  Empirically, adding the "if(0)"
		# no-op here makes perl behave.
		if(0) { }
		if(defined $evaluate) {
			$value = $evaluate->();
			$evaluate = undef;
		}
		return $value;
	};
}

sub count($) {
	my($foreach_func) = @_;
	my $count = 0;
	$foreach_func->(sub { $count++ });
	return $count;
}

my $c0 = XML::Easy::Content->new([ "bop" ]);
my $e0 = XML::Easy::Element->new("foo", {}, $c0);

my @interesting_value = (
	undef,
	"",
	"abc",
	do { no warnings "utf8"; "\x{d800}" },
	do { no warnings "utf8"; "\x{ffffffff}" },
	*STDOUT,
	\"",
	[],
	{},
	sub{},
	bless({},"main"),
	bless({},"ARRAY"),
	bless([],"main"),
	bless([],"HASH"),
	$c0,
	$e0,
	[""],
);
sub foreach_interesting_value($) {
	my($do) = @_;
	$do->($_) foreach @interesting_value;
}

sub foreach_no_string($) {
	my($do) = @_;
	foreach_interesting_value sub { my($value) = @_;
		$do->($value) unless is_string($value);
	}
}
*COUNT_no_string = memoise sub { count(\&foreach_no_string) };

sub foreach_no_array($) {
	my($do) = @_;
	foreach_interesting_value sub { my($value) = @_;
		$do->($value) unless is_ref($value, "ARRAY");
	}
}
*COUNT_no_array = memoise sub { count(\&foreach_no_array) };

sub foreach_no_hash($) {
	my($do) = @_;
	foreach_interesting_value sub { my($value) = @_;
		$do->($value) unless is_ref($value, "HASH");
	}
}
*COUNT_no_hash = memoise sub { count(\&foreach_no_hash) };

sub foreach_no_array_or_content_object($) {
	my($do) = @_;
	foreach_interesting_value sub { my($value) = @_;
		$do->($value) unless
			is_ref($value, "ARRAY") ||
			is_strictly_blessed($value, "XML::Easy::Content");
	}
}
*COUNT_no_array_or_content_object =
	memoise sub { count(\&foreach_no_array_or_content_object) };

sub foreach_no_string_or_array_or_content_object_or_element($) {
	my($do) = @_;
	foreach_interesting_value sub { my($value) = @_;
		$do->($value) unless
			is_string($value) ||
			is_ref($value, "ARRAY") ||
			is_strictly_blessed($value, "XML::Easy::Content") ||
			is_strictly_blessed($value, "XML::Easy::Element");
	}
}
*COUNT_no_string_or_array_or_content_object_or_element = memoise sub {
	count(\&foreach_no_string_or_array_or_content_object_or_element)
};

sub foreach_hex_char($@) {
	my $do = shift(@_);
	foreach(@_) {
		no warnings "utf8";
		my $c = chr(hex($_));
		die "chr/ord failure" unless sprintf("%x", ord($c)) eq $_;
		$do->($c);
	}
}

*COUNT_yes_char = memoise sub { 3 + 11 + 3 + 4 + 4 };
sub foreach_yes_char($) {
	foreach_hex_char $_[0], qw(
		9 a d
		20 26 3a 3c 3e 7f 80 9f a0 a3 d7ff
		e000 fdd0 fffd
		10000 1fffd 1fffe 1ffff
		20000 10fffd 10fffe 10ffff
	);
}

*COUNT_ch_no_char = memoise sub { 3 + 2 + 2 + 2 + 2 + 4 };
sub foreach_ch_no_char($) {
	foreach_hex_char $_[0], qw(
		0 1 8
		b c
		e 1f
		d800 dfff
		fffe ffff
		110000 7fffffff 80000000 ffffffff
	);
}

*COUNT_yes_namestartchar = memoise sub { 1 + 2 + 3 + 1 + 1 };
sub foreach_yes_namestartchar($) {
	foreach_hex_char $_[0], qw(
		3a
		41 7a
		c0 d6 ff
		b5c
		d7a3
	);
}

sub foreach_ch_no_namestartchar($) {
	my($do) = @_;
	&foreach_ch_no_char;
	foreach_hex_char $do, qw(
		9 a d 20 21 26 2d 30
		3c 3e
		7e 7f
		80 9f a0 bf
		b5e
		d7a4
	);
	foreach_yes_char sub { $do->($_[0]) if ord($_[0]) > 0xd7a4; };
}
*COUNT_ch_no_namestartchar =
	memoise sub { count(\&foreach_ch_no_namestartchar) };

*COUNT_yes_namechar = memoise sub { 3 + 2 + 3 + 1 + 1 };
sub foreach_yes_namechar($) {
	foreach_hex_char $_[0], qw(
		2d 30 3a
		41 7a
		c0 d6 ff
		b5c
		d7a3
	);
}

sub foreach_ch_no_namechar($) {
	my($do) = @_;
	&foreach_ch_no_char;
	foreach_hex_char $do, qw(
		9 a d 20 21 26
		3c 3e
		7e 7f
		80 9f a0 bf
		b5e
		d7a4
	);
	foreach_yes_char sub { $do->($_[0]) if ord($_[0]) > 0xd7a4; };
}
*COUNT_ch_no_namechar = memoise sub { count(\&foreach_ch_no_namechar) };

*COUNT_yes_name =
	memoise sub { 3*COUNT_yes_namestartchar() + COUNT_yes_namechar()*2 };
sub foreach_yes_name($) {
	my($do) = @_;
	foreach_yes_namestartchar sub { my($a) = @_;
		foreach my $b ("", "a", "a"x40000) {
			$do->($a.$b);
		}
	};
	foreach my $b ("a", "a"x40000) {
		foreach_yes_namechar sub { my($c) = @_;
			$do->($b.$c);
		};
	}
}

*COUNT_string_no_name = memoise sub {
	return 1 + 3*COUNT_ch_no_namestartchar() + COUNT_ch_no_namechar()*2;
};
sub foreach_string_no_name($) {
	my($do) = @_;
	$do->("");
	foreach_ch_no_namestartchar sub { my($a) = @_;
		foreach my $b ("", "a", "a"x40000) {
			$do->($a.$b);
		}
	};
	foreach my $b ("a", "a"x40000) {
		foreach_ch_no_namechar sub { my($c) = @_;
			$do->($b.$c);
		};
	}
}

*COUNT_no_name = memoise sub { COUNT_no_string() + COUNT_string_no_name() };
sub foreach_no_name($) {
	&foreach_no_string;
	&foreach_string_no_name;
}

*COUNT_yes_encnamestartchar = memoise sub { 4 };
sub foreach_yes_encnamestartchar($) {
	foreach_hex_char $_[0], qw(
		41 5a
		61 7a
	);
}

sub foreach_ch_no_encnamestartchar($) {
	my($do) = @_;
	&foreach_ch_no_char;
	foreach_hex_char $do, qw(
		9 a d 20 21 26 2c
		2d 2e
		2f
		30 39
		3a 40
		5b 5e
		5f
		60
		7e 7f
	);
	foreach_yes_char sub { $do->($_[0]) if ord($_[0]) >= 0x80; };
}
*COUNT_ch_no_encnamestartchar =
	memoise sub { count(\&foreach_ch_no_encnamestartchar) };

*COUNT_yes_encnamechar = memoise sub { 9 };
sub foreach_yes_encnamechar($) {
	foreach_hex_char $_[0], qw(
		2d 2e
		30 39
		41 5a
		5f
		61 7a
	);
}

sub foreach_ch_no_encnamechar($) {
	my($do) = @_;
	&foreach_ch_no_char;
	foreach_hex_char $do, qw(
		9 a d 20 21 26 2c
		2f
		3a 40
		5b 5e
		60
		7e 7f
	);
	foreach_yes_char sub { $do->($_[0]) if ord($_[0]) >= 0x80; };
}
*COUNT_ch_no_encnamechar = memoise sub { count(\&foreach_ch_no_encnamechar) };

*COUNT_yes_encname = memoise sub {
	return 3*COUNT_yes_encnamestartchar() + COUNT_yes_encnamechar()*2;
};
sub foreach_yes_encname($) {
	my($do) = @_;
	foreach_yes_encnamestartchar sub { my($a) = @_;
		foreach my $b ("", "a", "a"x40000) {
			$do->($a.$b);
		}
	};
	foreach my $b ("a", "a"x40000) {
		foreach_yes_encnamechar sub { my($c) = @_;
			$do->($b.$c);
		};
	}
}

*COUNT_string_no_encname = memoise sub {
	return 1 + 3*COUNT_ch_no_encnamestartchar() +
		COUNT_ch_no_encnamechar()*2;
};
sub foreach_string_no_encname($) {
	my($do) = @_;
	$do->("");
	foreach_ch_no_encnamestartchar sub { my($a) = @_;
		foreach my $b ("", "a", "a"x40000) {
			$do->($a.$b);
		}
	};
	foreach my $b ("a", "a"x40000) {
		foreach_ch_no_encnamechar sub { my($c) = @_;
			$do->($b.$c);
		};
	}
}

*COUNT_no_encname =
	memoise sub { COUNT_no_string() + COUNT_string_no_encname() };
sub foreach_no_encname($) {
	&foreach_no_string;
	&foreach_string_no_encname;
}

*COUNT_yes_chardata =
	memoise sub { 1 + 3 * COUNT_yes_char() * 2 + COUNT_yes_char() };
sub foreach_yes_chardata($) {
	my($do) = @_;
	$do->("");
	foreach my $a ("", "a", "a"x40000) {
		foreach_yes_char sub { my($b) = @_;
			$do->($a.$b);
			$do->($b.$a);
		};
	}
	foreach_yes_char sub { $do->($_[0] x 40000) };
}

*COUNT_string_no_chardata =
	memoise sub { 3 * COUNT_ch_no_char() * 2 + COUNT_ch_no_char() * 2 };
sub foreach_string_no_chardata($) {
	my($do) = @_;
	foreach my $a ("", "a", "a"x40000) {
		foreach_ch_no_char sub { my($b) = @_;
			$do->($a.$b);
			$do->($b.$a);
		};
	}
	foreach_ch_no_char sub {
		$do->("abc".$_[0]."xyz");
		$do->($_[0] x 40000);
	};
}

*COUNT_no_chardata =
	memoise sub { COUNT_no_string() + COUNT_string_no_chardata() };
sub foreach_no_chardata($) {
	&foreach_no_string;
	&foreach_string_no_chardata;
}

*COUNT_yes_attributes =
	memoise sub { 2 + COUNT_yes_name() + COUNT_yes_chardata() };
sub foreach_yes_attributes($) {
	my($do) = @_;
	$do->({});
	$do->({ map { ("a$_" => "z$_") } 0..99 });
	foreach_yes_name sub { $do->({ $_[0] => "foo" }) };
	foreach_yes_chardata sub { $do->({ foo => $_[0] }) };

}

*COUNT_hash_no_attributes =
	memoise sub { COUNT_string_no_name() + COUNT_no_chardata() };
sub foreach_hash_no_attributes($) {
	my($do) = @_;
	foreach_string_no_name sub { $do->({ $_[0] => "foo" }) };
	foreach_no_chardata sub { $do->({ foo => $_[0] }) };
}

*COUNT_no_attributes =
	memoise sub { COUNT_no_hash() + COUNT_hash_no_attributes() };
sub foreach_no_attributes($) {
	&foreach_no_hash;
	&foreach_hash_no_attributes;
}

*COUNT_yes_content_object = memoise sub { 1 };
sub foreach_yes_content_object($) {
	my($do) = @_;
	$do->($c0);
}

sub foreach_no_content_object($) {
	my($do) = @_;
	foreach_interesting_value sub { my($value) = @_;
		$do->($value) unless
			is_strictly_blessed($value, "XML::Easy::Content");
	}
}
*COUNT_no_content_object = memoise sub { count(\&foreach_no_content_object) };

*COUNT_yes_content_twine = memoise sub { 3*COUNT_yes_chardata() };
sub foreach_yes_content_twine($) {
	my($do) = @_;
	foreach_yes_chardata sub {
		$do->([ $_[0] ]);
		$do->([ $_[0], $e0, "y" ]);
		$do->([ "x", $e0, $_[0] ]);
	};
}

sub COUNT_no_element();
sub foreach_no_element($);

*COUNT_array_no_content_twine =
	memoise sub { 2 + 3*COUNT_no_chardata() + COUNT_no_element() };
sub foreach_array_no_content_twine($) {
	my($do) = @_;
	$do->($_) foreach [ ], [ "x", $e0 ];
	foreach_no_chardata sub {
		$do->([ $_[0] ]);
		$do->([ $_[0], $e0, "y" ]);
		$do->([ "x", $e0, $_[0] ]);
	};
	foreach_no_element sub { $do->([ "x", $_[0], "y" ]) };
}

*COUNT_no_content_twine =
	memoise sub { COUNT_no_array() + COUNT_array_no_content_twine() };
sub foreach_no_content_twine($) {
	&foreach_no_array;
	&foreach_array_no_content_twine;
}

*COUNT_yes_content =
	memoise sub { COUNT_yes_content_object() + COUNT_yes_content_twine() };
sub foreach_yes_content($) {
	&foreach_yes_content_object;
	&foreach_yes_content_twine;
}

*COUNT_no_content = memoise sub {
	return COUNT_no_array_or_content_object() +
		COUNT_array_no_content_twine();
};
sub foreach_no_content($) {
	&foreach_no_array_or_content_object;
	&foreach_array_no_content_twine;
}

*COUNT_yes_element = memoise sub { 1 };
sub foreach_yes_element($) {
	my($do) = @_;
	$do->($e0);
}

sub foreach_no_element($) {
	my($do) = @_;
	foreach_interesting_value sub { my($value) = @_;
		$do->($value) unless
			is_strictly_blessed($value, "XML::Easy::Element");
	}
}
*COUNT_no_element = memoise sub { count(\&foreach_no_element) };

1;
