#!perl -T

use strict;
use warnings;

use Test::More;


{
  my $wf = MyWorkflowRegistry->new_workflow( mwf => text => 'foo' );
  $wf->work
    while $wf->is_flowing;
  ok( 1, 'simple workflow' );
}

{
  my $wf = eval { MyWorkflowRegistry->new_workflow( ttr => text => 'foo' ) };
  like( $@, qr/No class registered for 'ttr'\./, 'unregistered class' );
}

done_testing;


BEGIN {
  package MyWorkflow;

  use namespace::autoclean;
  use Test::More;
  use Workflow::Lite;

  has text => ( is => 'ro', isa => 'Str', required => 1 );

  steps
    START => sub { is( $_[0]->text, 'foo', 'START' ); $_[0]->end }
  ;
}

BEGIN {
  package MyWorkflowRegistry;

  use namespace::autoclean;
  use Moose;

  extends qw( Workflow::Lite::Registry );

  __PACKAGE__->register( mwf => 'MyWorkflow' );

  __PACKAGE__->meta->make_immutable;
}
