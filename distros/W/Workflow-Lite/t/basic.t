#!perl -T

use strict;
use warnings;

use Test::More;


{
  my $wf = MyWorkflow->new( start => 'ok_1' );
  $wf->work
    while $wf->is_flowing;
  ok( 1, 'simple workflow' );
}

{
  my $wf = MyWorkflow->new( start => 'e_flow' );
  eval {
    $wf->work
      while $wf->is_flowing;
  };
  like( $@, qr/^Destination step 'e_flow' does not exist\./, 'undefined destination step' );
}

{
  my $wf = MyWorkflow->new( start => 'e_work' );
  eval {
    $wf->work
      while $wf->is_flowing;
  };
  like( $@, qr/^No handler defined for step 'e_work'\./, 'undefined handler' );
}

{
  my $wf = MyWorkflow->new( start => 'die' );
  $wf->end;
  eval {
    $wf->work
      while 1;
  };
  like( $@, qr/^Cannot work if workflow has ended\./, 'undefined handler' );
}

done_testing;


BEGIN {
  package MyWorkflow;

  use namespace::autoclean;
  use Test::More;
  use Workflow::Lite;

  has start => ( is => 'ro', isa => 'Str', required => 1 );

  step START => sub { ok( 1, 'START' ); $_[0]->flow( $_[0]->start ) };

  steps
    ok_1 => sub {
      ok( 1, 'ok_1' );
      $_[0]->flow( 'ok_2' );
    },

    ok_2 => sub {
      ok( 1, 'ok_1' );
      $_[0]->end;
    },
  ;

  __PACKAGE__->_steps->{e_work} = undef;


  __PACKAGE__->meta->make_immutable;
}
