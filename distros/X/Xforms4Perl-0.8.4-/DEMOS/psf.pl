#!/usr/bin/perl
# List a hierarchical display of processes
#
$PID = 2;
$PPID = 1;
%dtl_pref=undef;
#
# First build the child/parent relationships
#

open(PROCESSES, "ps -xj |");
<PROCESSES>;
for ($i = 0; $process = <PROCESSES>; ++$i) {
	chop $process;
	@items = split(/\s+/, " $process");
	$parent{$items[$PID]} = $items[$PPID];
}

#
# Now get what the user really wants
#

open(PROCESSES, "ps @ARGV |");
@result = <PROCESSES>;
chop @result;

#
# Parse out the PID
#

@headings = split(/\s+/, " $result[0]");
for ($i = 0; $i <= $#headings && ($PID1 == 0); ++$i) {
	$PID1 = $i if ($headings[$i] eq "PID");
}

#
# Build parent/child list for requested processes (ignoring the ps processes
# themselves - a slightly ugly byproduct!)
#

for ($i = 1; $i <= $#result; ++$i) {
	@temp = split(/\s+/, " $result[$i]");
	$temp_child = $temp[$PID1];
	next if (! defined($parent{$temp_child}));
	$temp_parent = $parent{$temp_child};
	$childlist{$temp_parent} = "$temp_child $childlist{$temp_parent}" unless ($temp_child == $temp_parent);
 	($dtl_pref{$temp_child}, $dtl_time{$temp_child}, $dtl_cmd{$temp_child}) = split(/(\s\d*\:\d\d\s)/, $result[$i]);
        $temp_l = length($dtl_pref{$temp_child});
        $dtl_pref_l = $temp_l if ($dtl_pref_l < $temp_l);
}

#
# Print a heirarchical list of processes as per the users request
#
@headings = split(/( TIME )/, " $result[0]");
print "$headings[0]  $headings[1]" . "$headings[2]\n";
foreach $parent (sort numsort (keys(%childlist))) {
	heirprint ($parent) if (defined($childlist{$parent}));
}
exit;

sub heirprint {
	#
	# print the heirarchy associated with &_[0] and its immediate children
	#

	my($old_tab_pref) = $tab_pref;
	my($old_child_pref) = $child_pref;
	my($old_tab_suff) = $tab_suff;
	my($process) = @_;

 	if ($dtl_pref{$process}) {
		printf("%-" . $dtl_pref_l . "s%8s%s%s%s\n", 
                        $dtl_pref{$process}, 
                        $dtl_time{$process}, 
                        $tab_pref, 
                        $tab_suff, 
                        $dtl_cmd{$process});
	}

	$tab_pref .= $child_pref;
	my(@child) = split (/\s+/, $childlist{$process});
	my($i) = undef;
	for ($i = 0; defined($child[$i]); $i++) {
		my($nextchild) = $child[$i];
		if ($dtl_pref{$process}) {
			$tab_suff = "\\_ ";
			$child_pref = ($i == $#child ? "   " : "|  "); 
		}
		heirprint($nextchild);
	}
	$tab_pref = $old_tab_pref;
	$child_pref = $old_child_pref;
	$tab_suff = $old_tab_suff;
	delete $childlist{$process};
}

sub numsort {
	return (1) if ($a > $b);
	return (0) if ($a == $b);
	return -1;
}
