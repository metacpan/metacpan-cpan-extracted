package WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Response;

=head1 NAME

WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Response

=head1 SYNOPSIS

Represents a response from the 'ScorePairwiseRelations' operation

    $op      = $wsdl->operation( operation => 'ScorePairwiseRelations' );
    $op_call = $op->compileClient();
    $answer  = $op_call->( parameters => { ... } );

    $response = WebService::FuncNet::Predictor::ScorePairwiseRelations::Response->new( $answer );

=cut

use Moose;

use WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Result;
use WebService::FuncNet::Predictor::Logger;

use Data::Dumper;

with 'WebService::FuncNet::Predictor::Logable';

my $logger = get_logger();

=head2 BUILDARGS

=cut

sub BUILDARGS {
    my $class = shift;
    my $args = @_ == 1
                ? { results => _results_from_wsdl_response( $_[0] ) }
                : { @_ };
    
    return $args;
}

=head1 ACCESSORS

=head2 results

an array of WebService::FuncNet::Predictor::ScorePairwiseRelations::Result

=cut

has 'results' => (
    is => 'rw',
    isa => 'ArrayRef[WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Result]',
    lazy_build => 1,
);

=head1 METHODS

=head2 _results_from_wsdl_response

Returns an ARRAY ref of results based on the WSDL response data structure

=cut

sub _results_from_wsdl_response {
    my $wsdl_response = shift;
    my @results = ();
    
    $logger->debug( 'response: ' . Dumper( $wsdl_response ) );
    
    foreach my $result ( @{ $wsdl_response->{ parameters }->{ 's' } } ) {
        push @results, WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Result->new(
                protein_1 => $result->{p1},
                protein_2 => $result->{p2},
                p_value   => $result->{pv},
                raw_score => $result->{rs},
            );
    }

    return \@results;
}

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
