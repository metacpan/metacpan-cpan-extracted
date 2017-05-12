package WebService::FuncNet::Request;

use strict;
use warnings;

use base 'WebService::FuncNet';

our $VERSION  = '0.2';

=head1 NAME

WebService::FuncNet::Request - object representing a request

=head1 FUNCTIONS

=head2 new

Creates a new request object. Takes as input a reference to an array of reference proteins,
a reference to an array of query proteins and optionally an email address used for tracking
the job at a later stage.

   my $ra_ref_proteins   = [ 'A3EXL0','Q8NFN7', 'O75865' ];
   my $ra_query_proteins = [ 'Q9H8H3','Q5SR05','P22676' ];

   my $r = WebService::FuncNet::Request->new( 
      $ra_ref_proteins, 
      $ra_query_proteins,
   [ 'test@example.com' ] );

This subroutine returns I<undef> on error.

=cut

sub new {
   my $class             = shift;
   my $ra_ref_proteins   = shift;
   my $ra_query_proteins = shift;
   my $email             = shift || 'anonymous-perl-user@funcnet.eu';
   
   my $self  = { };
   bless $self, $class;

   unless ( defined $ra_query_proteins 
      && defined $ra_ref_proteins ) {
         return;
      }
   
   if ( ! $self->{'clients'} ) {
      $self->{'clients'} = $self->init( );
   }

   $self->{'params'} = {
      'queryProteins'       => { p => $ra_query_proteins },
      'refProteins'         => { p => $ra_ref_proteins },
      'emailAddress'        => $email,
      'enableEmailNotify'   => 1,
   };
   
   return $self;
}

=head2 submit

Submits the request to the frontend. This is done by implementing the 
I<SubmitTwoProteinSets> SOAP method in the background. The frontend by default
will submit the request to all available predictors.

This subroutine returns a L<WebService::FuncNet::Job> object.

   my $j = $r->submit( );

This subroutine will return I<undef> on error.

=cut

sub submit {
   my $self = shift;
   
   my ( $answer, $trace ) =
      $self->{'clients'}->{'SubmitTwoProteinSets'}->( 
         'parameters' => $self->{'params'} );
   
   if ( $answer ) {
      
      my $rh_job_params = {
         'id'             => $answer->{'parameters'}->{'jobID'},
         'emailAddress'   => $self->{'params'}->{'emailAddress'},
         'clients'        => $self->{'clients'},
      };
      
      return WebService::FuncNet::Job->new( $rh_job_params );
      
   } else {
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
