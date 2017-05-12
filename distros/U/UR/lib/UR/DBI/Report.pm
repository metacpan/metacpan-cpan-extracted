

=pod

=head1 NAME

UR::DBI::Report - a database report interface

=head1 SYNOPSIS

  ##- use UR::DBI::Report;  
  UR::DBI::Report->use_standard_cmdline_options();
  UR::DBI::Report->generate(sql => \@ARGV);
  

=head1 DESCRIPTION

This module is a reporting interface which takes SQL queries in a variety of forms
and prints their results with formatting options.

=cut


use strict;
use warnings;

package UR::DBI::Report;
use base 'UR::ModuleBase';
require UR;
our $VERSION = "0.46"; # UR $VERSION;

use Data::Dumper;
use Time::HiRes;

# Support some options right on the "use" line. 

sub import 
{
    my $class = shift;
    my %params = @_;
    UR::DBI::Report->extend_command_line() if delete $params{extend_command_line};
    die "Unknown options passed-to " . __PACKAGE__ . join(", ", keys %params) if keys %params;
}


# Applications which do no additional configuration will get these parameters by default.

our %module_default_params =
(
    delimit => 'spaces',
    header => 1,
    count => 1,
    orient => 'vert',
    trunc => 35,
    sloppy => 0,
    nulls => 1,
    data => 1,
    combine => 0,
    "explain-sql" => 0,
);

# Applications which call this method before init() will allow the user 
# to override reporting defaults via standard command line options.

our %application_default_params = %module_default_params;

sub extend_command_line
{    
    # this callback processes all of the options and sets application defaults for this module
    my $parse_option_callback;
    $parse_option_callback = 
        sub
        {
            my ($flag,$value) = @_;
            if ($flag eq 'parse')
            {
                $parse_option_callback->("header",!$value);
                $parse_option_callback->("count",!$value);
                $parse_option_callback->("delimit",($value ? "tabs" : "spaces"));
                $parse_option_callback->("trunc",($value ? undef : $application_default_params{"trunc"}));
                return 1;
            }
            
            $application_default_params{$flag} = $value;
            return 1;
        };
    
    # ask Getopt to expect some new cmdline parameters
    UR::Command::Param->add(
        map { 
            if (ref($_)) {
               $_->{module} = "Data Report Formatting" 
            }
            $_;
        } 
        delimit =>
        {
            action => $parse_option_callback,
            msg => "spaces|tabs: spaces separate columns evenly, tab-delimited columns are easiliy parsed",
            argument => '=s',
            option => '--delimit',
        },
        header =>
        {
            action => $parse_option_callback,
            msg => "Show column headers.",
            argument => '!',
            option => '--header',
        },
        data =>
        {
            action => $parse_option_callback,
            msg => "Show returned query data (on by default!).",
            argument => '!',
            option => '--data',
        },    
        count =>
        {
            action => $parse_option_callback,
            msg => "Show row count at the end of output.",
            argument => '!',
            option => '--count',
        },
        orient =>
        {
            action => $parse_option_callback,
            msg => "vert: (default) one row per output line, horiz: one row per output column.",
            argument => '=s',
            option => '--orient',
        },
        trunc =>
        {
            action => $parse_option_callback,
            msg => "Set column truncation for long values.  A zero setting truncates at the level of the default DBI LongReadLen; see DBI documentation for details.",
            argument => '=s',
            option => '--trunc',
        },
        sloppy =>
        {
            action => $parse_option_callback,
            msg => "When processing multiple SQL statements and a failure occurs, just proceed to the next statement.",
            argument => '!',
            option => '--sloppy',
        },
        nulls =>
        {
            action => $parse_option_callback,
            msg => "Show nulls.  When turned-off with 'no-nulls' replaces them with a ?.",
            argument => '!',
            option => '--nulls',
        },
        parse =>
        {
            action => $parse_option_callback,
            msg => "Equivalent to --noheader --nocount --tabs --trunc=0",
            argument => '!',
            option => '--parse',
        },
        echo =>
        {
            action => $parse_option_callback,
            msg => "Print SQL before its first execution.  Does not print multiple times on multiple executes with different params.",
            argument => '!',
            option => '--echo',
        },
        combine => 
        {
            action => $parse_option_callback,
            msg => "When executing the same query multiple times with different params, combine the results as though it were one query.",
            argument => '!',
            option => '--combine',    
        },
        "explain-sql" => 
        {
            action => $parse_option_callback,
            msg => "Dump a query plan instead of running the query.",
            argument => '!',
            option => '--explain-sql',
        }
    );

}

#
# This method executes the specified sql statements and prints reports for each.
#

sub generate
{
    my $class = shift;
    my %params = (%application_default_params, @_);

    my $sql_param = delete $params{sql};
    my @queries = (ref($sql_param) ? (@$sql_param) : ($sql_param) );
    
    my $dbh = delete $params{dbh};
    unless ($dbh) {
        Carp::confess("No dbh sent to UR::DBI::Report, and no default available anymore!");
    }

    $dbh->{LongTruncOk} = 1;
    if ($params{trunc})
    {
        $dbh->{LongReadLen} = $params{trunc};
    }
    elsif(defined($params{trunc}))
    {
        warn "Setting the trunc value to 0 does not guarantee no truncating.";
        warn "There is no way to completely prevent truncating in the current version of DBI.";
        warn "The current trunc limit is $dbh->{LongReadLen}.";
        warn "If this does not satisfy your needs, try setting trunc to a higher number";
    }


    # The outer loop runs once per SQL statement.
    my $sql_request;
    while($sql_request = shift(@queries))
    {
        # The SQL comes from the cmdline or STDIN.
        my $sql;
        if ($sql_request eq '-')
        {
            $sql = '';
            while (<STDIN>)
            {
                next if (/^#!/);
                if (/;\s*$/)
                {
                    s/;\s*$//;
                    $sql .= $_;
                    last;
                }
                else
                {
                    $sql .= $_;
                }
            }
        }
        else
        {
            $sql = $sql_request;
        }
        
        next if ($sql !~ /\S/);
        
        chomp($sql);
        print "SQLRUN: $sql\n" if $params{echo};

        
        # See if we expect paramters from STDIN
        my $question_marks = $sql;
        $question_marks =~ s/[^\?]//msg;
        my $question_mark_count = length($question_marks);

        if ($params{"explain-sql"}) {
            my $outfh = IO::Handle->new;
            $outfh->fdopen(fileno(STDOUT), 'w');
            UR::DBI::_print_query_plan($sql,$dbh,outfh => $outfh,%params);
            
            # skip past any parameters, since we're not really executing,
            # and they don't (can't) affect the query plan
            if ($question_mark_count)
            {
                my $data;
                while (1)
                {
                    $data = <STDIN>;
                    chomp $data;
                    last unless (defined($data) and length($data));
                } 
            }
            
            # redo if we're reading from stdin, otherwise go to the next specified cmd
            if ($sql_request eq '-') {
                redo;
            }
            else {
                next;
            }
        }
        
        # This will never get re-prepared
        my $sth = $dbh->prepare_cached($sql);
        
        unless($sth)
        {
            if ($params{sloppy})
            {
                App::UI->error_message($dbh->errstr);
                next;
            }
            else
            {
                die $dbh->errstr;
            }
        }

        # This flag may be set after the first parameter set runs to speed further executions.
        
        # The inner loop runs once per required execution of the SQL.
        # SQL is executed multiple times if there are ? placeholders and there are multiple lines on STDIN
        my ($combine_row_count, $combine_time)=(0, 0);
        my $sql_execution_count = 0;
        my $statement_is_not_a_query = 0;
        my $outfh = $params{outfh};        
        for (1)
        {
            # Get params from STDIN if necessary
            my @params;
            if ($question_mark_count)
            {
                # Get data from STDIN as needed for any ?s.
                my $data = <STDIN>;
                chomp $data if defined($data);

                # If we have a ? count and there is no data on this line, we're done with this SQL statement.
                unless (defined($data) and length($data))
                {
                    # We want to warn the user if a SQL statement had no params at all.
                    if ($sql_execution_count == 0)
                    {
                        $class->error_message("No params!");
                    }
                    # On to the next staement, if there is one.
                    last;
                }
                @params = split(/\t/, $data);
                $#params = $question_mark_count - 1;
                
                if ($params{echo})
                {       
                    print "PARAMS: @params\n";
                }                
            }
            
            # Note the time so we can show the elapsed time.
            my $t1 = Time::HiRes::time();

            # Execute the current statement with the parameters.
            my $execcnt;
            
            unless ($execcnt = $sth->execute(@params))
            {
                my $msg = "Failed to execute SQL:\n$sql\n" . (@params ? "Data:\n>" . join(",",@params) . "<\n" : '') . $sth->errstr;
                if ($params{sloppy})
                {
                    App::UI->error_message($msg);
                }
                else
                {
                    die $msg;
                }
            }
            
            # Count these for better error messaging.
            $sql_execution_count++;
            
            # Count results returned (SQL) or affected (DML).
            my $rowcnt;
            
            # This flag may not be set until we try to get the first result.
            unless ($statement_is_not_a_query)
            {
                $rowcnt = UR::DBI::Report->print_formatted(
                    sth => $sth,
                    outfh => $outfh,
                    (
                        $params{combine} 
                        ? (position_in_combined_sql_list => $sql_execution_count)
                        :()
                    ),
                    %params
                );
                $statement_is_not_a_query = 1 if defined($rowcnt) and ($rowcnt eq "0 because the statement is not a query");
            }
            
            # Flush any data pending to the output filter.
            if (ref($outfh) and not $params{combine} and not $params{outfh}) {
                $outfh->close;
                $outfh = undef;
            }
            
            $sth->finish;
            
            # Summarize the effect of the query/dml.
            if ($params{count}) {
                if($params{combine}) {
                    #If we're doing a combined output, we'll have to tally these up for later
                    $combine_row_count+=$statement_is_not_a_query?($execcnt+0):($rowcnt+0);
                    $combine_time+=Time::HiRes::time()-$t1;
                } else {
                    my $td = Time::HiRes::time() - $t1;
                    $td =~ s/(\.\d\d\d).*/$1/;
                    if ($statement_is_not_a_query)
                    {
                        print (($execcnt+0) . " row(s) affected.  Execution time: ${td} second(s).\n");
                    }
                    else
                    {
                        print (($rowcnt+0) . " row(s) returned.  Execution time: ${td} second(s).\n");
                    }
                }
            }
            
            # By default this block will execute just once.
            # Continue if there is a question_mark_count.
            # It will "last" out at the top if there is no more data on stdin.
            redo if $question_mark_count;
            
        } # end params loop        

        if ($params{combine}) {
            $outfh->close if ref($outfh) and not $params{outfh};
            if ($params{count})
            {
                $combine_time=~s/(\.\d\d\d).*/$1/;
                print("$combine_row_count row(s) ".($statement_is_not_a_query?'affected':'returned').
                      ".  Execution time: $combine_time second(s).\n");

            }
        }

        # If the cmdline sql was a dash, we're reading from STDIN until it exits the loop.
        redo if $sql_request eq '-';
        
    } # end SQL loop
   
   # Done executing all SQL.
   return 1;
   
} # end of sqlrun subroutine

# This method prints a single report for a given statement handle.

sub print_formatted
{
    my $class = shift;
    my %params = (%application_default_params, @_);
    
    # sth       A statement handle from which the data comes.
    # sql       If no handle is specified, the SQL to use.
    # infh      If no sth or sql is specified, a handle from which sql can be pulled.
    #           If sth or sql ARE specifed, a handle from which parameter values can be pulled.
    
    my $sth = delete $params{sth};
    unless ($sth) {
        
    }
    
    # outfh     An optional handle to which the report is written.
    
    my $outfh = delete $params{outfh};    
    if ($outfh) {
        if ($params{delimit} =~ /^s/i && $^O ne "MSWin32" && $^O ne 'cygwin')
        {
            # We only handle one case of $outfh and still do tab2col.
            # If it's stderr, we redirect there.
            $outfh = IO::File->new('| tab2col --nocount 1>&' . fileno($outfh));
            Carp::confess("Failed to pipe through tab2col!") unless $outfh;
        }    
    }
    else {
        if ($params{delimit} =~ /^s/i)
        {
            # Handle tab-delimit via tab2col
            $outfh = IO::File->new("| tab2col --nocount");
        }
        else
        {
            $outfh = IO::Handle->new;
            $outfh->fdopen(fileno(STDOUT), 'w');
        }
    }
    
    # This is the return value.
    # Set to an integer, or to the false-valued string "0 because the statement is not a query".
    my $rowcnt = 0;
    
    # Get the column names into an array of headers.
    my @headers = @{ $sth->{NAME_uc} };
    
    
    # Display as needed according the requested orientation.
    if ($params{orient} =~ /^v/i)  # lines listed vertically
    {
        # Get the first row, but re-hook warnings first to see if we
        # are really running a query wich can return data (not DML).
        my $msg;
        local $SIG{__WARN__} = sub { $msg = shift };
        
        my $row = $sth->fetchrow_arrayref;

        if ($msg =~ /ERROR no statement executing/)
        {
            # Set this flag so we do not re-try fetch*() on this query.
            return "0 because the statement is not a query";
        }
        elsif ($sth->errstr) {
            die $sth->errstr;
        }
        else
        {
            if ($params{data})
            {
                # Spacers are dashes.
                my @spacers = @headers;
                for (@spacers) { $_ =~ s/./-/g }
                
                # Print the headers, a line of spacers, then one line for each result row.
                if ($params{header} and not ($params{combine} and $params{position_in_combined_sql_list} > 1))
                {
                    if (my $trunc = $params{trunc})
                    {
                        for my $row (\@headers, \@spacers)
                        {
                            print $outfh join("\t", map { substr($_,0,$trunc) } @$row) . "\n";
                        }                                
                    }
                    else
                    {
                        for my $row (\@headers, \@spacers)
                        {
                            print $outfh join("\t",@$row) . "\n";
                        }
                    }
                }                            
                
                # Print the initial row, and any others we can fetch().
                while ($row)
                {
                    print $outfh join("\t",@$row) . "\n";
                    $rowcnt++;
                    $row = $sth->fetchrow_arrayref;
                }
                
            }
            else
            {
                # Just get the count
                while ($row) { $rowcnt++; $row = $sth->fetchrow_arrayref }
            }
        }
    }
    elsif ($params{orient} =~ /^h/i)
    {
        my $msg;
        local $SIG{__WARN__} = sub { $msg = shift };
        
        my $results = $sth->fetchall_arrayref;
        
        if ($msg =~ /ERROR no statement executing/)
        {
            # Set this flag so we do not re-try fetch*() on this query.
            return "0 because the statement is not a query";
        }
        else
        {
            # Process the fetched data.
            $rowcnt = scalar(@$results);
            
            if ($params{data})
            {
                # Show the data
                my $cnum = 0;
                
                if (my $trunc = $params{trunc})
                {
                    for my $header (@headers)
                    {
                        print $outfh $header . "\t:\t" if ($params{header});
                        print $outfh join("\t", map { substr($_->[$cnum],0,$trunc) } @$results) . "\n";
                        $cnum++;
                    }                            
                }
                else
                {                            
                    for my $header (@headers)
                    {
                        $outfh->print($header . "\t:\t") if ($params{header});
                        $outfh->print(join("\t", map { $_->[$cnum] } @$results) . "\n");
                        $cnum++;
                    }
                }
            }
        }
    }
    else
    {
        $class->error_message("Unknown orientation $params{orient}");
        return;
    }

    return $rowcnt;
}

1;

