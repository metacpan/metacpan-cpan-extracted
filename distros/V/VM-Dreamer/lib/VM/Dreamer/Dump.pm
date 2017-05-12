package VM::Dreamer::Dump;

use strict;
use warnings;

our $VERSION = '0.851';

use VM::Dreamer::Util qw( stringify_array );

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( dump_status dump_memory );

sub dump_status {
    my $machine = shift;

    foreach my $part ( keys %$machine ) {
        my $current_value;
        unless ( $part eq 'memory' ) {
            if ( ref($machine->{$part}) eq "ARRAY" ) {
                $current_value = stringify_array( $machine->{$part} );
            }
            else {
                $current_value = $machine->{$part};
            }
            printf "%-11s\t%3s\n", $part, $current_value;
        }
    }
}

sub dump_memory {
    my $machine = shift;

    foreach my $address ( sort keys %{$machine->{memory}} ) {
        print "$address\t$machine->{memory}->{$address}\n";
    }

    return 0;
}

1;

=pod

=head1 NAME

VM::Dreamer::Dump

=head1 SYNOPSIS

dump_status($machine);
dump_memory($machine);

=head1 DESCRIPTION

This module helps debug instantiations of Dreamer by dumping their memory or their other components. They help give a snapshot of your machine's state at a given point in time.

=head1 SUBROUTINES 

-head2 dump_status

Takes a reference to an initialized machine and outputs the current value for all parts of the machine other than memory.

=head2 dump_memory

Tkaes a reference to an iniitalized machine and outputs the contents of memory.

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 William Stevenson. All rights reserved.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

VM::Dreamer
 
=cut
