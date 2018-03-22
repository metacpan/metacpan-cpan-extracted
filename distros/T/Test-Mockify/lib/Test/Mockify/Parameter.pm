package Test::Mockify::Parameter;
use Test::Mockify::ReturnValue;
use Data::Compare;
use Test::Mockify::TypeTests qw ( IsString );
use Scalar::Util qw(blessed );
use Test::Mockify::Tools qw (Error);
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
    Error ('NoReturnValueDefined') unless ($self->{'ReturnValue'});
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

    for(my $i=0; $i < scalar @Params; $i++){## no critic (ProhibitCStyleForLoops) i need the counter
        my $StoredValue = $self->{'ExpectedParams'}->[$i]->{'Value'};
        if(not $StoredValue || (defined $StoredValue && "$StoredValue" eq '0')){ ## no critic (ProhibitMixedBooleanOperators )
            next;
        }elsif(blessed($Params[$i]) && $Params[$i]->isa($StoredValue)){# map package name
            next;
        }elsif(Data::Compare->new()->Cmp($Params[$i], $StoredValue)){
            next;
        } else{
            return 0;
        }
    }
    return 1;
}

1;