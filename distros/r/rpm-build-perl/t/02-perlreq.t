use Test::More qw(no_plan);
use strict;

use Fcntl qw(F_SETFD);

sub spawn ($) {
	my $file = shift;
	use 5.007_001; # the list form of open() for pipes
	open my $pipe, "-|", $^X, qw(-Mblib perl.req) => $file
		or return (undef, undef);
	my $output = join '' => <$pipe>;
	return (close($pipe), $output);
}

sub grok ($) {
	my $file = shift;
	fcntl(STDERR, F_SETFD, 1);
	my ($ok, $output) = spawn($file);
	if (not $ok) {
		fcntl(STDERR, F_SETFD, 0);
		spawn($file);
	}
	chomp $output;
	$output =~ s/\s+/ /g;
	return $output;
}

sub Requires ($$) {
	my ($f, $expected) = @_;
	require $f;
	my $got = grok $INC{$f};
	cmp_ok $got, "eq", $expected, "$f dependencies";
	ok $? == 0, "$f zero exit status";
}

# Valid for perl-5.8.0 - perl-5.16.1.
Requires "AutoLoader.pm"	=> "";
Requires "Exporter.pm"		=> "perl(Exporter/Heavy.pm)";

