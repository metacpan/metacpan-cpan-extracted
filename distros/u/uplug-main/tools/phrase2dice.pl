#!/usr/bin/perl

my $DiceThr = 0.0001;

my %transl = ();
my $current = '';

while (<>){
    chomp;
    my @parts = split(/ \|\|\| /);

    #---------------------------------------------------
    # different types of tests / filters are possible
    #---------------------------------------------------

    ## only one-word phrases ...
    next if ($parts[0]=~/ /);
    next if ($parts[1]=~/ /);

    ## only if one side is a single word phrase
#    next if ($parts[0]=~/ / && $parts[1]=~/ /);


    my $srcword = $parts[0];
    my $trgword = $parts[1];

    $srcword=~s/\/\S*//g;  # remove POS tag (if attached)
    $trgword=~s/\/\S*//g;


    ## only one-word lower-case letter-phrases 
#    next if ($srcword=~/\P{IsLl}/);
#    next if ($trgword=~/\P{IsLl}/);

    ## only lower-case letter-phrases (MWUs allowed)
    next if ($srcword=~/[^\p{IsLl}\s]/);
    next if ($trgword=~/[^\p{IsLl}\s]/);




    if ($current ne $parts[0]){
	if (keys %transl){

	    ## print only if there are at least 2 alternative translations!
	    if (keys %transl > 1){
		print join('', sort { $transl{$b} <=> $transl{$a} } keys %transl);
		print "\n";
	    }
	    %transl = ();
	}
	$current = $parts[0];
    }

    my @scores = split (/ /,$parts[2]);
    my @freqs = split (/ /,$parts[4]);
    my $cooc1 = int($scores[0]*$freqs[0]+0.5);
    my $cooc2 = int($scores[2]*$freqs[1]+0.5);

    # should be the same ....
    # if not approximate as average
    if ($cooc1 != $cooc2){
	$cooc1 = int(($cooc1+$cooc2)/2+0.5);
    }
    my $dice = 2*$cooc1/($freqs[0]+$freqs[1]);
    if ($dice>=$DiceThr){
#	$transl{$cooc1."\t".$dice."\t".$_."\n"} = $dice
	my $string = join("\t",($cooc1,$dice,$parts[0],$parts[1],
				$scores[0],$scores[1]));
	$transl{$string."\n"} = $dice
	# $transl{$cooc1."\t".$dice."\t".$_."\n"} = $dice
	# print $_,"\t",$cooc1,"\t",$dice,"\n";
    }
}


if (keys %transl){
    print join('', sort { $transl{$b} <=> $transl{$a} } keys %transl);
    print "\n";
}
