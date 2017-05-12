#!/usr/bin/perl

=head2 grade_list.pl

=item Creator: Andrew Robertson

=back

=item Revised: 20020527

=back

=item License: GPL 2

=back

This is used to generate a perl index of japanese kanji, organized by grade.

This uses kanjidic by Jim Breen, which is available from ???.com/???

=cut

use Data::Dumper;

# 	'grade number' to '
# %grades = ('g1' => ['3ab3', '3ba2']);
my %grades;

	my $line;
	open (KANJIDIC, 'kanjidic');
	while ($line = <KANJIDIC>) {
		if ($line !~ /^#/) {
			if ($line =~ /.*\s(U[0-9a-f]{4})\s.*(G\d)/) {
				#print "$2\t$1\n";
				push(@{$grades{$2}}, $1);
			} # ignore others, either no UNICODE or no Grade
		}
	}
	print @{$grades{'G1'}} . "\n";
	my $count = @{$grades{'G1'}};
	print "Number $count\n";
	print @{$grades{'G8'}} . "\n";
	my $count = @{$grades{'G8'}};
	print "Number $count\n";
	open (GRADE_HASH, '> temp.pl');
	print GRADE_HASH Dumper \%grades;
	close (GRADE_HASH);
	close(KANJIDIC);
