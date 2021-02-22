# $Id: BLK.pm,v 1.11 2005/03/20 19:50:59 mpeppler Exp $
#
# Shamelessly copied 2001 from Sybase::BCP and transformed magically
# into Sybase::BLK by Scott Zetlan
#
# Copyright (c) 2001-2002
#   Michael Peppler
#
#   You may copy this under the terms of the GNU General Public License,
#   or the Artistic License, copies of which should have accompanied
#   your Perl kit.
#

package Sybase::BLK;

=head1 NAME

Sybase::BLK - Simple front end to the Sybase Bulk Libraries (from ctlib/comlib)

=head1 SYNOPSIS

    use Sybase::BLK;

    $bcp = new Sybase::BLK ...;
    $bcp->config(...);
    $bcp->run;

It's I<very> similar to Sybase::BCP, except that it's based on Sybase::CTlib
instead of Sybase::DBlib.


=head1 DESCRIPTION

The Sybase::BLK module serves as a simplified front end for Sybase's Bulk
Copy library. It is sub-classed from the L<Sybase::CTlib> module, so all the
features of the Sybase::CTlib module are available in addition to the
specific Sybase::BLK methods.

So how does it work?

Let's say we want to copy the contents of a file name 'foo.bcp' into the
table 'mydb.dbo.bar'. The fields in the file are separated by a '|'.

    #!/usr/local/bin/perl

    use Sybase::BLK;

    $bcp = new Sybase::BLK $user, $passwd;
    $bcp->config(INPUT => 'foo.bcp',
		 OUTPUT => 'mydb.dbo.bar',
		 SEPARATOR => '|');
    $bcp->run;

That's it!

Of course, there are several things you can do to cater for non-standard
input files (see B<Configuration Parameters>, below).

=head2 Features

=over 4

=item * Allows use of Regular Expressions as separator

=item * Automatic conversions from non-standard date formats.

=item * Handles column reordering and/or skipping of unneeded data.

=item * Row or column based callbacks.

Allows vetoing of rows, or arbitrary processing of data on input.

=back

=head2 The following methods are available:

=over 4

=item $bcp=new Sybase::BLK [$user [, $pass [, $server [, $appname [, $attr]]]]]

Allocate a new B<BLK> handle. Opens a new connection to Sybase via the
B<Sybase::CTlib> module, and enables BLK IN on this handle. The $attr
variable is a hash ref that gets passed to Sybase::CTlib, and can be 
used to set connection properties (see the new/ct_connect entry in the
Sybase::CTlib man page).

=item $bcp->config([parameters])

Sets up the Bulk Copy operation. See B<Configuration Parameters> below for
details.

=item $bcp->describe($colid, {parameters})

Adds a specific configuration element for column $colid. Columns are numbered
starting at 1, as is standard in the Sybase APIs.

=item $bcp->run

Perform the B<BLK> operation, returns the actual number of rows sent to the
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

Where B<BLK> should take it's input from. It's a filename for B<bcp IN>, it's
a table name for B<bcp OUT>.

For B<bcp IN> B<INPUT> can also be a reference to a perl subroutine that
returns the array to be inserted via blk_rowxfer().

=item OUTPUT

Where B<BLK> should place it's output. It's a table name for B<bcp IN>, a
filename for B<bcp OUT>.

=item ERRORS

The file where invalid rows should be recorded. Default: bcp.err.

=item SEPARATOR

The pattern that separates fields in the input file, or that should be used
to separate fields in the output file. Since this pattern is passed to 
B<split>, it can be a regular expression.  By default regular expression
meta-characters are I<not> interpreted as such, unless the I<RE_USE_META>
attribute is set. Default: TAB.

=item RE_USE_META

If this attribute is set then the regular expression used to split rows
into columns (defined by SEPARATOR) will interpret regular expression
meta-characters normally (i.e. a '|' means alternation - see perldoc perlre
for details on regular expression meta-characters). Default: false.

=item RECORD_SEPARATOR

The pattern that separates records (rows) in the input file. Sybase:BLK will
set a local copy of $/ to this value before reading the file. Default: NEWLINE.

=item BATCH_SIZE

Number of rows to be batched together before committing to the server for
B<bcp IN> operations. Defaults to 100. If there is a risk that retries could
be requiered due to failed batches (e.g. duplicate rows/keys errors) then
you should not use a large batch size: one failed row in a batch requires
the entire batch to be resent.

=item RETRY_FAILED_BATCHES

If this attribute is set then a failed batch will be retried one row at a time
so that all the rows that don't fail get loaded. Default: false.

=item NULL

A pattern to be used to detect NULL values in the input file. Defaults to
a zero length string.

=item HAS_IDENTITY

Boolean determining whether the values in the input file should be used 
to populate any IDENTITY column in the target table. Leave false if the
target table doesn't have any identity columns, or if you want to let the
server populate the IDENTITY column (and see the IDENTITY_COL attribute,
below).

=item IDENTITY_COL

If your target table has an identity column, and you want to let the
server populate it, then set IDENTITY_COL to the column number of the 
identity column in the table (starting with 1 for the first column).

=item DATE

The default format for DATE fields in the input file. The parameter should
be a symbolic value representing the format. Currently, the following values
are recognized: CTIME (the Unix ctime(3) format), or the numbers 0-12,
100-112, corresponding to the conversion formats defined in table 2-4 of
the I<SQL Server Reference Manual>.

B<BLK> detects I<datetime> targets by looking up the target table
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
parameter, and the callback should return the value that it wants B<BLK>
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
    
    use Sybase::BLK;

    $bcp = new Sybase::BLK sa, undef, TROLL;

    $bcp->config(INPUT => '../../Sybperl/xab',
	         OUTPUT => 'excalibur.dbo.t3',
   	         BATCH_SIZE => 200,
	         REORDER => {1 => 'account',
			     3 => 'date',
			     2 => 'seq_no',
			     11 => 'broker'},
	         SEPARATOR => '\|');
    $bcp->run;


=head1 BUGS

Bulk copy out is not implemented.

This module was copied from Sybase::BCP and so is subject to many of the same
issues noted in that module.

The current implementation seems to run about 2.5 to 3 times slower than
plain bcp.

=head1 AUTHOR

Scott Zetlan F<E<lt>scottzetlan@aol.comE<gt>> after the original Sybase::BCP by
Michael Peppler F<E<lt>mpeppler@peppler.orgE<gt>>. Contact the sybperl mailing
list C<mailto:sybperl-l@peppler.org> if you have any questions.

=cut

# '
# A module implementing a generalized Bulk Copy API.
# This version requires sybperl 2.13

use Sybase::CTlib qw(2.13);
use Carp;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION $Version);

@ISA    = qw(Exporter Sybase::CTlib);
@EXPORT = @Sybase::CTlib::EXPORT;

use strict;

$VERSION = substr( q$Revision: 1.11 $, 10 );
$Version = q|$Id: BLK.pm,v 1.11 2005/03/20 19:50:59 mpeppler Exp $|;

my @g_keys = qw(INPUT OUTPUT ERRORS SEPARATOR FIELDS BATCH_SIZE
  NULL DATE REORDER CALLBACK TAB_INFO DIRECTION CONDITION
  LOGGER RECORD_SEPARATOR HAS_IDENTITY IDENTITY_COL
  RE_USE_META RETRY_FAILED_BATCHES);
my @f_keys = qw(CALLBACK SKIP);
my %g_keys = map { $_ => 1 } @g_keys;
my %f_keys = map { $_ => 1 } @f_keys;

my %date_fmt = (
  CTIME => \&_datectime,
  101   => \&_date101,

  # 102 => \&_date102, This one is probably automatic...
  103 => \&_date103,
  104 => \&_date104,
  105 => \&_date105,
  106 => \&_date106,

  # 107 => \&_date107, This one's probably automatic...
  110 => \&_date110,
  111 => \&_date111,
  112 => \&_date112
);

sub new {
  my ( $package, $user, $passwd, $server, $appname, $attr ) = @_;
  my ($d);

  # Grumble... with warnings turned on, we get 'Use of unitialized...'
  $user    = '' unless $user;
  $passwd  = '' unless $passwd;
  $server  = '' unless $server;
  $appname = '' unless $appname;

  # Have to set CS_BULK_LOGIN to CS_TRUE when the connection is
  # allocated, or bulk-mode operations are disabled.
  $attr                               = {} unless $attr;
  $attr->{_blk_global}                = {};
  $attr->{_blk_cols}                  = {};
  $attr->{CON_PROPS}->{CS_BULK_LOGIN} = CS_TRUE;

  $d = $package->SUPER::new( $user, $passwd, $server, $appname, $attr );
}

sub DESTROY {
  my $self = shift;

  # Make sure we close the Sybase::CTlib connection.
  $self->SUPER::DESTROY;
}

sub config {
  my ( $self, %ref ) = @_;
  my ( $key, $errs );

  foreach $key ( keys(%ref) ) {
    if ( !defined( $g_keys{$key} ) ) {
      carp "$key is not a valid Sybase::BLK key";
      ++$errs;
    }
  }
  croak "Sybase::BLK processing aborted because of errors\n" if ($errs);
  $ref{DIRECTION} = 'IN' unless ( $ref{DIRECTION} );
  $self->{_blk_global} = {%ref};

  # Get the table definition from Sybase system tables:
  $self->{_blk_global}->{TAB_INFO} =
    $self->_gettabinfo( $self->{_blk_global}->{OUTPUT} )
    if ( $ref{DIRECTION} eq 'IN' );    ### FIXME

  1;
}

sub describe {
  my ( $self, $colid, $ref ) = @_;
  my ( $key, $errs );

  foreach $key ( keys(%$ref) ) {
    if ( !defined( $f_keys{$key} ) ) {
      carp "$key is not a valid Sybase::BLK key";
      ++$errs;
    }
  }
  croak "Sybase::BLK processing aborted because of errors\n" if ( $errs > 0 );
  $self->{_blk_cols}->{ $colid - 1 } = $ref;
  1;
}

sub run {
  my $self = shift;
  my $ret;

  if ( $self->{_blk_global}->{DIRECTION} eq 'OUT' ) {
    $ret = $self->do_out(@_);
  } else {
    $ret = $self->do_in(@_);
    my $log_file = $self->{_blk_global}->{ERRORS} || 'bcp.err';
    if ( -e $log_file && -z $log_file ) {
      unlink($log_file);
    }
  }
  $ret;
}

sub do_out {
  croak("BLK OUT is not implemented!");
}

sub do_in {
  my $self = shift;

  # Initialize:
  my $infile  = $self->{_blk_global}->{INPUT};
  my $table   = $self->{_blk_global}->{OUTPUT};
  my $logfile = $self->{_blk_global}->{ERRORS}    || 'bcp.err';
  my $sep     = $self->{_blk_global}->{SEPARATOR} || "\t";
  local $/ = $self->{_blk_global}->{RECORD_SEPARATOR} || "\n";

  #    my $cols 	= $self->{_blk_global}->{FIELDS};   #### IGNORED!
  my $has_ident    = $self->{_blk_global}->{HAS_IDENTITY} || 0;
  my $ident_col    = $self->{_blk_global}->{IDENTITY_COL} || 0;
  my $batch_size   = $self->{_blk_global}->{BATCH_SIZE}   || 100;
  my $null_pattern = $self->{_blk_global}->{'NULL'};
  my $date_fmt     = $self->{_blk_global}->{DATE} || 102;
  my %cols    = defined( $self->{_blk_cols} ) ? %{ $self->{_blk_cols} } : ();
  my $g_cb    = $self->{_blk_global}->{CALLBACK};
  my $logger  = $self->{_blk_global}->{LOGGER} || \&carp;
  my %reorder = %{ $self->{_blk_global}->{REORDER} }
    if ( defined( $self->{_blk_global}->{REORDER} ) );
  my @tabinfo = @{ $self->{_blk_global}->{TAB_INFO} };
  my $cols    = scalar @tabinfo;
  my $i;
  my $in_sub;

  croak "You must define a table name!"       if ( !defined($table) );
  croak "You must define an input file name!" if ( !defined($infile) );

  # The user has defined a reordering pattern of columns:
  # If the target columns are entered as column names, we must
  # convert that back to column numbers...

  foreach ( keys(%reorder) ) {
    if ( $reorder{$_} =~ /\D+/ ) {
      for ( $i = 0 ; $i < @tabinfo ; ++$i ) {
        if ( $tabinfo[$i]->[0] eq $reorder{$_} ) {
          $reorder{$_} = $i + 1;
        }
      }
    }
  }

  # If one of the target fields is a DATETIME field, then we
  # check to see if the user has defined a default conversion:
  if ( defined( $self->{_blk_global}->{DATE} ) ) {
    for ( $i = 0 ; $i < @tabinfo ; ++$i ) {
      if ( $tabinfo[$i]->[1] =~ /datetim/
        && !defined( $cols{$i}->{CALLBACK} ) ) {
        $cols{$i}->{CALLBACK} =
          $date_fmt{ $self->{_blk_global}->{DATE} };
      }
    }
  }

  if ( !ref($infile) ) {
    open( IN, $infile ) || croak "Can't open file $infile: $!";
    binmode(IN);
    if ( $self->{_blk_global}->{RE_USE_META} ) {
      $in_sub = \&_readln_meta;
    } else {
      $in_sub = \&_readln;
    }
  } elsif ( ref($infile) eq 'CODE' ) {
    $in_sub = $infile;
  } else {
    croak("INPUT parameter is a ref but not a CODE ref");
  }

  if ( $self->blk_init( $table, $cols, $has_ident, $ident_col ) != CS_SUCCEED )
  {
    croak "blk_init failed.";
  }
  open( LOG, ">$logfile" ) || croak "Can't open file $logfile: $!";

  my $batch_commit = 0;
  my $total_commit = 0;
  my @data;
  my @t_data;
  my @rows;
  my $row;

  local $" = $sep;    # Set the output field separator.

  # SDZ: I rewrote most of this section to make it a little cleaner.
  # In the process, I removed the automatic batch retry; it might speed
  # things up a little, and I've rarely needed a batch retried.  In
  # any case, failed rows get copied to the log file for easy retry.
  while ( @data = &$in_sub($sep) ) {

    # Reorder the data as needed
    foreach $i ( keys(%reorder) ) {
      $t_data[ $reorder{$i} - 1 ] = $data[ $i - 1 ];
    }
    @data = @t_data if @t_data;

    # Next, run the global callback (if defined):
    if ( defined($g_cb) ) {
      next unless &$g_cb( \@data );
    }

    # If the row is still short, push undef values onto the row:
    while ( scalar(@data) < $cols ) {
      push( @data, undef );
    }

    # Do any special data handling: set NULL fields, maybe convert dates,
    # call the callbacks if they are defined.
    for ( $i = 0 ; $i < $cols ; ++$i ) {

      # Skip any SKIPped cols:
      if ( defined( $cols{$i}->{SKIP} ) ) {
        splice( @data, $i, 1 );
        next;
      }

      # Run column callbacks:
      if ( defined( $cols{$i}->{CALLBACK} ) ) {
        $data[$i] = &{ $cols{$i}->{CALLBACK} }( $data[$i] );
      }

      # Check for nulls:
      if ( defined($null_pattern)
        && length($null_pattern) > 0
        && $data[$i] =~ /$null_pattern/ ) {
        $data[$i] = undef;
      } elsif ( length( $data[$i] ) == 0 ) {

        # default NULL handling.
        $data[$i] = undef;
      }
    }

    # Send the row to the server. A failure here indicates a
    # conversion error of data from the @data array. The row has NOT been
    # sent to the server. We log the row data and move on to the next row.
    if ( $self->blk_rowxfer( \@data ) == CS_FAIL ) {
      print LOG "@data\n";
      next;
    }

    # Remember this row until we are certain that this batch is OK.
    push( @rows, [@data] );

    #If we've sent $batch_size rows to the server, commit them.
    my $batch_commit;

    # Don't want to automatically commit if there are no rows, so
    # make sure that rows is > 0:
    if ( @rows > 0 && @rows % $batch_size == 0 ) {
      if ( $self->blk_done( CS_BLK_BATCH, $batch_commit ) == CS_SUCCEED ) {
        $total_commit += $batch_commit;
        &$logger(
          "Sent $batch_commit ($total_commit total so far) rows to the server");
      } elsif ( $self->{_blk_global}->{RETRY_FAILED_BATCHES} ) {
        my $retry_count = 0;
        &$logger("Batch failed to commit - redoing");

        # The batch failed, so re-run it one row at a time.
        foreach my $row (@rows) {
          if ( $self->blk_rowxfer($row) == CS_FAIL ) {
            print LOG "@$row\n";
            next;
          }

          # batch each row, so that we can find which is wrong...
          if ( $self->blk_done( CS_BLK_BATCH, $batch_commit ) != CS_SUCCEED ) {

            # This row failed to commit - dup index, for example.
            print LOG "@$row\n";
          } else {
            ++$retry_count;
          }
        }
        $total_commit += $retry_count;
        &$logger(
          sprintf(
"Sent $retry_count (%d failed) ($total_commit total so far) rows to the server",
            $batch_size - $retry_count )
        );
      } else {
        &$logger("Batch failed to commit: saved rows in error file");
        foreach my $rowref (@rows) {
          print LOG "@{ $rowref }\n";
        }
      }

      # Now flush the cache:
      @rows = ();
    }
  }

  # Commit any remaining rows:
  if ( $self->blk_done( CS_BLK_ALL, $batch_commit ) == CS_SUCCEED ) {
    $total_commit += $batch_commit;
  } else {
    &$logger("Final batch failed to commit: saved rows in error file");
    foreach my $rowref (@rows) {
      print LOG "@{ $rowref }\n";
    }
  }

  $self->blk_drop;

  close(LOG);
  close(IN);

  $total_commit;    # number of rows actually sent to the server
}

# Default data read method
sub _readln {
  my $sep = shift;
  my $ln;
  my @d;
  if ( defined( $ln = <IN> ) ) {
    chomp $ln;
    @d = split( /\Q$sep\E/, $ln, -1 );
  }
  @d;
}

# Default data read method
sub _readln_meta {
  my $sep = shift;
  my $ln;
  my @d;
  if ( defined( $ln = <IN> ) ) {
    chomp $ln;
    @d = split( /$sep/, $ln, -1 );
  }
  @d;
}

# Extracts information about the column names and column types from
# the database. Uses the system tables for this.
sub _gettabinfo {
  my $dbh   = shift;
  my $table = shift;
  my ( $db, $user, $tab );
  my $ref;

  # Table name starts with #: it's a tempdb table.
  if ( $table =~ /\#/ ) {
    $db   = 'tempdb';
    $user = '';
    $tab  = $table;
  } else {
    ( $db, $user, $tab ) = split( /\./, $table );
  }
  croak "Must specify the Sybase table as database.user.table"
    if ( !defined($tab) );
  $user = 'dbo' if ( !defined($user) || $user =~ /^$/ );

  my @arr = $dbh->nsql( "
select c.name, t.name
from $db.dbo.syscolumns c, $db.dbo.systypes t
where c.id = object_id('$db.$user.$tab')
and   c.usertype *= t.usertype
", "ARRAY" );

  return [@arr];
}

# Date conversion routines.

# Convert from Unix ctime(3) format:
sub _datectime {
  my $date = shift;
  my @f;

  @f    = split( ' ', $date );
  $date = "$f[1] $f[2] $f[4] $f[3]";
}

# Convert from the Sybase datetime convert() formats:
sub _date101 {
  my $date = shift;
  my @f;

  @f    = split( /\//, $date );
  $date = "$f[2]$f[0]$f[1]";
}

sub _date103 {
  my $date = shift;
  my @f;

  @f    = split( /\//, $date );
  $date = "$f[2]$f[1]$f[0]";
}

sub _date104 {
  my $date = shift;
  my @f;

  @f    = split( /\./, $date );
  $date = "$f[2]$f[1]$f[0]";
}

sub _date105 {
  my $date = shift;
  my @f;

  @f    = split( /\-/, $date );
  $date = "$f[2]$f[1]$f[0]";
}

sub _date106 {
  my $date = shift;
  my @f;

  @f    = split( ' ', $date );
  $date = "$f[1] $f[0] $f[2]";
}

sub _date110 {
  my $date = shift;
  my @f;

  @f    = split( /\-/, $date );
  $date = "$f[2]$f[0]$f[1]";
}

sub _date111 {
  my $date = shift;

  $date =~ s/\///g;
}

1;

__END__    
