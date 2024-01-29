#
# read symbols from stdin. e.g. HAS_FOO
# grep though the source tree to see if they are used.
# exclude config.h.in since thats where they came from.
#
use strict;
use warnings;

my %out = ();

while(my $def = <STDIN>){
    chomp $def;
    my @lines = qx(/usr/bin/grep -a -H -r --exclude=config.h.in $def usrc);
    $out{$def} = @lines;
}

for my $def ( sort keys %out ) {
    next if $out{$def} == 0;
    printf "%4d  %s\n", $out{$def}, $def;
}

exit 0;
