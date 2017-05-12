package t::FF_Common;
use strict;
use warnings;
use POSIX qw(tmpnam);
use Exporter ();
use File::Spec::Functions;
use Fatal qw(open close);

BEGIN {
	our @ISA = qw(Exporter);
	our @EXPORT = qw(%Common slurp_file unslurp_file testfile
	diff copy_binary);
	our @EXPORT_OK = @EXPORT;
}


our $DEBUG;
our %Common;


sub init {
	if ("@_" =~ /\bdebug\b/) {
		$DEBUG = 1;
	}

	my $tmpnam = $DEBUG ? '/tmp/tfa-test.dir' : tmpnam();
	%Common = (
		tempdir => $tmpnam,
		tempin => catfile($tmpnam,'input'),
		tempout => catfile($tmpnam,'output'),
	);

	return if (-d $Common{tempdir});
	mkdir $Common{tempdir};
	unslurp_file(catfile($Common{tempdir},'t.test.Tie-FlatFile-Array'), '');
}



sub cleanup {
	return if $DEBUG;

	unlink $Common{tempin};
	unlink $Common{tempout};
	my @temps = glob(catfile($Common{tempdir},'t.*'));
	unlink @temps;
	rmdir $Common{tempdir};
}

sub slurp_file {
	my $filename = shift;
	my $fh;
	local $/;

	open $fh, '<:raw', $filename;
	my $data = <$fh>;
	close $fh;
	$data;
}

sub unslurp_file {
	my $filename = shift;
	my $fh;

	open $fh, '>:raw', $filename;
	print $fh @_;
	close $fh;
	1;
}

sub testfile {
	my $num = shift;
	catfile($Common{tempdir}, "t.$num");
}

sub diff {
	my ($name1, $name2) = @_;
	my $file1 = slurp_file($name1);
	my $file2 = slurp_file($name2);
	$file1 eq $file2;
}

sub copy_binary {
	my ($source, $dest) = @_;
	local $/ = \1024;

	open (my $ifh, '<:raw', $source);
	open (my $ofh, '>:raw', $dest);
	while (my $line = <$ifh>) {
		print $ofh $line;
	}
	close $ofh;
	close $ifh;
}



1;

