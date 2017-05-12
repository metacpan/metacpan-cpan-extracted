package VarGuard::Hash;

use strict;
use warnings;

=head1 NAME

VarGuard::Hash - safe clean blocks for variables

=head1 SYNOPSIS

see VarGuard

=cut

use Tie::Hash;
use base qw(Tie::StdHash);

my %cb;

sub TIEHASH {
    my $class = shift;
    my $self = $class->SUPER::TIEHASH;
    $cb{0+$self} = $_[0];
    return $self;
}

sub DESTROY {
    my $self = shift;
    my $cb = delete $cb{0+$self};
    $cb->(%$self) if( $cb );
}

1;
