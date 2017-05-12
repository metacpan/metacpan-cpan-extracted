package VarGuard::Scalar;

use strict;
use warnings;

=head1 NAME

VarGuard::Scalar - safe clean blocks for variables

=head1 SYNOPSIS

see VarGuard

=cut

use Tie::Scalar;
use base qw(Tie::StdScalar);

my %cb;

sub TIESCALAR {
    my $class = shift;
    my $self = $class->SUPER::TIESCALAR;
    $cb{0+$self} = $_[0];
    return $self;
}

sub DESTROY {
    my $self = shift;
    my $cb = delete $cb{0+$self};
    $cb->($$self) if( $cb );
}

1;
