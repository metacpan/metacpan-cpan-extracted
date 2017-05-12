package VarGuard::Array;

use strict;
use warnings;

=head1 NAME

VarGuard::Array - safe clean blocks for variables

=head1 SYNOPSIS

see VarGuard

=cut

use Tie::Array;
use base qw(Tie::StdArray);

my %cb;

sub TIEARRAY {
    my $class = shift;
    my $self = $class->SUPER::TIEARRAY;
    $cb{0+$self} = $_[0];
    return $self;
}

sub DESTROY {
    my $self = shift;
    my $cb = delete $cb{0+$self};
    $cb->(@$self) if( $cb );
}

1;
