# -*- Perl -*-
use constant TESTS => 4;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI1020' ); }

isa_ok(new Text::NASA_Ames('t/FFI-1020-a.txt'), Text::NASA_Ames::FFI1020);
isa_ok(new Text::NASA_Ames('t/FFI-1020-b.txt'), Text::NASA_Ames::FFI1020);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-1020-a.txt');

    my $count;
    while (my $dataEntry = $f->nextDataEntry) {
	$count++;
	if ($count == 2) {
	    $x = $dataEntry->X()->[0];
	    if ($x != 15) {
		print STDERR "could not evaluate second X 15 != $x\n";
		return 0;
	    }
	    $v = $dataEntry->V()->[2];
	    if ($v != 55000) {
		print STDERR "could not evaluate third value ov second X 55000 != $v\n";
		return 0;

	    }
	}
    }
    my $Lines = 55;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }
	
	
    $f = new Text::NASA_Ames('t/FFI-1020-b.txt');
    while ($f->nextDataEntry) {
    }
    $Lines = 52;
    if ($f->currentLine != $Lines) {
	print STDERR "expected $Lines lines, got ". $f->currentLine;
	return 0;
    }

    1;
}
