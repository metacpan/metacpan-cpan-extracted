package Scanner::TableCe;

# $Revision:   1.1  $

=head1 NAME 

TableCe - use flex to generate the tables for a state-driven scanner

=cut

require 5.001;

sub Generate {
    my $prefix = $_[2] || "yy_";
    my $file = $_[0];
    open(TEMP, "> tbl$$") || die "Can't write to temp file!";
    print TEMP '%%', "\n";
    my $i;
    for ($i = 0; $i < @{$_[1]}; $i += 2) {
        $regexp = $_[1][$i];
        $regexp =~ s/"/\\"/g;
        print TEMP $regexp, " 1;\n";
    }
    print TEMP '%%', "\n";
    close TEMP;

    my $found = 1;
    my $jambase;
    open(FLEX, "flex -Ce -t tbl$$ |") || die "Can't run flex!";
    @tables = ( "accept", "ec", "base", "def", "nxt", "chk" );
  FLEX:
    while (<FLEX>) {
        foreach $table (@tables) {
          if (/^\s+while\s+\(\s+yy_base\[yy_current_state\]\s+!=\s+([0-9]+)/) {
              $jambase = $1;
          }
            elsif (/yy_$table\s*\[[0-9]+\]/ .. /\s*\}\s*;\s*$/) {
                if ($found) {
                    print $file "\n\@$prefix$table =\n";
                    $found = 0;
                    next FLEX;
                }
                $found = 1 if /\}/;
                s/\{/(/; s/\}/)/;
                print $file $_;
                next FLEX;
            }
        }
    }
    print $file "\n\$${prefix}jambase = $jambase;\n";
    print $file "\n1;\n";
    close FLEX;
    unlink "tbl$$";
}

1;
