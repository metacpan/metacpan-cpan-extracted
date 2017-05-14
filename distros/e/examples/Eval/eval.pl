while (defined($s = <>)) {          # Read a line into $s
    $result = eval $s;      # Evaluate that line
    if ($@) {               # Check for compile or run-time errors.
        print "Invalid string :\n $s";
    } else {
        print $result, "\n";
    }
}
