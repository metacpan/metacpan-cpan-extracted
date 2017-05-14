open (F, "oscar.txt") || die "Could not open database: $:";
%category_index = (); %year_index = ();
while (defined($line = <F>)) {
    chomp $line;
    ($year, $category, $name) = split (/:/, $line);
    create_entry($year, $category, $name) if $name;
}

print "Entries for the year 1995:\n";
print_entries_for_year(1995);

exit(0);


sub create_entry {             # create_entry (year, category, name)
    my($year, $category, $name) = @_;
    # Create an anonymous list for each entry
    $rlEntry = [$year, $category, $name];
    # Add this to the two indexes
    push (@{$year_index {$year}}, $rlEntry);         # By Year
    push (@{$category_index{$category}}, $rlEntry);  # By Category
}  


sub print_entries_for_year {
    my($year) = @_;
    print ("Year : $year \n");
    foreach $rlEntry (@{$year_index{$year}}) {
        print ("\t",$rlEntry->[1], "  : ",$rlEntry->[2], "\n");
    }
}


sub print_all_entries_for_year {
    foreach $year (sort keys %year_index) {
        print_entries_for_year($year);
    }
}

sub print_entry {
    my($year, $category) = @_;
    foreach $rlEntry (@{$year_index{$year}}) {
        if ($rlEntry->[1] eq $category) {
            print "$category ($year), ", $rlEntry->[2], "\n";
            return;
        }
    }
    print "No entry for $category ($year) \n";
}
