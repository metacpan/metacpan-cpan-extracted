package ConvertHeader; {
# Copyright (C) 2019 Peter C. Jones
#   see LICENSE file

# using this to replace h2ph script,
#   customized to convert into a hash in the resulting .pm, rather than the constant-subs that h2ph creates

    use warnings;
    use strict;
    use autodie;

    our $in_file;

    sub ConvertHeader::readIntoHash {
        $in_file = $_[0]; die "ConvertHeader::readIntoHash(\$in_file): input filename required!" unless defined $in_file;

        # slurp the file
        my $slurp = do {
            local $/;
            open my $fh, '<', $in_file;
            <$fh>;
        };

        # collapse line-continuation (backslash followed by EOL) into single space
        $slurp =~ s/\\\n\s*/ /g;

        # remove whole-line comments
        $slurp =~ s{//.*$}{}gim;


        # first check for enumerations and add them to the hash
        my %hash = ();
        foreach ( $slurp =~ /^\h*enum\s\w+\s*{\s*.*?\s*}\s*;/gims ) {
            s/\s+/ /gims;
            my ($list) = ($_ =~ /{\s*(.*?)\s*}/g);
            my @enums = split /,\s*/, $list;
            foreach my $i (0 .. $#enums) {
                $hash{ $enums[$i] } = $i;
            }
        }

        # then hashify the #defines
        foreach ( $slurp =~ /^\h*#\s*define\s+\w+.+$/gim ) {
            #print STDERR "|$_|\n";
            my ($name, $value) = ( m/^\h*#\s*define\s+(\w+)(.*)$/ );
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            $hash{ $name } = $value;
        }

        return %hash;

    }

    sub ConvertHeader::hash2pm {
        my $usage = "ConvertHeader::hash2pm(\$out_file, \$module_name, \$var_name, [list of keys to do first], \%hash)";
        my $out_file = shift; die "$usage: output filename required!" unless defined $out_file;
        my $module_name = shift; die "$usage: module name required!" unless defined $module_name;
        my $var_name = shift; die "$usage: variable name required!" unless defined $var_name;
        my $rfirst = shift; die "$usage: reference to list of keys to do first required!" unless defined $rfirst and UNIVERSAL::isa($rfirst, 'ARRAY');
        my %hash = @_;

        # make sure windows' WM_USER is always defined
        $hash{WM_USER} = 0x400 unless exists $hash{WM_USER};

        # there may be some keys that want to be processed first
        my @first = ('WM_USER', @$rfirst);

        # start the output
        open my $fh, '>', $out_file;
        print {$fh} "# auto-converted from $in_file at ", scalar localtime, "\n";
        print {$fh} "package $module_name;\n";
        print {$fh} <<'EOH';

use warnings;
use strict;
use Exporter 5.57 ('import');

EOH
        print {$fh} 'our @EXPORT = qw/%', $var_name, "/;\n";
        print {$fh} 'our %', $var_name, " = (\n";

        my %already;
        foreach my $key ( @first, sort keys %hash ) {
            next if $already{$key};
            my $value = $hash{$key};
            if( !defined $value ) {
                $value = 'undef';
            } elsif ($value eq '') {
                $value = "''";
            } elsif ($value =~ /[^0-9]/) {
                my $replaced = "0e0";   # zero but true
                while($replaced) {
                    my @reps;
                    while ( $value =~ m/([A-Z]\w+)/gi ) {
                        my $rep = $1;
                        next if $rep eq $var_name;
                        if( exists $hash{$rep} ) {
                            push @reps, $rep;
                        }
                    } # while value matches
                    foreach my $rep ( @reps ) {
                        $value =~ s/\b$rep\b/$hash{$rep}/;
                    }
                    $replaced = scalar @reps;
                } # /while $replaced is true
            }
            next if $value =~ /^[a-z]\w+$/i;
            printf {$fh} "    %-60s => %s,\n", "'$key'", $value;
            $hash{$key} = $value;   # need the key to also update, so that recursive definitions are done properly
            $already{$key} = 'done';
        } # /key loop

        print {$fh} ");\n1;\n";

    }

    1;
}

package main; {
    use warnings;
    use strict;

    die "missing argument: convertHeaders.pl infile outfile module-name variable-name\n\t" if 4 > @ARGV;
    my ($i, $o, $m, $v) = @ARGV;
    my %h = ConvertHeader::readIntoHash($i);
    ConvertHeader::hash2pm($o, $m, $v, [], %h);

}