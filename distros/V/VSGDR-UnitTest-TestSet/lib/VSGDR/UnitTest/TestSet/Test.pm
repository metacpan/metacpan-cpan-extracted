package VSGDR::UnitTest::TestSet::Test;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.01';


use Data::Dumper ;
use Carp ;


use vars qw($AUTOLOAD);
my %ok_field;

# Authorize four attribute fields
{
#for my $attr ( qw(nameSpace className testName testDataName ) ) { $ok_field{$attr}++; } 
#for my $attr ( qw(testName testActionDataName postTestAction testAction preTestAction) ) { $ok_field{$attr}++; } 
for my $attr ( qw(testName testActionDataName ) ) { $ok_field{$attr}++; } 
}
sub new {

    local $_ = undef ;

#warn Dumper @_;

    my $invocant         = shift ;
    my $class            = ref($invocant) || $invocant ;

    my @elems            = @_ ;
    my $self             = bless {}, $class ;
   
    $self->_init(@elems) ;
    return $self ;
}


sub _init {

    local $_ = undef ;

#warn Dumper @_;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    my $ref = shift or croak "no arg";

#print Dumper $ref ;

    for my $attr ( qw(TESTNAME TESTACTIONDATANAME PRETESTACTION TESTACTION POSTTESTACTION ) ) { $self->{OK_PARAMS}{$attr}++; } 
    my @validargs = grep { $$ref{$_} } keys %{$self->{OK_PARAMS}} ;
#warn Dumper @validargs ;    
    croak "bad args"
        if scalar(@validargs) != 5 ; 


    my ${TestName}              = $$ref{TESTNAME};
    my ${TestActionDataName}    = $$ref{TESTACTIONDATANAME};
    my ${PreTestAction}         = $$ref{PRETESTACTION};
    my ${TestAction}            = $$ref{TESTACTION};
    my ${PostTestAction}        = $$ref{POSTTESTACTION};

    $self->testName(${TestName}) ; 
    $self->testActionDataName(${TestActionDataName}) ; 
    $self->preTestAction(${PreTestAction}) ; 
    $self->testAction(${TestAction}) ; 
    $self->postTestAction(${PostTestAction}) ; 
    
    $self->{TESTCONDITIONS}   = [] ;
    
    $self->{PRETEST_TESTCONDITIONS}     = [] ;
    $self->{TEST_TESTCONDITIONS}        = [] ;
    $self->{POSTTEST_TESTCONDITIONS}    = [] ;
    
#multiple tests
#each with multiple actions
#each with multiple conditions

#    $self->testName(${TestName}) ; 
#    $self->testDataName(${TestDataName}) ; 
    
    return ;
    
}

#-- TODO --->
sub actions {
    my $self       = shift or croak 'no self';
    my %actions ;

    if ( $self->preTestAction()  !~ m/^(?:null|nothing)$/ix ) { $actions{$self->testName()."_".$self->preTestAction()} = 1; }
    if ( $self->testAction()     !~ m/^(?:null|nothing)$/ix ) { $actions{$self->testName()."_".$self->testAction()} = 1; }
    if ( $self->postTestAction() !~ m/^(?:null|nothing)$/ix ) { $actions{$self->testName()."_".$self->postTestAction()} = 1; }
    
    return \%actions ;
}

#sub hasAction {
#    my $self       = shift or croak 'no self';
#    my $action     = shift ;
#    croak 'No action requested' if not defined $action;
#    return exists($self->{ACTIONS}{$action}) ;
#}



sub preTestActionLiteral {
    my $self            = shift;
    return "PretestAction";
}
sub testActionLiteral {
    my $self            = shift;
    return "TestAction";
}
sub postTestActionLiteral {
    my $self            = shift;
    return "PosttestAction";
}

sub preTestActionLiteralName {
    my $self            = shift;
    return $self->testName . '_' . $self->preTestActionLiteral() ;   
}
sub testActionLiteralName {
    my $self            = shift;
    return $self->testName . '_' . $self->testActionLiteral() ;   
}
sub postTestActionLiteralName {
    my $self            = shift;
    return $self->testName . '_' . $self->postTestActionLiteral() ;   
}

sub commentifyTestName {
    my $self            = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->testName()]}
            ${commentChars}
EOF
}


sub commentifyPreTestAction {
    my $self            = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->preTestAction()]}
            ${commentChars}
EOF
}

sub commentifyTestAction {
    my $self            = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->testAction()]}
            ${commentChars}
EOF
}

sub commentifyPostTestAction {
    my $self            = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->postTestAction()]}
            ${commentChars}
EOF
}

sub commentifyActionDataName {
    my $self    = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->testActionDataName()]}
            ${commentChars}
EOF
}

sub preTest_conditions {
    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
        my @conditions      = @$conditions ;
        $self->{PRETEST_TESTCONDITIONS} = \@conditions ;
    }
    return $self->{PRETEST_TESTCONDITIONS} ;
}

sub test_conditions {
    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
        my @conditions      = @$conditions ;
        $self->{TEST_TESTCONDITIONS} = \@conditions ;
    }
    return $self->{TEST_TESTCONDITIONS} ;
}

sub postTest_conditions {
    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
        my @conditions      = @$conditions ;
        $self->{POSTTEST_TESTCONDITIONS} = \@conditions ;
    }
    return $self->{POSTTEST_TESTCONDITIONS} ;
}

sub conditions {
    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
croak 'obsoleted method' ;  
    }
    my $preTestConditions  = $self->preTest_conditions() ;
    my $testConditions     = $self->test_conditions() ;
    my $postTestConditions = $self->postTest_conditions() ;
    my @Conditions =  flatten ([@$preTestConditions,@$testConditions,@$postTestConditions]);
    
    return \@Conditions ;
}

sub preTestAction {
    my $self        = shift or croak 'no self';
    my $action ;
    $action         = shift if @_;
    # normalise
    if ( defined $action ) {
        $action = 'null' if $action =~ m{^null|nothing$}ix ;
        $self->{PRETESTACTION} = $action ;
    }
    return $self->{PRETESTACTION} ;

}
sub testAction {
    my $self        = shift or croak 'no self';
    my $action ;
    $action         = shift if @_;
    # normalise
    if ( defined $action ) {
        $action = 'null' if $action =~ m{^null|nothing$}ix ;
        $self->{TESTACTION} = $action ;
    }
    return $self->{TESTACTION} ;

} 
sub postTestAction {
    my $self        = shift or croak 'no self';
    my $action ;
    $action         = shift if @_;
    # normalise
    if ( defined $action ) {
        $action = 'null' if $action =~ m{^null|nothing$}ix ;
        $self->{POSTTESTACTION} = $action ;
    }
    return $self->{POSTTESTACTION} ;

}


sub flatten { return map { @$_} @_ } ;

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s{.*::}{}x;
    return unless $attr =~ m{[^A-Z]}x;  # skip DESTROY and all-cap methods
    croak "invalid attribute method: ->$attr()" unless $ok_field{$attr};
    $self->{uc $attr} = shift if @_;
    return $self->{uc $attr};
}

1 ;

__DATA__


