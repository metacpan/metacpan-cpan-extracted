# -*- Perl -*-
use constant TESTS => 4;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI1001' ); }

isa_ok(new Text::NASA_Ames('t/FFI-1001-a.txt'), Text::NASA_Ames::FFI1001);
isa_ok(new Text::NASA_Ames('t/FFI-1001-b.txt'), Text::NASA_Ames::FFI1001);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-1001-a.txt');

    my $first;
    while (my $dataEntry = $f->nextDataEntry) {
	unless ($first) {
	    $first = $dataEntry;
	    $x = $first->X()->[0];
	    if ($x != 1.0133E+03) {
		print STDERR "didn't start in first line\n";
		return 0;
	    }
	}
    }
    if ($f->currentLine != 65) {
	print STDERR "expected 65 lines, got ". $f->currentLine;
	return 0;
    }

    $f = new Text::NASA_Ames('t/FFI-1001-b.txt');
    while (my $dataEntry = $f->nextDataEntry) {
    }
    if ($f->currentLine != 63) {
	print STDERR "expected 63 lines, got ". $f->currentLine;
	return 0;
    }
    1;
}
