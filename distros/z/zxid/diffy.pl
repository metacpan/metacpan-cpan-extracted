#!/usr/bin/perl
# 2.2.2010, Sampo Kellomaki (sampo@iki.fi)
# 20.11.2010, added Algorithm::Diff based ediff support --Sampo
# $Id$
#
# See also: man diff, diff -u, man sdiff, sdiff -b -w 270, perldoc Algorithm::Diff
#           man cmp, cmp -b
#
# Usage: ./diffy.pl [-ediff] file1 file2
#   -ediff tries to use Algorithm::Diff to produce colorized char-by-char diffs a'la emacs ediff

$ediff = 1,shift if $ARGV[0] eq '-ediff';

$ascii = 2;
# See https://wiki.archlinux.org/index.php/Color_Bash_Prompt
#sub red   { $ascii > 1 ? "\e[1;31m$_[0]\e[0m" : $_[0]; }  # red text
#sub green { $ascii > 1 ? "\e[1;32m$_[0]\e[0m" : $_[0]; }
#sub red   { $ascii > 1 ? "\e[1;41m$_[0]\e[0m" : $_[0]; }   # red background, black bold text
#sub green { $ascii > 1 ? "\e[1;42m$_[0]\e[0m" : $_[0]; }
sub redy   { $ascii > 1 ? "\e[41m$_[0]\e[0m" : $_[0]; }   # red background, black text (no bold)
sub greeny { $ascii > 1 ? "\e[42m$_[0]\e[0m" : $_[0]; }

sub simple_line_diff {
    my ($a, $b) = @_;
    my @a = split /\n/, $a;
    my @b = split /\n/, $b;
    print "\t- reference output\n\t+ testrun\n";
    my $i,$j,$n=10;
    print "\toutputs differ in length ($#a vs. $#b)\n" if $#a != $#b;
    for ($i=0, $j=0; $i <= $#a && $j <= $#b; ++$i, ++$j) {
	next if $a[$i] eq $b[$j];
	if (!--$n) {
	    print "\tToo many differences. Output truncated. Run real diff.\n";
	    last;
	}
	$a[$i] = substr($a[$i],0,80);
	$b[$j] = substr($b[$j],0,80);
	if ($a[$i+1] eq $b[$j]) {       # Extra line in a
	    print "\t".($i+1).": - $a[$i]\n";
	    ++$i;
	} elsif ($a[$i] eq $b[$j+1]) {  # Extra line in b
	    print "\t".($j+1).": + $b[$j]\n";
	    ++$j;
	} else {
	    print "\t".($i+1).": - $a[$i]\n\t".($j+1).": + $b[$j]\n";
	}
    }
    if ($n) {
	for (; $i <= $#a; ++$i) {
	    if (!--$n) {
		print "\tToo many differences. Output truncated. Run real diff.\n";
		last;
	    }
	    print "\t".($i+1).": - $a[$i]\n";
	}
    }
    if ($n) {
	for (; $j <= $#b; ++$j) {
	    if (!--$n) {
		print "\tToo many differences. Output truncated. Run real diff.\n";
		last;
	    }
	    print "\t".($j+1).": - $a[$j]\n";
	}
    }
}

$line_len = 160;

sub char_diff {
    my ($a, $b) = @_;
    my @a = split //, $a;
    my @b = split //, $b;
    my ($i, $j, $a_line, $b_line, $diff_line);
    for ($i = $j = 0; $i <= $#a && $j <= $#b; ++$i, ++$j) {
	#warn "CHAR $i $j  $a[$i]  $b[$j]  " . (($a[$i] eq $b[$j])?'':'***');
	if (length $diff_line >= $line_len) {
	    print "$a_line\n";
	    print "$b_line\n";
	    print "$diff_line\n";
	    $a_line = $b_line = $diff_line = '';
	}
	$a_line .= $a[$i];
	$b_line .= $b[$j];
	if ($a[$i] eq $b[$j]) {
	    $diff_line .= ' ';
	} else {
	    $diff_line .= '*';
	}
    }

    print "$a_line\n";
    print "$b_line\n";
    print "$diff_line\n";
}

sub ediffy {
    my ($data1,$data2) = @_;
    require Algorithm::Diff;
    my @seq1 = split //, $data1;
    my @seq2 = split //, $data2;
    my $diff = Algorithm::Diff->new( \@seq1, \@seq2 );
    
    $diff->Base(1);   # Return line numbers, not indices
    while(  $diff->Next()  ) {
        if (@sames = $diff->Same()) {
	    print @sames;
	    next;
	}
        if (@dels = $diff->Items(1)) {
	    print redy(join '', @dels);
	}
        if (@adds = $diff->Items(2)) {
	    print greeny(join '', @adds);
	}
    }
}

sub readall {
    my ($f) = @_;
    my ($pkg, $srcfile, $line) = caller;
    undef $/;         # Read all in, without breaking on lines
    open F, "<$f" or die "$srcfile:$line: Cant read($f): $!";
    binmode F;
    #flock F, 1;
    my $x = <F>;
    #flock F, 8;
    close F;
    return $x;
}

($file1, $file2) = @ARGV;

#warn "file1($file1) file2($file2)";

$data1 = readall $file1;
$data2 = readall $file2;

if ($ediff) {
    ediffy($data1,$data2);
} else {
    char_diff($data1, $data2);
    #simple_line_diff($data1, $data2);
}

__END__
