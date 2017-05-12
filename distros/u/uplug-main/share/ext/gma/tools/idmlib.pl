$FALSE = 0;
$TRUE = 1;
$INFINITY = 9999999999;
$TINY = 0.0000001;


sub min {
    my($x, $y) = @_;
    if ($x < $y) {
	return $x;
    } else {
	return $y;
    };
};


sub minratio {
# returns smaller of x/y or y/x
    my($x, $y) = @_;
    if ($x < $y) {
	return $x / $y;
    } else {
	return $y / $x;
    };
};


sub max {
    my($x, $y) = @_;
    if ($x > $y) {
	return $x;
    } else {
	return $y;
    };
};


sub round {
# rounds numbers to the specified precision
    my($prec,$orig) = @_;
    my($sign) = $orig <=> 0;
    return int($orig / $prec + .5 * $sign) * $prec;
};


sub maxar {
# returns @$arptr index with highest value, 
# out of those listed in @$choice
    ($arptr, $choice) = @_;

    my($m, $i) = (0, 0);
    while ($i <= $#$choice) {
	if ($$arptr[$$choice[$i]] > $$arptr[$$choice[$m]]) {
	    $m = $i;
	};
	$i++;
    };
    return $$choice[$m];
};


sub minar {
# returns @$arptr index with lowest value, 
# out of those listed in @$choice
    ($arptr, $choice) = @_;

    my($m, $i) = (0,0);
    while ($i <= $#$choice) {
	if ($$arptr[$$choice[$i]] < $$arptr[$$choice[$m]]) {
	    $m = $i;
	};
	$i++;
    };
    return $$choice[$m];
};

sub maxar_string {
# returns @$arptr index with highest value, 
# out of those listed in @$choice
    ($arptr, $choice) = @_;

    my($m, $i) = (0, 0);
    while ($i <= $#$choice) {
	if ($$arptr[$$choice[$i]] gt $$arptr[$$choice[$m]]) {
	    $m = $i;
	};
	$i++;
    };
    return $$choice[$m];
};


sub minar_string {
# returns @$arptr index with lowest value, 
# out of those listed in @$choice
    ($arptr, $choice) = @_;

    my($m, $i) = (0,0);
    while ($i <= $#$choice) {
	if ($$arptr[$$choice[$i]] lt $$arptr[$$choice[$m]]) {
	    $m = $i;
	};
	$i++;
    };
    return $$choice[$m];
};

sub eqar {
# boolean string array "equals"
    my($ptr1, $ptr2) = @_;
    my($i);

    if ($#{$ptr1} != $#{$ptr2}) {
	return $FALSE;
    };
    for($i = 0; $i < @$ptr1; $i++) {
	if ($$ptr1[$i] ne $$ptr2[$i]) {
	    return $FALSE;
	};
    };

    return $TRUE;
};


sub eqar_numeric {
# boolean numeric array "equals"
    my($ptr1, $ptr2) = @_;
    my($i);

    if ($#{$ptr1} != $#{$ptr2}) {
	return $FALSE;
    };
    for($i = 0; $i < @$ptr1; $i++) {
	if ($$ptr1[$i] != $$ptr2[$i]) {
	    return $FALSE;
	};
    };

    return $TRUE;
};


sub gtar_numeric {
# boolean numeric array "greather than"
    my($ptr1, $ptr2) = @_;
    my($i, $maxind);

    $maxind = &min($#{$ptr1}, $#{$ptr2});
    for($i = 0; $i <= $maxind; $i++) {
	if ($$ptr1[$i] < $$ptr2[$i]) {
	    return $FALSE;
	};
    };
    if ($#{$ptr1} <= $#{$ptr2}) {
	return $FALSE;
    };

    return $TRUE;
};


sub bynumar { 
# sort subroutine: numeric arrays
    my($i, $uc, $lc);

    if ($#{$a} <= $#{$b}) {
	$lc = $a;
	$uc = $b;
    } else {
	$uc = $a;
	$lc = $b;
    } 
    for($i = 0; $i < @$lc; $i++) {
	if ($$a[$i] < $$b[$i]) {
	    return -1;
	} elsif ($$a[$i] > $$b[$i]) {
	    return 1;
	};
    };
    
    if ($#{$a} < $#{$b}) {
	return -1;
    } else {
	return 0;
    };
};

sub arcopy {
# returns a copy of the array
# used for passing recursive arrays by value
    my($arptr) = shift;

    my(@newar);

    foreach $el (@$arptr) {
	if (not ref($el)) {
	    push(@newar, $el);
	} elsif (ref($el) eq "ARRAY") {
	    push(@newar, &arcopy($el));
	} else {
	    die "Element in recursive array is a non-array reference!\n";
	};
    };

    return [@newar];
};


sub insar_numeric_uniq {
# inserts numeric array into sorted list of arrays
# if array already exists, only one copy is kept
# returns pointer to new list of arrays, and index of insertion
# if not unique, then index of insertion = -1

    my($ararptr, $iarptr) = @_;
    my($i);

    for($i = 0; $i <= $#{$ararptr}; $i++) {
	if (&eqar_numeric($$ararptr[$i], $iarptr)) {
	    return ($ararptr, -1); # no insertion
	} elsif (&gtar_numeric($$ararptr[$i], $iarptr)) {
	    splice(@$ararptr, $i, $iarptr);
	    return ($ararptr, $i);
	};
    };

    # greatest so far
    push(@$ararptr, $iarptr);
    return ($ararptr, $i+1);
};


sub rnd {
    my($min, $max) = @_;
    $range = $max - $min + 1;
    return int(rand() * $range + $min);
};


sub byvalue { $val{$a} <=> $val{$b} };
sub bynumber { $a <=> $b };


sub isnumber {
    my($x) = @_;
    $z = $x;
    return ($z + 0 != 0 || $x eq "0" || $x eq "0.0");
};


sub Log {
    my($p) = @_;

    if ($p == 0)
    {-999999;}
    else
    {log($p)};
}

sub string_lcs {
# length of longest common subsequence of two strings
# uses dynamic programming
    my($str1, $str2) = @_;
    my(@m, $i, $j);
    
    my(@c1) = split('', $str1);
    my(@c2) = split('', $str2);

    if ($c1[0] eq $c2[0]) {
	$m[0][0] = 1;
    } else {
	$m[0][0] = 0;
    };
    for($i = 1; $i <= $#c1; $i++) {
	if ($c1[$i] eq $c2[0]) {
	    do {
		$m[$i][0] = 1;
		$i++;
	    } until ($i > $#c1);
	} else {
	    $m[$i][0] = 0;
	};
    };
    for($j = 1; $j <= $#c2; $j++) {
	if ($c1[0] eq $c2[$j]) {
	    do {
		$m[0][$j] = 1;
		$j++;
	    } until ($j > $#c2);
	} else {
	    $m[0][$j] = 0;
	};
    };
    for($i = 1; $i <= $#c1; $i++) {
	for($j = 1; $j <= $#c2; $j++) {
	    if ($c1[$i] eq $c2[$j]) {
		$m[$i][$j] = $m[$i-1][$j-1] + 1;
	    } else {
		$m[$i][$j] = &max($m[$i-1][$j], $m[$i][$j-1]);
	    };
	};
    };

    return $m[$#c1][$#c2];
};


sub bsearch {
# returns index of highest element in array that
#         is smaller than target
# array should be sorted in increasing order
# N.B.:  if whole array is to be searched, then
#        the first $min parameter should = -1.
#        This way, if $$arptr[0] > $target, the
#        search can return -1;
# Also, if $#$arptr < 0, returns -1;
# this version does numeric comparisons

    my( $target, $min, $max, $arptr) = @_;
    if ($#$arptr < 0) {return -1};
    my( $shot, $comp);

    if ($min >= $max - 1) {
	$comp = $$arptr[$max] <=> $target;
	if ($comp < 0) {
	    return $max;
	} else {
	    return $min;
	};
    };

    $shot = int(($max + $min) * .5);
    $comp = $$arptr[$shot] <=> $target;
    if ($comp == 0) {
	return $shot;
    } elsif ( $comp < 0 ) {
	return &bsearch( $target, $shot, $max, $arptr);
    } else {
	return &bsearch( $target, $min, $shot, $arptr);
    };
};

sub nupdsort {
# numerical push-down sort, with uniq
    my($stackptr, $inputptr) = @_;
    my($ss);

    foreach $ss (@$inputptr) {
	$outind = $#$stackptr;
	while ($outind >=0 and
	       ($$inputptr[$ss] < $$stackptr[$outind])) {
	    $outind--;
	};
	if ($$inputptr[$ss] == $$stackptr[$outind]) {
	    next;
	};
	$outind++;
	splice(@$stackptr, $outind, 0, $$inputptr[$ss]);
    };

    return $stackptr;
};

sub usort {
# string sort with unique
    my(@sorted) = sort @_;
    my($i);

    for($i = $#sorted; $i > 0; $i--) {
	if ($sorted[$i] eq $sorted[$i - 1]) {
	    splice(@sorted, $i, 1);
	};
    };

    return \@sorted;
};

sub dump_hash {
    my($hashptr) = shift;
    my($key, $value);

    while (($key,$value) = each %$hashptr) {
	print "$key $value\n";
    };
};

return 1;
