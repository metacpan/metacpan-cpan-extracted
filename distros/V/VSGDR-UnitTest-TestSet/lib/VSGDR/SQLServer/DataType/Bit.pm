package VSGDR::SQLServer::DataType::Bit ;

use 5.010;
use strict;
use warnings;


#our \$VERSION    = "1.01";

use VSGDR::SQLServer::DataType ;

use parent qw(VSGDR::SQLServer::DataType);



sub getValue {
    local $_ ;
    my $self                = shift ;
    return                  ( ! defined($self->{VALUE})         ? undef
                            : $self->{VALUE} == 1               ? 'true' 
                            : $self->{VALUE} == 0               ? 'false' 
                            : $self->{VALUE} =~ /\Atrue\z/i     ? 'true' 
                            : $self->{VALUE} =~ /\Afalse\z/i    ? 'false' 
                            : $self->{VALUE} =~ /\A\s*\z/i      ? 'false' 
                            : 'true'
                            ) ;
}


1 ;

__DATA__

