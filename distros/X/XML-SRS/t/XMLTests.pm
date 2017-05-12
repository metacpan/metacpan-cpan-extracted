
package XMLTests;

BEGIN { *$_ = \&{"main::$_"} for qw(ok diag) }
use Scriptalicious;
use File::Find;
use strict;
use YAML;

our $grep;
(our $test_dir = $0) =~ s{\.t$}{};

getopt_lenient( "test-grep|t=s" => \$grep );

sub find_tests {
	my @tests;
	find(
		sub {
			if ( m{\.xml$} && (!$grep||m{$grep}) ) {
				my $name = $File::Find::name;
				$name =~ s{^\Q$test_dir\E/}{} or die;
				push @tests, $name;
			}
		},
		$test_dir
	);
	@tests;
}

sub read_xml {
	my $test = shift;
	open XML, "<$test_dir/$test";
	binmode XML, ":utf8";
	my $xml = do {
		local($/);
		<XML>;
	};
	close XML;
	$xml;
}

sub parse_test {
	my $class = shift;
	my $xml = shift;
	my $test_name = shift;
	start_timer;
	my $object = eval { $class->parse($xml) };
	my $time = show_elapsed;
	my $ok = ok($object, "$test_name - parsed OK ($time)");
	if ( !$ok ) {
		diag("exception: $@");
	}
	if ( $ok and $main::VERBOSE>0) {
		diag("read: ".Dump($object));
	}
	$object;
}

sub emit_test {
	my $object = shift;
	my $test_name = shift;
	start_timer;
	my $r_xml = eval { $object->to_xml };
	my $time = show_elapsed;
	ok($r_xml, "$test_name - emitted OK ($time)")
		or do {
		diag("exception: $@");
		return undef;
		};
	if ($main::VERBOSE>0) {
		diag("xml: ".$r_xml);
	}
	return $r_xml;
}

sub xml_compare_test {
	my $xml_compare = shift;
	my $r_xml = shift;
	my $xml = shift;
	my $test_name = shift;

	my $is_same = $xml_compare->is_same($r_xml, $xml);
	ok($is_same, "$test_name - XML output same")
		or diag("Error: ".$xml_compare->error);

}
1;
