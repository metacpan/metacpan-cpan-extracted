package WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations;

=head1 NAME

WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations

=head1 SYNOPSIS

Represents the 'ScorePairwiseRelations' FuncNet WebService operation

  $ws = WebService::FuncNet::Predictor->new( ... );
  
  @proteins1 = qw( A3EXL0 Q8NFN7 O75865 );
  @proteins2 = qw( Q5SR05 Q9H8H3 P22676 );

  $response = $ws->score_pairwise_relations( \@proteins1, \@proteins2 );

  foreach my $result ( @{ $response->results } ) {
      printf "%s matches %s with p-value of %f\n",
                $result->protein_1,
                $result->protein_2,
                $result->p_value;
  }

=cut

use Moose;

use WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Response;

extends 'WebService::FuncNet::Predictor::Operation';

has '+operation' => ( default => 'ScorePairwiseRelations' );
has '+response_class' => ( default => 'WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Response' );

=head1 METHODS

=head2 run( \@proteins1, \@proteins2 )

Calls the WebService operation 'ScorePairwiseRelations' which does a pairwise comparison
of two sets of protein identifiers.

Returns:

  WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Response

=cut

around 'run' => sub {
    my ( $next, $self, $proteins1_ref, $proteins2_ref ) = @_;

    my $parameters = {
        proteins1 => { p => $proteins1_ref },
        proteins2 => { p => $proteins2_ref },
    };
    
    return $self->$next( $parameters );
};


1; # Magic true value required at end of module
__END__


=head1 AUTHOR

Ian Sillitoe  C<< <sillitoe@biochem.ucl.ac.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Ian Sillitoe C<< <sillitoe@biochem.ucl.ac.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 REVISION INFO

  Revision:      $Rev: 62 $
  Last editor:   $Author: isillitoe $
  Last updated:  $Date: 2009-07-06 16:01:23 +0100 (Mon, 06 Jul 2009) $

The latest source code for this project can be checked out from:

  https://funcnet.svn.sf.net/svnroot/funcnet/trunk

=cut
