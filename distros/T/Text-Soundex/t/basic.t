use strict;

my $test_counter;

BEGIN {
    $test_counter = 0;
    sub t (&);
    sub tsoundex;
    sub test_label;
}

END {
    print "1..$test_counter\n";
}

t {
    test_label "use Text::Soundex 'soundex'";
    eval "use Text::Soundex 'soundex'";
    die if $@;
};

t {
    test_label "use Text::Soundex 'soundex_nara'";
    eval "use Text::Soundex 'soundex_nara'";
    die if $@;
};

t {
    test_label "use Text::Soundex;";
    eval "use Text::Soundex";
    die if $@;
};

# Knuth's test cases, scalar in, scalar out
tsoundex("Euler"       => "E460");
tsoundex("Gauss"       => "G200");
tsoundex("Hilbert"     => "H416");
tsoundex("Knuth"       => "K530");
tsoundex("Lloydi"      => "L300");
tsoundex("Lukasiewicz" => "L222");

# check default "no code" code on a bad string and undef
tsoundex("2 + 2 = 4"   => undef);
tsoundex(undef()       => undef);

# check list context with and without "no code"
tsoundex([qw/Ellery Ghosh Heilbronn Kant Ladd Lissajous/],
	 [qw/E460   G200  H416      K530 L300 L222     /]);
tsoundex(['Mark', 'Mielke'],
	 ['M620', 'M420']);
tsoundex(['Mike', undef, 'Stok'],
	 ['M200', undef, 'S320']);

# check the deprecated $soundex_nocode and make sure it's reflected in
# the $Text::Soundex::nocode variable.
{
    our $soundex_nocode;
    my $nocodeValue = 'Z000';
    $soundex_nocode = $nocodeValue;

    t {
	test_label "setting \$soundex_nocode";
	die if soundex(undef) ne $nocodeValue;
    };

    t {
	test_label "\$soundex_nocode eq \$Text::Soundex::nocode";
	die if $Text::Soundex::nocode ne $soundex_nocode;
    };
}

# make sure an empty argument list returns an undefined scalar
t {
    test_label "empty list";
    die if defined(soundex());
};

# test to detect an error in Mike Stok's original implementation, the
# error isn't in Mark Mielke's at all but the test should be kept anyway.
# originally spotted by Rich Pinder <rpinder@hsc.usc.edu>
tsoundex("CZARKOWSKA" => "C622");

exit 0;


my $test_label;

sub t (&)
{
    my($test_f) = @_;
    $test_label = undef;
    eval {&$test_f};
    my $ok = $@ ? "not ok" : "ok";
    $test_counter++;
    print "$ok - $test_counter $test_label\n";
}

sub tsoundex
{
    my($string, $expected) = @_;
    if (ref($string) eq 'ARRAY') {
	t {
            my $s = scalar2string(@$string);
            my $e = scalar2string(@$expected);
	    $test_label = "soundex($s) eq ($e)";
	    my @codes = soundex(@$string);
	    for (my $i = 0; $i < @$string; $i++) {
		my $success = !(defined($codes[$i])||defined($expected->[$i]));
		if (defined($codes[$i]) && defined($expected->[$i])) {
		    $success = ($codes[$i] eq $expected->[$i]);
		}
		die if !$success;
	    }
	};
    } else {
	t {
	    my $s = scalar2string($string);
	    my $e = scalar2string($expected);
	    $test_label = "soundex($s) eq $e";
	    my $code = soundex($string);
	    my $success = !(defined($code) || defined($expected));
	    if (defined($code) && defined($expected)) {
		$success = ($code eq $expected);
	    }
	    die if !$success;
	};
    }
}

sub test_label
{
    $test_label = $_[0];
}

sub scalar2string
{
    join(", ", map {defined($_) ? qq{'$_'} : qq{undef}} @_);
}
