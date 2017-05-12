use strict;
use Encode qw(decode_utf8 encode_utf8);
use Unicode::LineBreak qw(:all);

@Unicode::LineBreak::Config = (
    CharMax => 998,
    ColMax => 76,
    ColMin => 0,
    Context => 'NONEASTASIAN',
    EAWidth => [[0x302E, 0x302F] => EA_Z()], # 6.1.0: Changed from Mn to Mc.
    Format => 'SIMPLE',
    HangulAsAL => 'NO',
    LBClass => undef,
    LegacyCM => "YES",
    Newline => "\n",
    Prep => undef,
    Sizing => "UAX11",
    Urgent => undef,
);

sub dotest {
    my $in = shift;
    my $out = shift;

    open IN, "<test-data/$in.in" or die "open: $!";
    my $instring = decode_utf8(join '', <IN>);
    close IN;
    my $lb = Unicode::LineBreak->new(@_);
    my $broken = encode_utf8($lb->break($instring));

    my $outstring = '';
    if (open OUT, "<test-data/$out.out") {
	$outstring = join '', <OUT>;
	close OUT;
    } else {
	open XXX, ">test-data/$out.xxx";
	print XXX $broken;
	close XXX;
    }

    is($broken, $outstring, "$in --> $out");
}    

sub dotest_partial {
    my $in = shift;
    my $out = shift;
    my $len = shift;

    my $lb = Unicode::LineBreak->new(@_);
    open IN, "<test-data/$in.in" or die "open: $!";
    my $instring = decode_utf8(join '', <IN>);
    close IN;

    my $broken = '';
    while ($instring) {
	my $p = substr($instring, 0, $len);
	if (length $instring < $len) {
	    $instring = '';
	} else {
	    $instring = substr($instring, $len);
	}
	$broken .= encode_utf8($lb->break_partial($p)); 
    }
    $broken .= encode_utf8($lb->break_partial(undef));

    my $outstring = '';
    if (open OUT, "<test-data/$out.out") {
	$outstring = join '', <OUT>;
	close OUT;
    } else {
	open XXX, ">test-data/$out.xxx";
	print XXX $broken;
	close XXX;
    }

    is($broken, $outstring, "$in --> $out, length $len");
}

sub dotest_array {
    my $in = shift;
    my $out = shift;

    open IN, "<test-data/$in.in" or die "open: $!";
    my $instring = decode_utf8(join '', <IN>);
    close IN;
    my $lb = Unicode::LineBreak->new(@_);
    my @broken = map { encode_utf8("$_") } $lb->break($instring);

    my @outstring = ();
    if (open OUT, "<test-data/$out.out") {
	@outstring = <OUT>;
	close OUT;
    } else {
	open XXX, ">test-data/$out.xxx";
	print XXX join '', @broken;
	close XXX;
    }

    is_deeply(\@broken, \@outstring, "$in --> $out");
}    

1;

