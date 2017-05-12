# $Id: BCP.pm,v 1.7 2004/04/13 20:03:05 mpeppler Exp $
# from	@(#)BCP.pm	1.15	03/05/98
#
# Copyright (c) 1996-1999
#   Michael Peppler
#
#   You may copy this under the terms of the GNU General Public License,
#   or the Artistic License, copies of which should have accompanied
#   your Perl kit.

package Sybase::BCP;

=head1 NAME

Sybase::BCP - Simple front end to the Sybase BCP API

=head1 SYNOPSIS

    use Sybase::BCP;

    $bcp = new Sybase::BCP ...;
    $bcp->config(...);
    $bcp->run;


=head1 DESCRIPTION

The Sybase::BCP module serves as a simplified front end for Sybase's Bulk
Copy library. It is sub-classed from the L<Sybase::DBlib> module, so all the
features of the Sybase::DBlib module are available in addition to the
specific Sybase::BCP methods.

So how does it work?

Let's say we want to copy the contents of a file name 'foo.bcp' into the
table 'mydb.dbo.bar'. The fields in the file are separated by a '|'.

    #!/usr/local/bin/perl

    use Sybase::BCP;

    $bcp = new Sybase::BCP $user, $passwd;
    $bcp->config(INPUT => 'foo.bcp',
		 OUTPUT => 'mydb.dbo.bar',
		 SEPARATOR => '|');
    $bcp->run;

That's it!

Of course, there are several things you can do to cater for non-standard
input files (see B<Configuration Parameters>, below).

=head2 Features

=over 4

=item * Automatic conversions from non-standard date formats.

=item * Automatic retries of failed batches.

If there are errors in the input file, or if there are duplicat rows that are
rejected, the invalid rows are stored in an error log file, and the batch is
retried, so that only the failed rows are not uploaded.

=item * Handles column reordering and/or skipping of unneeded data.

=item * Row or column based callbacks.

Allows vetoing of rows, or arbitrary processing of data on input.

=back

=head2 The following methods are available:

=over 4

=item $bcp = new Sybase::BCP [$user [, $password [, $server [, $appname]]]]

Allocate a new B<BCP> handle. Opens a new connection to Sybase via the
B<Sybase::DBlib> module, and enables BCP IN on this handle.

=item $bcp->config([parameters])

Sets up the Bulk Copy operation. See B<Configuration Parameters> below for
details.

=item $bcp->describe($colid, {parameters})

Adds a specific configuration element for column $colid. Columns are numbered
starting at 1, as is standard in the Sybase APIs.

=item $bcp->run

Perform the B<BCP> operation, returns the actual number of rows sent to the
server.

=back

=head2 Configuration Parameters

The general form for configuration is to pass (parameter => value) pairs
via the config() or describe() methods. Some parameters take slightly more
complex arguments (see B<REORDER>).

=head2 Paramaters for config()

=over 4

=item DIRECTION

The direction in which the bulkcopy operation is done. Can be 'IN' or 'OUT'.
Default: 'IN' (I<Note:> 'OUT' is not implemented yet.)

=item INPUT

Where B<BCP> should take it's input from. It's a filename for B<bcp IN>, it's
a table name for B<bcp OUT>.

For B<bcp IN> B<INPUT> can also be a reference to a perl subroutine that
returns the array to be inserted via bcp_sendrow().

=item OUTPUT

Where B<BCP> should place it's output. It's a table name for B<bcp IN>, a
filename for B<bcp OUT>.

=item ERRORS

The file where invalid rows should be recorded. Default: bcp.err.

=item SEPARATOR

The pattern that separates fields in the input file, or that should be used
to separate fields in the output file. Default: TAB.

=item RECORD_SEPARATOR

The pattern that separates records (rows) in the input file. Sybase:BCP will
set a local copy of $\ to this value before reading the file. Default: NEWLINE.

=item FIELDS

Number of fields in the input file for B<bcp IN> operations. Default: Number
of fields found in the first line. This parameter is ignored for B<bcp OUT>.

=item BATCH_SIZE

Number of rows to be batched together before committing to the server for
B<bcp IN> operations. Defaults to 100. If there is a risk that retries could
be requiered due to failed batches (e.g. duplicat rows/keys errors) then
you should not use a large batch size: one failed row in a batch requires
the entire batch to be resent.

=item NULL

A pattern to be used to detect NULL values in the input file. Defaults to
a zero length string.

=item DATE

The default format for DATE fields in the input file. The parameter should
be a symbolic value representing the format. Currently, the following values
are recognized: CTIME (the Unix ctime(3) format), or the numbers 0-12,
100-112, corresponding to the conversion formats defined in table 2-4 of
the I<SQL Server Reference Manual>.

B<BCP> detects I<datetime> targets by looking up the target table
structure in the Sybase system tables.

=item REORDER

The ordering of the fields in the input file does not correspond to the
order of columns in the table, or there are columns that you wish to
skip. The REORDER parameter takes a hash that describes the reordering
operation:

    $bcp->config(...
		 REORDER => { 1 => 2,
			      3 => 1,
			      2 => 'foobar',
			      12 => 4},
		 ...);

In this example, field 1 of the input file goes in column 2 of the table,
field 3 goes in column 1, field 2 goes in the column named I<foobar>, and
field 12 goes in column 4. Fields 4-11, and anything beyond 12 is skipped.
As you can see you can use the column I<name> instead of its position.
The default is to not do any reordering.

=item CALLBACK

The callback subroutine is called for each row (after any reordering), and
allows the user to do global processing on the row, or vetoing it's
processing. Example:

    $bcp->config(...
                 CALLBACK => \&row_cb,
                 ...);

    sub row_cb {
	my $row_ref = shift;

	# Skip rows where the first field starts with FOO:
	return undef if $$row_ref[0] =~ /^FOO/;

	1;
    }

=item CONDITION

A I<where> clause to be used in B<bcp OUT> operations. Not implemented.

=back

=head2 Parameters for describe()

=over 4

=item CALLBACK

Specify a callback for this column. The field value is passed as the first
parameter, and the callback should return the value that it wants B<BCP>
to use. Example:

    $dbh->describe(2, {CALLBACK, \&col_cb});

    sub col_cb {
	my $data = shift;

	# Convert to lower case...
	$data =~ tr/A-Z/a-z/;
    }

=item SKIP

If this is defined then this field is skipped. This is useful if only one or
two fields need to be skipped and you don't want to define a big REORDER hash
to handle the skipping.

=back

=head1 EXAMPLES

    #!/usr/local/bin/perl
    
    use Sybase::BCP;
    require 'sybutil.pl';

    $bcp = new Sybase::BCP sa, undef, TROLL;

    $bcp->config(INPUT => '../../Sybperl/xab',
	         OUTPUT => 'excalibur.dbo.t3',
   	         BATCH_SIZE => 200,
	         FIELDS => 4,
	         REORDER => {1 => 'account',
			     3 => 'date',
			     2 => 'seq_no',
			     11 => 'broker'},
	         SEPARATOR => '|');
    $bcp->run;


=head1 BUGS

The current implementation seems to run about 2.5 to 3 times slower than
plain bcp.

=head1 AUTHOR

Michael Peppler F<E<lt>mpeppler@peppler.orgE<gt>>. Contact the sybperl mailing
list C<mailto:sybperl-l@listproc.net> if you have any questions.

=cut

# A module implementing a generalized Bulk Copy API.
# This version requires sybperl 2.04.

use Sybase::DBlib qw(2.04);
use Carp;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION $Version);

@ISA = qw(Exporter Sybase::DBlib);
@EXPORT = qw(dbmsghandle dberrhandle TRUE FALSE INT_CANCEL SYBESMSG $DB_ERROR);

use strict;
use warnings;

$VERSION = substr(q$Revision: 1.7 $, 10);
$Version = q|$Id: BCP.pm,v 1.7 2004/04/13 20:03:05 mpeppler Exp $|;

my @g_keys = qw(INPUT OUTPUT ERRORS SEPARATOR FIELDS BATCH_SIZE
	     NULL DATE REORDER CALLBACK TAB_INFO DIRECTION CONDITION
             LOGGER RECORD_SEPARATOR);
my @f_keys = qw(CALLBACK SKIP);
my %g_keys = map { $_ => 1 } @g_keys;
my %f_keys = map { $_ => 1 } @f_keys;

my %date_fmt =
(CTIME => \&_datectime,
 101 => \&_date101,
 # 102 => \&_date102, This one is probably automatic...
 103 => \&_date103,
 104 => \&_date104,
 105 => \&_date105,
 106 => \&_date106,
 # 107 => \&_date107, This one's probably automatic...
 110 => \&_date110,
 111 => \&_date111,
 112 => \&_date112);


sub new {
    my($package, $user, $passwd, $server, $appname) = @_;
    my($d);
    
    BCP_SETL(TRUE);		# Turn BCP_IN on.
    
    # Grumble... with warnings turned on, we get 'Use of unitialized...'
    $user = '' unless $user;
    $passwd = '' unless $passwd;
    $server = '' unless $server;
    $appname = '' unless $appname;
    
    $d = new Sybase::DBlib $user,$passwd,$server,$appname,
{Global => {}, Cols => {}};
bless $d, $package if $d;
}

sub DESTROY {
    my $self = shift;
    
    # Make sure we close the Sybase::DBlib connection.
    $self->SUPER::DESTROY;
}


sub config {
    my($self, %ref) = @_;
    my($key, $errs);
    
    foreach $key (keys(%ref)) {
	if(!defined($g_keys{$key})) {
	    carp "$key is not a valid Sybase::BCP key";
	    ++$errs;
	}
    }
    croak "Sybase::BCP processing aborted because of errors\n" if($errs);
    $ref{DIRECTION} = 'IN' unless ($ref{DIRECTION});
    $self->{Global} = {%ref};
    # Get the table definition from Sybase system tables:
    $self->{Global}->{TAB_INFO} = $self->_gettabinfo($self->{Global}->{OUTPUT})
	if($ref{DIRECTION} eq 'IN'); ### FIXME
    
    1;
}

sub describe {
    my($self, $colid, $ref) = @_;
    my($key, $errs);
    
    foreach $key (keys(%$ref)) {
	if(!defined($f_keys{$key})) {
	    carp "$key is not a valid Sybase::BCP key";
	    ++$errs;
	}
    }
    croak "Sybase::BCP processing aborted because of errors\n" if($errs>0);
    $self->{Cols}->{$colid-1} = $ref;
    1;
}

sub run {
    my $self = shift;
    my $ret;
    
    if($self->{Global}->{DIRECTION} eq 'OUT') {
	$ret = $self->do_out(@_);
    } else {
	$ret = $self->do_in(@_);
	my $log_file = $self->{Global}->{ERRORS} || 'bcp.err';
	if(-e $log_file && -z $log_file) {
	    unlink($log_file);
	}
    }
    $ret;
}

sub do_out {
    croak("BCP OUT is not implemented!");
}

sub do_in {
    my $self = shift;
    my $verbose = shift;	# not used....
    
    
    # Initialize:
    my $infile 	= $self->{Global}->{INPUT};
    my $table 	= $self->{Global}->{OUTPUT};
    my $logfile = $self->{Global}->{ERRORS};
    my $sep 	= $self->{Global}->{SEPARATOR};
    local $/    = $self->{Global}->{RECORD_SEPARATOR} || "\n";
    my $cols 	= $self->{Global}->{FIELDS};
    my $batch_size = $self->{Global}->{BATCH_SIZE};
    my $null_pattern = $self->{Global}->{'NULL'};
    my $date_fmt = $self->{Global}->{DATE};
    my %cols 	= defined($self->{Cols}) ? %{$self->{Cols}} : ();
    my $g_cb 	= $self->{Global}->{CALLBACK};
    my $logger  = $self->{Global}->{LOGGER} || \&carp;
    my %reorder = %{$self->{Global}->{REORDER}} if(defined($self->{Global}->{REORDER}));
    my @tabinfo = @{$self->{Global}->{TAB_INFO}};
    my $i;
    my $in_sub;
    
    croak "You must define a table name!" if(!defined($table));
    croak "You must define an input file name!" if(!defined($infile));
    
    # The user has defined a reordering pattern of columns:
    # If the target columns are entered as column names, we must
    # convert that back to column numbers...
    foreach (keys(%reorder)) {
	if($reorder{$_} =~ /\D+/) {
	    for($i = 0; $i < @tabinfo; ++$i) {
		if(${$tabinfo[$i]}[0] eq $reorder{$_}) {
		$reorder{$_} = $i+1;
	    }
	}
    }
}
# If one of the target fields is a DATETIME field, then we
# check to see if the user has defined a default conversion:
if(defined($self->{Global}->{DATE})) {
    for($i = 0; $i < @tabinfo; ++$i) {
	if(${$tabinfo[$i]}[1] =~ /datetim/ &&
	    !defined($cols{$i}->{CALLBACK})) {
	$cols{$i}->{CALLBACK} = $date_fmt{$self->{Global}->{DATE}};
    }
}
}

$logfile = 'bcp.err' unless $logfile;
$sep = "\t" unless $sep;
$batch_size = 100 unless $batch_size;

if(!ref($infile)) {
    open(IN, $infile) || croak "Can't open file $infile: $!";
    binmode(IN);
    $in_sub = \&_readln;
} elsif(ref($infile) eq 'CODE') {
    $in_sub = $infile;
} else {
    croak("INPUT parameter is a ref but not a CODE ref");
}

($self->bcp_init($table, '', '', DB_IN) == SUCCEED) ||
    croak "bcp_init failed.";
open(LOG, ">$logfile") || croak "Can't open file $logfile: $!";

my $count = 0;
my $t_rows = 0;
my @data;
my @t_data;
my @rows;
my $row;

local $" = $sep;		# Set the output field separator."

while(@data = &$in_sub($sep)) {
    foreach $i (keys(%reorder)) {
	$t_data[$reorder{$i}-1] = $data[$i-1];
    }
    @data = @t_data if @t_data;
    
    if(defined($g_cb)){
	next unless &$g_cb(\@data);
    }
    # Here we use the number of columns found in the first row of data to
    # define the COPY IN operation.
    if($count == 0) {
	# Get the number of fields from the first data row if
	# we didn't get that info via config().
	$cols = scalar(@data) unless $cols;
	$self->bcp_meminit($cols); # This sets up the copy_in operation.
    }
    
    # If the row is short, push undef values onto the row:
    while(scalar(@data) < $cols) {
	push(@data, undef);
    }
    # Do any special data handling: set NULL fields, maybe convert dates,
    # call the callbacks if they are defined.
    if(defined($null_pattern) || %cols) {
	for($i = 0; $i < $cols; ++$i) {
	    if($cols{$i}->{SKIP} == TRUE) {
		splice(@data, $i, 1);
		next;
	    }
	    if(defined($cols{$i}->{CALLBACK})) {
		$data[$i] = &{$cols{$i}->{CALLBACK}}($data[$i]);
	    }
	    if(defined($null_pattern) && length($null_pattern) > 0 &&
	       $data[$i] =~ /\Q$null_pattern\E/) 
	    {
		$data[$i] = undef;
	    }
	}
    }
    # Send the row to the server. A failure here indicates a
    # conversion error of data from the @data array. The row has NOT been sent to
    # the server. We log the row data and move on to the next row.
    if($self->bcp_sendrow(\@data) == FAIL) {
	print LOG "@data\n";
	next;
    }
    # Remember this row until we are certain that this batch is OK.
    push(@rows, [@data]);
    #If we've sent $batch_size rows to the server, commit them.
    if((++$count % $batch_size) == 0) {
	if($self->bcp_batch <= 0) {
	    my $r_count = 0;
	    &$logger("bcp_batch failed - redoing");
	    # The batch failed, so re-run it one row at a time.
	    foreach $row (@rows) {
		if($self->bcp_sendrow($row) == FAIL) {
		    print LOG "@$row\n";
		    next;
		}
		if($self->bcp_batch != 1) { # batch each row, so that we can find which is wrong...
		    print LOG "@$row\n";
		}
		else
		{
		    ++$r_count;
		}
	    }
	    &$logger (sprintf("bcp sent %d rows to the server (%d failed)\n",
			      $r_count, $batch_size - $r_count));
	    $t_rows += $r_count;
	}
	else
	{
	    $t_rows += scalar(@rows);
	    &$logger("bcp sent $batch_size rows to the server...\n");
	}
	@rows = ();		# The batch was successfull, flush the row cache.
    }
}
# Commit any outstanding rows.
if(scalar(@rows)) {
    if($self->bcp_batch <= 0) {
	&$logger("bcp_batch failed - redoing");
	foreach $row (@rows) {
	    if($self->bcp_sendrow($row) == FAIL) {
		print LOG "@$row\n";
		next;
	    }
	    if($self->bcp_batch != 1) { # batch each row, so that we can find which is wrong...
		print LOG "@$row\n";
	    } else {
		++$t_rows;
	    }
	}
    } else {
	$t_rows += scalar(@rows);
    }
}
$self->bcp_done;

close(LOG);
close(IN);
$t_rows;			# number of rows actually sent to the server
}

# Default data read method
sub _readln {
    my $sep = shift;
    my $ln; my @d;
    if(defined($ln = <IN>)) {
	chomp $ln;
	@d = split(/\Q$sep\E/, $ln, -1);
    }
    @d;
}



# Extracts information about the column names and column types from
# the database. Uses the system tables for this.
sub _gettabinfo {
    my $dbh = shift;
    my $table = shift;
    my($db, $user, $tab);
    my $ref;
    
    # Table name starts with #: it's a tempdb table.
    if($table =~ /\#/) {
	$db = 'tempdb';
	$user = '';
	$tab = $table;
	# This is really weird: when DBLIBVS < 1000, I have to issue this
	# dbuse command or the bcp_init() call in run() above fails.
	# The SQL trace (via dbrecftos()) shows that bcp_init does a
	# select on the available indices using unqualified system
	# table names. This select is not done when DBLIBVS == 1000.
	# This is probably due to internal behavior differences
	# between System 10 and previous releases. When DBLIBVS >= 1000 we
	# call dbsetversion() during the initialization of Sybase::DBlib.
	# In any case, you don't usually bulk copy data into a temp table,
	# so the issue isn't that important...
	$dbh->dbuse($db);
    } else {
	($db, $user, $tab) = split(/\./, $table);
    }
    croak "Must specify the Sybase table as database.user.table"
	if (!defined($tab));
    $user = 'dbo' if(!defined($user) || $user =~ /^$/);
    
    $ref = $dbh->sql("
select c.name, t.name
from $db.dbo.syscolumns c, $db.dbo.systypes t
where c.id = object_id('$table')
and   c.usertype *= t.usertype
");
}


# Date conversion routines.

# Convert from Unix ctime(3) format:
sub _datectime {
    my $date = shift;
    my @f;
    
    @f = split(' ', $date);
    $date = "$f[1] $f[2] $f[4] $f[3]";
}
# Convert from the Sybase datetime convert() formats:
sub _date101 {
    my $date = shift;
    my @f;
    
    @f = split(/\//, $date);
    $date = "$f[2]$f[0]$f[1]";
}
sub _date103 {
    my $date = shift;
    my @f;
    
    @f = split(/\//, $date);
    $date = "$f[2]$f[1]$f[0]";
}
sub _date104 {
    my $date = shift;
    my @f;
    
    @f = split(/\./, $date);
    $date = "$f[2]$f[1]$f[0]";
}
sub _date105 {
    my $date = shift;
    my @f;
    
    @f = split(/\-/, $date);
    $date = "$f[2]$f[1]$f[0]";
}
sub _date106 {
    my $date = shift;
    my @f;
    
    @f = split(' ', $date);
    $date = "$f[1] $f[0] $f[2]";
}
sub _date110 {
    my $date = shift;
    my @f;
    
    @f = split(/\-/, $date);
    $date = "$f[2]$f[0]$f[1]";
}
sub _date111 {
    my $date = shift;
    
    $date =~ s/\///g;
}



1;

__END__    
