package App::HWD;

use warnings;
use strict;

use App::HWD::Task;
use App::HWD::Work;

=head1 NAME

App::HWD - Support functions for How We Doin'?, the project estimation and tracking tool

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';

=head1 SYNOPSIS

This module is nothing more than a place-holder for the version info and the TODO list.

=head1 FUNCTIONS

These functions are used by F<hwd>, but are kept here so I can easily
test them.

=head2 get_tasks_and_work( @tasks )

Reads tasks and work, and applies the work to the tasks.

Returns references to C<@tasks>, C<@work>, C<%tasks_by_id> and C<@errors>.

=cut

sub get_tasks_and_work {
    my $handle = shift;

    my @tasks;
    my @work;
    my %tasks_by_id;
    my @errors;

    my @parents;
    my $curr_task;
    my $lineno;
    my $currfile;
    for my $line ( <$handle> ) {
        if ( !defined($currfile) ) {
            $currfile = defined $ARGV ? $ARGV : "DATA";
            $lineno = 1;
        }
        elsif ( !defined( $ARGV ) ) {
            ++$lineno;
        }
        elsif ( $currfile eq $ARGV ) {
            ++$lineno;
        }
        else {
            $currfile = $ARGV;
            $lineno = 1;
        }

        my $where = "line $lineno of $currfile";
        chomp $line;
        next if $line =~ /^\s*#/;
        next if $line !~ /./;

        if ( $line =~ /^(-+)/ ) {
            my $level = length $1;
            my $parent;
            if ( $level > 1 ) {
                $parent = $parents[ $level - 1 ];
                if ( !$parent ) {
                    push( @errors, ucfirst( "$where has no parent: $line" ) );
                    next;
                }
            }
            my $task = App::HWD::Task->parse( $line, $parent, $where );
            if ( !$task ) {
                push( @errors, "Can't parse at $where: $line" );
                next;
            }
            if ( $task->id ) {
                if ( $tasks_by_id{ $task->id } ) {
                    push( @errors, "Dupe task ID at $where: Task " . $task->id );
                    next;
                }
                $tasks_by_id{ $task->id } = $task;
            }
            push( @tasks, $task );
            $curr_task = $task;
            $parent->add_child( $task ) if $parent;

            @parents = @parents[0..$level-1];   # Clear any sub-parents
            $parents[ $level ] = $task;         # Set the new one
        }
        elsif ( $line =~ s/^\s+// ) {
            $curr_task->add_notes( $line );
        }
        else {
            my $work = App::HWD::Work->parse( $line );
            push( @work, $work );
            if ( $work->task eq "^" ) {
                if ( $curr_task ) {
                    $curr_task->add_work( $work );
                }
                else {
                    push( @errors, "Can't apply work to current task, because there is no current task" );
                }
            }
        }
    } # while

    # Validate the structure
    for my $task ( @tasks ) {
        if ( $task->estimate && $task->children ) {
            my $where = $task->id || ("at " . $task->where);
            push( @errors, "Task $where cannot have estimates, because it has children" );
        }
    }

    for my $work ( @work ) {
        next if $work->task eq "^"; # Already handled inline
        my $task = $tasks_by_id{ $work->task };
        if ( !$task ) {
            push( @errors, "No task ID " . $work->task );
            next;
        }
        $task->add_work( $work );
    }

    # Get the work done in date order for each of the tasks
    $_->sort_work() for @tasks;

    return( \@tasks, \@work, \%tasks_by_id, \@errors );
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-hwd at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-HWD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to
Neil Watkiss
and Luke Closs for features and patches.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::HWD
