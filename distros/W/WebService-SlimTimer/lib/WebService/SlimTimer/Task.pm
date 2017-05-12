# PODNAME: WebService::SlimTimer::Task
#
# ABSTRACT: Represents a single SlimTimer task.

use MooseX::Declare;

class WebService::SlimTimer::Task
{


use strict;
use warnings;

use MooseX::Types::Moose qw(Int Num Str);
use WebService::SlimTimer::Types qw(TimeStamp OptionalTimeStamp);

has id => ( is => 'ro', isa => Int, required => 1 );
has name => ( is => 'ro', isa => Str, required => 1 );
has created_at => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has updated_at => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has hours => ( is => 'ro', isa => Num, required => 1 );
has completed_on => ( is => 'ro', isa => OptionalTimeStamp, coerce => 1 );

# TODO: Add more fields:
#   - role: comma-separated list of (owner, coworker, reporter)
#   - tags: comma-separated list of arbitrary words
#   - owners: list of persons (name + user_id + email)
#   - reports: list of persons
#   - coworkers: list of persons

}

__END__
=pod

=head1 NAME

WebService::SlimTimer::Task - Represents a single SlimTimer task.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

The objects of this class repesent a SlimTimer task. These objects are not
created directly but rather retrieved from L<WebService::SlimTimer> using its
C<list_tasks()> or C<get_task()> methods.

    # Print the time spent on each task.
    my @tasks = $st->list_tasks();
    for my $task (@tasks) {
        printf "%-30s %9.2f\n", $task->name, $task->hours
    }

=head1 ATTRIBUTES

=head2 id

Numeric task id. The id never changes after the task creation and can be
cached locally.

=head2 name

The task name as an arbitrary string. Notice that it is possible, although
confusing, to have more than one task with the same name, use C<id> to
uniquely identify the task.

=head2 created_at

The time when the task was created.

=head2 updated_at

The time when the task was last updated.

=head2 hours

Total hours spent on this task as recorded on the server. This is a floating
point number.

=head2 completed_on

Boolean flag indicating whether the task was completed. The tasks created with
L<WebService::SlimTimer/create_task> are not initially completed, use
L<WebService::SlimTimer/complete_task> to mark them as completed.

=head1 SEE ALSO

L<WebService::SlimTimer>

=head1 AUTHOR

Vadim Zeitlin <vz-cpan@zeitlins.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Vadim Zeitlin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

