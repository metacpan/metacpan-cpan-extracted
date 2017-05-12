package App::HWD::Task;

=head1 NAME

App::HWD::Task - Tasks for HWD

=head1 SYNOPSIS

Used only by the F<hwd> application.

Note that these functions are pretty fragile, and do almost no data
checking.

=head1 FUNCTIONS

=head2 App::HWD::Task->parse( $input_line, $parent_task )

Returns an App::HWD::Task object from an input line

=cut

use warnings;
use strict;
use DateTime::Format::Strptime;

my $line_regex = qr/
    ^
    (-+|\*+)    # leading dashes or stars
    \s*         # whitespace
    (.+)        # everything else
    $
/x;

sub parse {
    my $class = shift;
    my $line = shift;
    my $parent = shift;
    my $where = shift;

    if ( $line =~ $line_regex ) {
        my $level = length $1;
        my $name = $2;
        my $id;
        my $estimate;
        my %date;

        if ( $name =~ s/\s*\(([^)]+)\)\s*$// ) {
            my $parens = $1;
            my $parser = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' );

            my @subfields = split /,/, $parens;
            for ( @subfields ) {
                # Strip whitespace
                s/^\s+//;
                s/\s+$//;

                # ID?
                /^#(\d+)$/ and $id = $1, next;

                # Estimate in hours or minutes?
                /^((\d*\.)?\d+)h$/  and $estimate = $1, next;
                /^(\d+)m$/          and $estimate = $1/60, next;

                # Add or delete dates
                /^(added|deleted) (\S+)$/i and do {
                    my ($type,$date) = ($1,$2);
                    $date{$type} = $parser->parse_datetime($date);
                    next if $date{$type};
                };
                warn qq{Can't parse $where: $_\n};
            }
        }

        my $task = $class->new( {
            level               => $level,
            name                => $name,
            id                  => $id,
            where               => $where,
            estimate            => $estimate,
            date_added_obj      => $date{added},
            date_deleted_obj    => $date{deleted},
            parent              => $parent,
        } );
    }
    else {
        return;
    }
}

=head2 App::HWD::Task->new( { args } )

Creates a new task from the args passed in.  They should include at
least I<level>, I<name> and I<id>, even if I<id> is C<undef>.

    my $task = App::HWD::Task->new( {
        level => $level,
        name => $name,
        id => $id,
        estimate => $estimate,
    } );

=cut

sub new {
    my $class = shift;
    my $args = shift;

    my $self = bless {
        %$args,
        work => [],
    }, $class;

    return $self;
}

=head2 $task->level()

Returns the level of the task

=head2 $task->name()

Returns the name of the task

=head2 $task->id()

Returns the ID of the task, or the empty string if there isn't one.

=head2 $task->where()

Returns a string describing the location of the task's line, as in "line 45 of foo.hwd"

=head2 $task->estimate()

Returns the estimate, or 0 if it's not set.

=head2 $task->notes()

Returns the list of notes for the task.

=head2 $task->date_added()

Returns a string showing the date the task was added, or empty string if it's not set.

=head2 $task->date_added_obj()

Returns a DateTime object representing the date the task was added, or C<undef> if it's not set.

=head2 $task->date_deleted()

Returns a string showing the date the task was deleted, or empty string if it's not set.

=head2 $task->date_deleted_obj()

Returns a DateTime object representing the date the task was deleted, or C<undef> if it's not set.

=head2 $task->parent()

Returns the parent of the task, or C<undef> if it's a top-level task.

=head2 $task->children()

Returns a list of child tasks.

=head2 $task->work()

Returns the array of App::HWD::Work applied to the task.

=cut

sub level               { return shift->{level} }
sub name                { return shift->{name} }
sub id                  { return shift->{id} || "" }
sub where               { return shift->{where} }
sub estimate            { return shift->{estimate} || 0 }
sub work                { return @{shift->{work}||[]} }
sub notes               { return @{shift->{notes}||[]} }
sub date_added_obj      { return shift->{date_added_obj} }
sub date_deleted_obj    { return shift->{date_added_obj} }
sub parent              { return shift->{parent} }
sub children            { return @{shift->{children}||[]} }

sub date_added {
    my $self = shift;
    my $obj = $self->{date_added_obj} or return '';

    return $obj->strftime( "%F" );
}

sub date_deleted {
    my $self = shift;
    my $obj = $self->{date_deleted_obj} or return '';

    return $obj->strftime( "%F" );
}

=head2 $task->is_todo()

Returns true if the task still has things to be done on it.  If the task
has no estimates, because it's a roll-up or milestone task, this is false.

=cut

sub is_todo {
    my $self = shift;

    if ( $self->estimate ) {
        return if $self->date_deleted;
        return !$self->completed;
    }

    for my $child ( $self->children ) {
        return 1 if $child->is_todo;
    }
    return;
}

=head2 $task->set( $key => $value )

Sets the I<$key> field to I<$value>.

=cut

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    die "Dupe key $key" if exists $self->{$key};
    $self->{$key} = $value;
}

=head2 add_notes( @notes_lines )

Adds the lines passed in to the notes lines for the task.

=cut

sub add_notes {
    my $self = shift;

    push( @{$self->{notes}}, @_ );
}

=head2 add_child( $task )

Adds a child Task record to the task

=cut

sub add_child {
    my $self = shift;
    my $child = shift;

    push( @{$self->{children}}, $child );
}

=head2 add_work( $work )

Adds a Work record to the task, for later accumulating

=cut

sub add_work {
    my $self = shift;
    my $work = shift;

    push( @{$self->{work}}, $work );
}

=head2 hours_worked()

Returns the number of hours worked, but counting up all the work records added in L</add_work>.

=cut

sub hours_worked {
    my $self = shift;

    my $hours = 0;
    for my $work ( @{$self->{work}} ) {
        $hours += $work->hours;
    }
    return $hours;
}

=head2 started()

Returns whether the task has been started.  Doesn't address the question
of whether the task is completed or not, just whether work has been done
on it.

=cut

sub started {
    my $self = shift;

    return @{$self->{work}} > 0;
}

=head2 completed()

Returns whether the task has been completed.

=cut

sub completed {
    my $self = shift;

    my $completed = 0;
    for my $work ( @{$self->{work}} ) {
        $completed = $work->completed;
    }

    return $completed;
}

=head2 summary

Returns a simple one line description of the Work.

=cut

sub summary {
    my $self = shift;
    my $sum;
    $sum = $self->id . " - " if $self->id;
    $sum .= sprintf( "%s (%s/%s)", $self->name, $self->estimate, $self->hours_worked );
    return $sum;
}

=head2 sort_work

Make sure all the work for a task is sorted so we can tell what was done when.

=cut

sub sort_work {
    my $self = shift;

    my $work = $self->{work};

    @$work = sort {
        $a->when cmp $b->when
        ||
        $a->completed cmp $b->completed
        ||
        $a->who cmp $b->who
    } @$work;
}

=head2 subtask_walk( $callback )

Recursively walks the tree of subtasks for the task, calling C<$callback>
for each subtask, like so:

    $callback->( $subtask )

=cut

sub subtask_walk {
    my $self = shift;
    my $callback = shift;

    for my $child ( $self->children ) {
        $callback->( $child );
        $child->subtask_walk( $callback );
    }
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"You got a killer scene there, man..."; # End of App::HWD::Task
