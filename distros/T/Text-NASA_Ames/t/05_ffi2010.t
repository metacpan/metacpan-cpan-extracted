# -*- Perl -*-
use constant TESTS => 5;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI2010' ); }

isa_ok(new Text::NASA_Ames('t/FFI-2010-a.txt'), Text::NASA_Ames::FFI2010);
isa_ok(new Text::NASA_Ames('t/FFI-2010-b.txt'), Text::NASA_Ames::FFI2010);
isa_ok(new Text::NASA_Ames('t/FFI-2010-c.txt'), Text::NASA_Ames::FFI2010);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-2010-a.txt');
    my $count;
    while (my $dataEntry = $f->nextDataEntry) {
	$count++;
	if ($count == 11) {
	    $x1 = $dataEntry->X()->[0];
	    $x2 = $dataEntry->X()->[1];
	    if ($x1 != 10) {
		print STDERR "could not 11th second X1 10 != $x1\n";
		return 0;
	    }
	    if ($x2 != 10) {
		print STDERR "could not evaluate 11th X2 10 != $x2\n";
		return 0;
	    }
	    $v = $dataEntry->V()->[0];
	    if ($v != 5.5) {
		print STDERR "could not evaluate (10,10):  5.5 != $v\n";
		return 0;

	    }
	}
    }
    my $Lines = 60;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }
	
    $f = new Text::NASA_Ames('t/FFI-2010-b.txt');
    while ($f->nextDataEntry) {
    }
    $Lines = 54;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }

    $f = new Text::NASA_Ames('t/FFI-2010-c.txt');
    while ($f->nextDataEntry) {
    }
    $Lines = 53;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }

    1;
}
