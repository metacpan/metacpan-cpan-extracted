use warnings;
use strict;

use IO::File;

autoflush STDIN;
autoflush STDOUT;

my %file_desc;
my %pid;

while ( my $command = <STDIN> ) {
    chomp $command;
    print "From program exec.pl : received message $command\n";

    exit if ( $command eq "quit" );

    my ( $file_name, $action, $data ) = split( /\|/, $command );
    if ( $action eq 'start' ) {
        if ( my $pid = $pid{$file_name} ) {
            if ( kill 0, $pid ) {
                kill 9, $pid;
            }
        }
		print "From program exec.pl : executing command $data...\n";
        $pid{$file_name} = open $file_desc{$file_name}, "| $data";
    }
    elsif ( $action eq 'stop' ) {
        if ( my $pid = $pid{$file_name} ) {
            if ( kill 0, $pid ) {
                kill 9, $pid;
            }
        }
    }

    # Send action here (to send data from Editor.pl to STDIN of launched process)
}

