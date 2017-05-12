package VSGDR::UnitTest::TestSet::Representation::NET::CS;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.02';

use parent qw(VSGDR::UnitTest::TestSet::Representation::NET) ;

#TODO 1. Add support for test method attributes eg new vs2010 exceptions  ala : -[ExpectedSqlException(MessageNumber = nnnnn, Severity = x, MatchFirstError = false, State = y)]
#TODO 2. Add checking support in the parser, etc that the bits of code we don't care about match our expectations.  Otherwise we risk screwing non-standard test classes
#TODO 3: If a condition has the same name as a test ( ie like the prefix of a test action, the check to determine resource or test condition fails.  We've strengthened it, but it might not ultimately be fixable.

use Data::Dumper ;
use Carp ;
use Parse::RecDescent;

use VSGDR::UnitTest::TestSet;
use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Representation;
use VSGDR::UnitTest::TestSet::Representation::NET;

our %Globals ; ## temp



##$::RD_HINT=1;
$::RD_AUTOACTION=q { [@item] };
#$::RD_TRACE        = 1;
#$::RD_WARN =1;


my $grammar_pass1 = q{

        { my %testConditions   = () ;
          my %testConditions_2 = () ;
          my %resources = () ;
             $resources{CONDITIONS} = () ;
          my %TESTACTIONS           = () ;
          my %actions = () ;
          my %globals = () ;
          }

                start:  /\A.*?(?=namespace)/s         { %testConditions   = () ;
                                                        %testConditions_2 = () ;
                                                        %resources = () ;
                                                        $resources{CONDITIONS} = () ;
                                                        %TESTACTIONS            = () ;
                                                        %actions = () ;
                                                        %globals = () ;
                                                      }

                        namespace
                    /.*?(?=public class )/s

                class

                    /.*?(?=\[TestMethod\(\)\])/s
                testmethod(s)


                m{ .* (?= \z )  }xsm 

                m{ \z }sx    { $return = { GLOBALS => \%globals, RESOURCES => \%resources, ACTIONS => \%actions, TESTCONDITIONS => \%testConditions, TESTCONDITIONS_DETAILS => \%testConditions_2, TESTACTIONS => \%TESTACTIONS } ;
                             }


        namespace_name: m{\w++}sx        { $globals{NAMESPACE} = $item[1];
                      [@item] ;
                    }
        namespace: /namespace / namespace_name
        class_name:     m{\w++}sx        { $globals{CLASSNAME} = $item[1]; $globals{CLEANUPACTION} = 'testCleanupAction'; $globals{INITIALIZEACTION} = 'testInitializeAction' ;
                      [@item] ;
                    }
        class: /public class / class_name



        testmethodname: m{\w++}sx       { $globals{TESTS}{$item[1]}{NAME} = $item[1];
                              [@item] ;
                            }
        testdata_name:  m{\w++}sx       { if ( defined $arg[0] and $arg[0] ne '' ) { $globals{TESTS}{$arg[0]}{ACTION} = $item[1] } ;
                              [@item] ;
                            }

        testdata: /DatabaseTestActions testActions = this\./ testdata_name[ $arg[0] ] /;/

        testmethod: /\[TestMethod\(\)\]\s+public\s+void/ testmethodname /\(\)/ /[{}]/ testdata[ $item[2][1] ] /.*?(?=(?:\[TestMethod\(\)\])|(?:\}\s*\z))/s


               };

my $grammar_pass2 = q{

        { my %testConditions   = () ;
          my %testConditions_2 = () ;
          my %resources = () ;
             $resources{CONDITIONS} = () ;
          my %TESTACTIONS           = () ;
          my %actions = () ;
          my %globals = () ;
          }

                start:  /\A.*?(?=namespace)/s         { %testConditions         = () ;
                                                        %testConditions_2       = () ;
                                                        %resources              = () ;
                                                        $resources{CONDITIONS}  = () ;
                                                        %TESTACTIONS            = () ;
                                                        %actions                = () ;
                                                        %globals                = %{$arg[0]} ; 
                                                      }

                        namespace
                    /.*?(?=public class )/s

                class

#                    /.*?(?=\[TestMethod\(\)\])/s
#                testmethod(s)

                    m{.*? #(?=(?:Microsoft\.Data\.Schema\.UnitTesting\.Conditions\.))
                        (?:         private\s+void\s+InitializeComponent\(\)\s+.\s+
                        )
                     }sx
                condition_or_testaction(s?)

            m{.*?(?=\s*//)}s
                resource_test_action(s?)
                /.*\Z/s { $return = { GLOBALS => \%globals, RESOURCES => \%resources, ACTIONS => \%actions, TESTCONDITIONS => \%testConditions, TESTCONDITIONS_DETAILS => \%testConditions_2, TESTACTIONS => \%TESTACTIONS } ;
                        }

        condition_or_testaction: condition | testaction | resourcemanager
        testaction: /Microsoft\.Data\.Schema\.UnitTesting\.DatabaseTestAction [\w]*;/
        resourcemanager: /System\.ComponentModel\.ComponentResourceManager/ /[\w]+/ /=/ /new/ /System\.ComponentModel\.ComponentResourceManager\(typeof\([\w]+\)\)/ /;/

        resource_test_action: resource | test | action


        namespace_name: m{\w++}sx        { $globals{NAMESPACE} = $item[1];
                      [@item] ;
                    }
        namespace: /namespace / namespace_name
        class_name:     m{\w++}sx        { $globals{CLASSNAME} = $item[1]; $globals{CLEANUPACTION} = 'testCleanupAction'; $globals{INITIALIZEACTION} = 'testInitializeAction' ;
                      [@item] ;
                    }
        class: /public class / class_name



        testmethodname: m{\w++}sx       { $globals{TESTS}{$item[1]}{NAME} = $item[1];
                              [@item] ;
                            }
        testdata_name:  m{\w++}sx       { if ( defined $arg[0] and $arg[0] ne '' ) { $globals{TESTS}{$arg[0]}{ACTION} = $item[1] } ;
                              [@item] ;
                            }

        testdata: /DatabaseTestActions testActions = this\./ testdata_name[ $arg[0] ] /;/

        testmethod: /\[TestMethod\(\)\]\s+public\s+void/ testmethodname /\(\)/ /[{}]/ testdata[ $item[2][1] ] /.*?(?=(?:\[TestMethod\(\)\])|(?:#region Designer support code))/s




        condition_type: m{\w++}sx
        condition_name: m{\w++}sx
        condition: /Microsoft\.Data\.Schema\.UnitTesting\.Conditions\./ condition_type condition_name /;/
                    { $testConditions{$item[3][1]} = $item[2][1];
                      [@item] ;
                    }


        test_comment:   m{//[^/]*//[^/]*//}
        testname:       m{\w++}sx
        testproperty:   /ColumnNumber|Enabled|ExpectedValue|Name|NullExpected|ResultSet|RowNumber|RowCount|ExecutionTime|Checksum|Verbose/

        testvalue_string: / (?: \"(?:(?:[\\\\][\"])|(?:[^\"]))*?\" )/x 
                    { #VSGDR::UnitTest::TestSet::Dump(@item) ;
                      $item[1] ;
                    }
        testvalue:  testvalue_string
                 | /System\.TimeSpan\.Parse\("[\d:]*"\)/x
                 | /(?: \w+ ) /x
                    { #VSGDR::UnitTest::TestSet::Dump(@item) ;
                      [@item] ;
                    }

        test_element: testname /\./ testproperty /=/ testvalue /;/
                    { $testConditions_2{$item[1][1]}{$item[3][1]} = $item[5][1];
                      #VSGDR::UnitTest::TestSet::Dump(@item) ;
                      [@item] ;
                    }
        test_element: /resources\.ApplyResources\(/ /\w+/ /,/ testvalue_string /\)/
                    { [@item] ;
                    }

        test:   test_comment test_element(s)



        action_comment: m{//[^/]*//[^/]*//}
        action_type:    /PosttestAction|PretestAction|TestAction/
        action_name:    m{\w++}sx
        action_element: /this\./ testdata_name /\./ action_type /=/ action_name /;/
                { $actions{$item[2][1]}{$item[4][1]}=$item[6][1];
                  my $testAction = $item[2][1] ;
                  my $testActionDataValue = $item[6][1] ;
                  $testActionDataValue =~ s{ _ (?: PosttestAction|PretestAction|TestAction ) }{}x;
                  $TESTACTIONS{$testActionDataValue} = $testAction if $testActionDataValue !~ m{\A null \z}ix ;
                  [@item] ;
                    }

        action: action_comment action_element(s)



        resource_comment:       m{//[^/]*//[^/]*//}
        resource_name:          m{\w++}sx
        resource_name_string:   m{"\w++"}sx
        resource_element:       /resources\.ApplyResources\(/ resource_name /,/ resource_name_string /\)/ /;/

        # reject this parse if it doesn't apply to some testaction resource.
        # relies on us being able to parse the test name first !!!!!!!
        # if we don't do this then the test condition resource can get mixed up with it
        # leading to early parse condition 2 termination
        # at fault is the optionality of resource_condition below.
        # viz resource_condition(s?)
        #
        # BUT ** If a condition has the same name as a test ( ie like the prefix of a test action, 
        # the check to determine resource or test condition fails.  
        # We've strengthened it, but it might not ultimately be fixable. 
        # A better way may be to check the final element of $item[2][1]
        # to see if it is TestAction/PretestAction/PostTestaction, AFAIK
        # this can't be meddled with by the user.  However some fool might name a test or
        # condition TestAction etc, so it still isn't fool-proof in isolation.
        
                { my $x = $item[2][1] ;
#VSGDR::UnitTest::TestSet::Dump($x);
                  $x =~ s/[_][^_]*$// ;
#VSGDR::UnitTest::TestSet::Dump($x);
##VSGDR::UnitTest::TestSet::Dump(%TESTACTIONS);
                     if ( exists($testConditions{$x}) && ! exists($globals{TESTS}{$x})) {
                         undef ;
                      }
                      else {
                         $resources{$item[2][1]}=1;
                         [@item] ;
                     }
                }
        resource_condition: resource_name /\.Conditions\.Add\(/ condition_name /\)/ /;/
                { unshift (@{$resources{CONDITIONS}{$item[1][1]}},$item[3][1]);
                  [@item] ;
                    } 
        resource: resource_comment resource_condition(s?) resource_element


               };

sub _init {

    local $_ ;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    my $ref                 = shift or croak "no arg";

    my $parser1 = new Parse::RecDescent($grammar_pass1);
    my $parser2 = new Parse::RecDescent($grammar_pass2);

    $self->{PARSER1} = $parser1 ;
    $self->{PARSER2} = $parser2 ;
    return ;

}

sub representationType {
    local $_    = undef;
    my $self    = shift or croak 'no self';
    return 'CS' ;
}



sub trim {
    local $_    = undef;
    my $self    = shift or croak 'no self';
    my $code    = shift or croak 'no code' ;
#
#    $code =~ s/\A.*?Public Class/Public Class/ms;
    $code =~ s/"\s*\+\s*"//msg;                              # join split strings
    $code =~ s/resources\.GetString\(("[^""]*?")\)/$1/msg;  # strip out usage of resources.GetString() and just keep the string


#    $code =~ s{  Dim\s+[\w]+\s+As\s+                        # strip out variable declarations that we aren't interested in
#                                     (?:
#                                       (?: Microsoft\.Data\.Schema\.UnitTesting\.DatabaseTestAction)
#                                     | (?: System\.ComponentModel\.ComponentResourceManager\s+=\s+New\s+System\.ComponentModel\.ComponentResourceManager\(GetType\([\w]+\)\))
#                                     )
#              }{}msgx  ;
#
#    $code =~ s/Microsoft\.Data\.Schema\.UnitTesting\.Conditions/MS\.D\.S\.UT\.C/msg;  # shorten file


#    $code =~ s/End\sSub\s+#End\sRegion\s+#Region\s"Additional\stest\sattributes".*\z//ms;
#warn Dumper $code ;
    return $code ;
}


## -- ** ---

sub declareVariable {
    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $type                    = shift or croak 'no type' ;
    my $var                     = shift or croak 'no var' ;
    my $res = "" ;
    $res .=  $type . " " . $var ;
    return $res;
}

sub declareAndCreateVariable {
    local $_                    = undef;
    my $self                    = shift or croak 'no self' ;
    my $type                    = shift or croak 'no type' ;
    my $var                     = shift or croak 'no var' ;
    my $constructor             = shift or croak 'no $constructor' ;
    my $res = "" ;
    $res .=  $type . " " . $var . " = " . $self->newKeyWord() . " " . $constructor ;
    return $res;
}



#####################################################################

sub icHeader {

    local $_ = undef;
    my $self        = shift or croak 'no self' ;

return <<"EOF";
        #region Designer support code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
EOF
}



sub icFooter {

    local $_ = undef;
    my $self        = shift or croak 'no self' ;

return <<"EOF";
        }

        #endregion

EOF
}



sub Tests {

    local $_ = undef ;

    my $self        = shift or croak 'no self' ;
    my $ra_tests    = shift or croak 'no tests' ;
#print Dumper $ast_branch ;
    my @tests       = @$ra_tests ;

    my $p1 = '    ';
    my $p2 = '        ';
    my $p3 = '            ';
    my $res = "" ;

    foreach my $test ( @tests) {

        $res .= "${p2}[TestMethod()]\n";
        $res .= "${p2}public void ".$test->testName()."()\n";
        $res .= "${p2}{\n";
        $res .= "${p3}DatabaseTestActions testActions = " . $self->selfKeyWord() . ".".$test->testActionDataName().";\n";

        $res .= $self->Lang_testsection('pre-test',$test->preTestActionLiteral(),'pretestResults','Executing pre-test script...','PrivilegedContext') ;
        $res .= $self->Lang_testsection('test',$test->testActionLiteral(),'testResults','Executing test script...','ExecutionContext') ;
        $res .= $self->Lang_testsection('post-test',$test->postTestActionLiteral(),'posttestResults','Executing post-test script...','PrivilegedContext') ;


        $res .= "${p2}}\n";
        $res .= "\n";

    }

    return $res;
}


sub Lang_testsection {

    local $_    = undef ;

    my $self    = shift or croak 'no self' ;
    my $arg1    = shift or croak 'no comment';
    my $arg2    = shift or croak 'no method';
    my $arg3    = shift or croak 'no results';
    my $arg4    = shift or croak 'no text';
    my $arg5    = shift or croak 'no context';

    my $p3 = '            ';
    my $res     = "" ;

#print Dumper ${arg2} ;

    $res .= "${p3}// Execute the ${arg1} script\n";
    $res .= "${p3}// \n";

    $res .= "${p3}System.Diagnostics.Trace.WriteLineIf((testActions.".${arg2}." != " . $self->null() . "), \"${arg4}\");\n";
    $res .= "${p3}ExecutionResult[] "."${arg3}"." = TestService.Execute(" . $self->selfKeyWord() . ".${arg5}, " . $self->selfKeyWord() . ".PrivilegedContext, testActions.".${arg2}.");\n";

    $res ;

}


sub Header {

    local $_        = undef ;
    my $self        = shift or croak 'no self' ;
    my $namespace   = shift or croak "No namespace supplied" ;
    my $class       = shift or croak "No Class" ;


return <<"EOF";

using System;
using System.Text;
using System.Data;
using System.Data.Common;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.Data.Schema.UnitTesting;
using Microsoft.Data.Schema.UnitTesting.Conditions;

namespace ${namespace}
{
    [TestClass()]
    public class ${class} : DatabaseTestClass
    {

        public ${class}()
        {
            InitializeComponent();
        }

        [TestInitialize()]
        public void TestInitialize()
        {
            base.InitializeTest();
        }
        [TestCleanup()]
        public void TestCleanup()
        {
            base.CleanupTest();
        }

EOF

}

sub Footer {

    local $_        = undef ;
    my $self        = shift or croak 'no self' ;
    my $ra_tests    = shift or croak 'no tests' ;
    my @tests       = @$ra_tests ;

    my $p1 = '    ';
    my $p2 = '        ';
    my $res = "" ;

    foreach my $test (@tests) {
        $res .= "${p2}private DatabaseTestActions ".$test->testActionDataName().";\n";
    }

return <<"EOF";

        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        #endregion

${res}
    }
}
EOF

}


sub typeExtractor {
    my $self        = shift or croak 'no self' ;
    return "typeof"
}
sub newKeyWord {
    my $self        = shift or croak 'no self' ;
    return "new" ;
}
sub selfKeyWord {
    my $self        = shift or croak 'no self' ;
    return "this" ;
}
sub functionOpenDelimiter {
    my $self        = shift or croak 'no self' ;
    return "(" ;
}
sub functionCloseDelimiter {
    my $self        = shift or croak 'no self' ;
    return ")" ;
}
sub functionDelimiters {
    my $self        = shift or croak 'no self' ;
    return "()" ;
}
sub lineTerminator {
    my $self        = shift or croak 'no self' ;
    return ";" ;
}
sub quoteChars {
    my $self        = shift or croak 'no self' ;
    return "// " ;
}
sub true {
    my $self        = shift or croak 'no self' ;
    return 'true' ;
}
sub false {
    my $self        = shift or croak 'no self' ;
    return 'false' ;
}
sub null {
    my $self        = shift or croak 'no self' ;
    return 'null' ;
}

sub convertKeyWord {
    my $self        = shift or croak 'no self' ;
    my $KW          = shift ;
    croak 'No key word' if not defined ($KW) ;

    return 'true' if $KW =~ /^true$/i ;
    return 'false' if $KW =~ /^false$/i ;
    return 'null' if $KW =~ /^(?:"nothing"|nothing|null)$/i ;
    return $KW ; # otherwise
}

1;



###my $grammar = q{
###            
###        { my %testConditions   = () ; 
###          my %testConditions_2 = () ; 
###          my %resources = () ; 
###             $resources{CONDITIONS} = () ;
###          my %TESTACTIONS           = () ;             
###          my %actions = () ; 
###          my %globals = () ; 
###          }
###        
###                start:  /\A.*?(?=namespace)/s         { %testConditions   = () ; 
###                                                        %testConditions_2 = () ; 
###                                                        %resources = () ; 
###                                                        $resources{CONDITIONS} = () ;
###                                                        %TESTACTIONS            = () ;                                                        
###                                                        %actions = () ; 
###                                                        %globals = () ; 
###                                                      }
###
###                        namespace 
###                    /.*?(?=public class )/s 
###
###                class
###
###                    /.*?(?=\[TestMethod\(\)\])/s 
###                testmethod(s)
###
###                    m{.*? #(?=(?:Microsoft\.Data\.Schema\.UnitTesting\.Conditions\.))
###                        (?:         private\s+void\s+InitializeComponent\(\)\s+.\s+
###                        )
###                     }sx 
###                condition_or_testaction(s?)
###
###            m{.*?(?=\s*//)}s
###                resource_test_action(s?)
###                /.*\Z/s { $return = { GLOBALS => \%globals, RESOURCES => \%resources, ACTIONS => \%actions, TESTCONDITIONS => \%testConditions, TESTCONDITIONS_DETAILS => \%testConditions_2, TESTACTIONS => \%TESTACTIONS } ;
###                        }
###
###        condition_or_testaction: condition | testaction | resourcemanager
###        testaction: /Microsoft\.Data\.Schema\.UnitTesting\.DatabaseTestAction [\w]*;/
###        resourcemanager: /System\.ComponentModel\.ComponentResourceManager/ /[\w]+/ /=/ /new/ /System\.ComponentModel\.ComponentResourceManager\(typeof\([\w]+\)\)/ /;/
###
###        resource_test_action: resource | test | action 
###
###
###        namespace_name: m{\w++}sx        { $globals{NAMESPACE} = $item[1];
###                      [@item] ;
###                    } 
###        namespace: /namespace / namespace_name
###        class_name:     m{\w++}sx        { $globals{CLASSNAME} = $item[1]; $globals{CLEANUPACTION} = 'testCleanupAction'; $globals{INITIALIZEACTION} = 'testInitializeAction' ;
###                      [@item] ;
###                    }   
###        class: /public class / class_name
###
###
###
###        testmethodname: m{\w++}sx       { $globals{TESTS}{$item[1]}{NAME} = $item[1];
###                              [@item] ;
###                            } 
###        testdata_name:  m{\w++}sx       { if ( $arg[0] ne '' ) { $globals{TESTS}{$arg[0]}{ACTION} = $item[1] } ; 
###                              [@item] ;
###                            } 
###
###        testdata: /DatabaseTestActions testActions = this\./ testdata_name[ $arg[0] ] /;/
###
###        testmethod: /\[TestMethod\(\)\]\s+public\s+void/ testmethodname /\(\)/ /[{}]/ testdata[ $item[2][1] ] /.*?(?=(?:\[TestMethod\(\)\])|(?:#region Designer support code))/s 
###        
###
###
###
###        condition_type: m{\w++}sx
###        condition_name: m{\w++}sx       
###
###        condition: /Microsoft\.Data\.Schema\.UnitTesting\.Conditions\./ condition_type condition_name /;/ 
###        condition: /Microsoft\.Data\.Schema\.UnitTesting\.Conditions\./ /\w++/ /\w++/ /;/ 
###                    { $testConditions{$item[3][1]} = $item[2][1];
###                      [@item] ;
###                    } 
###
###
###        test_comment:   m{\s*//[^/]*//[^/]*//\s*}
###        testname:       m{\w++}sx
###        testproperty:   /ColumnNumber|Enabled|ExpectedValue|Name|NullExpected|ResultSet|RowNumber|RowCount|ExecutionTime|Checksum|Verbose/
###
###        testvalue_string: / (?: \"[^\"]*?\" )/x { $item[1] }
###        testvalue: testvalue_string
###                 | /System\.TimeSpan\.Parse\("[\d:]*"\)/x
###                 | /(?: \w+ ) /x 
###                    { #VSGDR::UnitTest::TestSet::Dump(@item) ;
###                      [@item] ;
###                    } 
###
###        test_element: testname /\./ testproperty /=/ testvalue /;/
###                    { $testConditions_2{$item[1][1]}{$item[3][1]} = $item[5][1];
###                      #VSGDR::UnitTest::TestSet::Dump(@item) ;
###                      [@item] ;
###                    } 
###        test_element: /resources\.ApplyResources\(/ /\w+/ /,/ testvalue_string /\)/ 
###                    { [@item] ;
###                    }
###
###        test:   test_comment test_element(s)
###
###
###
###        action_comment: m{\s*//[^/]*//[^/]*//\s*}
###        action_type:    /PosttestAction|PretestAction|TestAction/      
###        action_name:    m{\w++}sx   
###        action_element: /this\./ testdata_name /\./ action_type /=/ action_name /;/
###                { $actions{$item[2][1]}{$item[4][1]}=$item[6][1];
###                  my $testAction = $item[2][1] ;
###                  my $testActionDataValue = $item[6][1] ;
###                  $testActionDataValue =~ s{ _ (?: PosttestAction|PretestAction|TestAction ) }{}x;
###                  $TESTACTIONS{$testActionDataValue} = $testAction if $testActionDataValue !~ m{\A null \z}ix ;
###                  [@item] ;
###                    } 
###
###        action: action_comment action_element(s) 
###
### 
###
###        resource_comment:       m{\s*//[^/]*//[^/]*//\s*}
###        resource_name:          m{\w++}sx 
###        resource_name_string:   m{"\w++"}sx  
###        resource_element:       /resources\.ApplyResources\(/ resource_name /,/ resource_name_string /\)/ /;/
###        # reject this parse if it applies to some condition.
###        # relies on us being able to parse all the bleeding conditions first
###        # at fault is the optionality of resource_condition below.
###        # viz resource_condition(s?)
###                { my $x = $item[2][1] ;
####VSGDR::UnitTest::TestSet::Dump($x);
###                  $x =~ s/[_][^_]*$// ;
####VSGDR::UnitTest::TestSet::Dump($x);                  
#####VSGDR::UnitTest::TestSet::Dump(%TESTACTIONS);                  
###                      if ( exists($testConditions{$x})) {
###                         undef ;                
###                      }
###                      else {
###                         $resources{$item[2][1]}=1;
###                         [@item] ;
###                     } 
###                }
###        resource_condition: resource_name /\.Conditions\.Add\(/ condition_name /\)/ /;/
###                { unshift (@{$resources{CONDITIONS}{$item[1][1]}},$item[3][1]);
###                  [@item] ;
###                    } 
###        resource: resource_comment resource_condition(s?) resource_element
###
###
###               };


__DATA__




<ROOT>
    <SECTIONS>


        <SECTION Name="TestClass">
        public <@ClassName@>()
        {
            InitializeComponent();
        }
        </SECTION>


        <SECTION Name="TestInitialize">
        [TestInitialize()]
        public void TestInitialize()
        {
            base.InitializeTest();
        }
        </SECTION>

        <SECTION Name="TestCleanup">
        [TestCleanup()]
        public void TestCleanup()
        {
            base.CleanupTest();
        }
        </SECTION>



        <SECTION Name="TestMethod">
        [TestMethod()]
        public void <@MethodName@>()
        {
            DatabaseTestActions testActions = this.<@MethodName@>Data;
            // Execute the pre-test script
            //
            System.Diagnostics.Trace.WriteLineIf((testActions.PretestAction != null), "Executing pre-test script...");
            ExecutionResult[] pretestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PretestAction);
            // Execute the test script
            //
            System.Diagnostics.Trace.WriteLineIf((testActions.TestAction != null), "Executing test script...");
            ExecutionResult[] testResults = TestService.Execute(this.ExecutionContext, this.PrivilegedContext, testActions.TestAction);
            // Execute the post-test script
            //
            System.Diagnostics.Trace.WriteLineIf((testActions.PosttestAction != null), "Executing post-test script...");
            ExecutionResult[] posttestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PosttestAction);
        }

        </SECTION>

        <SECTION Name="Additional test attributes">
        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        #endregion
        </SECTION>

    </SECTIONS>
</ROOT>

-- data tools version of unit tests
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Text;
using Microsoft.Data.Tools.Schema.Sql.UnitTesting;
using Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace TestProject1
{
    [TestClass()]
    public class SqlServerUnitTest1 : SqlDatabaseTestClass
    {

        public SqlServerUnitTest1()
        {
            InitializeComponent();
        }

        [TestInitialize()]
        public void TestInitialize()
        {
            base.InitializeTest();
        }
        [TestCleanup()]
        public void TestCleanup()
        {
            base.CleanupTest();
        }

        [TestMethod()]
        public void SqlTest1()
        {
            SqlDatabaseTestActions testActions = this.SqlTest1Data;
            // Execute the pre-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PretestAction != null), "Executing pre-test script...");
            SqlExecutionResult[] pretestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PretestAction);
            // Execute the test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.TestAction != null), "Executing test script...");
            SqlExecutionResult[] testResults = TestService.Execute(this.ExecutionContext, this.PrivilegedContext, testActions.TestAction);
            // Execute the post-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PosttestAction != null), "Executing post-test script...");
            SqlExecutionResult[] posttestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PosttestAction);
        }

        #region Designer support code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestAction SqlTest1_TestAction;
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.InconclusiveCondition inconclusiveCondition1;
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.RowCountCondition rowCountCondition1;
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ChecksumCondition checksumCondition1;
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.EmptyResultSetCondition emptyResultSetCondition1;
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ExecutionTimeCondition executionTimeCondition1;
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ExpectedSchemaCondition expectedSchemaCondition1;
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(SqlServerUnitTest1));
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.NotEmptyResultSetCondition notEmptyResultSetCondition1;
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ScalarValueCondition scalarValueCondition1;
            this.SqlTest1Data = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestActions();
            SqlTest1_TestAction = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestAction();
            inconclusiveCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.InconclusiveCondition();
            rowCountCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.RowCountCondition();
            checksumCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ChecksumCondition();
            emptyResultSetCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.EmptyResultSetCondition();
            executionTimeCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ExecutionTimeCondition();
            expectedSchemaCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ExpectedSchemaCondition();
            notEmptyResultSetCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.NotEmptyResultSetCondition();
            scalarValueCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ScalarValueCondition();
            // 
            // SqlTest1_TestAction
            // 
            SqlTest1_TestAction.Conditions.Add(inconclusiveCondition1);
            SqlTest1_TestAction.Conditions.Add(rowCountCondition1);
            SqlTest1_TestAction.Conditions.Add(checksumCondition1);
            SqlTest1_TestAction.Conditions.Add(emptyResultSetCondition1);
            SqlTest1_TestAction.Conditions.Add(executionTimeCondition1);
            SqlTest1_TestAction.Conditions.Add(expectedSchemaCondition1);
            SqlTest1_TestAction.Conditions.Add(notEmptyResultSetCondition1);
            SqlTest1_TestAction.Conditions.Add(scalarValueCondition1);
            resources.ApplyResources(SqlTest1_TestAction, "SqlTest1_TestAction");
            // 
            // inconclusiveCondition1
            // 
            inconclusiveCondition1.Enabled = true;
            inconclusiveCondition1.Name = "inconclusiveCondition1";
            // 
            // rowCountCondition1
            // 
            rowCountCondition1.Enabled = true;
            rowCountCondition1.Name = "rowCountCondition1";
            rowCountCondition1.ResultSet = 1;
            rowCountCondition1.RowCount = 0;
            // 
            // SqlTest1Data
            // 
            this.SqlTest1Data.PosttestAction = null;
            this.SqlTest1Data.PretestAction = null;
            this.SqlTest1Data.TestAction = SqlTest1_TestAction;
            // 
            // checksumCondition1
            // 
            checksumCondition1.Checksum = null;
            checksumCondition1.Enabled = true;
            checksumCondition1.Name = "checksumCondition1";
            // 
            // emptyResultSetCondition1
            // 
            emptyResultSetCondition1.Enabled = true;
            emptyResultSetCondition1.Name = "emptyResultSetCondition1";
            emptyResultSetCondition1.ResultSet = 1;
            // 
            // executionTimeCondition1
            // 
            executionTimeCondition1.Enabled = true;
            executionTimeCondition1.ExecutionTime = System.TimeSpan.Parse("00:00:30");
            executionTimeCondition1.Name = "executionTimeCondition1";
            // 
            // expectedSchemaCondition1
            // 
            expectedSchemaCondition1.Enabled = true;
            expectedSchemaCondition1.Name = "expectedSchemaCondition1";
            resources.ApplyResources(expectedSchemaCondition1, "expectedSchemaCondition1");
            expectedSchemaCondition1.Verbose = false;
            // 
            // notEmptyResultSetCondition1
            // 
            notEmptyResultSetCondition1.Enabled = true;
            notEmptyResultSetCondition1.Name = "notEmptyResultSetCondition1";
            notEmptyResultSetCondition1.ResultSet = 1;
            // 
            // scalarValueCondition1
            // 
            scalarValueCondition1.ColumnNumber = 1;
            scalarValueCondition1.Enabled = true;
            scalarValueCondition1.ExpectedValue = null;
            scalarValueCondition1.Name = "scalarValueCondition1";
            scalarValueCondition1.NullExpected = true;
            scalarValueCondition1.ResultSet = 1;
            scalarValueCondition1.RowNumber = 1;
        }

        #endregion


        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        #endregion

        private SqlDatabaseTestActions SqlTest1Data;
    }
}
