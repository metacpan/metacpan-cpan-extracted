package WFA::Workflow;

use 5.008;
use strict;
use warnings;
use Moo;

use WFA::Job;

with 'WFA::Role::Response';

=head1 NAME

WFA::Workflow - A workflow object, representing a single WFA workflow

=cut

sub BUILDARGS {
    my ($class, %args) = @_;

    my $response = $args{response}->{workflow};
    delete $args{response};

    return {
        %args,
        response => $response,
    };
};

=head1 METHODS

=head2 my $workflow_name = $workflow->name()

Get the name of the workflow.

=cut

sub name {
    my ($self) = @_;
    return $self->response()->{name};
}

=head2 my $workflow_version = $workflow->version()

Get the version of the workflow in the form C<$major.$minor.$revision>.

=cut

sub version {
    my ($self) = @_;
    my %version_hash = %{ $self->response()->{version} };
    return join('.', @version_hash{qw/major minor revision/});
}

=head2 my $workflow_description = $workflow->description()

Get the description of the workflow.

=cut

sub description {
    my ($self) = @_;
    return $self->response()->{description};
}

=head2 my $workflow_uuid = $workflow->uuid()

Get the uuid of the workflow.  This unique identifier is assigned server-side and is often used in the URLs of the REST C<api>.

=cut

sub uuid {
    my ($self) = @_;
    return $self->response()->{uuid};
}

=head2 my %workflow_parameters = $workflow->parameters()

Get the parameters accepted by this workflow during execution.  Example:

  (
    Parameter1 => {
      type        => 'String',
      description => 'Some parameter',
      mandatory   => 'true',
    },
    Parameter2 => {
      type        => 'String',
      description => 'Some parameter',
      mandatory   => 'false',
    },
  )

=cut

sub parameters {
    my ($self) = @_;
    return %{ $self->response()->{userInputList}->{userInput} };
}

=head2 my $job = $workflow->execute(%parameters)

Execute the workflow with the given parameters.  This returns a C<WFA::Job> object which can be used to poll the job status.

=over

=item I<%parameters>

Parameters for the job.  Example:

  (
    Parameter1 => 'value1',
    Parameter2 => 'value2',
  )

=back

=cut

sub execute {
    my ($self, %parameters) = @_;

    return WFA::Job->new(
        client => $self->client(),
        response => $self->client()->submit_wfa_request(
            $self->url_for_action('execute'),
            $self->client()->construct_xml_request_parameters(%parameters),
        ),
    );
}

1;
