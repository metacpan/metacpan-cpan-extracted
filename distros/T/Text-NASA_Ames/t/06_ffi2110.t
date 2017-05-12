# -*- Perl -*-
use constant TESTS => 3;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI2110' ); }

isa_ok(new Text::NASA_Ames('t/FFI-2110.txt'), Text::NASA_Ames::FFI2110);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-2110.txt');
    my $count;
    while (my $dataEntry = $f->nextDataEntry) {
	$count++;
	if ($count == 6) {
	    $x1 = $dataEntry->X()->[0];
	    $x2 = $dataEntry->X()->[1];
	    if ($x1 != 40) {
		print STDERR "could not evaluate second X1 40 != $x1\n";
		return 0;
	    }
	    if ($x2 != 10) {
		print STDERR "could not evaluate second X2 10 != $x2\n";
		return 0;
	    }
	    $v = $dataEntry->V()->[0];
	    if ($v != 28) {
		print STDERR "could not evaluate (40,10):  28 != $v\n";
		return 0;

	    }
	}
    }
    my $Lines = 91;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }
    1;
}
