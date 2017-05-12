package VSGDR::SQLServer::DataType;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.01';
use Carp;
use parent qw(Clone);

use overload        (
        q("")   => sub {$_[0]->{VALUE}}, 
        q(0+)   => sub {$_[0]->{VALUE}},
        '<=>'   => \&spaceship,
        'cmp'   => \&spaceship,
);


our %Types      =   ( Bit       => 1
                    , Generic   => 1
                    ) ;


sub new {

    local $_ ;

    my $invocant         = shift ;
    my $class            = ref($invocant) || $invocant ;

    my @elems            = @_ ;
    my $self             = bless {}, $class ;

    $self->_init(@elems) ;
    return $self ;
}


sub _init {

    local $_ ;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    my $arg                 = shift ;##  can''t check undef !or croak "no _init arg";

    my $Value               = $arg;
    $self->setValue(${Value} ) ; 

    return ;
    
}

sub setValue {

    local $_ ;

    my $self                = shift ;
    my $arg                 = shift ;##  can''t check undef or croak "no setValue arg";
    $self->{VALUE}          = $arg ;
        
}

sub value {

    local $_ ;

    my $self                = shift ;
    return scalar $self->{VALUE} ;
        
}

## parent type - do nothing
sub quoteValue {
    local $_ ;
    my $self                = shift ;
    my $value               = shift ;
    return                  $value ;
}

## parent type - do nothing
sub unQuoteValue {
    local $_ ;
    my $self                = shift ;
    my $value               = shift ;
    return                  $value ;
}


sub make {

    local $_ ;
    my $self            = shift ;
    my $flagthing       = shift or croak 'No object type' ;
    
    my $objectType ;
    if ( $flagthing == -7 ) {
        $objectType = 'Bit';
    }
    else {
        $objectType = 'Generic';
    }
    croak "Invalid SQL Server Data Type" unless exists $Types{${objectType}};
    
    require "VSGDR/SQLServer/DataType/${objectType}.pm";
    return "VSGDR::SQLServer::DataType::${objectType}"->new(@_) ;

}


sub spaceship { 
    my ($s1, $s2, $inverted) = @_;

return 0 if ( ! defined $s1->value() ) or ( ! defined $s2->value() ) ;
    return $inverted ? $s2->value() cmp $s1->value() : $s1->value() cmp $s2->value() ;
} 


1 ;

__DATA__

