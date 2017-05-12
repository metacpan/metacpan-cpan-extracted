package VSGDR::UnitTest::TestSet::Test::TestCondition::ExpectedSchema;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.01';


use parent qw(VSGDR::UnitTest::TestSet::Test::TestCondition) ;
BEGIN {
*AUTOLOAD = \&VSGDR::UnitTest::TestSet::Test::TestCondition::AUTOLOAD ;
}

use Data::Dumper ;
use Carp ;


use vars qw($AUTOLOAD %ok_field);

# Authorize constructor hash fields
my %ok_params = () ;
for my $attr ( qw(CONDITIONTESTACTIONNAME CONDITIONNAME CONDITIONENABLED CONDITIONVERBOSE CONDITIONAPPLYRESOURCES) ) { $ok_params{$attr}++; } 
my %ok_fields       = () ;
my %ok_fields_type  = () ;
# Authorize attribute fields
for my $attr ( qw(conditionTestActionName conditionName conditionEnabled conditionVerbose conditionApplyResources) )  { $ok_fields{$attr}++; $ok_fields_type{$attr} = 'plain'; } 
$ok_fields_type{conditionName}                  = 'quoted';  
$ok_fields_type{conditionEnabled}               = 'bool';  
$ok_fields_type{conditionApplyResources}        = 'literalcode';  


sub _init {

    local $_ = undef ;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    my $ref                 = shift or croak "no arg";

    $self->{OK_PARAMS}      = \%ok_params ;
    $self->{OK_FIELDS}      = \%ok_fields ;
    $self->{OK_FIELDS_TYPE} = \%ok_fields_type ;
    my @validargs           = grep { exists($$ref{$_}) } keys %{$self->{OK_PARAMS}} ;
#warn Dumper @validargs;    
    croak "bad args"
        if scalar(@validargs) != 4 ; 
#warn Dumper @validargs;    
    my ${Name}              = $$ref{CONDITIONNAME};
    my ${TestActionName}    = $$ref{CONDITIONTESTACTIONNAME};
    my ${Enabled}           = $$ref{CONDITIONENABLED};
    my ${Verbose}           = $$ref{CONDITIONVERBOSE};

    $self->conditionName(${Name}) ; 
    $self->conditionTestActionName(${TestActionName}) ; 
    $self->conditionEnabled(${Enabled}) ; 
    $self->conditionVerbose(${Verbose}) ; 

  
    return ;
    
}

sub testConditionType {
    my $self    = shift;
    return 'ExpectedSchema' ;
}

sub testConditionMSType {
    return 'ExpectedSchemaCondition' ;
}

sub check {
    local $_                = undef ;
    my $self                = shift ;
    my $ra_res              = shift ;

#warn Dumper $ra_res ;

    if ( $self->conditionISEnabled() ) {
#say 'Condition is ', $self->conditionName() ;
#say 'value    is  ', '"'.$ra_res->[$self->conditionResultSet()-1]->[$self->conditionRowNumber()-1]->[$self->conditionColumnNumber()-1].'"'  ;
#say 'expected was ', $self->conditionExpectedValue()  ;
        return scalar 1 ; 
    }
    else {
#say 'Condition ', $self->conditionName(), ' is disabled' ;
        return scalar -1 ; 
    }
} 

## local override for unstorable attribute - when called upon - just derive it.
## luckily we can get away with this it's the same for vb and c#

sub conditionApplyResources {
    local $_                = undef ;
    my $self                = shift ;
    my $ra_res              = shift ;
    return "resources.ApplyResources(" . $self->conditionName() . ', "' . $self->conditionName() . '")' ;
}




1 ;

__DATA__

