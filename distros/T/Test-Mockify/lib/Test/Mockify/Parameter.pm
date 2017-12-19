package Test::Mockify::Parameter;
use Test::Mockify::ReturnValue;
use Data::Compare;
use Test::Mockify::TypeTests qw ( IsString );
use Scalar::Util qw(blessed );

use strict;
use warnings;
#---------------------------------------------------------------------
sub new {
    my $class = shift;
    my ($ExpectedParams) = @_;
    $ExpectedParams //= [];
    my $self = bless {
        'ExpectedParams' => $ExpectedParams,
    }, $class;
    return $self;
}
#---------------------------------------------------------------------
sub call {
    my $self = shift;
    die ('NoReturnValueDefined') unless ($self->{'ReturnValue'});
    return $self->{'ReturnValue'}->call(@_);
}
#---------------------------------------------------------------------
sub buildReturn {
    my $self = shift;
    $self->{'ReturnValue'} = Test::Mockify::ReturnValue->new();
    return $self->{'ReturnValue'};
}
#---------------------------------------------------------------------
sub compareExpectedParameters {
    my $self = shift;
    my ($Parameters) = @_;
    $Parameters //= [];
    return 0 unless (scalar @{$Parameters} == scalar @{$self->{'ExpectedParams'}});
    return Data::Compare->new()->Cmp($Parameters, $self->{'ExpectedParams'});
}
#---------------------------------------------------------------------
sub matchWithExpectedParameters {
    my $self = shift;
    my @Params = @_;
    return 0 unless (scalar @Params == scalar @{$self->{'ExpectedParams'}});

    for(my $i=0; $i < scalar @Params; $i++){
        if(not $self->{'ExpectedParams'}->[$i]->{'Value'}){ #No Value no Match
            next;
        }elsif(blessed($Params[$i]) && $Params[$i]->isa($self->{'ExpectedParams'}->[$i]->{'Value'})){# map package name
            next;
        }elsif(Data::Compare->new()->Cmp($Params[$i], $self->{'ExpectedParams'}->[$i]->{'Value'})){
            next;
        } else{
            return 0;
        }
    }
    return 1;
}

1;