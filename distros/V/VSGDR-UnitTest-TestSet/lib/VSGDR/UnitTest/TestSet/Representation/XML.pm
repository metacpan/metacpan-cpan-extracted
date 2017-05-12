package VSGDR::UnitTest::TestSet::Representation::XML;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.01';


#TODO 1. Add support for test method attributes eg new vs2010 exceptions  ala : -[ExpectedSqlException(MessageNumber = nnnnn, Severity = x, MatchFirstError = false, State = y)]

use parent qw(VSGDR::UnitTest::TestSet::Representation) ;

use English;
use XML::Simple;

use VSGDR::UnitTest::TestSet;
use VSGDR::UnitTest::TestSet::Test;

use Data::Dumper ;
use Carp ;


use vars qw($AUTOLOAD );



sub _init {

    local $_ = undef ;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    my $ref                 = shift or croak "no arg";


    my ${Caller}            = $$ref{NAMESPACE};
    
    return ;
    
}

## ======================================================

sub parse {

    my $self    = shift or croak 'no self' ;
    my $code    = shift or croak 'no code' ;
    
    my $ref = XMLin($code);

    my %testSetActions ;
#warn Dumper $ref ;
#exit;
    my @testConditions ;

    my %Globals = map { $$ref{TestGlobals}{$_}      =~ s/^\s*(.*?)\s*$/$1/x;
                        { uc($_) => $$ref{TestGlobals}{$_}
                      }
                    } 
        keys %{$$ref{TestGlobals}} ;
    
#print Dumper %Globals ;
#exit;
    my $testSet = VSGDR::UnitTest::TestSet->new( { NAMESPACE           => $Globals{TESTNAMESPACE}
                                                    , CLASSNAME         => $Globals{TESTCLASS}
                                                  } 
                                                ) ;
#print Dumper $testSet ;
#exit;
    my $ra_testGlobalConditions         = () ;
    
#print Dumper $$ref{TestGlobalConditions} ;
#exit;

#    {TestGlobalConditions}{TestInitializeConditions}
#    {TestGlobalConditions}{TestCleanupConditions}

    if ( defined ($$ref{TestGlobalConditions}) 
         and defined ($$ref{TestGlobalConditions}{TestInitializeAction})
       ) {
            $testSet->initializeAction('testInitializeAction') ;
            $testSetActions{'testInitializeAction'} = 1 ;
         }
    if ( defined ($$ref{TestGlobalConditions}) 
         and defined ($$ref{TestGlobalConditions}{TestInitializeConditions})
         and defined ($$ref{TestGlobalConditions}{TestInitializeConditions}{TestInitializeCondition})
       ) {
            $testSet->initializeAction('testInitializeAction') ;
            $testSetActions{'testInitializeAction'} = 1 ;
            my $condition = $$ref{TestGlobalConditions}{TestInitializeConditions}{TestInitializeCondition} ;         
#print Dumper $condition ;          
            $ra_testGlobalConditions =  $self->gatherTestSetConditions($condition) ;
#print Dumper @testGlobalConditions ;           
            $testSet->initializeConditions($ra_testGlobalConditions);        
         }
     else {
            $testSet->initializeConditions([]);      
     }

    if ( defined ($$ref{TestGlobalConditions}) 
         and defined ($$ref{TestGlobalConditions}{TestCleanupAction})
       ) {
            $testSet->cleanupAction('testCleanupAction') ;
            $testSetActions{'testTestCleanup'} = 1 ;
         }
    if ( defined ($$ref{TestGlobalConditions}) 
         and defined ($$ref{TestGlobalConditions}{TestCleanupConditions})
         and defined ($$ref{TestGlobalConditions}{TestCleanupConditions}{TestCleanupCondition})
       ) {
            $testSet->cleanupAction('testCleanupAction') ;
            $testSetActions{'testCleanupAction'} = 1 ;
            my $condition = $$ref{TestGlobalConditions}{TestCleanupConditions}{TestCleanupCondition} ;       
#print Dumper $condition ;          
            $ra_testGlobalConditions =  $self->gatherTestSetConditions($condition) ;
#print Dumper @testGlobalConditions ;           
            $testSet->cleanupConditions($ra_testGlobalConditions);       
         }
     else {
            $testSet->cleanupConditions([]);         
     }
    
#############################################

    my @testObjects = () ;

    if ( ref($$ref{Tests}{Test}) eq 'HASH' ) {
        my $test = $$ref{Tests}{Test} ;
        my $testObject = $self->createTest($test,\%testSetActions)  ;
        push @testObjects, $testObject ;
    }
    elsif ( ref($$ref{Tests}{Test}) eq 'ARRAY' ) {
        foreach my $test (@{$$ref{Tests}{Test}}) {
            my $testObject = $self->createTest($test,\%testSetActions)  ;
            push @testObjects, $testObject ;
        } 
    }
#print Dumper $testSet; 
    $testSet->tests(\@testObjects) ; 
#   $testSet->actions({}) ;
#    $testSet->actions(\%testSetActions) ;
#print Dumper $testSet ;    
    return $testSet;
}

sub createTest {
    local $_            = undef ;
    my $self            = shift or croak 'no self' ;
    my $test            = shift or croak 'no test arg' ;
    my $rh_testSetActions = shift or croak 'no test set actions' ;

    ( my $testName          = $$test{TestName} ) =~ s/^\s*(.*?)\s*$/$1/x;
    ( my $testActions       = $$test{TestActions} ) ;
    ( my $testActionData    = $$test{TestActions}{TestActionData} ) ;

    ( my $preTestConditions = $$test{TestActions}{TestActionData}{PretestConditions}{TestCondition} ) ;
    ( my $testConditions    = $$test{TestActions}{TestActionData}{TestConditions}{TestCondition} ) ;
    ( my $postTestConditions= $$test{TestActions}{TestActionData}{PosttestConditions}{TestCondition} ) ;


    my ${TestActionDataName}    = $$testActionData{TestActionDataName};
    my ${PreTestAction}         = $$testActionData{PretestAction};
    my ${TestAction}            = $$testActionData{TestAction};
    my ${PostTestAction}        = $$testActionData{PosttestAction};

    my $testObject = VSGDR::UnitTest::TestSet::Test->new( { TESTNAME                => $testName 
                                                             , TESTACTIONDATANAME    =>  ${TestActionDataName}  
                                                             , PRETESTACTION         =>  ${PreTestAction}           
                                                             , TESTACTION            =>  ${TestAction}          
                                                             , POSTTESTACTION        =>  ${PostTestAction}      
                                                           } ) ;

    my @preTestConditions  = $self->gatherConditions(${preTestConditions})  ;
    my @testConditions     = $self->gatherConditions(${testConditions})  ;
    my @postTestConditions = $self->gatherConditions(${postTestConditions})  ;

    my @Conditions = flatten ([@preTestConditions,@testConditions,@postTestConditions]);
#    $testObject->conditions( \@Conditions ) ;

    $testObject->preTest_conditions( \@preTestConditions ) ;
    $testObject->test_conditions( \@testConditions ) ;
    $testObject->postTest_conditions( \@postTestConditions ) ;

    if ( scalar(@preTestConditions))  { $$rh_testSetActions{$testObject->testName() . "_PretestAction"} = 1 ; } ;
    if ( scalar(@testConditions))     { $$rh_testSetActions{$testObject->testName() . "_TestAction"} = 1 ; } ;
    if ( scalar(@postTestConditions)) { $$rh_testSetActions{$testObject->testName() . "_PosttestAction"} = 1 ; } ;

    return $testObject ;
    
}


sub gatherTestSetConditions {

    my $self            = shift or croak 'no self' ;
    my $testConditions  = shift or croak 'no conditions' ;
#print Dumper $testConditions ;

    my @testGlobalConditions    = () ;


    if ( ref( $testConditions ) eq 'HASH' )  {
        my $testCondition = $testConditions ;
        return (\@testGlobalConditions) if not exists $$testCondition{TestConditionType};

        my $testConditionObject = $self->createTestCondition($testCondition) ;
        push @testGlobalConditions, $testConditionObject ;  

    }
    elsif ( ref($testConditions) eq 'ARRAY' )  {
        return (\@testGlobalConditions) if scalar(@$testConditions) == 0 ;

        foreach my $testCondition (@$testConditions) {
            my $testConditionObject = $self->createTestCondition($testCondition) ;
            push @testGlobalConditions, $testConditionObject ;  

        }
    }

    return (\@testGlobalConditions) ;
}



sub createTestCondition {

    local $_            = undef ;
    my $self            = shift or croak 'no self' ;
    my $testCondition            = shift or croak 'no test condition' ;

    ( my $testconditiontype = $$testCondition{TestConditionType} ) =~ s{^\s*(.*?)\s*$}{$1}x;

    my @other_keys = grep {$_ ne 'TestConditionType'  } keys %{$testCondition} ;
    my %constructor = map { ( my $key = uc($_) ) =~ s{TEST}{}x; 
                            ( my $val = $$testCondition{$_} ) =~ s{^\s*(.*?)\s*$}{$1}x;
                            $key => $val ;
                        } 
        @other_keys ;
    $constructor{TESTCONDITIONTYPE}  = $testconditiontype ;
    my $testConditionObject = VSGDR::UnitTest::TestSet::Test::TestCondition->make(\%constructor) ;

    return $testConditionObject ;

}


sub gatherConditions {
    my $self            = shift or croak 'no self' ;
    my $testConditions  = shift ;
    my @resultTestConditions = () ;

    return @resultTestConditions unless defined $testConditions ;

    if ( ref( $testConditions ) eq 'HASH' )  {
        my $testCondition = $testConditions ;
        my $testConditionObject = $self->createTestCondition($testCondition) ;
        push @resultTestConditions, $testConditionObject ;
    }
    elsif ( ref($testConditions) eq 'ARRAY' )  {
        foreach my $testCondition (@$testConditions) {
            my $testConditionObject = $self->createTestCondition($testCondition) ;
            push @resultTestConditions, $testConditionObject ;
        }
    }
    return @resultTestConditions ;
}


sub representationType {
    my $self    = shift;
    return 'XML' ;
}

sub deparse {
    my $self    = shift or croak 'no self' ;
    my $testSet = shift or croak 'no test' ;

    my $p1 = '    ';
    my $p2 = '        ';
    my $p3 = '            ';
    my $p4 = '                ';

#warn Dumper $testSet;
#print Dumper $ast ;
#print Dumper keys %$ast;
#exit ;

    return $self->xmlHeader() .
           $self->xmlGlobals($testSet) .
           "${p1}<TestGlobalConditions>\n" .
           $self->xmlGlobalConditions($testSet) .
           "${p1}</TestGlobalConditions>\n" .
           $self->xmlTests($testSet) .
           $self->xmlFooter() ;

}


sub xmlHeader {
    my $self        = shift or croak 'no self' ;
return <<"EOH";
<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<ROOT xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
EOH
}

sub xmlFooter {
    my $self        = shift or croak 'no self' ;
return <<"EOF";
</ROOT>
EOF
}

sub xmlGlobals {
    my $self        = shift or croak 'no self' ;
    my $testSet     = shift or croak 'no testSet' ;


    my $p1 = '    ';
    my $p2 = '        ';

    return "${p1}<TestGlobals>\n" .
           "${p2}<TestNameSpace>" .         $testSet->nameSpace()               ."</TestNameSpace>\n" .
           "${p2}<TestClass>".              $testSet->className()               ."</TestClass>\n" . 
           "${p2}<TestInitializeAction>".   $testSet->initializeActionLiteral() ."</TestInitializeAction>\n" .  
           "${p2}<TestCleanupAction>".      $testSet->cleanupActionLiteral()    ."</TestCleanupAction>\n" .
           "${p1}</TestGlobals>\n" ;
}


sub xmlGlobalConditions {
    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $testSet                 = shift or croak 'no testSet' ;
    my $ra_tests                = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests                   = @$ra_tests;
    my $ra_cleanupConditions    = $testSet->cleanupConditions();
    my $ra_initializeConditions = $testSet->initializeConditions();
    my @cleanupConditions       = @{$ra_cleanupConditions} ;
    my @initializeConditions    = @{$ra_initializeConditions} ;
#warn Dumper $testSet ;
    my $res = "" ;
              
    my $p1 = '    ';
    my $p2 = '        ';
    my $p3 = '            ';
    my $p4 = '                ';
    my $p5 = '                    ';
    my $p6 = '                        ';
    my $p7 = '                            ';
    my $p8 = '                                ';
    my $p9 = '                                    ';


    if ($testSet->initializeAction() ) {
        $res .= "${p2}<TestInitializeAction>".   $testSet->initializeAction()  ."</TestInitializeAction>\n" ;
        $res .= "${p3}<TestInitializeConditions>\n" ;
        foreach my $condition (@initializeConditions) {
            $res .= "${p4}<TestInitializeCondition>\n" ;
            $res .= "${p5}<TestConditionType>" . $condition->testConditionType() . "</TestConditionType>\n" ;
            foreach my $attr ($condition->testConditionAttributes()) {
                ( my $UC_attr = $attr ) =~ s{^(.)}{\U${1}}x;
                $UC_attr = 'Test' . $UC_attr if $UC_attr !~ m{^Test}ix ;
                $res .= "${p5}<${UC_attr}>" . $condition->${attr}() . "</${UC_attr}>\n" ;
            }
            $res .= "${p4}</TestInitializeCondition>\n" ;
        }
        $res .= "${p3}</TestInitializeConditions>\n" ;
    }
    if ($testSet->cleanupAction() ) {
       $res .=  "${p2}<TestCleanupAction>".         $testSet->cleanupAction()     ."</TestCleanupAction>\n" ;
        $res .= "${p3}<TestCleanupConditions>\n" ;
        foreach my $condition (@cleanupConditions ) {
            $res .= "${p4}<TestCleanupCondition>\n" ;
            $res .= "${p5}<TestConditionType>" . $condition->testConditionType() . "</TestConditionType>\n" ;
            foreach my $attr ($condition->testConditionAttributes()) {
                ( my $UC_attr = $attr ) =~ s{^(.)}{\U${1}}x;
                $UC_attr = 'Test' . $UC_attr if $UC_attr !~ m{^Test}ix ;
                $res .= "${p5}<${UC_attr}>" . $condition->${attr}() . "</${UC_attr}>\n" ;
            }
            $res .= "${p4}</TestCleanupCondition>\n" ;
        }
        $res .= "${p3}</TestCleanupConditions>\n" ;
    }

    return $res;

}

sub xmlTests {

    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $testSet                 = shift or croak 'no testSet' ;
    my $ra_tests                = $testSet->tests() ; #@{$$ast{BODY}} ;
    my @tests                   = @$ra_tests;
    my $ra_cleanupConditions    = $testSet->cleanupConditions();
    my $ra_initializeConditions = $testSet->initializeConditions();
    my @cleanupConditions       = @{$ra_cleanupConditions} ;
    my @initializeConditions    = @{$ra_initializeConditions} ;

    my $p1 = '    ';
    my $p2 = '        ';
    my $p3 = '            ';
    my $p4 = '                ';
    my $p5 = '                    ';
    my $p6 = '                        ';
    my $p7 = '                            ';
    my $p8 = '                                ';
    my $p9 = '                                    ';

    my $res = "${p1}<Tests>\n" ;

    my $rh_actions = $testSet->actions();
    my %actions    = %{$rh_actions} ;
    my %Usedactions = ();

    foreach my $test (@tests) {

        $res .= "${p3}<Test>\n" ;
        $res .= "${p4}<TestName>".$test->testName()."</TestName>\n" ;
        $res .= "${p4}<TestActions>\n" ;
        $res .= "${p5}<TestActionData>\n" ;
        $res .= "${p6}<TestActionDataName>".$test->testActionDataName()."</TestActionDataName>\n" ;
        $res .= "${p6}<PretestAction>".$test->preTestAction()."</PretestAction>\n" ;
        $res .= "${p7}<PretestConditions>\n" ;

        if ( $test->preTestAction() !~ m{^null|nothing$}ix ) { 
            my $conditions = $test->preTest_conditions() ;
#print Dumper $conditions;            
            foreach my $condition (@$conditions) {
                $res .= "${p8}<TestCondition>\n" ;
                $res .= "${p9}<TestConditionType>" . $condition->testConditionType() . "</TestConditionType>\n" ;
                foreach my $attr ($condition->testConditionAttributes()) {
                    ( my $UC_attr = $attr ) =~ s{^(.)}{\U${1}}x;
                    $UC_attr = 'Test' . $UC_attr if $UC_attr !~ m{^Test}ix ;
                    $res .= "${p9}<${UC_attr}>" . $condition->${attr}() . "</${UC_attr}>\n" ;
                }
                $res .= "${p8}</TestCondition>\n" ;
            }
            $Usedactions{$test->preTestAction()}{PROCESSED} = 1;
        }
        $res .= "${p7}</PretestConditions>\n" ;

        $res .= "${p6}<TestAction>".$test->testAction()."</TestAction>\n" ;
        $res .= "${p7}<TestConditions>\n";
        if ( $test->testAction() !~ m{^null|nothing$}ix ) { 
            my $conditions = $test->test_conditions() ;
            foreach my $condition (@$conditions) {
                $res .= "${p8}<TestCondition>\n" ;
                $res .= "${p9}<TestConditionType>" . $condition->testConditionType() . "</TestConditionType>\n" ;
                foreach my $attr ($condition->testConditionAttributes()) {
                    ( my $UC_attr = $attr ) =~ s{^(.)}{\U${1}}x;
                    $UC_attr = 'Test' . $UC_attr if $UC_attr !~ m{^Test}ix ;
                    $res .= "${p9}<${UC_attr}>" . $condition->${attr}() . "</${UC_attr}>\n" ;
                }
                $res .= "${p8}</TestCondition>\n" ;
            }
            $Usedactions{$test->testAction()}{PROCESSED} = 1;
        }
        $res .= "${p7}</TestConditions>\n" ;

        $res .= "${p6}<PosttestAction>".$test->postTestAction()."</PosttestAction>\n" ;
        $res .= "${p7}<PosttestConditions>\n";
        if ( $test->postTestAction() !~ m{^null|nothing$}ix ) { 
            my $conditions = $test->postTest_conditions() ;
            foreach my $condition (@$conditions) {
                $res .= "${p8}<TestCondition>\n" ;
                $res .= "${p9}<TestConditionType>" . $condition->testConditionType() . "</TestConditionType>\n" ;
            
                foreach my $attr ($condition->testConditionAttributes()) {
                    ( my $UC_attr = $attr ) =~ s{^(.)}{\U${1}}x;
                    $UC_attr = 'Test' . $UC_attr if $UC_attr !~ m{^Test}ix ;
                    $res .= "${p9}<${UC_attr}>" . $condition->${attr}() . "</${UC_attr}>\n" ;
                }
                $res .= "${p8}</TestCondition>\n" ;
            }
            $Usedactions{$test->postTestAction()}{PROCESSED} = 1;
        }
        $res .= "${p7}</PosttestConditions>\n";
        $res .= "${p5}</TestActionData>\n" ;

        $res .= "${p4}</TestActions>\n" ;
        $res .= "${p3}</Test>\n" ;

    }   $res .= "${p1}</Tests>\n" ;

    return $res;
}


sub flatten { return map {@$_} @_ } ;

1 ;

__DATA__


