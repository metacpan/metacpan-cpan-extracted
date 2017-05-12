package WFA::Job;

use 5.008;
use strict;
use warnings;
use Moo;

with 'WFA::Role::Response';

=head1 NAME

WFA::Job - A job object, representing a single WFA job

=cut

has workflow => (
    is       => 'rw',
    required =>    1,
);

sub BUILDARGS {
    my ($class, %args) = @_;

    my $response = $args{response}->{job};
    delete $args{response};

    return {
        %args,
        response => $response,
        workflow => WFA::Workflow->new(%args, response => $response),
    };
};

=head1 METHODS

=head2 my $workflow = $job->workflow()

Retrieve the workflow associated with this job.  Returns a C<WFA::Workflow> object.

=head2 my $job_id = $job->id()

Get the unique id of the job.

=cut

sub id {
    my ($self) = @_;
    return $self->response()->{jobId};
}

=head2 my $job_start_time = $job->start_time()

Get the start time of the job.  This is a string formatted by WFA of the format C<Jan 29, 2015 2:26:14 PM>.

=cut

sub start_time {
    my ($self) = @_;
    return $self->response()->{jobStatus}->{startTime};
}

=head2 my $job_end_time = $job->end_time()

Get the end time of the job.  This is a string formatted by WFA of the format C<Jan 29, 2015 2:26:14 PM>.

=cut

sub end_time {
    my ($self) = @_;
    return $self->response()->{jobStatus}->{endTime};
}

=head2 my %job_parameters = $job->parameters()

Get the parameters passed when executing the workflow.  Example:

  (
    Parameter1 => 'value1',
    Parameter2 => 'value2',
  )

=cut

sub parameters {
    my ($self) = @_;
    return map { $_->{key} => $_->{value} } @{ $self->response()->{jobStatus}->{userInputValues}->{userInputEntry} };
}

=head2 my $job_status = $job->status()

Get the status of the job.  This is a string that can be one of C<COMPLETED>, C<FAILED>, C<CANCELED>, C<OBSOLETE>, or C<SCHEDULED>.

=cut

sub status {
    my ($self) = @_;
    return $self->response()->{jobStatus}->{jobStatus};
}

=head2 my $job_is_running = $job->running()

Returns true if the job is still running (not completed or failed).

=cut

sub running {
    my ($self) = @_;
    return $self->status() !~ m/COMPLETED|FAILED|CANCELED|OBSOLETE/;
}

=head2 my $job_was_successful = $job->success()

Returns true if the job has completed and was successful.

=cut

sub success {
    my ($self) = @_;
    return $self->status() =~ m/COMPLETED/;
}

=head2 $job->refresh()

The C<$job> object does not automatically update as state changes on the WFA server.  Call C<refresh> to update in-place the state of the C<$job> object.  This is absolutely necessary if you are polling for completion with methods such as C<running> and C<success>.

=cut

sub refresh {
    my ($self) = @_;
    my $job = WFA::Job->new(
        client => $self->client(),
        response => $self->client()->submit_wfa_request($self->url_for_action('self')),
    );
    $self->response($job->response());
    $self->workflow($job->workflow());
    return $self;
}

=head2 $job->poll_for_completion()

Wait until the job is complete, regularly polling the WFA server.  This is equivalent to:

  while ($job->running()) {
    $job->refresh();
    sleep(5);
  }

=cut

sub poll_for_completion {
    my ($self) = @_;

    while ($self->running()) {
        sleep(5);
        $self->refresh();
    }

    return $self;
}

1;
