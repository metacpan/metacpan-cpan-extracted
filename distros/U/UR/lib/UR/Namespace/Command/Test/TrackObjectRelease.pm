package UR::Namespace::Command::Test::TrackObjectRelease;

use strict;
use warnings;

use UR;
our $VERSION = "0.47"; # UR $VERSION;
use IO::File;

class UR::Namespace::Command::Test::TrackObjectRelease {
    is => 'UR::Namespace::Command::Base',
    has => [
        file => { is => 'Text', doc => 'pathname of the input file' },
    ],
};

sub help_brief { 'Parse the data produced by UR_DEBUG_OBJECT_RELEASE and report possible memory leaks' };

sub help_synopsis { 
"ur test track-object-release --file /path/to/text.file > /path/to/results"
}

sub help_detail {
"When a UR-based program is run with the UR_DEBUG_OBJECT_RELEASE environment
variable set to 1, it will emit messages to STDERR describing the various
stages of releasing an object.  This command parses those messages and
provides a report on objects which did not completely deallocate themselves,
usually because of a reference being held."
}

sub execute {
    my $self = shift;

#$DB::single = 1;
    my $file = $self->file;
    my $fh = IO::File->new($file,'r');

    unless ($fh) {
        $self->error_message("Can't open input file: $!");
        return;
    }

    # for a given state, it's legal predecessor
    my %prev_states = ( 'PRUNE object'       => '',
                        'DESTROY object'     => 'PRUNE object',
                        'UNLOAD object'      => 'DESTROY object',
                        'DELETE object'      => 'UNLOAD object',
                        'BURY object'        => 'DELETE object',
                        'DESTROY deletedref' => 'BURY object',
                      );
    my %next_states = reverse %prev_states;
    # After this we stop stracking it
    my %terminal_states = ( 'DESTROY deletedref' => 1 );
    my %objects;


    while(<$fh>) {
        chomp;

        my ($action,$refaddr);
        if (m/MEM ((PRUNE|DESTROY|UNLOAD|DELETE|BURY) (object|deletedref)) (\S+)/) {
            $action = $1;
            my $refstr = $4;
            ($refaddr) = ($refstr =~ m/=HASH\((.*)\)/);
        } else {
            next;
        }
        my($class,$id) = m/class (\S+) id (.*)/;   # These don't appear in the deletedref line, and are optional

        my $expected_prev_state = $prev_states{$action};
        if (defined $expected_prev_state && $expected_prev_state) {
            # This state must have a predecessor
            if ($objects{$expected_prev_state}->{$refaddr}) {
                if ($terminal_states{$action}) {
                    delete $objects{$expected_prev_state}->{$refaddr};
                } else {
                    $objects{$action}->{$refaddr} = delete $objects{$expected_prev_state}->{$refaddr};
                }
            } else {
                print STDERR "$action for $refaddr without matching $expected_prev_state at line $.\n";
            }

        } elsif (defined $expected_prev_state) {
            # The initial state
            $objects{$action}->{$refaddr} = $_;

        } else {
            print STDERR "Unknown action $action at line $.\n";
        }
    }

    foreach my $action (keys %objects) {
        if (keys %{$objects{$action}} ) {
            print "\n$action but not $next_states{$action}\n";
            foreach (keys %{$objects{$action}}) {
                print "$_ : ",$objects{$action}->{$_},"\n";
            }
        }
    }

    return 1;
}

1;


