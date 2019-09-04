#!/usr/bin/env perl
use strict;
use warnings;

use lib 'inc/';
use Module::Package 'Au:dry 1';

license('cc0');

my $DefaultVersion  = 'v12.0.0';
my $DefaultDate     = '2019-01-21';

_build_pm();

sub _build_pm {
    my $file;

    foreach (@INC) {
	$file = "$_/unicore/EastAsianWidth.txt";
	last if -e $file;
    }

    my $use_bundled = 1;
    TRY: {
        unless (-e $file) {
            print "*** Cannot find unicore/EastAsianWidth.txt\n";
            last TRY;
        }

        unless (open EAW, $file) {
            print "*** Cannot open $file for reading: $!\n";
            last TRY;
        }

        unless (<EAW> =~ /EastAsianWidth/) {
            print "*** Cannot parse $file.\n";
            last TRY;
        }

        unless (<EAW> =~ /Date: (\d+-\d+-\d+)/ and $1 gt $DefaultDate) {
            print "*** Installed table not newer than the bundled version.\n"; 
            last TRY;
        }

        $use_bundled = 0;
    }

    if ($use_bundled) {
	print "*** Using bundled EastAsianWidth table ($DefaultVersion).\n";
	return;
    }

    my %ToFullName = (
	N	=> 'InEastAsianNeutral',
	A	=> 'InEastAsianAmbiguous',
	H	=> 'InEastAsianHalfwidth',
	W	=> 'InEastAsianWide',
	F	=> 'InEastAsianFullwidth',
	Na	=> 'InEastAsianNarrow',
    );

    my ($prev_code, $prev_categ) = '';
    my $prev_code_end = '';
    my %categ;

    while (<EAW>) {
        if (/^(\w+);(\w+)/) {
            my ($code, $categ) = ($1, $2);
            if ($prev_categ ne $categ) {
                $categ{$ToFullName{$prev_categ}} .= "$prev_code\\t$prev_code_end\n" if $prev_categ;
                $prev_code = $code;
                $prev_categ = $categ;
            }
            $prev_code_end = $code;
        }
        elsif (/^(\w+)\.\.(\w+);(\w+)/) {
            $categ{$ToFullName{$prev_categ}} .= "$prev_code\\t$prev_code_end\n" if $prev_categ;
            $categ{$ToFullName{$3}} .= "$1\\t$2\n";
            $prev_categ = '';
        }
    }

    my $out;
    unless (open PM, 'lib/Unicode/EastAsianWidth.pm') {
	print "*** Cannot read module ($!), falling back to default ($DefaultVersion)\n";
	return;
    }

    while (<PM>) { $out .= $_;    last if /^### BEGIN ###$/ }

    $out .= "our \@EXPORT = qw(\n" . join(
	"\n", sort(values %ToFullName), qw(InFullwidth InHalfwidth)
    ) . "\n);\n\n";

    for my $name (sort values %ToFullName) {
        $out .= << ".";
sub $name {
    return <<"END";
$categ{$name}END
}

.
    }

    while (<PM>) { $out .= $_ and last if /^### END ###$/ }
    while (<PM>) { $out .= $_ }

    close PM;

    chmod 0644, 'lib/Unicode/EastAsianWidth.pm';
    unless (open PM, '>', 'lib/Unicode/EastAsianWidth.pm') {
	print "*** Cannot write to module ($!), falling back to default ($DefaultVersion)\n";
	return;
    }

    print PM $out;
    close PM;
}
