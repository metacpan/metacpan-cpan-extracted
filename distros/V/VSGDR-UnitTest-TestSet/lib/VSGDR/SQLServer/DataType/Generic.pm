package VSGDR::SQLServer::DataType::Generic ;

#our \$VERSION    = "1.01";
use strict;
use warnings;

use parent qw(VSGDR::SQLServer::DataType);


sub getValue {
    local $_ ;
    my $self                = shift ;
    return                  $self->{VALUE} ;
}

sub quoteValue {
    local $_ ;
    my $self                = shift ;
    my $value               = shift ;
    $value =~ s{"}{\\"}gms; #" -- kill Textpad highlighting
    return                  $value ;
}

sub unQuoteValue {
    local $_ ;
    my $self                = shift ;
    my $value               = shift ;
    $value =~ s{\\"}{"}gms; #" -- kill Textpad highlighting
    return                  $value ;
}

1 ;

__DATA__

