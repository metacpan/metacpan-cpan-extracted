# -*- Perl -*-
use constant TESTS => 3;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI2160' ); }

isa_ok(new Text::NASA_Ames('t/FFI-2160.txt'), Text::NASA_Ames::FFI2160);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-2160.txt');
    my $count;
    while (my $dataEntry = $f->nextDataEntry) {
	$count++;
	if ($count == 9) {
	    $x1 = $dataEntry->X()->[0];
	    $x2 = $dataEntry->X()->[1];
	    if ($x1 != 10) {
		print STDERR "could not evaluate 9th X1 10 != $x1\n";
		return 0;
	    }
	    my $covent = 'Coventry';
	    unless ($x2 eq $covent) {
		print STDERR length($covent). " ". length($x2);
		print STDERR "could not evaluate 9th X2 $covent ne $x2\n";
		return 0;
	    }
	    $v = $dataEntry->V()->[0];
	    if ($v != 1.9) {
		print STDERR "could not evaluate (10,$covent):  1.9 != $v\n";
		return 0;

	    }
	}
    }
    my $Lines = 81;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }
    1;
}
