#!/opt/bin/perl
# Extracts columns of text from a file
# Usage : col [-s<n>] col-range1, col-range2, files ...
# where col-range is specified as col1-col2 (column 1 through column2) 
#         or col1+n, where n is the number of columns.
$size = 0;          # 0 => line-oriented input, else fixed format.
@files = ();        # List of files
$open_new_file = 1; # Force get_next_line() to open the first file
$debugging = 0;     # Enable with -d commmand line flag

generate_part1();  
generate_part2();
generate_part3();
col();           # sub col has now been generated. Call it !
exit(0);


#------------------------------------------------------------------
sub generate_part1 {
    # Generate the initial invariant code of sub col()
    $code  = 'sub col { my $tmp;';           # Note the single quotes
    $code .= 'while (1) {$s = get_next_line(); $col = "";';
    $delimiter = '|';
}

#------------------------------------------------------------------
sub generate_part2 {
    # Process arguments
    foreach $arg (@ARGV) {
        if (($col1, $col2) = ($arg =~ /^(\d+)-(\d+)/)) {
            $col1--;# Make it 0 based
            $offset = $col2 - $col1;
            add_range($col1, $offset);
        } elsif (($col1, $offset) = ($arg =~ /^(\d+)\+(\d+)/)) {
            $col1--;
            add_range($col1, $offset);
        } elsif ($size = ($arg =~ /-s(\d+)/)) {
            # noop
        } elsif ($arg =~ /^-d/) {
            $debugging = 1;
        } else {
            # Must be a file name
            push (@files, $arg);
        }
    }
}

#------------------------------------------------------------------
sub generate_part3 {
    $code .= 'print $col, "\n";}}';

    print $code if $debugging; # -d flag enables debugging.
    eval $code;
    if ($@) {
        die "Error ...........\n $@\n $code \n";
    }
}

#------------------------------------------------------------------
sub add_range { 
    my ($col1, $numChars) = @_;
    # substr complains (under -w) if we look past the end of a string
    # To prevent this, pad the string with spaces if necessary.
    $code .= "\$s .= ' ' x ($col1 + $numChars - length(\$s))";
    $code .= "    if (length(\$s) < ($col1+$numChars));";
    $code .= "\$tmp = substr(\$s, $col1, $numChars);";
    $code .= '$tmp .= " " x (' . $numChars .  ' - length($tmp));';
    $code .= "\$col .= '$delimiter' . \$tmp; ";
}

#------------------------------------------------------------------
sub get_next_line {
    my($buf);

  NEXTFILE:
    if ($open_new_file) {
        $file = shift @files || exit(0);
        open (F, $file) || die "$@ \n";
        $open_new_file = 0;
    }
    if ($size) {
        read(F, $buf, $size);
    } else {
        $buf = <F>;
    }
    if (! $buf) {
        close(F);
        $open_new_file = 1;
        goto NEXTFILE;
    }
    chomp($buf);
    # Convert tabs to spaces (assume tab stop width == 8)

    # expand leading tabs first — the common case
    $buf =~ s/^(\t+)/' ' x (8 * length($1))/e;

    # Now look for nested tabs. Have to expand them one at a time - hence
    # the while loop. In each iteration, a tab is replaced by the number of
    # spaces left till the next tab-stop. The loop exits when there are
    # no more tabs left
    1 while ($buf =~ s/\t/' ' x (8 - length($`)%8)/e);

    $buf;
}
