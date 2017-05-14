package Scanner::Table;

# $Revision:   1.1  $

=head1 NAME 

Table - use flex to generate the tables for a state-driven scanner

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

    my $found = 0;
    print $file "\@${prefix}nxt = (\n";
    open(FLEX, "flex -f -t tbl$$ |") || die "Can't run flex!";
    while (<FLEX>) {
        if (/yy_nxt\s*\[\]/ .. /\s*\}\s*;\s*$/) {
            $first = <FLEX>, $found = 1, next if ! $found;
            s/{/[/; s/}/]/;
            if (! /;/) {
                print $file $_;
            } else {
                print $file ");\n";
            }
        }
        elsif (/yy_accept\s*\[[0-9]+\]/ .. /\s*\}\s*;\s*$/) {
            if ($found) {
                print $file "\n\@${prefix}accept =\n";
                $found = 0;
                next;
            }
            s/{/(/; s/}/)/;
            print $file $_;
        }
    }
    print $file "\n1;\n";
    close FLEX;
    unlink "tbl$$";
}

1;
