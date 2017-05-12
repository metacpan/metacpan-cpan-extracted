package Text::Livedoor::Wiki::IDKeeper;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self  = shift ;
    bless $self , $class; 
    for(1..3){
        $self->{level}{$_} = 0;
    }
    return $self;
}

sub up {
    my $self = shift;
    my $level = shift ;
    $self->{level}{$level}++;
}

sub id {
    my $self = shift;
    my $target_level = shift;

    my $id = $self->{name} ;

    foreach my $level ( sort keys %{$self->{level}} ) {
        last if $level > $target_level;
        $id.= '_' . $self->{level}{$level} ;
    }
    return $id;
}

1;

=head1 NAME

Text::Livedoor::Wiki::IDKeeper - ID Keeper

=head1 DESCRIPTION

keep header id for #contents

=head1 METHOD 

=head2 new

=head2 up

=head2 id

=head1 AUTHOR

polocky

=cut
