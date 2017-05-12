# -*- Perl -*-
use constant TESTS => 3;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI2310' ); }

isa_ok(new Text::NASA_Ames('t/FFI-2310.txt'), Text::NASA_Ames::FFI2310);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-2310.txt');
    my $count;
    while (my $dataEntry = $f->nextDataEntry) {
	$count++;
	if ($count == 9) {
	    $x1 = $dataEntry->X()->[0];
	    $x2 = $dataEntry->X()->[1];
	    if ($x1 != 60) {
		print STDERR "could not evaluate second X1 60 != $x1\n";
		return 0;
	    }
	    if ($x2 != 10) {
		print STDERR "could not evaluate second X2 10 != $x2\n";
		return 0;
	    }
	    $v = $dataEntry->V()->[0];
	    if ($v != 14.9) {
		print STDERR "could not evaluate (40,10):  14.9 != $v\n";
		return 0;

	    }
	}
    }
    my $Lines = 54;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }
    1;
}
