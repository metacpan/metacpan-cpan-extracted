package VSGDR::UnitTest::TestSet;

use 5.010;
use strict;
use warnings;

=head1 NAME

VSGDR::UnitTest::TestSet - Sealed class for Microsoft Visual Studio Database Edition UnitTest Utility Suite by Ded MedVed

=head1 VERSION

Version 1.35

=cut

our $VERSION = '1.35';


use autodie qw(:all);

#TODO 1. Add support for test method attributes eg new vs2010 exceptions  ala : -[ExpectedSqlException(MessageNumber = nnnnn, Severity = x, MatchFirstError = false, State = y)]

use VSGDR::UnitTest::TestSet::Representation ;
use Data::Dumper ;
use Carp ;

use Clone;

use base qw(Clone) ;

our $AUTOLOAD ;
my %ok_field ;
# Authorize four attribute fields
{
for my $attr ( qw(nameSpace className __testCleanupAction __testInitializeAction) ) { $ok_field{$attr}++; }
}

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
    my $ref = shift or croak "no arg";

    my ${NameSpace}         = $$ref{NAMESPACE};
    my ${ClassName}         = $$ref{CLASSNAME};

    $self->nameSpace(${NameSpace}) ;
    $self->className(${ClassName}) ;
    $self->initializeConditions([]) ;
    $self->cleanupConditions([]) ;
    return ;

}

sub tests {
    local   $_      = undef ;

    my $self        = shift or croak 'no self';
    my $tests ;
    $tests          = shift if @_;
# try to break refees here
    if ( defined $tests ) {
        $self->{TESTS} = $tests ;
    }
    return $self->{TESTS} ;
}

sub actions {
    local   $_      = undef ;

    my $self        = shift or croak 'no self';
    my $actions ;
    $actions        = shift if @_;
    if ( defined $actions ) {
croak 'obsoleted method';
#        $self->{ACTIONS} = $actions ;
    }
    my %actions = () ;
    my $ra_tests = $self->tests() ;
    foreach my $test ( @$ra_tests ) {
#warn Dumper $test ;
        my $rh_= $test->actions() ;
        foreach my $action ( keys %$rh_ ) {
#warn Dumper $action ;
            $actions{$action} = 1 ;
        }
    }
#warn Dumper %actions ;
    $actions{$self->initializeAction()} = 1 if defined $self->initializeAction() ;
    $actions{$self->cleanupAction()}    = 1 if defined $self->cleanupAction() ;
    return \%actions ;
}


sub initializeConditions {
    local   $_          = undef ;

    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
        $self->{INITIALIZECONDITIONS} = $conditions ;
    }
    return $self->{INITIALIZECONDITIONS} ;
}

sub cleanupConditions {
    local   $_          = undef ;

    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
        $self->{CLEANUPCONDITIONS} = $conditions ;
    }
    return $self->{CLEANUPCONDITIONS} ;
}

sub commentifyAny {
    local   $_  = undef ;

    my $self    = shift;
    my $commentChars    = shift or die 'No Chars' ;
    my $thing   = shift or die 'No thing' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}${thing}
            ${commentChars}
EOF
}

sub commentifyInitializeAction {
    local   $_  = undef ;

    my $self    = shift;
    my $commentChars    = shift or die 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->initializeAction()]}
            ${commentChars}
EOF
}

sub commentifyCleanupAction {
    local   $_  = undef ;

    my $self    = shift;
    my $commentChars    = shift or die 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->cleanupAction()]}
            ${commentChars}
EOF
}

sub commentifyClassName {
    local   $_  = undef ;

    my $self    = shift;
    my $commentChars    = shift or die 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->className()]}
            ${commentChars}
EOF
}
sub initializeAction {
    local   $_      = undef ;

    my $self        = shift or croak 'no self';
    my $action ;
    $action         = shift if @_;
    if ( defined $action ) {
        $self->__testInitializeAction($action) ;
    }
    return $self->__testInitializeAction() ;
}

sub cleanupAction {
    local   $_      = undef ;

    my $self        = shift or croak 'no self';
    my $action ;
    $action         = shift if @_;
    if ( defined $action ) {
        $self->__testCleanupAction($action) ;
    }
    return $self->__testCleanupAction() ;

}

sub initializeActionLiteral {
    local   $_      = undef ;

    my $self        = shift or croak 'no self';
    return 'testInitializeAction' ;
}

sub cleanupActionLiteral {
    local   $_      = undef ;

    my $self        = shift or croak 'no self';
    return 'testCleanupAction' ;

}

sub allConditionAttributeNames {
    local   $_      = undef ;

    my $self        = shift;
    return ('Type','Name','ResultSet','RowNumber','ColumnNumber','ExpectedValue','RowCount','NullExpected','ExecutionTime','Enabled') ;
}

sub generate {
    local   $_          = undef ;

    my $self            = shift;
    my $generator_type  = shift or croak "No generator supplied" ;
    my $generator       =  VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $generator_type } ) ;
    return $generator->deparse($self);
}

sub AST {
    local   $_          = undef ;

    my $self            = shift or croak "No self" ;
    return { HEAD => { NAMESPACE        => $self->nameSpace()
                     , CLASSNAME        => $self->className()
                     , INITIALIZEACTION => $self->__testInitializeAction()
                     , CLEANUPACTION    => $self->__testCleanupAction()
                     }
           , INITIALIZECONDITIONS   => $self->initializeConditions()
           , CLEANUPCONDITIONS      => $self->cleanupConditions()
           , BODY                   => $self->tests()
           , ACTIONS                => $self->actions()
           }
}

sub renameTest {
    local   $_          = undef ;

    my $self            = shift;
    my $oldTestName     = shift or croak "No old Test Name supplied" ;
    my $newTestName     = shift or croak "No new Test Name supplied" ;

    return ;
}

sub deleteTest {
    local   $_          = undef ;

    my $self            = shift;
    my $testName        = shift or croak "No Test Name supplied" ;

    return ;

}

sub Dump {
    local   $_ = undef ;

    warn "!\n";
    warn Dumper @_ ;
    warn "!\n";
    return ;
}

sub flatten { return map { @$_}  @_ } ;

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



=head1 SYNOPSIS

Sealed unit.  No user serviceable parts.
This module, and all sub-modules exist only to support the suite of applications packaged with it.
The applications offer support to creators and maintainers of Microsoft Visual Studio
Database Project Unit tests, particularly those frustrated by the VS interface to these tests,
who are also comfortable using perl software from the command line.

Support is given for VS2008, VS2010, and now SSDT and VS2012.  The latter 2 work with Sql unit tests rather than database unit
tests. In practice this means using some new .Net classes and assemblies, very little else has changed. To generate the new 
Sql Unit tests "-v2" should be passed as an additional argument to the scripts.  See the script man/help pages.
Parsing Sql Unit tests is the fallback taken in the scripts if the input unit test source code fails to parse 
as database unit tests.

Full support is offered for:-
    Scalar, EmptyResultSet, NotEmptyResultSet, RowCount conditions.
Partial support for:-
    ExecutionTime, ExpectedSchema, Inconclusive, Checksum conditions.
No support is offered for bespoke conditions, apart from what you can add yourself.
No support is offered for any unit tests that have been manually edited to add code Attributes, or alter the transaction mode etc etc.
    
The suite offers scripts to generate unit tests from sql scripts, merge unit test files, split apart unit test files, extract the sql from unit test files, delete
tests from unit test files, disable test conditions, report over unit test files, and run unit test files, with better reporting of test failures
than MSTest or Visual Studio. It can also translate unit test files from VB to C# and vice-versa, as well as to
Excel Spreadsheet, or XML.
The test runner cannot check ExecutionTime, ExpectedSchema, Inconclusive, Checksum conditions.
This is because it is pure perl, and has no access to .NET internals, or the database connection code used by .NET.

=head1 AUTHOR

Ded MedVed, C<< <dedmedved at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vsgdr-unittest-testset at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VSGDR-UnitTest-TestSet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VSGDR::UnitTest::TestSet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VSGDR-UnitTest-TestSet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VSGDR-UnitTest-TestSet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VSGDR-UnitTest-TestSet>

=item * Search CPAN

L<http://search.cpan.org/dist/VSGDR-UnitTest-TestSet/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of VSGDR::UnitTest::TestSet
