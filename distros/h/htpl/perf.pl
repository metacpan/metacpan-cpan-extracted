use strict;

sub makehash {
        my ($par, $indent, @words) = @_;
        my (%glob, %hash, @loc, @array, $line);
        my $out;
        $par = "$par\_" if ($par);
        $indent = "$indent " if ($indent);
	$line = 0;
        foreach (@words) {
                $glob{$_} = $line++;
                my $ch1 = substr($_, 0, 1);
                my $ch2 = substr($_, -1, 1);
                my $val = ((ord($ch1) * ord($ch2)) ^ length($_)) % 10;
                $hash{$val} ||= [];
                push(@{$hash{$val}}, $_);
        }

        $out .= "${indent}char *${par}table[] = {";
        my $notfirst;
        foreach (@words) {
		$out .= ",\n\t" if ($notfirst++);
                $out .= qq!"$_"!;
        }
        $out .= "};\n";

        @loc = (-1) x 10;
        foreach my $key (keys %hash) {
                $loc[$key] = @array;
                foreach (@{$hash{$key}}) {
                        push(@array, $glob{$_});
                }
                push(@array, -1);
        }

        $out .= "${indent}int ${par}locations[] = { " . join(", ", @array) . " };\n";
        $out .= "${indent}int ${par}shortcuts[] = { " . join(", ",
                        @loc) . " };\n";
        $out .= "${indent}struct hash_t ${par}hash = {${par}table,\n\t ${par}locations, ${par}shortcuts};\n";
        return (wantarray ? split(/\n/, $out) : $out);
}

1;
