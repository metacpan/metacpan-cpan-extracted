#!/usr/bin/perl -w

use strict;
use utf8;
require Text::Metaphone::Amharic;

my $am = new Text::Metaphone::Amharic ( granularity => "high" );

my $count = 0;
print "High Granularity:\n";
foreach ($am->metaphone ( "ጠትጠ" )) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";

$am->granularity ( "medium" );
$count = 0;
print "Medium Granularity:\n";
foreach ($am->metaphone ( "ጠትጠ" )) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";

$am->granularity ( "low" );
$count = 0;
print "Low Granularity:\n";
foreach ($am->metaphone ( "ጠትጠ" )) {
	$count++;
	printf "%2i: $_\n", $count;
}


__END__

=head1 NAME

granularity.pl - Amharic Metaphone demonstrator granularity levels.

=head1 SYNOPSIS

./granularity.pl

=head1 DESCRIPTION

This is a simple demonstration script that generates Amharic Metaphone
keys in Ethiopic script that demonstrates the three granularity levels
("high", "medium" and "low") with a fictional word.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::Metaphone::Amharic>

=cut
