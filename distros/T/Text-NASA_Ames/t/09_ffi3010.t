# -*- Perl -*-
use constant TESTS => 3;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI3010' ); }

isa_ok(new Text::NASA_Ames('t/FFI-3010.txt'), Text::NASA_Ames::FFI3010);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-3010.txt');
    my $count;
    while (my $dataEntry = $f->nextDataEntry) {
	$count++;
	if ($count == 37) {
	    $x1 = $dataEntry->X()->[0];
	    $x2 = $dataEntry->X()->[1];
	    $x3 = $dataEntry->X()->[2];
	    if ($x1 != -60) {
		print STDERR "could not evalute 37th X1 -60 != $x1\n";
		return 0;
	    }
	    if ($x2 != 40) {
		print STDERR "could not evaluate 37th X2 40 != $x2\n";
		return 0;
	    }
	    if ($x3 != 355) {
		print STDERR "could not evaluate 37th X3 355 != $x3\n";
		return 0;
	    }
	    $v = $dataEntry->V()->[0];
	    if ($v != 289) {
		print STDERR "could not evaluate (10,10):  289 != $v\n";
		return 0;

	    }
	}
    }
    my $Lines = 52;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }
	
    1;
}
