package VSGDR::UnitTest::TestSet::Representation::XLS;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.02';


use parent qw(VSGDR::UnitTest::TestSet::Representation) ;

#TODO 1. Add support for test method attributes eg new vs2010 exceptions  ala : -[ExpectedSqlException(MessageNumber = nnnnn, Severity = x, MatchFirstError = false, State = y)]


use English;
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel;
use List::MoreUtils qw/:all/;

use VSGDR::UnitTest::TestSet;
use VSGDR::UnitTest::TestSet::Test;

use Data::Dumper ;
use Carp ;


use vars qw($AUTOLOAD);


my  $test_No ;
#our $wks_test ;
my  $G_ln ;


sub _init {

    local $_ = undef ;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    my $ref                 = shift or croak "no arg";


    my ${Caller}            = $$ref{NAMESPACE};
    
    return ;
    
}

## ======================================================
## could alias this  *Here::blue = \$There::green;
##let's not - harder to understand and will alias other member of the typeglobs
sub serialise {
    my $self        = shift or croak 'no self' ;
    return $self->writeSpreadsheet(@_) ;
}
## ======================================================
sub deserialise {
    my $self        = shift or croak 'no self' ;
    return $self->readSpreadsheet(@_) ;
}
## ======================================================
# dummy implementations
## ======================================================
sub code {
    my $self        = shift or croak 'no self' ;
    carp 'Dummy method - may you want serialise';
    return "";
}
## ======================================================
sub parse {
    my $self        = shift or croak 'no self' ;
    carp 'Dummy method - may you want deserialise';
    return "";
}
## ======================================================

sub readSpreadsheet {

    my $self        = shift or croak 'no self' ;
    my $file        = shift or croak 'no file' ;
    
    my $parser      = Spreadsheet::ParseExcel->new();
    my $workbook    = $parser->Parse($file);    

    my $worksheet   = $workbook->worksheet('TestGlobals') or croak 'no TestGlobals worksheet' ;

    my %Globals     = ( TESTNAMESPACE   => $worksheet->get_cell(1,0)->value()
                      , TESTCLASS       => $worksheet->get_cell(1,1)->value()
                      ) ;

#warn Dumper %Globals ;
    
    my $testSet = VSGDR::UnitTest::TestSet->new( { NAMESPACE           => $Globals{TESTNAMESPACE}
                                                    , CLASSNAME         => $Globals{TESTCLASS}
                                                  } 
                                                ) ;


    my @header      = $testSet->allConditionAttributeNames() ;
    my %header_pos  = () ;
    for ( my $i = 0; $i <= $#header; $i++) { $header_pos{$header[$i]} = $i } ;

    $worksheet      = $workbook->worksheet('TestGlobalConditions') or croak 'no TestGlobalConditions worksheet' ;

#warn $worksheet->row_range() ;
    my ($row_min,$row_max)   = $worksheet->row_range();
    my $testInitialiseAction = defined $worksheet->get_cell(0,1) ? $worksheet->get_cell(0,1)->value() 
                              : undef ;

    my %testSetActions ;
    my @testConditions ;

    my $row = 1 ;
    if ($testInitialiseAction) {
        $testSetActions{'testInitializeAction'} = 1 ;
        $testSet->initializeAction('testInitializeAction') ;
        my $ra_testGlobalConditions    =  $self->gatherTestSetConditions($worksheet,'testInitializeAction',\@header,\%header_pos,$row,$row_max) ;
        $testSet->initializeConditions($ra_testGlobalConditions);        
    }
    else {
        $testSet->initializeConditions([]);      
    }

    my $testCleanupAction = undef ;
    for ( my $r = $row; $r <= $row_max; $r++ ) {
        if ( defined ($worksheet->get_cell($r,1)) and ($worksheet->get_cell($r,1)->value() eq 'testCleanupAction') ) {
            $testCleanupAction = 1 ;
            $row = $r+1 ;
            last ;
        }
    }
    
    if ($testCleanupAction) {
        $testSetActions{'testCleanupAction'} = 1 ;
        $testSet->cleanupAction('testCleanupAction') ;
        my $ra_testGlobalConditions    =  $self->gatherTestSetConditions($worksheet,'testCleanupAction',\@header,\%header_pos,$row,$row_max) ;
        $testSet->cleanupConditions($ra_testGlobalConditions);        
    }
    else {
        $testSet->cleanupConditions([]);      
    }

#    $testSet->tests([]);

    my  @testObjects = () ;
    
    for ( my $wi = 2 ; $wi < $workbook->worksheet_count() ; $wi++ ) {
        my $worksheet       = $workbook->worksheet($wi) ;
        my $testName        = $worksheet->get_cell(0,1)->value() ;

        my ($row_min,$row_max) = $worksheet->row_range();

        my %TA              = ( PretestAction  => 'null' 
                              , TestAction     => 'null' 
                              , PosttestAction => 'null' 
                              ) ;

        my @preTestConditions  = () ;
        my @testConditions     = () ;
        my @postTestConditions = () ;

        my $row = 1 ;
        
        my ($firstRow,$actionType) = $self->find_next_set($worksheet,$row,$row_max) ;
#warn Dumper ($firstRow,$actionType) ;        
        $row = $firstRow +1 ;
        $TA{$actionType}        = "${testName}_${actionType}" ;
        
        if ( ${actionType} eq 'PretestAction' ) { 
            @preTestConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
        } 
        if ( ${actionType} eq 'TestAction' ) { 
            @testConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
        } 
        if ( ${actionType} eq 'PosttestAction' ) { 
            @postTestConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
        } 

        ($firstRow,$actionType) = $self->find_next_set($worksheet,$row,$row_max) ;
        
        if ( defined $firstRow ) {
#warn Dumper ($firstRow,$actionType) ;        

            $row = $firstRow +1 ;
            $TA{$actionType}        = "${testName}_${actionType}" ;

            if ( ${actionType} eq 'PretestAction' ) { 
                @preTestConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
            } 
            if ( ${actionType} eq 'TestAction' ) { 
                @testConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
            } 
            if ( ${actionType} eq 'PosttestAction' ) { 
                @postTestConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
            } 
        } 
        ($firstRow,$actionType) = $self->find_next_set($worksheet,$row,$row_max) ;
        if ( defined $firstRow ) {
#warn Dumper ($firstRow,$actionType) ;        

            $row = $firstRow +1 ;
            $TA{$actionType}        = "${testName}_${actionType}" ;

            if ( ${actionType} eq 'PretestAction' ) { 
                @preTestConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
            } 
            if ( ${actionType} eq 'TestAction' ) { 
                @testConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
            } 
            if ( ${actionType} eq 'PosttestAction' ) { 
                @postTestConditions    =  $self->gatherConditions($worksheet,"${testName}_${actionType}",\@header,\%header_pos,$row,$row_max) ;
            } 
        } 

        my $testObject = VSGDR::UnitTest::TestSet::Test->new( { TESTNAME                => $testName 
                                                                 , TESTACTIONDATANAME    => "${testName}Data"
                                                                 , PRETESTACTION         => $TA{PretestAction}
                                                                 , TESTACTION            => $TA{TestAction}
                                                                 , POSTTESTACTION        => $TA{PosttestAction}
                                                               } ) ;
        
        $testObject->preTest_conditions( \@preTestConditions ) ;
        $testObject->test_conditions( \@testConditions ) ;
        $testObject->postTest_conditions( \@postTestConditions ) ;

        if ( scalar(@preTestConditions))  { $testSetActions{$testObject->testName() . "_PretestAction"} = 1 ; } ;
        if ( scalar(@testConditions))     { $testSetActions{$testObject->testName() . "_TestAction"} = 1 ; } ;
        if ( scalar(@postTestConditions)) { $testSetActions{$testObject->testName() . "_PosttestAction"} = 1 ; } ;

        push @testObjects, $testObject ;

    }


    $testSet->tests(\@testObjects) ; 
#    $testSet->actions(\%testSetActions) ;
#warn Dumper $testSet ;    
    return $testSet;
}


sub find_next_set {
    my $self            = shift or croak 'no self' ;
    my $wks             = shift or croak 'no worksheet' ;
    my $row             = shift or croak 'no start row' ;
    my $row_max         = shift or croak 'no max row' ;

    my $retRow = undef ;
    my $retVal = undef ;

    for (my $r = $row; $r <= $row_max; $r++) {
        if ( defined $wks->get_cell($r,1) and $wks->get_cell($r,1)->value() =~ m{^(?:Pre|Post|)TestAction}ix ) {
            $retRow = $r ;
            $retVal = $wks->get_cell($r,1)->value() ;
            last; 
        }
    }

    return ($retRow,$retVal) ;    
}

sub gatherTestSetConditions {

    my $self            = shift or croak 'no self' ;
    my $wks             = shift or croak 'no worksheet' ;
    my $testAction      = shift or croak 'no action';
    my $ra_header       = shift or croak 'no headers' ;
    my $rh_header_cols  = shift or croak 'no header cols' ;
    my $row             = shift or croak 'no start row' ;
    my $row_max         = shift or croak 'no max row' ;

    my @testGlobalConditions    = () ;

    my $TYPECOL = 2 ;
    for (my $r = $row; $r <= $row_max; $r++ ) {

        last if defined $wks->get_cell($r,0) ;
        last if ( defined $wks->get_cell($r,0) and $wks->get_cell($r,0)->value() ) ;

        last if not defined $wks->get_cell($r,$TYPECOL) ;
        last if ( defined $wks->get_cell($r,$TYPECOL) and $wks->get_cell($r,$TYPECOL)->value() eq '' ) ;

        my $testconditiontype   = $wks->get_cell($r,$TYPECOL)->value() ; 
        
        my @populatedColumns    = map { $_ - $TYPECOL } grep { defined $wks->get_cell($r,$_) and $wks->get_cell($r,$_)->value() ne '' } ( $TYPECOL+1 .. $TYPECOL + scalar(@{$ra_header}) ) ;
        my @populatedVals       = map { $wks->get_cell($r,$_ + $TYPECOL)->value() } @populatedColumns ;

        my @populatedColumnsHeaders     = map { $ra_header->[$_] } @populatedColumns ;
        my @populatedColumnsHeadersHASH = map { uc "CONDITION${_}" } @populatedColumnsHeaders ;

        my @constructor = zip( @populatedColumnsHeadersHASH,@populatedVals );
        my %constructor = @constructor ;

        $constructor{TESTCONDITIONTYPE}         = $testconditiontype ;
        $constructor{CONDITIONTESTACTIONNAME}   = $testAction ;        
        
        my $testConditionObject = VSGDR::UnitTest::TestSet::Test::TestCondition->make(\%constructor) ;
        push @testGlobalConditions, $testConditionObject ;  
    }

    return (\@testGlobalConditions) ;
}


sub gatherConditions {

    my $self            = shift or croak 'no self' ;
    my $wks             = shift or croak 'no worksheet' ;
    my $testAction      = shift or croak 'no action';
    my $ra_header       = shift or croak 'no headers' ;
    my $rh_header_cols  = shift or croak 'no header cols' ;
    my $row             = shift or croak 'no start row' ;
    my $row_max         = shift or croak 'no max row' ;

    my @testGlobalConditions    = () ;

    my $TYPECOL = 2 ;
    for (my $r = $row; $r <= $row_max; $r++ ) {

        last if defined $wks->get_cell($r,1) ;
        last if ( defined $wks->get_cell($r,1) and $wks->get_cell($r,1)->value() ) ;

        last if not defined $wks->get_cell($r,$TYPECOL) ;
        last if ( defined $wks->get_cell($r,$TYPECOL) and $wks->get_cell($r,$TYPECOL)->value() eq '' ) ;

        my $testconditiontype   = $wks->get_cell($r,$TYPECOL)->value() ; 
        
        my @populatedColumns    = map { $_ - $TYPECOL } grep { defined $wks->get_cell($r,$_) and $wks->get_cell($r,$_)->value() ne '' } ( $TYPECOL+1 .. $TYPECOL + scalar(@{$ra_header}) ) ;
        my @populatedVals       = map { $wks->get_cell($r,$_ + $TYPECOL)->value() } @populatedColumns ;

        my @populatedColumnsHeaders     = map { $ra_header->[$_] } @populatedColumns ;
        my @populatedColumnsHeadersHASH = map { uc "CONDITION${_}" } @populatedColumnsHeaders ;

        my @constructor = zip( @populatedColumnsHeadersHASH,@populatedVals );
        my %constructor = @constructor ;

        $constructor{TESTCONDITIONTYPE}         = $testconditiontype ;
        $constructor{CONDITIONTESTACTIONNAME}   = $testAction ;        
        
#warn Dumper %constructor ;

        my $testConditionObject = VSGDR::UnitTest::TestSet::Test::TestCondition->make(\%constructor) ;
        push @testGlobalConditions, $testConditionObject ;  
    }

    return (@testGlobalConditions) ;
}


sub representationType {
    my $self    = shift;
    return 'XLS' ;
}


sub writeSpreadsheet {
    my $self        = shift or croak 'no self' ;
    my $filename    = shift or croak 'no file' ;
    my $testSet     = shift or croak 'no test' ;

    my $colOffset = 2 ;

    my @header      = $testSet->allConditionAttributeNames() ;
    my %header_pos  = () ;
    for ( my $i = 0; $i <= $#header; $i++) { $header_pos{$header[$i]} = $i } ;

    my $workbook  = Spreadsheet::WriteExcel->new(${filename});

    my $format1 = $workbook->add_format();
    $format1->set_bold();


    my $wks_globals             = $workbook->add_worksheet('TestGlobals');
    $wks_globals->write_row(0,0,['TestNameSpace','TestClass'],$format1) ;
    $wks_globals->write_row(1,0,[ $testSet->nameSpace() 
                                , $testSet->className() 
                                ]
                           ) ;

    my $wks_globalconditions    = $workbook->add_worksheet('TestGlobalConditions');
    
    $G_ln = 0 ;
    $wks_globalconditions->write_row($G_ln, 0, ['TestInitializeAction'],$format1);
    $wks_globalconditions->write_row($G_ln, 1, [$testSet->initializeAction()]);
    $wks_globalconditions->write_row($G_ln, $colOffset, \@header,$format1);

    if ( $testSet->initializeAction() ) {
        $G_ln++;
        my $ra_Conditions = $testSet->initializeConditions();
        $self->printConditions( $wks_globalconditions,\@header, \%header_pos, $ra_Conditions) ;
    }

    $G_ln++;$G_ln++;

    $wks_globalconditions->write_row($G_ln, 0, ['TestCleanupAction'],$format1);
    $wks_globalconditions->write_row($G_ln, 1, [$testSet->cleanupAction()]);
    $wks_globalconditions->write_row($G_ln, $colOffset, \@header,$format1);
    if ( $testSet->cleanupAction() ) {
        $G_ln++;
        my $ra_Conditions = $testSet->cleanupConditions();
        $self->printConditions( $wks_globalconditions,\@header, \%header_pos, $ra_Conditions) ;
    }


    my $ra_tests = $testSet->tests() ;
    my $wks_test = undef ;
    
    $test_No = 0 ;  
    for my $test (@$ra_tests) {
        $test_No++ ;
        $wks_test           = $workbook->add_worksheet("Test ${test_No}");
        $G_ln = 0 ;
        $wks_test->write_row($G_ln, 0, [ 'Test Name '],$format1);
        $wks_test->write_row($G_ln, 1, [ $test->testName() ]);
        my $ra_Conditions = undef ;
        if ( $test->preTestAction() ne 'null' ) {
            $wks_test->write_row($G_ln, $colOffset, \@header,$format1);
            $G_ln++;
            $wks_test->write_row($G_ln, 1, ['PretestAction'],$format1);
            $G_ln++;
            $ra_Conditions = $test->preTest_conditions();
            $self->printConditions( $wks_test,\@header, \%header_pos, $ra_Conditions) ;
        }

        $G_ln++;
        $wks_test->write_row($G_ln, $colOffset, \@header,$format1);
        $G_ln++;
        $wks_test->write_row($G_ln, 1, ['TestAction'],$format1);
        $G_ln++;
        $ra_Conditions = $test->test_conditions();
        $self->printConditions( $wks_test,\@header, \%header_pos, $ra_Conditions) ;
        $G_ln++;

        if ( $test->postTestAction() ne 'null' ) {
            $wks_test->write_row($G_ln, $colOffset, \@header,$format1);
            $G_ln++;
            $wks_test->write_row($G_ln, 1, ['PosttestAction'],$format1);
            $G_ln++;
            $ra_Conditions = $test->postTest_conditions();
            $self->printConditions( $wks_test,\@header, \%header_pos, $ra_Conditions) ;
            $G_ln++;    
        }
    }
    
    $workbook->close();
    return "" ; #$workbook ;

}


sub printConditions {
    
    local $_            = undef ;

    
    my $self            = shift or croak 'no self' ;
    my $wks             = shift or croak 'no worksheet';
    my $ra_header       = shift or croak 'no header' ;
    my $rh_header_pos   = shift or croak 'no header' ;
    my $ra_Conditions   = shift or croak 'no conditions' ;
    
    my %conditionVals   = map { $_ => undef } @{$ra_header} ;

    my $colOffset = 2 ;
    
    for my $condition (@$ra_Conditions) {
        my @attrs = $condition->testConditionAttributes();
        my @attrvals = () ;
#warn Dumper @attrs ;        
        for my $attr ( grep { $_ !~ m{^conditionTestActionName$}x } @attrs ) {
            ( my $fixedName = $attr ) =~ s{^condition}{}ix;
            $conditionVals{$fixedName} = $condition->${attr}() ;
            $attrvals[$rh_header_pos->{$fixedName}] = $condition->${attr}() ;
        }
        $attrvals[$rh_header_pos->{'Type'}] = $condition->testConditionType() ;
#warn "hello\n";        
#warn $condition->testConditionType();
#warn Dumper @attrvals;
        $wks->write_row($G_ln, $colOffset, \@attrvals);
        $G_ln++;
    }
    
    return ;
}

sub flatten { return map { @$_}  @_ } ;

1 ;

__DATA__

