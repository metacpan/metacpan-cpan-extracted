# -*- Perl -*-
use constant TESTS => 3;
use Test::More tests => TESTS;
use Data::Dumper;

BEGIN { use_ok( 'Text::NASA_Ames::FFI1010' ); }

isa_ok(new Text::NASA_Ames('t/FFI-1010.txt'), Text::NASA_Ames::FFI1010);

ok (&loop);


sub loop {
    my $f = new Text::NASA_Ames('t/FFI-1010.txt');

    my $first;
    while (my $dataEntry = $f->nextDataEntry) {
	unless ($first) {
	    $first = $dataEntry;
	    $x = $first->X()->[0];
	    if ($x != 10) {
		print STDERR "didn't start in first line\n";
		return 0;
	    }
	}
    }
    if ($f->currentLine != 84) {
	print STDERR "expected 84 lines, got ". $f->currentLine;
	return 0;
    }

    1;
}
