#!/usr/bin/perl 

=head1 NAME

CUICollector.pl - Scrapes MetaMap Machine Output (MMO) files to build a database of CUI bigram scores. 

=head1 SYNOPSIS

    $ perl CUICollector.pl --directory metamapped-baseline/2014/ 
    CUICollector 0.04 - (C) 2015 Keith Herbert and Bridget McInnes
    Released under the GNU GPL.
    Connecting to database CUI_Bigrams on localhost
    Parsing file: /home/share/data/metamapped-baseline/2014/text.out_01.gz
    Parsing file: /home/share/data/metamapped-baseline/2014/text.out_02.gz
    Parsing file: /home/share/data/metamapped-baseline/2014/text.out_03.gz
    Parsing file: /home/share/data/metamapped-baseline/2014/text.out_02.gz
    Parsing file: /home/share/data/metamapped-baseline/2014/text.out_03.gz
    Entering scores into CUI_Bigrams
    ...
    Finished

=head1 USAGE

Usage: CUICollector.pl [DATABASE OPTIONS] [OTHER OPTIONS] [FILES | DIRECTORIES]

=head1 INPUT

=head2 Required Arguments:

=head3 [FILES | DIRECTORIES]

Specify a directory containing *ONLY* compressed MetaMapped Medical Baseline files:
    --directory /path/to/files/

Multiple directories may also be supplied:
    --directory /path/to/first/folder/ /path/to/second/folder/

Likewise, specify a list of individual files
    --files text.out_01.txt.gz text_mm_out_42.txt.gz text_mm_out_314.txt.gz

a glob of files:
    --files /path/to/dir/*.gz

Or just one:
    --files text.out_01.txt.gz 


=head2 Optional Arguments:


=head3 --database STRING        

Database to contain the CUI bigram scores. DEFAULT: CUI_Bigrams

If the database is not found in MySQL, CUICollector will create it for you. 

=head3 --username STRING

Username is required to access the CUI bigram database on MySql. You will be prompted
for it if it is not supplied as an argument. 

=head3 --password STRING

Password is required to access the CUI bigram database on MySql. You will be prompted
for it if it is not supplied as an argument. 

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --socket STRING

Socket where the mysql.sock or mysqld.sock is located. 
DEFAULT: mysql.sock 

=head3 --port STRING

The port your mysql is using. DEFAULT: 3306

=head3 --file_step INTEGER

How many MetaMap files to read between writes to the database. 
DEFAULT: 5

MMO files can be rather large so setting a low file_step reduces the memory footprint of the script. However, setting a higher file_step reduces the number of write operations to the database.

=head3 --debug 

Sets the debug flag for testing. NOTE: extremely verbose.

=head3 --verbose 

Print the current status of the program to STDOUT. This indicates the files being processed and when the program is writing to the database. This is the default output setting.

=head3 --quiet 

Don't print anything to STDOUT.

=head3 --help

Displays the quick summary of program options.

=head1 OUTPUT

By default, CUICollector prints he current status of the program as it works through the Metamapped Medline Output files (disable with `--quiet`). It creates a database (or connects to an existing one) and adds bigram scores of the CUIs it encounters in the MMO files. 

The resulting database will have four tables:

=over

=item N_11

    cui_1   cui_2   n_11
    
This shows the count (n_11) for every time a particular CUI (cui_1) is immediately followed by another particular CUI (cui_2) in an utterance. 

=back

=head1 AUTHOR

 Keith Herbert, Virginia Commonwealth University
 Amy Olex, Virginia Commonwealth University
 Bridget McInnes, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2015-2017
Keith Herbert, Virginia Commonwealth University
herbertkb at vcu edu 

Amy Olex, Virginia Commonwealth University
alolex at vcu dot edu

Bridget McInnes, Virginia Commonwealth University
btmcinnes at vcu dot edu


This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

###############################################################################
#                               THE CODE STARTS HERE
###############################################################################

use strict;
use warnings;
use Time::HiRes;

use Data::Dumper;       # Helps with debugging
use DBI;                # Database stuff
use Getopt::Long;       # Parse command line options
use File::Type;         # Know when a file is compressed

use feature qw(say);

$|=1;   # toggle buffering to STDOUT. Essential when CPU is fully worked.

###############################################################################
# CONSTANT STRINGS
###############################################################################

my $version = "0.20";
my $header = 
"CUICollector $version - (C) 2015 Keith Herbert and Bridget McInnes, PhD\n"
."Released under the GNU GPL.";

my $usage = $header."\n"
."FLAGS\n"
."--debug       Print EVERYTHING to STDERR.\n"
."--verbose     Print log of files processed to STDOUT (DEFAULT)\n"
."--quiet       Print NOTHING to STDERR or STDOUT.\n"
."--help        Print this help screen.\n"
."DATABASE OPTIONS\n"
."--database    Name of MySQL database to store CUI data. (Default=CUI_Bigrams)\n"
."--hostname    Hostname for MySQL database. (Default=localhost)\n"
."--socket      Socket where the mysql.sock or mysqld.sock is located.\n"
."--username    Username for MySQL access. (Optional, but will be prompted)\n"
."--password    Password for MySQL access. (Optional, but will be prompted)\n"
."MetaMap Machine Output File Options\n"
."--directory   Path to directory containing *only* MetaMap Baseline files\n"
."--files       Explicit list of one or more MetaMap Baseline files\n"
."--file_step   How many files to read between database writes. (DEFAULT=5)\n"
."--plain       All input files are uncompressed.\n"
."NGRAM OPTIONS\n"
."--window N    Window size (DEFAULT: 1)\n"
."--sliding         Use a sliding window\n"
."\nUSAGE EXAMPLES\n"
."Open directory ./metamap/ and write to database CUIs on localhost:\n"
."\tperl CUICollector.pl --database CUIs --directory metamap/\n\n"
."Open single file test.mmb and write to default database:\n"
."\tperl CUICollector.pl --file test.mmb\n"
;

###############################################################################
#                           Parse command line options 
###############################################################################
my $DEBUG = 0;      # Prints EVERYTHING. Use with small testing files.
my $VERBOSE = 1;    # Only print for reading from files, writing to database          
my $HELP = '';      # Prints usage and exits if true.


my $database = "CUI_Bigrams";        # Values needed to connect to MySQL dbase.
my $hostname = "localhost";
my $socket = "/var/run/mysqld/mysqld.sock";
my $port     = "3306";
my $username;
my $password;

my $sliding; 
my $window = 1; 

my $file_step = 3;  # How many files to read between writes to database.
my $gzipped = 1;    
my @dirs    = ();   # Directories containing *only* MetaMap Baseline files
my @files   = ();   # Explicit list of MetaMap Baseline files.

GetOptions( 'debug'         => \$DEBUG, 
            'help'          => \$HELP,
            'verbose!'      => \$VERBOSE,
            'quiet'         => sub { $VERBOSE = 0 },
            'plain'         => sub { $gzipped = 0 }, 
            'database=s'    => \$database,
            'hostname=s'    => \$hostname,
	    'socket=s'      => \$socket,
            'port=s'        => \$port,
            'username=s'    => \$username,
            'password=s'    => \$password,
            'file_step=i'   => \$file_step,
            'directory=s{1,}' => \@dirs,
            'files=s{1,}'   => \@files, 
	    'window=i' => \$window,
	    'sliding' => \$sliding
);

die $usage unless $#ARGV;    
die $usage if $HELP;               
die("Invalid file_step. Must be positive integer") if $file_step < 1;
die "*** No input files ***\n$usage" unless @dirs or @files;

say $header if $VERBOSE;

## Prompt for username/pass if they weren't provided.
if (not defined $username){
    print "Enter username for MySQL server on $hostname: ";
    $username = <STDIN>;
    chomp $username;
}
if (not defined $password){     
    print "Enter password for $username: ";
    $password = <STDIN>;
    chomp $password;
}
 

## Collect all files from input into one massive list.
for my $dir (@dirs) {
    opendir(DIR, $dir) || die "Could not open dir ($dir)\n";
    push @files, grep { $_ ne "$dir." and $_ ne "$dir.." } map { "$dir$_" } readdir DIR; 
    close DIR;
}

## Test if all these files are readable to avoid a nasty surprise later.
for my $file (@files) {
    die "Cannot read $file" unless -r $file;
}

# Presorting makes the console output easier to read.
@files = sort @files;

###############################################################################
#                                   Main 
###############################################################################
{
	
say "Connecting to $database on $hostname" if $VERBOSE;
my $dbh = open_mysql_database($database, $hostname, $port, $username, $password, $socket);

my($filetime_s,$filetime_e,$dbtime_s,$dbtime_e,$total_time_s);


$total_time_s = Time::HiRes::gettimeofday() if $DEBUG;


while (@files) {
    my @curr_files = splice @files, 0, $file_step;
    
    $filetime_s = Time::HiRes::gettimeofday() if $DEBUG;
    my($bigram_ref) = process_files(@curr_files);
    $filetime_e = Time::HiRes::gettimeofday() if $DEBUG;
	
    say "Entering scores into $database..." if $VERBOSE;  
	$dbtime_s = Time::HiRes::gettimeofday() if $DEBUG;
    update_database($dbh, $bigram_ref);
    $dbtime_e = Time::HiRes::gettimeofday() if $DEBUG;
	
    if ($DEBUG) {
        print Dumper($bigram_ref);
    }
}

my $total_time_e = Time::HiRes::gettimeofday() if $DEBUG;

printf("Serial elapsed time for file processing only: %.2f sec\n", $filetime_e - $filetime_s) if $DEBUG;
printf("Serial elapsed time for database update only: %.2f sec\n", $dbtime_e - $dbtime_s) if $DEBUG;
printf("Serial elapsed time for entire Main: %.2f sec\n", $total_time_e - $total_time_s) if $DEBUG;

# Close connection to database                       
$dbh->disconnect;

say "Finished." if $VERBOSE;
}

###############################################################################
#                           Database Subroutines
###############################################################################
sub open_mysql_database {
    my ($dbase, $host, $port, $user, $pass, $socket) = (@_);
    
       # See if database exists in the specified DBMS                        
    my @dbases = DBI->data_sources("mysql",
      {"host" => $host, "user" => $user, 
       password => $pass, "socket"=> $socket});

    my $dbase_exists = grep /DBI:mysql:$dbase/, @dbases;

    # Connect to the database if it exists. Otherwise create it from scratch.
    my $dbh;                
    if ($dbase_exists) {

        $dbh =  DBI->connect("DBI:mysql:database=$dbase;host=$host;"
			     ."mysql_socket=$socket",
			     $user, $pass,
			     {'RaiseError' => 1, 'AutoCommit' => 0});
    } 
    else {
	#connect to the DB and turn AutoCommit Off (value of 1)
        $dbh = DBI->connect("DBI:mysql:host=$host", $user, $pass,
                            {'RaiseError' => 1,'AutoCommit' => 0});
        create_database($dbh, $dbase);
    }

    return $dbh;        # Return the handler to keep connection alive.
}

###############################################################################
sub create_database {
    my $dbh = shift;
    my $dbase = shift;
    
    $dbh->do("CREATE DATABASE $dbase");
    $dbh->do("USE $dbase");
    
     $dbh->do("CREATE TABLE N_11 (   
                    cui_1   CHAR(10)    NOT NULL,
                    cui_2   CHAR(10)    NOT NULL, 
                    n_11    BIGINT      NOT NULL, 
                    PRIMARY KEY (cui_1, cui_2) )"   );
                    
}

###############################################################################
sub update_row {
    my ($dbh,                   # database handler
        $table,                 # name of table being updated
        $updated_field,         # field being updated
        $updated_value,         # value to change in field
        $key_names_ref,         # array ref for key names of table
        $key_values_ref         # array ref to values to locate row in table
    ) = @_;       
        
    
    # Build conditional statement to locate row in table.
    my $conditional = "";
    if (@$key_names_ref) {
        $conditional = join ' AND ', map {"$_ = ? "} @$key_names_ref;
    }
    else {
        $conditional = "$updated_field > -1";
    }
    # Check if row to update is already in table
    my $select = "SELECT * FROM $table WHERE $conditional LIMIT 1";
    say $select if $DEBUG;
    my $sth = $dbh->prepare($select);
    $sth->execute(@$key_values_ref);
            
    # If it is, update entry with new sum.
    my @match = $sth->fetchrow_array();
    if ( @match ) {
        
        $updated_value += $match[-1];
        
        my $update = "UPDATE $table SET $updated_field = ? WHERE $conditional";
                        
        $dbh->do( $update,undef, $updated_value, @$key_values_ref );
    }
    # Otherwise, insert a new row into the table.     
    else {
    
        # Build the insert statement
        my $key_list = join ', ', @$key_names_ref;
        my $field_length = @$key_names_ref;
        my $insert ="INSERT INTO $table ($key_list, $updated_field) " . 
                        "VALUES (" . '?, ' x $field_length . '?' . ")";
        say $insert if $DEBUG;              
        $dbh->do($insert, undef, @$key_values_ref, $updated_value); 
    }
}

##############################################################################
sub update_database {
    my($dbh, $bigram_ref, $n1p_ref, $np1_ref, $npp) = (@_);
    
    # Add all of the bigram counts to the database
    say STDERR "n11:" if $DEBUG;
    foreach my $cui_1 (keys %$bigram_ref){
        foreach my $cui_2 (keys %{$$bigram_ref{$cui_1}}) {
            my $n_11 = $$bigram_ref{$cui_1}{$cui_2};
            
	        say STDERR "$cui_1\t$cui_2\t$n_11" if $DEBUG;
	        
	        update_row($dbh, 'N_11', 'n_11', $n_11, 
	            ['cui_1', 'cui_2'], [$cui_1, $cui_2] );
        }
    }
    $dbh->commit or die $dbh->errstr;
}

###############################################################################
#                       This is where the magic happens 
###############################################################################

sub process_files {
    my @files = @_;
    
    my %bigrams;   # cui_1 => cui_2 => sum of cui_1 preceeding cui_2
            
    # Anonymous subroutine to update the bigram and marginal counts
    my $incrementor = sub {
        my($cui_1, $cui_2) = @_;
	$bigrams{$cui_1}{$cui_2}++;
    };
    
    for my $file (@files) {
        
        if( File::Type->mime_type($file) =~ /x-gzip/) {
	    #unzip file to temp
	    my $tempFileName = $file.'_temp';
	    !(system "gunzip -c $file >$tempFileName -f -q") 
		or die "error gunzipping $file\n";	  
 	    
	    #process temp as normal
            process_file($tempFileName, $incrementor);

	    #remove temp file
	    system "rm $tempFileName";
        }
        else {
            process_file($file, $incrementor);
        }
    }
    
    return (\%bigrams); 
}
###############################################################################
sub process_file {
    my $file = shift;           # text/plain file to process
    my $incrementor = shift;    # ref to anon sub that updates bigram counts
    
    open(my $fh, '<', $file) or die "Cannot read $file: $!";    #fh = filehandle
    say "Parsing uncompressed file: $file" if $VERBOSE;
    
    until (eof $fh ){
        count_bigrams( read_utterance( $fh ), $incrementor );
    }
}

###############################################################################
# take filehandle as lexical variable
# returns ref to array of phrases for single utterance
sub read_utterance {
    my $fh = shift;
   
    my @phrases_in_utterance;

    my $pid = "";  
    # The following loop will iterate over all the phrases for this utterance
    while (<$fh>) {
	chomp; 

	if($_=~/utterance\(\'(.*)\.(ti|ab)\.[0-9]+/) { 
	    my $cid = $1; 
	    if($DEBUG == 1) { print STDERR "IDs: $cid  $pid\n"; }
	    if($pid ne "" && $cid ne $pid)  { 
		seek($fh, -length($_), 1); 
		last; 
	    }
	    $pid = $cid; 
	}
	
	# Skip all lines that aren't mappings for a phrase in the utterance
        next unless /^mappings/;
      	
	my @mappings = @{ get_mappings($_) };
	
	push @phrases_in_utterance, \@mappings if @mappings;
	
    }

    return \@phrases_in_utterance;
}

###############################################################################
sub get_mappings {
    my $mapping_string = shift;    # the line for which /^mappings/ is true
    
    # Break mappings into each possible mapping of phrase into CUIs
    my @maps = split /map\(/, $mapping_string;

    # Collect the CUIs in each possible mapping (assumes format 'C1234567')
    # as a set of strings
    my @mappings;           
    for my $map (@maps) {
        
       my $CUI_string = join " ", ( $map =~ m/C\d{7}/g );
       
       say $CUI_string if $CUI_string and $DEBUG;
       
       push @mappings, $CUI_string if $CUI_string; 
    }

    return \@mappings;
}

###############################################################################
sub count_bigrams {
    my( $phrases_ref,   # reference to list of mappings for single utterance 
        $incrementor    # anonymous subroutine to update counting hashes
        ) = @_;
        
    my @phrases = @$phrases_ref;

    my %tree = (); my $hid = 0; 
    
    for (my $i = 0; $i <= $#phrases; $i++) {
	my @phrase = @{$phrases[$i]}; 
	my $j = 0; my $increment = 1; 
	foreach $j (0..$#phrase) { 
	    my @cuis = split/\s+/, $phrase[$j]; 
	    foreach my $k (0..$#cuis) { 
		$tree{$hid+$k}{$cuis[$k]}++;
		my $temp = $hid + $k; 
		if($DEBUG == 1) { print STDERR "$cuis[$k] $temp\n"; }
	    }
	    $increment = $#cuis + 1; 
	}
	$hid += $increment; 
    }

    if(defined $sliding) { 
	foreach my $id (sort {$a<=>$b} keys %tree) { 
	    foreach my $cui (sort keys %{$tree{$id}}) { 
		for my $s (1..$window) { 
		    for my $w (1..$s) { 
			my $k = $w+$id; 
			foreach my $c (sort keys %{$tree{$k}}) { 
			    $incrementor->($cui, $c);
			    if($DEBUG == 1)  { print STDERR "ADDING $cui $c\n"; }
			}
		    }
		}		    
	    }
	}
    }
    else { 
	foreach my $id (sort {$a<=>$b} keys %tree) { 
	    foreach my $cui (sort keys %{$tree{$id}}) { 
		for my $w (1..$window) { 
		    my $k = $w+$id; 
		    foreach my $c (sort keys %{$tree{$k}}) { 
			$incrementor->($cui, $c);
			if($DEBUG == 1)  { print STDERR "ADDING $cui $c\n"; }
		    }
		}		    
	    }
	}	
    }
}
