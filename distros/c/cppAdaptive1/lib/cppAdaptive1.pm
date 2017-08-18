package cppAdaptive1;

use strict;
use warnings;

require DynaLoader;

our $VERSION = '0.01';
$VERSION = eval $VERSION;    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
DynaLoader::bootstrap cppAdaptive1 $VERSION;

sub dl_load_flags { return 0 }    # Prevent DynaLoader from complaining and croaking

sub update {
    my ( $obsVector, $futVector, $betaVector, $n_observed ) = @_;

    return @{ _update( $obsVector, $futVector, $betaVector, $n_observed ) };
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "common" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 9                    | ValuesAndExpressions::RequireConstantVersion - $VERSION value must be a constant                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

cppAdaptive1 - cppAdaptive1 XS

=head1 SYNOPSIS

    use cppAdaptive1;

    my ( $newFutVector, $newBetaVector ) = cppAdaptive1::update( $obsVector, $futVector, $betaVector, $n_observed );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
