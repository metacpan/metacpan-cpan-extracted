#!/usr/bin/perl -w

use strict;
use utf8;
require Text::Metaphone::Amharic;

my $am = new Text::Metaphone::Amharic ( granularity => "high" );

my @keys  = $am->metaphone ( "ኘሬዚደንት" );
my $count = 0;
foreach(@keys) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
@keys = $am->metaphone ( "ዓለም" );
$count = 0;
foreach (@keys) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
@keys = $am->metaphone ( "ፀሐይ" );
$count = 0;
foreach (@keys) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
$count = 0;
foreach ($am->metaphone ( "ኀይለ ሥላሴ" )) {
	$count++;
	printf "%2i: $_\n", $count;
}


__END__

=head1 NAME

amphone-high.pl - Amharic Metaphone demonstrator for 5 sample words (High Granularity Usage).

=head1 SYNOPSIS

./amphone-high.pl

=head1 DESCRIPTION

This is a simple demonstration script that generates Amharic Metaphone
keys in Ethiopic script under the "high" granularity setting.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::Metaphone::Amharic>

=cut
