package VSGDR::TestScriptGen;

use strict;
use warnings;

use 5.010;

use List::Util qw(max);
#use List::MoreUtils;
use List::MoreUtils qw{firstidx} ;
use POSIX qw(strftime);
use Carp;
use DBI;
use Data::Dumper;
use English;
use IO::File ;
use File::Basename;
use Try::Tiny;

use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Test::TestCondition;
use VSGDR::UnitTest::TestSet::Representation;
use VSGDR::UnitTest::TestSet::Resx;
use File::Basename;


=head1 NAME

VSGDR::TestScriptGen - Unit test script support package for SSDT unit tests, Ded MedVed.

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';


sub databaseName {

    local $_    = undef ;

    my $dbh     = shift ;

    my $sth2 = $dbh->prepare(databaseNameSQL());
    my $rs   = $sth2->execute();
    my $res  = $sth2->fetchall_arrayref() ;

    return $$res[0][0] ;

}

sub databaseNameSQL {

return <<"EOF" ;

select  db_name()

EOF

}

sub ExecSp {

    local $_    = undef ;

    my $dbh     = shift ;

    my $sth2    = $dbh->prepare( ExecSpSQL());
    my $rs      = $sth2->execute();
    my $res     = $sth2->fetchall_arrayref() ;

    if ( scalar @{$res} ) { return $res ; } ;
    return [] ;
}



sub ExecSpSQL {

return <<"EOF" ;

; with BASE as (
SELECT  case when ROUTINE_TYPE = 'PROCEDURE' then cast([PARAMETER_NAME] + ' = ' + [PARAMETER_NAME] + case when PARAMETER_MODE = 'IN' then '' else  ' OUTPUT' + CHAR(10) end as VARCHAR(MAX)) 
             when ROUTINE_TYPE = 'FUNCTION'  then cast([PARAMETER_NAME] as VARCHAR(MAX)) 
        end  as PARAMTER
--      cast([PARAMETER_NAME] + ' = ' + [PARAMETER_NAME] + case when PARAMETER_MODE = 'IN' then '' else  ' OUTPUT' + CHAR(10) end as VARCHAR(MAX)) as PARAMTER
,		cast([PARAMETER_NAME] + '  ' + case when P.DATA_TYPE in ('table type') then user_defined_type_schema +'.'+ user_defined_type_name when P.DATA_TYPE in ('ntext','text') then 'varchar' when P.DATA_TYPE in ('image') then 'varbinary' else P.DATA_TYPE end +
              case when P.DATA_TYPE not in ('xml') then coalesce('('+case when P.CHARACTER_MAXIMUM_LENGTH = -1 or P.CHARACTER_MAXIMUM_LENGTH > 8000 then 'max' else cast(P.CHARACTER_MAXIMUM_LENGTH as varchar) end +')','') ELSE '' END + CHAR(10) as VARCHAR(MAX)) as DECLARATION
,       R.[SPECIFIC_CATALOG]
,       R.[SPECIFIC_SCHEMA]
,       R.[SPECIFIC_NAME]
,       [ORDINAL_POSITION]
,       [PARAMETER_MODE]
FROM    [INFORMATION_SCHEMA].[PARAMETERS] P
JOIN    INFORMATION_SCHEMA.ROUTINES R
on      R.[SPECIFIC_NAME]           = P.[SPECIFIC_NAME]
and     R.[SPECIFIC_SCHEMA]         = P.[SPECIFIC_SCHEMA]
and     R.[SPECIFIC_CATALOG]        = P.[SPECIFIC_CATALOG]
where   1=1 
and     ORDINAL_POSITION = 1
union all 
select  cast(PARAMTER + +char(10)+CHAR(9)+CHAR(9)+CHAR(9)+char(9)+CHAR(9)+CHAR(9)+CHAR(9)+CHAR(9)+',' + CHAR(9)+ CHAR(9) +   case when ROUTINE_TYPE = 'PROCEDURE' then cast(N.[PARAMETER_NAME] + ' = ' + N.[PARAMETER_NAME] + case when N.PARAMETER_MODE = 'IN' then '' else  ' OUTPUT' + CHAR(10) end as VARCHAR(MAX)) 
                                     when ROUTINE_TYPE = 'FUNCTION'  then cast(N.[PARAMETER_NAME] as VARCHAR(MAX)) 
                                end as VARCHAR(MAX)) as PARAMTER                            
--N.[PARAMETER_NAME] + ' = ' + N.[PARAMETER_NAME] + case when N.PARAMETER_MODE = 'IN' then '' else  ' OUTPUT' + CHAR(10) end as varchar(max))
,		cast(DECLARATION + CHAR(9)+',' + CHAR(9)+CHAR(9) + [PARAMETER_NAME] + '  ' + case when n.DATA_TYPE in ('table type') then user_defined_type_schema +'.'+ user_defined_type_name when N.DATA_TYPE in ('ntext','text') then 'varchar' when N.DATA_TYPE in ('image') then 'varbinary' else N.DATA_TYPE end +
              case when N.DATA_TYPE not in ('xml') then coalesce('('+case when N.CHARACTER_MAXIMUM_LENGTH = -1 or N.CHARACTER_MAXIMUM_LENGTH > 8000 then 'max' else cast(N.CHARACTER_MAXIMUM_LENGTH as varchar) end +')','') ELSE '' END + CHAR(10) as VARCHAR(MAX))
,       N.[SPECIFIC_CATALOG]
,       N.[SPECIFIC_SCHEMA]
,       N.[SPECIFIC_NAME]
,       N.[ORDINAL_POSITION]
,       N.[PARAMETER_MODE]
from    [INFORMATION_SCHEMA].[PARAMETERS] N 
JOIN    INFORMATION_SCHEMA.ROUTINES R
on      R.[SPECIFIC_NAME]           = N.[SPECIFIC_NAME]
and     R.[SPECIFIC_SCHEMA]         = N.[SPECIFIC_SCHEMA]
and     R.[SPECIFIC_CATALOG]        = N.[SPECIFIC_CATALOG]
join    BASE B
on      N.[SPECIFIC_NAME]           = B.[SPECIFIC_NAME]
and     N.[SPECIFIC_SCHEMA]         = B.[SPECIFIC_SCHEMA]
and     N.[SPECIFIC_CATALOG]        = B.[SPECIFIC_CATALOG]
and     N.ORDINAL_POSITION          = B.ORDINAL_POSITION+1
)
, ALLL as ( 
select  *
,       ROW_NUMBER() over (partition by [SPECIFIC_CATALOG],[SPECIFIC_SCHEMA],[SPECIFIC_NAME] order by ORDINAL_POSITION DESC ) as RN  
from    BASE 
)
, PARAMS as (
select * from ALLL where RN = 1
)
select  '[' + R.SPECIFIC_SCHEMA + '].[' + R.SPECIFIC_NAME +']' as sp
,	case when ROUTINE_TYPE = 'FUNCTION' and DATA_TYPE != 'TABLE' 
             then 'declare ' + coalesce(DECLARATION+char(9)+','+char(9)+char(9),'') + '\@RC ' + DATA_TYPE+coalesce('('+cast(CHARACTER_MAXIMUM_LENGTH as varchar)+')','')
             else coalesce('declare ' + DECLARATION,'')
        end as DECLARATION
,       case when ROUTINE_TYPE = 'PROCEDURE' then 'execute [' + R.SPECIFIC_SCHEMA + '].[' + R.SPECIFIC_NAME + '] ' + coalesce(B.PARAMTER,'') 
             when ROUTINE_TYPE = 'FUNCTION' and DATA_TYPE = 'TABLE'  then 'select * from [' + R.SPECIFIC_SCHEMA + '].[' + R.SPECIFIC_NAME + '](' + coalesce(B.PARAMTER,'')  + ')'
             when ROUTINE_TYPE = 'FUNCTION' and DATA_TYPE != 'TABLE' then 'select \@RC = [' + R.SPECIFIC_SCHEMA + '].[' + R.SPECIFIC_NAME + '](' + coalesce(B.PARAMTER,'')  + ')'
             else '-- unknown routine type'
        end as sql 
from    INFORMATION_SCHEMA.ROUTINES R
LEFT    JOIN    PARAMS B
on      R.[SPECIFIC_NAME]           = B.[SPECIFIC_NAME]
and     R.[SPECIFIC_SCHEMA]         = B.[SPECIFIC_SCHEMA]
and     R.[SPECIFIC_CATALOG]        = B.[SPECIFIC_CATALOG]
where   R.ROUTINE_TYPE              in( 'PROCEDURE','FUNCTION')


EOF

}


sub generateScripts {

    local $_            = undef;
           
    my $dbh             = shift ;
    my $dbh_typeinfo    = shift ;
    my $dirs            = shift ;
    my $file            = shift ;
    my $runChecks       = shift ;

    croak "bad arg dbh"             unless defined $dbh;
    croak "bad arg dbh_typeinfo"    unless defined $dbh_typeinfo;
    croak "bad arg dirs"            unless defined $dirs;
    #croak "bad arg file"            unless defined $file;
    croak "bad arg runChecks"       unless defined $runChecks;
    
    my $testSet = undef;
    if ( defined $file ) {

        my %ValidParserMakeArgs = ( vb  => "NET::VB"
                                , cs  => "NET::CS"
                                , xls => "XLS"
                                , xml => "XML"
                                ) ;
        my %ValidParserMakeArgs2 = ( vb  => "NET2::VB"
                                , cs  => "NET2::CS"
                                ) ;                          
                                
        #my @validSuffixes       = keys %ValidParserMakeArgs ;
        my @validSuffixes       = map { '.'.$_ } keys %ValidParserMakeArgs ;
        
        my $infile = $file;
        
        my($infname, $directories, $insfx)      = fileparse($infile , @validSuffixes);
        croak 'Invalid input file'   unless defined $insfx ;
        $insfx        = lc $insfx ;
        $insfx        = substr $insfx,1;
        
        ### Validate parameters
        die 'Invalid input file'  unless exists $ValidParserMakeArgs{$insfx} ;
        
        ### Build parsers
        
        my %Parsers            = () ;
        $Parsers{${insfx}}     = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${insfx}} } );
        # if input is in a .net language, add in a .net2 parser to the list
        if ( firstidx { $_ eq ${insfx} } ['cs','vb']  != -1 ) {
            $Parsers{"${insfx}2"}  = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${insfx}} } );
        }
        
        ### Deserialise tests 
        eval {
            $testSet         = $Parsers{$insfx}->deserialise($infile);
            } ;
        if ( not defined $testSet ) {
            if ( exists $Parsers{"${insfx}2"}) {
                eval {
                    $testSet     = $Parsers{"${insfx}2"}->deserialise($infile);
                    }
            }            
            else {
                croak 'Parsing failed.'; 
            }
        }
        
    }
    my @existingTests = () ;
    if (defined $testSet) {
        @existingTests = map {$_->testName()}  @{$testSet->tests()};
    }
    
    
    my $database        = databaseName($dbh);

    no warnings;
    my $userName        = $OSNAME eq 'MSWin32' ? Win32::LoginName : ${[getpwuid( $< )]}->[6]; $userName =~ s/,.*//;
    use warnings;
    my $date            = strftime "%d/%m/%Y", localtime;
#warn Dumper $userName ;    
#warn Dumper $ra_columns ;
#exit ;

    my $execs           = ExecSp($dbh) ;

#warn Dumper     $widest_column_name_padding;

    foreach my $exec (@$execs) {
        
        my $ofile = $$exec[0];
        
        (my $fileName = "${ofile}" ) =~ s{[.]}{_} ;
        $fileName =~ s{[\]\[]}{}g ;
        $fileName =~ s{\s}{}g ;
        my $testName = $fileName;

        # if not already defined in the test file (if given)
        if ( (firstidx { $_ eq $testName } @existingTests ) == -1 ) {


            my $checkText    = "";
            my $receivingTable = "" ; 
    
            if ( $runChecks ) {
            
                $checkText    = CheckForExceptions($dbh, $dbh_typeinfo, $$exec[0], $userName, $date, $$exec[1],$$exec[2] ) ;
    
                my $resultsTable = undef ;
                if ( ! defined $checkText || $checkText eq q() ) {
                    $resultsTable = CheckForResults($dbh, $dbh_typeinfo, $$exec[0], $userName, $date, $$exec[1],$$exec[2] ) ;
                }
    #warn Dumper "--------------------------";            
    #warn Dumper $resultsTable;
    #warn Dumper scalar @$resultsTable ;
    #warn Dumper @{$resultsTable->[0]};
                if (defined $resultsTable && scalar @$resultsTable eq 1  && scalar @{$resultsTable->[0]} gt 0 ) {
                    $receivingTable = do { local $"= "\n\t,\t\t" ; "\tdeclare \@ResultSet table\n\t(\t\t@{$resultsTable->[0]} \n\t)" } ;
    #                $receivingTable = do { local $"= "\n\t,\t\t" ; "@{$resultsTable->[0]}" } ;
                }
                #elsif (scalar @$resultsTable gt 1 ) {
                #    $receivingTable = "More than one set of results - can't capture them" } ;
                #}
    #warn Dumper $receivingTable ;         
    #warn Dumper $$exec[2];
            } ;
    
            my $text = Template($dbh, $dbh_typeinfo, $$exec[0], $userName, $date, $$exec[1],$$exec[2],$checkText,$receivingTable ) ;
            $fileName .= ".sql";
        
            my $fh   = IO::File->new("> ${dirs}/${fileName}") ;
        
            if (defined ${fh} ) {
                print {${fh}} $text ;
                $fh->close;
            }
            else {
                croak "Unable to write to ${ofile}.sql.";
            }
        }
    }

exit;
}

sub Template {

    local $_            = undef;

    my $dbh             = shift ;
    my $dbh_typeinfo    = shift ;
    
    my $sut             = shift ;

    my $userName        = shift ;
    my $date            = shift ;

    my $declaration     = shift ;
    my $code            = shift ;

    my $checkText       = shift ;
    my $receivingTable  = shift ;
    
    if (defined $checkText) {
        $checkText = "\t--\t Raises this error:- " . $checkText ;
    }
    else {
        $checkText      = q();
    }
    if ($receivingTable ne '') {
        $code = "insert into \@ResultSet\n\t" . $code ;
    }
    
    
return <<"EOF";


/* AUTHOR
*    ${userName}
*
* DESCRIPTION
*    Tests the minimal case for ${sut}
*    Runs a basic smoke-test.
*
* SUT
*    ${sut}
*
* OTHER
*    Other notes.
*
* CHANGE HISTORY
*    ${date} ${userName}
*    Created.
*/


set nocount on

begin try

    declare \@testStatus varchar(100) 
    set     \@testStatus = 'Passed'

    begin transaction

${checkText}

    ${declaration}

${receivingTable}    

    ${code}
    
    select \@testStatus    


end try
begin catch

    set \@testStatus = 'Failed'

    select \@testStatus
    select error_state()
    select error_message()
    select error_number()

end catch


if \@\@trancount > 0 or xact_state() = -1
    rollback


EOF

}


sub CheckForExceptions {

    local $_            = undef;

    my $dbh             = shift ;
    my $dbh_typeinfo    = shift ;
    
    my $sut             = shift ;

    my $userName        = shift ;
    my $date            = shift ;

    my $declaration     = shift ;
    my $code            = shift ;

    my $sql             =  CheckForExceptionsSQL($declaration,$code) ;

    my @run1_res ;
    my @res_col ;
    my @res_type ;
    my $sth             = $dbh->prepare($sql,{odbc_exec_direct => 1});

    try {
        $sth->execute;
    
        do {
            push @res_type, $sth->{TYPE} ;
            push @res_col,  $sth->{NAME} ;
    
            no warnings;
            push @run1_res, $sth->fetchall_arrayref() ;
            use warnings;
        } while ($sth->{odbc_more_results}) ;
    } catch {
         warn "SUT :- $sut\n";
    };
#warn Dumper @run1_res ;    
    my $err = undef;
    if ( scalar @run1_res && scalar @{$run1_res[0]} && $run1_res[0][0][0] eq 'VSGDR::TestScriptGen - raised exception') {
        $err = $run1_res[0][0][1];
    }
#warn Dumper $err ;        
    return $err;
}
                                    
sub CheckForExceptionsSQL {

    local $_            = undef;

    my $declaration     = shift ;
    my $code            = shift ;
    
return <<"EOF";


set nocount on

begin try

    begin transaction

    ${declaration}
    ${code}
    
end try
begin catch

    select 'VSGDR::TestScriptGen - raised exception', error_message()

end catch


if \@\@trancount > 0 or xact_state() = -1
    rollback


EOF

}

sub CheckForResults {

    local $_            = undef;

    my $dbh             = shift ;
    my $dbh_typeinfo    = shift ;
    
    my $sut             = shift ;

    my $userName        = shift ;
    my $date            = shift ;

    my $declaration     = shift ;
    my $code            = shift ;

    my $sql             =  CheckForResultsSQL($declaration,$code) ;

    my @run1_res ;
    my @res_col ;
    my @res_type ;
    my $sth             = $dbh->prepare($sql,{odbc_exec_direct => 1});

    try {
        $sth->execute;
    
        do {
            push @res_type, $sth->{TYPE} ;
            push @res_col,  $sth->{NAME} ;

            my @names   = map { scalar $dbh_typeinfo->type_info($_)->{TYPE_NAME} }   @{ $sth->{TYPE} } ;
            my @colSize = map { scalar $dbh_typeinfo->type_info($_)->{COLUMN_SIZE} } @{ $sth->{TYPE} } ;

            my @types = () ;
            my @spec  = () ;
#warn Dumper $sth->{TYPE} ;        
#warn Dumper $sth->{NUM_OF_FIELDS} ;        
            if (scalar @names) {
                my $col=1;
                @types = List::MoreUtils::pairwise { $a =~ m{char|binary}ism ? "$a($b)" : "$a" }  @names, @colSize ;
                @spec  = List::MoreUtils::pairwise { ( ($a eq "" ) ? "[Column_" . ${col}++ . "]" : "[$a]" ) . "\t\t\t$b" }  @{$sth->{NAME}}, @types ;
            }

#warn Dumper @spec;
        
            #do { local $"= "\n,\t" ;
            #     say {*STDERR} "ResultSet(\n\t@{spec}\n)";
            #   };
        
            no warnings;
            push @run1_res, \@spec ;
            use warnings;


        } while ($sth->{odbc_more_results}) ;
    } catch {
         warn "SUT :- $sut\n";
    };

    return \@run1_res;
}


sub CheckForResultsSQL {

    local $_            = undef;

    my $declaration     = shift ;
    my $code            = shift ;
    
return <<"EOF";


set nocount on

begin try

    begin transaction

    ${declaration}
    ${code}
    
end try
begin catch

    select 'VSGDR::TestScriptGen - raised exception', error_message()

end catch


if \@\@trancount > 0 or xact_state() = -1
    rollback


EOF

}



1;

__DATA__



=head1 SYNOPSIS

Package to support the generation of stored procedure unit test scripts for SQL Server Data Tools projects.

=head1 AUTHOR

Ded MedVed, C<< <dedmedved@cpan.org> >>


=head1 BUGS


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VSGDR::TestScriptGen


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TestScriptGen
