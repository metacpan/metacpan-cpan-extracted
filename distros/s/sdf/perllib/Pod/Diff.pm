package Pod::Diff;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(pod_diff_files pod_diff_print_stats);
use strict;

# Set this for strict checking, i.e.:
# * over commands must match
# * multiple spaces within non-verbatim paragraphs must match
my $strict = 0;

# Statistics collected
my $total_runs = 0;
my $total_paras = 0;
my $total_diffs = 0;
my $total_resync_fails = 0;

# The default formatting routine for a difference
sub _pod_diff_fmt {
    my($i, $text1, $text2, $line1, $line2) = @_;

    # Find the first character which differs
    # Is there a better way than this?
    my $first =  0;
    $first++ while substr($text1, $first, 1) eq substr($text2, $first, 1);
    $first++;

    return join("\n",
        "*** paragraph $i - character $first ***",
        "--- $line1 ---",
        $text1,
        "--- $line2 ---",
        $text2);
}

# Parse a pod array into a list of paragraphs.
# Each paragraph has the following fields:
#
# * TEXT - the paragraph text
# * LINE - the starting line number
sub _pod_parse_paras {
    my($array) = @_;
    my(@list);

    my $lineno = 0;
    my $text = '';
    my $tab_size = 8;
    my $line;
    for $line (@$array) {
        $lineno++;

        # Trim trailing whitespace and convert tabs to spaces
        $line =~ s/\s+$//;
        1 while $line =~ s/\t+/' ' x (length($&) * $tab_size - length($`) % $tab_size)/e;

        # Build and store the paragraphs
        if ($line =~ /^$/) {
            if ($text ne '') {
                push(@list, {TEXT => $text, LINE => $lineno});
                $text = '';
            }
        }
        elsif ($text eq '') {
            $text  = $line;
        }
        else {
            if ($text =~ /^\s/) {
                $text  .= "\n$line";
            }
            else {
                $text  .= " $line";
            }
        }
    }

    # Save the last paragraph, if necessary
    if ($text ne '') {
        push(@list, {TEXT => $text, LINE => $lineno});
    }

    # Return result
    return @list;
}

# Remove redundant escapes from a paragraph
sub _fix_escapes {
    my($text) = @_;

    # For verbatim, leave things alone
    return $text if $text =~ /^ /;

    my $result = '';
    my $phrase = '';
    my @nested = ();
    my $tag = '';
    while ($text ne '') {

        # A > without a proceeding < may be a sequence end marker
        if ($text =~ /^([^<>]*)\>/) {
            $text = $';
            if (@nested) {
                $tag = pop(@nested);
                $phrase = $1;
                if ($tag eq 'E' && ($phrase eq 'gt' || $phrase eq 'lt')) {

                    # The escape isn't necessary unless:
                    # * the preceding character is [A-Z] for <, or
                    # * it's inside an interior sequence for >, or
                    if ($phrase eq 'gt' && scalar @nested > 0 ||
                        $phrase eq 'lt' && $result =~ /[A-Z]E\<$/) {
                        $result .= "$phrase>";
                    }
                    else {
                        $result =~ s/E\<$//;
                        $result .= $phrase eq 'gt' ? '>' : '<';
                    }
                }
                else {
                    $result .= $` . $&;
                }
            }
            else {
                $result .= $` . $&;
            }
        }

        # A sequence which may have something nested
        elsif ($text =~ /([A-Z])\</) {
            $result .= $`;
            $result .= $&;
            $text = $';
            push(@nested, $1);
        }

        # No sequences left
        else {
            $result .= $text;
            $text = '';
        }
    }

    # Return result
    return $result;
}

# Diff two pod arrays
sub pod_diff_arrays {
    my($array1, $array2, $formatter) = @_;
    my(@result) = ();

    # Use the default formatter if none is given
    $formatter = \&_pod_diff_fmt;

    # Parse the arrays into paragraphs
    my @para1 = _pod_parse_paras($array1);
    my @para2 = _pod_parse_paras($array2);

    # Diff the paragraph lists
    my $j = 0;
    for (my $i = 0; $i <= $#para1; $i++, $j++) {
        my $text1 = $para1[$i]{TEXT};
        my $text2 = $para2[$j]{TEXT};
        next if $text1 eq $text2;

        # If things don't match and strict checking isn't enabled:
        # * ignore over commands
        # * ignore extra spaces in non-verbatim paragraphs
        unless ($strict) {
            next if $text1 =~ /^=over/ && $text2 =~ /^=over/;
            $text1 =~ s/ +/ /g if $text1 =~ /^\S/;
            $text2 =~ s/ +/ /g if $text2 =~ /^\S/;
            next if $text1 eq $text2;
        }

        # Still no luck, so try removing unnecessary escapes
        $text1 = _fix_escapes($text1);
        $text2 = _fix_escapes($text2);
        next if $text1 eq $text2;

        # If we reach here, we have a failure
        my $line1 = $para1[$i]{LINE};
        my $line2 = $para2[$j]{LINE};
        push(@result, &$formatter($i, $text1, $text2, $line1, $line2));

        # Resynchronise if necessary and we can
        if ($para1[$i+1]{TEXT} eq $para2[$j+1]{TEXT}) {
            # next 2 paragraphs start off ok so do nothing
        }
        elsif ($text1 eq $para2[$j+1]{TEXT}) {
            $j++;
        }
        elsif ($text2 eq $para1[$i+1]{TEXT}) {
            $i++;
        }
        elsif ($text1 eq $para2[$j+2]{TEXT}) {
            $j += 2;
        }
        elsif ($text2 eq $para1[$i+2]{TEXT}) {
            $i += 2;
        }
        elsif ($text1 eq $para2[$j+3]{TEXT}) {
            $j += 3;
        }
        elsif ($text2 eq $para1[$i+3]{TEXT}) {
            $i += 3;
        }
        elsif ($text1 eq $para2[$j+4]{TEXT}) {
            $j += 4;
        }
        elsif ($text2 eq $para1[$i+4]{TEXT}) {
            $i += 4;
        }
        elsif ($text1 eq $para2[$j+5]{TEXT}) {
            $j += 5;
        }
        elsif ($text2 eq $para1[$i+5]{TEXT}) {
            $i += 5;
        }
        elsif ($text1 eq $para2[$j+6]{TEXT}) {
            $j += 6;
        }
        elsif ($text2 eq $para1[$i+6]{TEXT}) {
            $i += 6;
        }
        else {
            $total_resync_fails++;
        }
    }

    # Collect some stats
    $total_runs++;
    $total_paras += scalar(@para1);
    $total_diffs += scalar(@result);

    # Return result
    return @result;
}

 
# Diff two pod files
sub pod_diff_files {
    my($file1, $file2, $formatter) = @_;

    # Load the pod from the first file
    unless (open(FILE1, $file1)) {
        warn "unable to open '$file1': $!\n";
        return ();
    }
    my @pod1 = <FILE1>;
    chop(@pod1);
    close FILE1;

    # Load the pod from the second file
    unless (open(FILE2, $file2)) {
        warn "unable to open '$file2': $!\n";
        return ();
    }
    my @pod2 = <FILE2>;
    chop(@pod2);
    close FILE2;

    # Diff the arrays
    return pod_diff_arrays(\@pod1, \@pod2, $formatter);
}

sub pod_diff_print_stats {
    my($strm) = @_;

    print $strm "*** SUMMARY ***\n";
    print $strm "Total files: ", $total_runs, "\n";
    print $strm "Total paras: ", $total_paras, "\n";
    print $strm "Total diffs: ", $total_diffs, "\n";
    print $strm "Total resync failures: ", $total_resync_fails, "\n";
    if ($total_paras) {
        printf $strm "PERCENT OK: %.2f%%\n",
            ($total_paras - $total_diffs)/$total_paras * 100;
    }
}

# package return value
1;
