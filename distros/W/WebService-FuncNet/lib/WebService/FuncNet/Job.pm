package WebService::FuncNet::Job;

use strict;
use warnings;

use Carp;
our $VERSION = '0.2';

use WebService::FuncNet::JobStatus;

=head1 NAME

WebService::FuncNet::Job - object representing a job

=head1 FUNCTIONS

=head2 new

=cut

sub new {
    my $class = shift;
    my $self  = shift;
    bless $self, $class;
    return $self;
}

=head2 status

Probes the status of the job. This is done by implementing the I<MonitorJob> SOAP method
in the background. 

   my $rv = $j->status;
   
This subroutine returns a L<WebService::FuncNet::Status> object, or I<undef> if an error occurred.

=cut

sub status {
    my $self = shift;

    my ( $answer, $trace ) = $self->{ 'clients' }->{ 'MonitorJob' }->(
        'jobLocator' => {
            'jobID'        => $self->{ 'id' },
            'emailAddress' => $self->{ 'emailAddress' }
        }
    );

    if ( $answer ) {
        my $status =
          WebService::FuncNet::JobStatus->new( $answer->{ 'parameters' }{ 'status' }, $trace );
        return $status;
    }
    else {
        return;
    }
}

=head2 cancel

Cancels the job. This is done by implementing the I<CancelJob> SOAP method
in the background. 

   my $rv = $j->cancel;
   
This subroutine returns a reference to an array with two elements, the status of the job
and the SOAP trace. The status of the job is I<true> if all predictors report it as 
cancelled.

This subroutine returns I<undef> on error.

=cut

sub cancel {
    my $self = shift;

    my ( $answer, $trace ) = $self->{ 'clients' }->{ 'CancelJob' }->(
        'jobLocator' => {
            'jobID'        => $self->{ 'id' },
            'emailAddress' => $self->{ 'emailAddress' }
        }
    );

    if ( $answer ) {
        if ( $answer->{ 'parameters' }{ 'status' } eq 'CANCELLED' ) {
            return [ 1, $trace ];
        }
        else {
            return [ undef, $trace ];
        }
    }
    else {
        return;
    }

}

=head2 results

Fetches the results from the service. This is done by implementing 
the I<RetrievePairwiseScores> SOAP method in the background.

   my $R = $j->results;

This subroutine returns a L<WebService::FuncNet::Results> object.

This subroutine returns I<undef> on error.

=cut

sub results {
    my $self = shift;

    my ( $answer, $trace ) =
      $self->{ 'clients' }->{ 'RetrievePairwiseScores' }->(
        'jobLocator' => {
            'jobID'        => $self->{ 'id' },
            'emailAddress' => $self->{ 'emailAddress' }
        }
      );

    if ( $answer ) {
        my $rah_data = $answer->{ 'parameters' }->{ 's' };
        return WebService::FuncNet::Results->new( $rah_data );

    }
    else {
        return;
    }

}

1;

=head1 REVISION INFO

  Revision:      $Rev: 64 $
  Last editor:   $Author: andrew_b_clegg $
  Last updated:  $Date: 2009-07-06 16:12:20 +0100 (Mon, 06 Jul 2009) $

The latest source code for this project can be checked out from:

  https://funcnet.svn.sf.net/svnroot/funcnet/trunk

=cut
