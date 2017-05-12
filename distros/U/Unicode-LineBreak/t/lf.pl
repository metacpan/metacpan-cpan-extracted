use strict;
use Text::LineFold;

sub dounfoldtest {
    my $in = shift;
    my $out = shift;
    my $method = shift;

    open IN, "<test-data/$in.in" or die "open: $!";
    my $instring = join '', <IN>;
    close IN;
    my $lf = Text::LineFold->new(@_);
    my $unfolded = $lf->unfold($instring, $method);

    my $outstring = '';
    if (open OUT, "<test-data/$out.out") {
        $outstring = join '', <OUT>;
        close OUT;
    } else {
        open XXX, ">test-data/$out.xxx";
        print XXX $unfolded;
        close XXX;
    }

    is($unfolded, $outstring, "unfold $in, method=$method");
}

sub do5tests {
    my $in = shift;
    my $out = shift;

    open IN, "<test-data/$in.in" or die "open: $!";
    my $instring = join '', <IN>;
    close IN;
    my $lf = Text::LineFold->new(@_);
    my %folded = ();
    foreach my $method (qw(PLAIN FIXED FLOWED)) {
	$folded{$method} = $lf->fold($instring, $method);
	my $outstring = '';
	if (open OUT, "<test-data/$out.".(lc $method).".out") {
	    $outstring = join '', <OUT>;
	    close OUT;
	} else {
	    open XXX, ">test-data/$out.".(lc $method).".xxx";
	    print XXX $folded{$method};
	    close XXX;
	}
	is($folded{$method}, $outstring, "fold $in, method=$method");
    }
    foreach my $method (qw(FIXED FLOWED)) {
	my $outstring = $lf->unfold($folded{$method}, $method);
	if (open IN, "<test-data/$in.norm.in") {
	    $instring = join '', <IN>;
	    close IN;
	}
	is($outstring, $instring, "unfold $out, method=$method");
	#XXXopen XXX, ">test-data/$out.".(lc $method).".xxx";
	#XXXprint XXX $outstring;
	#XXXclose XXX;
    }
}    

sub dowraptest {
    my $in = shift;
    my $out = shift;

    open IN, "<test-data/$in.in" or die "open: $!";
    my $instring = join '', <IN>;
    close IN;
    my $lf = Text::LineFold->new(@_);
    my $folded = $lf->fold("\t", ' ' x 4, $instring);

    my $outstring = '';
    if (open OUT, "<test-data/$out.wrap.out") {
        $outstring = join '', <OUT>;
        close OUT;
    } else {
        open XXX, ">test-data/$out.wrap.xxx";
        print XXX $folded;
        close XXX;
    }

    is($folded, $outstring, "wrap $in");
}

1;

