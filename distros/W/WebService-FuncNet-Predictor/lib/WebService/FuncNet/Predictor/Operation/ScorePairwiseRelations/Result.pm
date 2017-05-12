package WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Result;

=head1 NAME

WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Result

=head1 SYNOPSIS

Represents a result from the 'ScorePairwiseRelations' operation

=cut

use Moose;
use WebService::FuncNet::Predictor::Types qw/ Float /;
use Moose::Util::TypeConstraints;

=head1 ATTRIBUTES

=head2 protein_1

Identity of protein_1

=cut

has 'protein_1' => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

=head2 protein_2

Identity of protein_2

=cut

has 'protein_2' => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

=head2 raw_score

The raw score of the match

=cut

has 'raw_score' => (
    is => 'rw',
    isa => 'Float',
    coerce => 1,
    lazy_build => 1,
);

=head2 p_value

The p-value of the match

=cut

has 'p_value' => (
    is => 'rw',
    isa => 'Float',
    coerce => 1,
    lazy_build => 1,
);


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
