#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use ULID::Tiny qw(ulid ulid_date);
use Time::HiRes qw(time);

my %opts = ();

################################################################################

print "Monotonically increasing ULIDs:\n";

# Generate a ULID and inspect it
for (1 .. 5) {
	my $id = ulid();
	say "Generated: $id";
}

################################################################################

%opts = ( unique => 1);

print "\n";
print "Unique ULIDs:\n";

# Generate a ULID and inspect it
for (1 .. 5) {
	my $id = ulid(%opts);
	say "Generated: $id";
}

################################################################################

%opts = ( unique => 0);

print "\n";
print "Visual of timestamp vs random:\n";
# Generate a ULID and inspect it
for (1 .. 5) {
	my $id = ulid(%opts);
	my $p1 = color('194', substr($id, 0, 10));
	my $p2 = color('230', substr($id, 10));
	say "Generated: $p1$p2";
}

################################################################################
################################################################################

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
	my ($str, $txt) = @_;

	if (-t STDOUT == 0 || $ENV{NO_COLOR}) { return $txt // ""; } # No interactive terminal
	if (!length($str) || $str eq 'reset') { return "\e[0m";    } # No string = RESET

	# Some predefined colors/commands
	my %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	my %cmd_map   = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);

	# Pre-process the string.
	$str =~ s/on_/-/;                              # "on_" becomes a negative number
	$str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg; # command number

	my @parts = split("_", $str);
	foreach my $p (@parts) {
		my $cmd_num = $cmd_map{$p // 0};

		if    ($cmd_num)                      { $p = $cmd_num;  }
		elsif (defined($p) && $p =~ /^-(.+)/) { $p = "48;5;$p"; }
		elsif (defined($p))                   { $p = "38;5;$p"; }
	}

	my $ret = "\e[" . join(";", @parts) . "m";

	if (defined($txt)) { $ret .= $txt . "\e[0m"; }

	return $ret;
}
