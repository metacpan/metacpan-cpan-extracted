package VSGDR::UnitTest::TestSet::Test::TestCondition::ExecutionTime;

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
for my $attr ( qw(CONDITIONTESTACTIONNAME CONDITIONNAME CONDITIONENABLED CONDITIONEXECUTIONTIME) ) { $ok_params{$attr}++; } 
my %ok_fields       = () ;
my %ok_fields_type  = () ;

# Authorize attribute fields
for my $attr ( qw(conditionTestActionName conditionName conditionEnabled conditionExecutionTime ) ) { $ok_fields{$attr}++; $ok_fields_type{$attr} = 'plain'; } 
$ok_fields_type{conditionName}      = 'quoted';  
$ok_fields_type{conditionEnabled}   = 'bool';  

sub _init {

    local $_ = undef ;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    my $ref                 = shift or croak "no arg";

    $self->{OK_PARAMS}      = \%ok_params ;
    $self->{OK_FIELDS}      = \%ok_fields ;
    $self->{OK_FIELDS_TYPE} = \%ok_fields_type ;

    my @validargs           = grep { exists($$ref{$_}) } keys %{$self->{OK_PARAMS}} ;
    croak "bad args"
        if scalar(@validargs) != 4 ; 


    my ${Name}              = $$ref{CONDITIONNAME};
    my ${TestActionName}    = $$ref{CONDITIONTESTACTIONNAME};
    my ${Enabled}           = $$ref{CONDITIONENABLED};
    my ${ExecutionTime}     = $$ref{CONDITIONEXECUTIONTIME};

    $self->conditionName(${Name}) ; 
    $self->conditionTestActionName(${TestActionName}) ; 
    $self->conditionEnabled(${Enabled}) ; 
    $self->conditionExecutionTime(${ExecutionTime}) ; 

    return ;

    
}



sub testConditionType {
    return 'ExecutionTime' ;
}

sub testConditionMSType {
    return 'ExecutionTimeCondition' ;
}


sub check {
    local $_                = undef ;
    my $self                = shift ;
    my $ra_res              = shift ;
    return scalar 1 ; 
}


1 ;

__DATA__

