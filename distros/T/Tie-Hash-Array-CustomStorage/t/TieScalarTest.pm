#!/usr/local/bin/perl
package TieScalarTest ;
# use warnings FATAL => qw(all);

use Carp;
use strict;

require Tie::Scalar ;

sub TIESCALAR {
    my $type = shift;
    my %args = @_ ;
    my $self={} ;
    if (defined $args{enum}) {
        # store all enum values in a hash. This way, checking
        # whether a value is present in the enum set is easier
        map {$self->{enum}{$_} =  1;} @{$args{enum}} ;
    } else {
        croak ref($self)," error: no enum values defined when calling init";
    }

    $self->{default} = $args{default};
    $self->{name} = $args{name};
    bless $self,$type;
}

sub STORE {
    my ($self,$value) = @_ ;
    croak "cannot set ",ref($self)," item to $value. Expected ",
      join(' ',keys %{$self->{enum}}) 
        unless defined $self->{enum}{$value} ;
    # we may want to check other rules here ... TBD
    # warn "Tie: Setting\n";
    $self->{value} = $value ;
    return $value;
}


sub FETCH {
    my $self = shift ;
    # warn "Tie: Fetching\n";
    return defined $self->{value} ? $self->{value} : $self->{default}  ;
}

1;
