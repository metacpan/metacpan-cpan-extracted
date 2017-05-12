# -*- Perl -*-
use constant TESTS => 3;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI4010' ); }

isa_ok(new Text::NASA_Ames('t/FFI-4010.txt'), Text::NASA_Ames::FFI4010);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-4010.txt');
    my $count;
    while (my $dataEntry = $f->nextDataEntry) {
	$count++;
	if ($count == 275) {
	    use Data::Dumper;
	    $x1 = $dataEntry->X()->[0];
	    $x2 = $dataEntry->X()->[1];
	    $x3 = $dataEntry->X()->[2];
	    $x4 = $dataEntry->X()->[3];
	    if ($x1 != -25) {
		print STDERR "could not evalute X1 -25 != $x1\n";
		return 0;
	    }
	    if ($x2 != 90) {
		print STDERR "could not evaluate X2 60 != $x2\n";
		return 0;
	    }
	    if ($x3 != 50) {
		print STDERR "could not evaluate X3 50 != $x3\n";
		return 0;
	    }
	    if ($x4 != 12) {
		print STDERR "could not evaluate X4 12 != $x3\n";
		return 0;
	    }
	    $v = $dataEntry->V()->[0];
	    if ($v != 270) {
		print STDERR "could not evaluate :  270 != $v\n";
		return 0;

	    }
	}
    }
    my $Lines = 84;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }
	
    1;
}
