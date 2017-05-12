# 	@(#)SecureSql.pm	1.1	12/30/97
#From olivier_mary@studio.disney.com  Wed Nov 26 07:14:32 1997
#
#     Hi michael I wrote the following package.
#     It executes what I call SecureSql queries.
#     It allows you to execute several queries in a single transaction
#     and have the full transaction rollback if any query shoud fail.
#     You just have to give an array of query as an arguement. You can 
#     surround some of the queries with checksql begin and checksql end 
#     statement. Any queries between these two statements will be excuted in 
#     a transaction.
#     EG:
#     (
#     select * from ...,
#     checksql begin,
#     delete from ...
#     delete from ...
#     checksql end,
#     checksql begin,
#     select * from ...,
#     checksql end
#     )
#     The two delete statements will be executed in a single transaction if 
#     the first delete statement produce an error the second won't be 
#     excuted : the entire transaction will be rollback and any further 
#     query in the transaction will be ignored.
#     The last select will be executed in a transaction.
#     
#     Any interest ?
#     (Or maybe there is an easier way to do it ?)
#     
#     Cheers
#     Olivier
#     -----------------------------------------------------------

package Tbrs::CTlib_Call;

use Sybase::CTlib;
use strict;
#This package is used to export sub and symbols
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA=qw(Exporter);
@EXPORT=qw(Secure_sql_Print Secure_sql);


#Function that execute "secure sql"
#
#$dbh           : valid database handle
#$q_ref         : reference of an array of sql queries
#separated by checksql begin and checksql end statements.
#$cb_names      : reference to a callback function to handles the column names
#$cb_types      : reference to a callback function to handles the column types 
#$cb_dat        : reference to a callback function to handles every row of data 
#$verbose       : print the sql queries performed if defined (eg:equal to 1)
#
#In the array of queries, you can encapsulate several ones
#between checksql begin and checksql end statements.
#The queries between these two statements will be executed in a
#transaction. The full transaction being rollback-ed
#if any of the query should fail.
sub Secure_sql
        {
	my($dbh,$q_ref,$cb_names,$cb_types,$cb_dat,$verbose)=@_;

        #Definitions
        my $begin='^\s*checksql\s+begin\s*$';
        my $end='^\s*checksql\s+end\s*$';
        my $q_begin="begin tran";
        my $q_commit="commit tran";
        my $q_rollback="rollback tran";
        my @q=@{$q_ref};
        my $abort="";
        my($in_secure,$q,$rc,$restype,$count,@names,@dat,@types)
;
        
        #Check that the the array of query is properly formatted with 
        #checksql begin and checksql end statements.
        #* checks there's the same number of 
        #checksql begin and checksql end
        #* checks that a checksql end follow a checksql begin
        $count=0;
        foreach $q (@q)
                {
                print STDERR "Badly nested  $begin and $end\n",return if($count > 1 or $count < 0);
                $count++ if($q=~/$begin/i);
                $count-- if($q=~/$end/i);
                }
        print STDERR "There is not the same number of $begin and $end\n",return if($count);
         
        #This flag allow to know if we're in
        #a secure set of sql queries
        #(To be placed in a transaction with the rollback option)
        $in_secure="";
        #Process the array of query
        foreach $q (@q)
                {
                #if the query is equal to checksql begin
                #replace it by a begin tran
                #Put the abort to flag to null
                if($q=~/$begin/i)
                        {
                        $abort="";      
                        $in_secure="1";
                        $q=$q_begin;
                        }
                #if the query is equal to checksql end 
                #replace it by a commit tran
                #Put the abort to flag to null
                if($q=~/$end/i)
                        {
                        $abort="";
                        $in_secure="";
                        $q=$q_commit;
                        }
                #If abort flag is on escape this query
                next if($abort);
                verbose($q) if($verbose);
                $dbh->ct_execute($q);
                #Check the result of the query
                while(($rc = $dbh->ct_results($restype)) == CS_SUCCEED)
                        {
                        #In case of a fail the abort flag is set on
                        if($restype == CS_CMD_FAIL  and $in_secure)
                                {
                                $abort=1;
                                }
                        next if($restype == CS_CMD_DONE || $restype == CS_CMD_FAIL || $restype == CS_CMD_SUCCEED);
                        #If a callback function is defined
                        if($cb_names and @names = $dbh->ct_col_names())
                                {
                                #Call to the callback function giving @names 
                                #as an argument
                                &{$cb_names}(@names);
                                }
                        if($cb_types and @types = $dbh->ct_col_types())
                                {
                                &{$cb_types}(@types);
                                }
                        if($cb_dat)
                                {
                                while(@dat = $dbh->ct_fetch)
                                        {
                                        &{$cb_dat}(@dat);
                                        }
                                }
                        }
                #If the abort flag is on rollback the transaction
                if($abort and $in_secure)       
                        {
                        verbose($q_rollback) if($verbose);
                        $dbh->ct_sql($q_rollback);
                        }
                }
        }

#Secure_sql_Print
#
#$dbh           : valid database handle
#$q_ref         : reference of an array of sql queries
#separated by checksql begin and checksql end statements.
#$verbose       : print the sql queries performed if defined (eg:equal to 1)
#
#This function is an example of use of Secure_sql
#It prints the results of the query on the specified format
#using the callback function defined
#
sub Secure_sql_Print
        {
        my($dbh,$q_ref,$verbose)=@_;
        my $cb_names=sub{
                my(@tab)=@_;
                my $val=join("\t",@tab);
                print $val."\n".'-' x (2*length($val))."\n";
                };
        my $cb_dat=sub{my(@tab)=@_;print join("\t",@tab)."\n"};
        Secure_sql($dbh,$q_ref,$cb_names,"",$cb_dat,$verbose);
        }

#Function that handles 
#the verbose option
sub verbose
        {
        my($val)=@_;
        print "**** $val ****\n";
        }

1;
__END__
