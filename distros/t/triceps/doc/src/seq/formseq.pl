#!/usr/bin/perl
# A script that formats a sequence file

use strict;

my $id = shift @ARGV;
die "Use: formseq seqid <seqfile.txt >seqfile.xml\n" if ($id eq "");

my @lines;
my $descr;
my $havetitle = 1;

while(<STDIN>) {
	chomp;
	if (/^#\s+(.*)/) {
		$descr = $1;
		next;
	}
	if (/^#NOTITLE/) {
		$havetitle = 0;
		next;
	}
	s/^\s+//; # remove the leading space
	s/[.;]*$/;/; # add a ; if it was missing
	push @lines, $_;
}

die "Missing title\n" if ($havetitle && $descr eq "");

if ($havetitle) {
	print '<figure id="' . $id . '" >' . "\n";
	print "<title>$descr</title>\n";
}
print '<informaltable frame="none" colsep="0" rowsep="0">' . "\n";
print "\n";
print '<tgroup cols="4" align="left">' ."\n";
print '<?dbhtml cellspacing="0" ?>' ."\n";
print '<?dbhtml cellpadding="0" ?>' ."\n";
print '<colspec colnum="1" colname="col1" colwidth="0.5in"/>' ."\n";
print '<colspec colnum="2" colname="col2" colwidth="0.5in"/>' ."\n";
print '<colspec colnum="3" colname="col3" colwidth="0.5in"/>' ."\n";
print '<colspec colnum="4" colname="col4" colwidth="1*"/>' ."\n";
print "<tbody>\n";

my %start = ( "A" => 1, "B" => 2, "C" => 3, "D" => 4 );

for my $it (@lines) {
	$it =~ /Thread ([A-D]) /
		or die "Each line must start with 'Thread [A-D] ', bad line: '$it'\n";
	my $st = $start{$1};
	print "<row>\n";
	for (my $i = 1; $i < $st; $i++) {
		print '  <entry colname="col' . $i . '">&#x2003;</entry>' . "\n";
	}
	print '  <entry namest="col' . $st . '" nameend="col4">' . "\n";
	print "  <itemizedlist><listitem>$it</listitem></itemizedlist>\n";
	print "  </entry>\n";
	print "</row>\n";
}

print "</tbody>\n";
print "</tgroup>\n";
print "</informaltable>\n";
if ($havetitle) {
	print "</figure>\n";
}
