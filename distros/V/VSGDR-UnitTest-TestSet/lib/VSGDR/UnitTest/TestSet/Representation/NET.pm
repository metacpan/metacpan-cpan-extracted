package VSGDR::UnitTest::TestSet::Representation::NET;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.01';


use parent qw(VSGDR::UnitTest::TestSet::Representation) ;

use Carp ;

use VSGDR::UnitTest::TestSet;
use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Representation;


use Storable qw(dclone);

use Data::Dumper ;
use autodie ;

our %Globals ; ## temp



#TODO:  1. This needs abstracting away - $condition->testConditionAttributeType(${conditionAttribute}) eq 'quoted' ne 'literalcode'

sub parser1 {
    local $_    = undef;
    my $self    = shift or croak 'no self';
    return $self->{PARSER1} ;
}
sub parser2 {
    local $_    = undef;
    my $self    = shift or croak 'no self';
    return $self->{PARSER2} ;
}


sub parse {
    local $_    = undef;
    my $self    = shift or croak 'no self';
    my $code    = shift or croak 'no code' ;

    $code       = $self->trim($code) ;

    my $res1    = $self->parser1()->start(${code});
    croak "Failed to parse .Net representation" if ! defined $res1 ;
    my $globals = dclone($res1->{GLOBALS});
    my $res2    = $self->parser2()->start(${code},1,$globals);

    my $res ;    
    $res->{GLOBALS}                     = $res1->{GLOBALS};
    $res->{ACTIONS}                     = $res2->{ACTIONS};
    $res->{TESTACTIONS}                 = $res2->{TESTACTIONS};
    $res->{RESOURCES}                   = $res2->{RESOURCES};
    $res->{TESTCONDITIONS}              = $res2->{TESTCONDITIONS};
    $res->{TESTCONDITIONS_DETAILS}      = $res2->{TESTCONDITIONS_DETAILS};
     
#    my $res=$self->start(${code});

#warn Dumper $res1 ; 
#warn Dumper $res ; 
#exit;


    my $nameSpace = $$res{GLOBALS}{NAMESPACE} ;
    my $className = $$res{GLOBALS}{CLASSNAME} ;
    my $cleanupAction = $$res{GLOBALS}{CLEANUPACTION} ;
    my $initializeAction = $$res{GLOBALS}{INITIALIZEACTION} ;

    my $testSet = VSGDR::UnitTest::TestSet->new( { NAMESPACE        => $nameSpace
                                                  , CLASSNAME        => $className
                                                  } 
                                                ) ;
    my @tests            = keys %{$$res{GLOBALS}{TESTS}} ;
    my %testActions      = map { $_ => $$res{GLOBALS}{TESTS}{$_}{ACTION}}   keys   %{$$res{GLOBALS}{TESTS}} ;


    my %testActionLinkage   = map { $_ => $$res{TESTACTIONS}{$_}}   keys   %{$$res{TESTACTIONS}} ;

#warn Dumper %testActions ;                                                    
#warn Dumper %testActionLinkage ;                                                    
    my %revTestActions   = map { $$res{GLOBALS}{TESTS}{$_}{ACTION} => $_ }  keys   %{$$res{GLOBALS}{TESTS}} ;
    my %testActionsData  = map { $revTestActions{$_} => $$res{ACTIONS}{$_}} values %testActions ;
#warn Dumper $$res{ACTIONS} ;    
#warn Dumper %testActionsData ;
    
    my %conditions          = () ;
#warn Dumper $$res{RESOURCES}{CONDITIONS} ;    
    %conditions             = %{$$res{RESOURCES}{CONDITIONS}} if defined $$res{RESOURCES}{CONDITIONS} ;
    my %testSetActions      = () ;
    %testSetActions         = map { $_ =>  $$res{RESOURCES}{$_} } 
                                    grep { $_ ne 'CONDITIONS'} keys %{$$res{RESOURCES}} 
                              if defined $$res{RESOURCES} ;   
                              

    if ( exists $testSetActions{testInitializeAction} ) {
        $testSet->initializeAction('testInitializeAction') ;
    }
    if ( exists $testSetActions{testCleanupAction} ) {
        $testSet->cleanupAction('testCleanupAction') ;
    }

#warn Dumper %testSetActions;
#warn Dumper $testSet->initializeAction() ;
#exit;
    my %testSetConditions   = map { $_ =>  $$res{RESOURCES}{CONDITIONS}{$_} }  qw(testInitializeAction testCleanupAction) ;

   
    my %testConditions      = map { $_ =>  $$res{RESOURCES}{CONDITIONS}{$_} } 
                                    grep { $_ ne 'testInitializeAction'and $_ ne 'testCleanupAction'} keys %{$$res{RESOURCES}{CONDITIONS}} ;

    my %testConditionTypes   = %{$$res{TESTCONDITIONS}} ;
    my %testConditionDetails = %{$$res{TESTCONDITIONS_DETAILS}} ;


    my @testInitObjects  = () ;
    my @testCleanupObjects  = () ;
    foreach my $testCondition ( @{$testSetConditions{'testInitializeAction'}} ) {
        my %testConditionConstructor = map { ( my $key = "CONDITION" . uc($_) ) ; 
                                             ( my $val = $testConditionDetails{$testCondition}{$_} ) =~ s/^\s*(.*?)\s*$/$1/x;
                                             $key => $val ;
                                           } keys %{$testConditionDetails{$testCondition}} ;

        ( my $testConditionType = $testConditionTypes{$testCondition} ) =~ s{Condition$}{}x;
        $testConditionConstructor{TESTCONDITIONTYPE}       = $testConditionType ;
        $testConditionConstructor{CONDITIONNAME}           = $testCondition ;
        $testConditionConstructor{CONDITIONTESTACTIONNAME} = 'testInitializeAction' ;
        my $testConditionObject = VSGDR::UnitTest::TestSet::Test::TestCondition->make(\%testConditionConstructor) ;

        unshift @testInitObjects, $testConditionObject ;
    }
    $testSet->initializeConditions(\@testInitObjects);
    foreach my $testCondition ( @{$testSetConditions{'testCleanupAction'}} ) {
        my %testConditionConstructor = map { ( my $key = "CONDITION" . uc($_) ) ; 
                                             ( my $val = $testConditionDetails{$testCondition}{$_} ) =~ s{^\s*(.*?)\s*$}{$1}x;
                                             $key => $val ;
                                           } keys %{$testConditionDetails{$testCondition}} ;

        ( my $testConditionType = $testConditionTypes{$testCondition} ) =~ s{Condition$}{}x;
        $testConditionConstructor{TESTCONDITIONTYPE}       = $testConditionType ;
        $testConditionConstructor{CONDITIONNAME}           = $testCondition ;
        $testConditionConstructor{CONDITIONTESTACTIONNAME} = 'testCleanupAction' ;
        my $testConditionObject = VSGDR::UnitTest::TestSet::Test::TestCondition->make(\%testConditionConstructor) ;

        unshift @testCleanupObjects, $testConditionObject ;
    }
    $testSet->cleanupConditions(\@testCleanupObjects);

    my @testObjects = () ;

    my @preTest_testConditionObjects   = undef ;
    my @test_testConditionObjects      = undef ;
    my @postTest_testConditionObjects  = undef ;

    foreach my $test (@tests) {
#        my @testConditionObjects  = () ;
#warn Dumper $test ;
#warn Dumper $testActions{$test} ;
#warn Dumper $testActionsData{$test} ;
        @preTest_testConditionObjects   = () ;
        @test_testConditionObjects      = () ;
        @postTest_testConditionObjects  = () ;

        my $testObject = VSGDR::UnitTest::TestSet::Test->new( { TESTNAME                => $test
                                                                 , TESTACTIONDATANAME    => $testActions{$test}
                                                                 , PRETESTACTION         => $testActionsData{$test}{PretestAction}          
                                                                 , TESTACTION            => $testActionsData{$test}{TestAction}         
                                                                 , POSTTESTACTION        => $testActionsData{$test}{PosttestAction}     
                                                               } ) ;

#        foreach my $testAction ( keys %testConditions ) {
#warn Dumper keys %testConditions ;
#        foreach my $testAction ( grep { $_ =~ m{^${test}_(?:Test|Pretest|PostTest)Action}x } keys %testConditions ) {
        foreach my $testAction ( grep { my $x =  $_ ; 
                                        $x    =~ s{ _(?: Test|Pretest|PostTest ) Action \z}{}x ;
                                        $testActionLinkage{$x} =~ m{^${test}Data}x                                      
                                      }  keys %testConditions ) {
            foreach my $testCondition ( @{$conditions{$testAction}} ) {
#warn Dumper $testCondition ;                    
                my %testConditionConstructor = map { ( my $key = "CONDITION" . uc($_) ) ; 
                                                     ( my $val = $testConditionDetails{$testCondition}{$_} ) =~ s/^\s*(.*?)\s*$/$1/x;
                                                     $key => $val ;
                                                   } keys %{$testConditionDetails{$testCondition}} ;
                                                   
                ( my $testConditionType = $testConditionTypes{$testCondition} ) =~ s{Condition$}{}x;
                $testConditionConstructor{TESTCONDITIONTYPE}       = $testConditionType ;
                $testConditionConstructor{CONDITIONNAME}           = $testCondition ;
                $testConditionConstructor{CONDITIONTESTACTIONNAME} = $testAction ;
#warn Dumper %testConditionConstructor ;                
                my $testConditionObject = VSGDR::UnitTest::TestSet::Test::TestCondition->make(\%testConditionConstructor) ;


#warn Dumper $testConditionObject->conditionName() ;
#warn Dumper $testAction ;
( my $testActionBase = $testAction ) =~ s{ _(?: Test|Pretest|PostTest ) Action \z}{}x ;

#warn Dumper $test ;
#warn Dumper $testActionBase ;
#warn Dumper %testActionLinkage ;
#warn Dumper $$res{ACTIONS}{$testActionLinkage{$testActionBase}} ;
#warn Dumper $testActionLinkage{$testActionBase} ;
#warn Dumper $testObject->testActionLiteral() ;
#warn Dumper $testActionLinkage{$testActionBase} ;

# this needs simlifying !
#                if ( $test ."_". $testObject->testActionLiteral()  eq $testAction ) {
                if ( $$res{ACTIONS}{ $testActionLinkage{$testActionBase} }{$testObject->testActionLiteral()}  eq $testAction ) {
                    unshift @test_testConditionObjects, $testConditionObject ;
                }
#                if ( $test ."_". $testObject->preTestActionLiteral() eq $testAction ) {
                if ( $$res{ACTIONS}{ $testActionLinkage{$testActionBase} }{$testObject->preTestActionLiteral()}  eq $testAction ) {
                    unshift @preTest_testConditionObjects, $testConditionObject ;
                }
#                if ( $test ."_". $testObject->postTestActionLiteral()   eq $testAction ) {
                if ( $$res{ACTIONS}{ $testActionLinkage{$testActionBase} }{$testObject->postTestActionLiteral()}  eq $testAction ) {
                    unshift @postTest_testConditionObjects, $testConditionObject ;
                }

            }
            $testObject->preTest_conditions(\@preTest_testConditionObjects) ;           
            $testObject->test_conditions(\@test_testConditionObjects) ;           
            $testObject->postTest_conditions(\@postTest_testConditionObjects) ;           

        }
#warn Dumper $testObject ;
        unshift @testObjects, $testObject ;
    } 

    $testSet->tests(\@testObjects) ;
#    $testSet->actions(\%testSetActions) ;
#print Dumper $testSet ;
    return $testSet ;

}



sub deparse {
    my $self    = shift or croak 'no self' ;
    my $testSet = shift or croak 'no test' ;
    my $ast     = $testSet->AST() ;

#print Dumper $ast ;

#print Dumper keys %$ast;
#print Dumper $$ast{INITIALIZECONDITIONS} ;
#print Dumper $$ast{CLEANUPCONDITIONS} ;
#exit ;

    return $self->Header($$ast{HEAD}{NAMESPACE},$$ast{HEAD}{CLASSNAME}) .
           $self->Tests($$ast{BODY}) .
           $self->icHeader() . 
           $self->icResourceModel($testSet) .
           $self->icDeclareTestActions($testSet) .
           $self->icDeclareTestConditions($testSet) .
           $self->icInitialiseTestActionData($testSet) .
           $self->icInitialiseTestActions($testSet) .
           $self->icInitialiseTestConditions($testSet) .
           $self->icAssignTestActions($testSet) .
           $self->icAddTestActionConditions($testSet) .
           $self->icDefineTestConditions($testSet) .
           $self->icDefineTestInitialiseCleanupActions($testSet) .
           $self->icFooter() .
           $self->Footer($$ast{BODY}) ;

}


sub icDefineTestInitialiseCleanupActions {

    local $_        = undef;
    my $self        = shift or croak 'no self' ;
    my $testSet     = shift or croak 'no testSet' ;
    my $ra_tests    = $testSet->tests() ; 
    my @tests       = @$ra_tests;

    my $p3 = '            ';
    my $res = "" ;

    if ( $testSet->initializeAction() or $testSet->cleanupAction() ) {
        $res .= $testSet->commentifyClassName($self->quoteChars());
        if ( $testSet->initializeAction() ) {
            $res .= "${p3}" . $self->selfKeyWord() . ".TestInitializeAction = " . $testSet->initializeAction()  . $self->lineTerminator() . "\n" ;
        }
        if ( $testSet->cleanupAction()  ) {
            $res .= "${p3}" . $self->selfKeyWord() . ".TestCleanupAction = " . $testSet->cleanupAction()  . $self->lineTerminator() . "\n" ;
        }
    }

    return $res;
}


sub icInitialiseTestActionData {
    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $testSet                 = shift or croak 'no testSet';
    my $ra_tests                = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests                   = @$ra_tests;
    my $ra_cleanupConditions    = $testSet->cleanupConditions();
    my $ra_initializeConditions = $testSet->initializeConditions();
    my @cleanupConditions       = @{$ra_cleanupConditions} ;
    my @initializeConditions    = @{$ra_initializeConditions} ;

    my $p3 = '            ';
    my $res = "" ;


    foreach my $test (@tests) {
        $res .= "${p3}" . $self->selfKeyWord() . "." . $test->testActionDataName() . " = " . $self->newKeyWord() . " Microsoft.Data.Schema.UnitTesting.DatabaseTestActions" . $self->functionDelimiters() . $self->lineTerminator() . "\n";
    }
    
    return $res ;
}


sub icDefineTestConditions {

    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $testSet                 = shift or croak 'no testSet';
    my $ra_tests                = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests                   = @$ra_tests;
    my $ra_cleanupConditions    = $testSet->cleanupConditions();
    my $ra_initializeConditions = $testSet->initializeConditions();
    my @cleanupConditions       = @{$ra_cleanupConditions} ;
    my @initializeConditions    = @{$ra_initializeConditions} ;

    my $p3 = '            ';
    my $res = "" ;


    foreach my $condition (@initializeConditions, @cleanupConditions ) {

    $res .=  $condition->commentifyName($self->quoteChars());

#warn "\n";

    foreach my $conditionAttribute ( grep { $_ ne 'conditionTestActionName' } @{[$condition->testConditionAttributes()]} ) {
        my $conditionAttributeName = $condition->testConditionAttributeName(${conditionAttribute});
#warn Dumper $conditionAttributeName;       
#warn Dumper $condition->$conditionAttribute();     
#This needs some heavy method subtyping now.................

        if ( $condition->testConditionAttributeType(${conditionAttribute}) ne 'literalcode' ) {
            $res .=  "${p3}" . $condition->conditionName() . ".${conditionAttributeName}" . " = " 
            . ( ( $condition->testConditionAttributeType(${conditionAttribute}) eq 'quoted' ) ? '"' : '' )
            . $self->convertKeyWord($condition->$conditionAttribute() )
            . ( ( $condition->testConditionAttributeType(${conditionAttribute}) eq 'quoted' ) ? '"' : '' )
            . "" . $self->lineTerminator() . "\n" ;     
        } 
        else {
            $res .=  "${p3}" . $self->convertKeyWord($condition->$conditionAttribute() ) 
            . "" . $self->lineTerminator() . "\n" ;     
        }
        
        }
    }


    foreach my $test (@tests) {

#warn "\n\n";
        my $ra_conditions = $test->conditions() ;
        foreach my $condition (@$ra_conditions) {

        $res .=  $condition->commentifyName($self->quoteChars());

#warn "\n";

        foreach my $conditionAttribute ( grep { $_ ne 'conditionTestActionName' } @{[$condition->testConditionAttributes()]} ) {
            my $conditionAttributeName = $condition->testConditionAttributeName(${conditionAttribute});
#warn Dumper $conditionAttributeName;       
#warn Dumper $condition->$conditionAttribute();     

#This needs some heavy method subtyping now.................

            if ( $condition->testConditionAttributeType(${conditionAttribute}) ne 'literalcode' ) {
                $res .=  "${p3}" . $condition->conditionName() . ".${conditionAttributeName}" . " = " 
                . ( ( $condition->testConditionAttributeType(${conditionAttribute}) eq 'quoted' ) ? '"' : '' )
                . $self->convertKeyWord($condition->$conditionAttribute() )
                . ( ( $condition->testConditionAttributeType(${conditionAttribute}) eq 'quoted' ) ? '"' : '' )
                . "" . $self->lineTerminator() . "\n" ;     
            } 
            else {
                $res .=  "${p3}" . $self->convertKeyWord($condition->$conditionAttribute() ) 
                . "" . $self->lineTerminator() . "\n" ;     
            }

            }
        }
    }

    return $res;
}


sub icInitialiseTestConditions {

    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $testSet                 = shift or croak 'no testSet';
    my $ra_tests                = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests                   = @$ra_tests;

    my $ra_cleanupConditions    = $testSet->cleanupConditions();
    my $ra_initializeConditions = $testSet->initializeConditions();
    my @cleanupConditions       = @{$ra_cleanupConditions} ;
    my @initializeConditions    = @{$ra_initializeConditions} ;

    my $p3 = '            ';
    my $res = "" ;


    foreach my $condition (@initializeConditions, @cleanupConditions ) {
        $res .=  "${p3}" . $condition->conditionName() . " = " . $self->newKeyWord() . " Microsoft.Data.Schema.UnitTesting.Conditions.". $condition->testConditionMSType() . $self->functionDelimiters() . $self->lineTerminator() . "\n";
    }


    foreach my $test (@tests) {
        my $ra_conditions = $test->conditions() ;
        foreach my $condition (@$ra_conditions) {
            $res .=  "${p3}" . $condition->conditionName() . " = " . $self->newKeyWord() . " Microsoft.Data.Schema.UnitTesting.Conditions.". $condition->testConditionMSType() . $self->functionDelimiters() . $self->lineTerminator() . "\n";
        }

    }


    return $res;
}

sub icDeclareTestConditions {

    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $testSet                 = shift or croak 'no testSet';
    my $ra_tests                = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests                   = @$ra_tests;
    my $ra_cleanupConditions    = $testSet->cleanupConditions();
    my $ra_initializeConditions = $testSet->initializeConditions();
#print Dumper $testSet; 
#print Dumper $ra_initializeConditions;
#print Dumper $ra_cleanupConditions;
    my @cleanupConditions       = @{$ra_cleanupConditions} ;
    my @initializeConditions    = @{$ra_initializeConditions} ;

    my $p3 = '            ';
    my $res = "" ;


    foreach my $condition (@initializeConditions, @cleanupConditions ) {
#       $res .=  "${p3}Microsoft.Data.Schema.UnitTesting.Conditions.". $condition->testConditionMSType() . " " . $condition->conditionName() . $self->lineTerminator() . "\n";
        $res .=  "${p3}" . $self->declareVariable( "Microsoft.Data.Schema.UnitTesting.Conditions.". $condition->testConditionMSType()
                                                 , $condition->conditionName()
                                                 ) . $self->lineTerminator() . "\n";
    }
    foreach my $test (@tests) {
        my $ra_conditions = $test->conditions() ;
#warn Dumper $ra_conditions ;        
        foreach my $condition (@$ra_conditions) {
#warn Dumper $condition ;        
#           $res .=  "${p3}Microsoft.Data.Schema.UnitTesting.Conditions.". $condition->testConditionMSType() . " " . $condition->conditionName() . $self->lineTerminator() . "\n";
            $res .=  "${p3}" . $self->declareVariable( "Microsoft.Data.Schema.UnitTesting.Conditions.". $condition->testConditionMSType()
                                                     , $condition->conditionName()
                                                     ) . $self->lineTerminator() . "\n";
        }
    }

    return $res;
}


sub icDeclareTestActions {

    local $_        = undef;
    my $self        = shift or croak 'no self' ;
    my $testSet     = shift or croak 'no testSet';
    my $ra_tests    = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests       = @$ra_tests;

    my $p3 = '            ';
    my $res = "" ;


    if ( $testSet->initializeAction()  ) {
        $res .= "${p3}" . $self->declareVariable("Microsoft.Data.Schema.UnitTesting.DatabaseTestAction", $testSet->initializeAction()) . $self->lineTerminator() . "\n" ;
    }
    if ( $testSet->cleanupAction() ) {
        $res .= "${p3}". $self->declareVariable("Microsoft.Data.Schema.UnitTesting.DatabaseTestAction", $testSet->cleanupAction())  . $self->lineTerminator() . "\n" ;
    }

    foreach my $test (@tests) {
        if ( defined $test->preTestAction() and $test->preTestAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $self->declareVariable("Microsoft.Data.Schema.UnitTesting.DatabaseTestAction", $test->preTestAction()) . $self->lineTerminator() . "\n" ;
        }
        if ( defined $test->testAction() and $test->testAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $self->declareVariable("Microsoft.Data.Schema.UnitTesting.DatabaseTestAction", $test->testAction()) . $self->lineTerminator() . "\n" ;
        }
        if ( defined $test->postTestAction() and $test->postTestAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $self->declareVariable("Microsoft.Data.Schema.UnitTesting.DatabaseTestAction", $test->postTestAction()) . $self->lineTerminator() . "\n" ;
        }
    }

    return $res;
}


sub icInitialiseTestActions {

    local $_    = undef;
    my $self    = shift or croak 'no self' ;
    my $testSet = shift or croak 'no testSet' ;
    my $ra_tests    = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests       = @$ra_tests;

    my $p3 = '            ';
    my $res = "" ;


    if ( $testSet->initializeAction()  ) {
        $res .= "${p3}".$testSet->initializeAction()  . " = " . $self->newKeyWord() . " Microsoft.Data.Schema.UnitTesting.DatabaseTestAction" . $self->functionDelimiters() . $self->lineTerminator() . "\n" ;
    }
    if ($testSet->cleanupAction() ) {
        $res .= "${p3}".$testSet->cleanupAction()  . " = " . $self->newKeyWord() . " Microsoft.Data.Schema.UnitTesting.DatabaseTestAction" . $self->functionDelimiters() . $self->lineTerminator() . "\n" ;
    }

    foreach my $test (@tests) {

        if ( defined $test->preTestAction() and $test->preTestAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $test->preTestAction() . " = " . $self->newKeyWord() . " Microsoft.Data.Schema.UnitTesting.DatabaseTestAction" . $self->functionDelimiters() . $self->lineTerminator() . "\n" ;
        }
        if ( defined $test->testAction() and $test->testAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $test->testAction() . " = " . $self->newKeyWord() . " Microsoft.Data.Schema.UnitTesting.DatabaseTestAction" . $self->functionDelimiters() . $self->lineTerminator() . "\n" ;
        }
        if ( defined $test->postTestAction() and $test->postTestAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $test->postTestAction() . " = " . $self->newKeyWord() . " Microsoft.Data.Schema.UnitTesting.DatabaseTestAction" . $self->functionDelimiters() . $self->lineTerminator() . "\n" ;
        }
    
    }

    return $res;
}


sub icAssignTestActions {

    local $_        = undef;
    my $self        = shift or croak 'no self' ;
    my $testSet     = shift or croak 'no testSet';
    my $ra_tests    = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests       = @$ra_tests;

    my $p3 = '            ';
    my $res = "" ;

    foreach my $test (@tests) {

        $res .= $test->commentifyActionDataName($self->quoteChars());
        if ( defined $test->preTestAction() and $test->preTestAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $self->selfKeyWord() . "." . $test->testActionDataName() . "." . $test->preTestActionLiteral() . " = " . $test->preTestAction(). "" . $self->lineTerminator() . "\n" ;
        }
        else {
            $res .= "${p3}" . $self->selfKeyWord() . "." . $test->testActionDataName() . "." . $test->preTestActionLiteral() . " = " . $self->null() . "" . $self->lineTerminator() . "\n" ;
        }
        if ( defined $test->testAction() and $test->testAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $self->selfKeyWord() . "." . $test->testActionDataName() . "." . $test->testActionLiteral() . " = " . $test->testAction(). "" . $self->lineTerminator() . "\n" ;
        }
        else {
            $res .= "${p3}" . $self->selfKeyWord() . "." . $test->testActionDataName() . "." . $test->testActionLiteral() . " = " . $self->null() . "" . $self->lineTerminator() . "\n" ;
        }
        if ( defined $test->postTestAction() and $test->postTestAction() !~ m{^null|nothing$}ix) {
            $res .= "${p3}" . $self->selfKeyWord() . "." . $test->testActionDataName() . "." . $test->postTestActionLiteral() . " = " . $test->postTestAction(). "" . $self->lineTerminator() . "\n" ;
        }
        else {
            $res .= "${p3}" . $self->selfKeyWord() . "." . $test->testActionDataName() . "." . $test->postTestActionLiteral() . " = " . $self->null() . "" . $self->lineTerminator() . "\n" ;
        }

    }

    return $res;
}

sub icAddTestActionConditions {

    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $testSet                 = shift or croak 'no testSet' ;
    my $ra_tests                = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests                   = @$ra_tests;
    my $ra_cleanupConditions    = $testSet->cleanupConditions();
    my $ra_initializeConditions = $testSet->initializeConditions();
    my @cleanupConditions       = @{$ra_cleanupConditions} ;
    my @initializeConditions    = @{$ra_initializeConditions} ;

    my $p3 = '            ';
    my $res = "" ;



    my $rh_actions = $testSet->actions();
    my %actions    = %{$rh_actions} ;
#    my %Usedactions = ();


    if ($testSet->initializeAction() ) {
        $res .=  $testSet->commentifyInitializeAction($self->quoteChars()) ;
        foreach my $condition (@initializeConditions) {
            $res .=  "${p3}".$condition->testAction(). ".Conditions.Add(".$condition->conditionName() . ")" . $self->lineTerminator() . "\n" ;
        }
        $res .=  "${p3}resources.ApplyResources(" . $testSet->initializeAction() . ', "'.$testSet->initializeAction() . '")' . $self->lineTerminator() ."\n";
#        $Usedactions{$testSet->initializeAction()}{PROCESSED} = 1;
    }
    if ($testSet->cleanupAction() ) {
        $res .=  $testSet->commentifyCleanupAction($self->quoteChars()) ;
        foreach my $condition (@cleanupConditions ) {
            $res .=  "${p3}".$condition->testAction(). ".Conditions.Add(".$condition->conditionName() . ")" . $self->lineTerminator() ."\n" ;
        }
        $res .=  "${p3}resources.ApplyResources(" . $testSet->cleanupAction() . ', "'.$testSet->cleanupAction() . '")'. $self->lineTerminator() ."\n";
#        $Usedactions{$testSet->cleanupAction()}{PROCESSED} = 1;
    }


    foreach my $test (@tests) {
    
        if ( $test->preTestAction() !~ m{^null|nothing$}ix ) { 
            $res .=  $test->commentifyPreTestAction($self->quoteChars()); 
            my $conditions = $test->preTest_conditions() ;
            foreach my $condition (@$conditions) {
                $res .=  "${p3}".$condition->testAction(). ".Conditions.Add(".$condition->conditionName() . ")" . $self->lineTerminator(). "\n" ;
            }
            $res .=  "${p3}resources.ApplyResources(" . $test->preTestAction() . ', "'.$test->preTestAction() . '")'. $self->lineTerminator() ."\n"; 
#            $Usedactions{$test->preTestAction()}{PROCESSED} = 1;
        }

        if ( $test->testAction() !~ m{^null|nothing$}ix ) { 
            $res .=  $test->commentifyTestAction($self->quoteChars()); 
            my $conditions = $test->test_conditions() ;
            foreach my $condition (@$conditions) {
                $res .=  "${p3}".$condition->testAction(). ".Conditions.Add(".$condition->conditionName(). ")" . $self->lineTerminator(). "\n" ;
            }
            $res .=  "${p3}resources.ApplyResources(" . $test->testAction() . ', "'.$test->testAction() . '")' . $self->lineTerminator() ."\n"; 
#            $Usedactions{$test->testAction()}{PROCESSED} = 1;
        }
        if ( $test->postTestAction() !~ m{^null|nothing$}ix ) { 
            $res .=  $test->commentifyPostTestAction($self->quoteChars()); 
            my $conditions = $test->postTest_conditions() ;
            foreach my $condition (@$conditions) {
                $res .=  "${p3}".$condition->testAction(). ".Conditions.Add(".$condition->conditionName(). ")" . $self->lineTerminator() . "\n" ;
            }
            $res .=  "${p3}resources.ApplyResources(" . $test->postTestAction() . ', "'.$test->postTestAction() . '")' . $self->lineTerminator() ."\n"; 
#            $Usedactions{$test->postTestAction()}{PROCESSED} = 1;
        }
    }
    
#    foreach my $action ( keys %actions ) {
#        if ( not defined ($Usedactions{$action}{PROCESSED})) {
#            $res .=  $testSet->commentifyAny($self->quoteChars(),$action);
#            $res .=  "${p3}resources.ApplyResources(" . $action . ', "'.$action . '")' . $self->lineTerminator() ."\n";
#        }
#    }

    return $res;
}


sub icResourceModel {

    local $_ = undef;
    my $self        = shift or croak 'no self' ;
#    my $Class       = shift or croak 'no class' ;
    my $testSet     = shift or croak 'no test set' ;
    my $Class       = $testSet->className();

    my $p3 = '            ';
    my $res = "" ;

    my $ra_tests                = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests                   = @$ra_tests;

# only output this if we have test action that needs resources creating
# horrible code esp :-
#              $testSet->initializeAction() ne '' or $testSet->cleanupAction() ne '' 

    foreach my $test (@tests) {
        if ( $test->testAction() !~ m{^null|nothing$}ix or $test->preTestAction() !~ m{^null|nothing$}ix or $test->postTestAction() !~ m{^null|nothing$}ix or
             defined $testSet->initializeAction() or defined $testSet->cleanupAction()  
           ) { 
            $res =  "${p3}" . $self->declareAndCreateVariable( 'System.ComponentModel.ComponentResourceManager'
                                                      , 'resources'
                                                      , "System.ComponentModel.ComponentResourceManager(@{[$self->typeExtractor()]}(${Class}))"
                                                      ) . $self->lineTerminator() . "\n";
        }
    }
    
    return $res ;

}



1;


###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################
###########################################################

__DATA__


