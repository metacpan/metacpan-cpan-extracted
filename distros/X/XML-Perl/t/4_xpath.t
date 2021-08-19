use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/..";

use Test::More tests => 12;

BEGIN { use_ok( 'XML::Perl' ); }


my $xml = <<EOD;
<a f="foo">
	<aa a="b">11</aa>
	<ab a="1">12</ab>
	<ab a="2">13</ab>
</a>
<b>
	<c>4</c>
	<d>5</d>
</b>
<b>
	<c>6</c>
	<d>7</d>
</b>
EOD


my $t = xml2perlbase($xml);


sub show {
	foreach (@_) {
		if (ref $_ eq "HASH") {
			 print perlbase2xml($_, 0, "\t", "\n");
		} else {
			print $_, "\n";
		}
	}
}

sub xpath_test {
	my ($t, $path, $expected) = @_;
	my @r = xpath($t, $path);
	# show(@r);
	# use Data::Dumper; print Dumper \@r, $expected;
	is_deeply(\@r, $expected, $path);
}


my $doit = 1;

$doit and xpath_test($t, '/a/ab', [xml2perlbase(<<EOD)]);
<ab a="1">12</ab>
<ab a="2">13</ab>
EOD

$doit and xpath_test($t, '/b/c', [xml2perlbase(<<EOD)]);
<c>4</c>
<c>6</c>
EOD

$doit and xpath_test($t, '/b[2]', [xml2perlbase(<<EOD)]);
<b>
	<c>6</c>
	<d>7</d>
</b>
EOD

$doit and xpath_test($t, '/b[2]/c', [xml2perlbase(<<EOD)]);
<c>6</c>
EOD

$doit and xpath_test($t, '/a/ab[2]/@a', ['2']);


$doit and xpath_test($t, 'ab', [xml2perlbase(<<EOD)]);
<ab a="1">12</ab>
<ab a="2">13</ab>
EOD




sub to_old {
	my @old = ();
	foreach (@_) {
		if (ref $_ eq "HASH") {
			foreach (values %$_) {
				foreach (@$_) {
					push @old,  $$_{''};
				}
			}
		} else {
			push @old, $_;
		}
	}
	return @old;
}


sub old_xpath_test {
	my ($t, $path, $expected) = @_;
	my $r = join ", ", to_old(xpath($t, $path));
	is $r, $expected, "old: $path";
}


old_xpath_test($t, '/a/ab',       '12, 13');
old_xpath_test($t, '/b/c',        '4, 6');
old_xpath_test($t, '/b[2]/c',     '6');
old_xpath_test($t, '/a/ab[2]/@a', '2');
old_xpath_test($t, 'ab', '12, 13');
