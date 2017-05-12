#
#   Copyright (c) 2000 Andreas Stiller
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.
#
require 5.005;
package DBD::RDB;

use DBI;
use DynaLoader ();
use Exporter ();

@ISA = qw(DynaLoader Exporter);

$VERSION = 1.16;
$ABSTRACT = "Oracle RDB driver for DBI";

use strict;
use vars qw($VERSION $ABSTRACT $err $errstr $state $drh $sqlstate);

bootstrap DBD::RDB $VERSION;

$err = 0;		# holds error code   for DBI::err
$errstr = "";	        # holds error string for DBI::errstr
$sqlstate = "";       # holds SQL state for    DBI::state

  sub driver {
    return $drh if $drh;	# already created - return same one
    my($class, $attr) = @_;

    $class .= "::dr";

    # not a 'my' since we use it above to prevent multiple drivers
    $drh = DBI::_new_drh($class, {
      'Name'    => 'File',
      'Version' => $VERSION,
      'Err'     => \$DBD::File::err,
      'Errstr'  => \$DBD::File::errstr,
      'State'   => \$DBD::File::state,
      'Attribution' => 'DBD::RDB $Version using dynamic SQL by Andreas Stiller',
    });

    return $drh;
  }

package DBD::RDB::dr; # ====== DRIVER ======
use strict;

sub connect {
    my($drh, $dbname, $user, $auth, $attr)= @_;

    # Some database specific verifications, default settings
    # and the like following here. This should only include
    # syntax checks or similar stuff where it's legal to
    # 'die' in case of errors.

    # create a 'blank' dbh (call superclass constructor)
    my $dbh = DBI::_new_dbh($drh, {
      'Name' => $dbname
    });

    DBD::RDB::db::_login( $dbh, $dbname, $user, $auth ) or return undef;
    $dbh;
}


package DBD::RDB::db; # ====== DATABASE ======
use strict;

sub prepare {
    my ( $dbh, $statement, $attribs ) = @_;

    # create a 'blank' sth
    my $sth = DBI::_new_sth($dbh, {'Statement' => $statement} );
    DBD::RDB::st::_prepare( $sth, $statement, $attribs ) or return undef;
    $sth;
}

sub do {
    my ( $dbh, $statement, $attr, @bind_values ) = @_;
    
    my $rv;
    if ( $attr || @bind_values ) {
	my $sth = $dbh->prepare( $statement, $attr ) or return undef;
        $rv = $sth->execute( @bind_values );
    } else {
        $rv = DBD::RDB::db::_do( $dbh, $statement );
	$rv = "0E0" if $rv == 0;
	$rv = undef if $rv < -1;
    }
    $rv;
}

sub table_info {
    my($dbh, $attr) = @_;
    # XXX add knowledge of temp tables, etc

	# SQL/CLI (ISO/IEC JTC 1/SC 32 N 0595), 6.63 Tables
    my $CatVal = $attr->{TABLE_CAT};
    my $SchVal = $attr->{TABLE_SCHEM};
    my $TblVal = $attr->{TABLE_NAME};
    my $TypVal = $attr->{TABLE_TYPE};
    my @Where = ();
    my $Sql;
    if ( $CatVal eq '%' && $SchVal eq '' && $TblVal eq '') { # Rule 19a
	$Sql = <<'SQL';
SELECT NULL TABLE_CAT
     , NULL TABLE_SCHEM
     , NULL TABLE_NAME
     , NULL TABLE_TYPE
     , NULL REMARKS
  FROM RDB$DATABASE
SQL
	}
	elsif ( $SchVal eq '%' && $CatVal eq '' && $TblVal eq '') { # Rule 19b
		$Sql = <<'SQL';
SELECT NULL      TABLE_CAT
     , NULL      TABLE_SCHEM
     , NULL      TABLE_NAME
     , NULL      TABLE_TYPE
     , NULL      REMARKS
  FROM ALL_USERS
 ORDER BY 2
SQL
	}
	elsif ( $TypVal eq '%' && $CatVal eq '' && $SchVal eq '' && $TblVal eq '') { # Rule 19c
		$Sql = <<'SQL';
SELECT NULL TABLE_CAT
     , NULL TABLE_SCHEM
     , NULL TABLE_NAME
     , t.tt TABLE_TYPE
     , NULL REMARKS
  FROM
(
  SELECT 'TABLE'    tt FROM RDB$DATABASE
) t
 ORDER BY TABLE_TYPE
SQL
	}
	else {
		$Sql = <<'SQL';
SELECT *
  FROM
(
  SELECT ''           TABLE_CAT
     , ''             TABLE_SCHEM
     , t.RDB$RELATION_NAME TABLE_NAME
     , 'TABLE'        TABLE_TYPE
  FROM RDB$RELATIONS t
 WHERE t.RDB$SYSTEM_FLAG = 0
) AO
SQL
		if ( defined $SchVal ) {
			push @Where, "AO.TABLE_SCHEM LIKE '$SchVal'";
		}
		if ( defined $TblVal ) {
			push @Where, "AO.TABLE_NAME  LIKE '$TblVal'";
		}
		if ( defined $TypVal ) {
			my $table_type_list;
			$TypVal =~ s/^\s+//;
			$TypVal =~ s/\s+$//;
			my @ttype_list = split (/\s*,\s*/, $TypVal);
			foreach my $table_type (@ttype_list) {
				if ($table_type !~ /^'.*'$/) {
					$table_type = "'" . $table_type . "'";
				}
				$table_type_list = join(", ", @ttype_list);
			}
			push @Where, "AO.TABLE_TYPE IN ($table_type_list)";
		}
		$Sql .= ' WHERE ' . join("\n   AND ", @Where ) . "\n" if @Where;
		$Sql .= " ORDER BY AO.TABLE_TYPE, AO.TABLE_SCHEM, AO.TABLE_NAME\n";
	}
	my $sth = $dbh->prepare($Sql) or return undef;
	$sth->execute or return undef;
	$sth;
}


sub type_info_all {
    my ( $dbh ) = @_;

    my $date_len = DBI::db::FETCH( $dbh, 'rdb_datelen' );
    my $info = [
	{ TYPE_NAME => 0,
	  DATA_TYPE => 1,
          COLUMN_SIZE => 2,
          LITERAL_PREFIX => 3,
	  LITERAL_SUFFIX => 4,
	  CREATE_PARAMS => 5,
	  NULLABLE => 6,
	  CASE_SENSITIVE => 7,
	  SEARCHABLE => 8,
	  UNSIGNED_ATTRIBUTE => 9,
	  FIXED_PREC_SCALE => 10,
	  MINIMUM_SCALE => 11,
	  MAXIMUM_SCALE => 12,
	  NUM_PREC_RADIX => 13,
	},
        [ 'VARCHAR',12,65269,"'","'","max length",2,1,3,
	  undef,undef,undef,undef,undef ],
        [ 'CHAR',1,65271,"'","'","length",2,1,3,
	  undef,undef,undef,undef,undef ],
        [ 'TINYINT',-6,3,undef,undef,"scale",2,undef,3,
          0,0,0,3,10],
        [ 'SMALLINT',5,5,undef,undef,"scale",2,undef,3,
          0,0,0,5,10],
        [ 'INTEGER',4,10,undef,undef,"scale",2,undef,3,
          0,0,0,10,10],
        [ 'BIGINT',-5,19,undef,undef,"scale",2,undef,3,
          0,0,0,19,10],
        [ 'FLOAT',6,53,undef,undef,"precision",2,undef,3,
          0,0,undef,undef,2],
        [ 'REAL',7,24,undef,undef,undef,2,undef,3,
          0,0,undef,undef,10],
        [ 'DOUBLE PRECISION',7,53,undef,undef,undef,2,undef,3,
          0,0,undef,undef,10],
        [ 'DATE VMS',9,$date_len,"'","'",undef,2,undef,3,
          0,0,undef,undef,undef]
    ];
    return $info;
}

sub get_info {
    my ( $dbh, $info_nr ) = @_;

    my $info;
    if ( $info_nr == 17 ) {			# SQL_DBMS_NAME
	$info = "Oracle RDB";
    } elsif ( $info_nr == 18 ) {		# SQL_DBMS_VER
	$info = $ENV{'RDBVMS$VERSION'};
    } elsif ( $info_nr == 29 ) {		# SQL_IDENTIFIER_QUOTE_CHAR
	$info = "'";
    } elsif ( $info_nr == 41 ) {		# SQL_CATALOG_NAME_SEPARATOR
	$info = ".";
    } elsif ( $info_nr == 114 ) {		# SQL_CATALOG_LOCATION
	$info = 1;
    }
    $info;
}


1;


__END__

=head1 General Information

=head2 Driver version

DBD::RDB version 1.20

=head2 Feature summary

    Transactions                            Yes
    Locking                                 Yes, implicit and explicit
    Table joins                             Yes, inner and outer
    LONG/LOB datatypes                      Yes, as cursor
    Statement handle attributes available   After prepare()
    Placeholders                            Yes, "?"
    Stored Procedures                       Yes
    Bind output values                      Yes
    Table name letter case                  Uppercase
    Field name letter case                  Uppercase
    Quoting of otherwise invalid names      Yes, via double quotes
    Case-insensitive "LIKE" operator        No
    Server table RWO ID pseudocolumn        Yes
    Positioned update/delete                Yes
    Concurrent use of mutliple handles      Yes 

=head2 Author and contact details

The driver author is Andreas Stiller. He can be contacted at 
andreas.stiller at eds dot com

=head2 Supported database versions and options

The DBD::RDB modules supports Orcale RDB for OpenVMS, versions 6.x (untested),
7.0.x and 7.1 (tested). A RDB development installation and license is needed
to build the module.

=head1 Connect Syntax

  use DBI;

  $dbh = DBI->connect("dbi:RDB:ATTACH FILENAME <rootfile>" );

  # The $user and $passwd parameters of the standard connect are unused.
  # They should be included instead in the ATTACH if needed for a remote
  # connection


The connect use the syntax of the CONNECT TO statement. The example above
connects to a database with the rootfile <rootfile> and use the standard RDB
alias. If inside SQL a connect works with

SQL> CONNECT TO 'connect-string';

then the next command should also work:

  $dbh = DBI->connect("dbi:RDB:connect-string");

An example with a second alias inside the same connection is

  $dbh = DBI->connect("dbi:RDB:ATTACH FILENAME <rootfile-1>, 
                               ATTACH ALIAS A FILENAME <rootfile-2>" );

Multiple connects (i.e. multiple $dbh's) are supported using the 
C<SET CONNECT> inside the DBD.

=head1 Datatypes

=head2 Numerica data handling

DBD::RDB supports these numeric datatypes

    TINYINT              - signed 8-bit integer
    SMALLINT             - signed 16-bit integer
    INTEGER              - signed 32-bit integer
    BIGINT               - signed 64-bit integer
                         - all four can have PRECISION
    FLOAT                - native C 'double'
    REAL                 - native C 'float'
    DOUBLE PRECISION     - Synonym for FLOAT
                         - using PRECISION switch between float and double

The corresponding IV and NV representation is used. BIGINTs are 
represented as strings. The conversion between NV and float and 
vice versa signals floating overflow and underflow in case.

=head2 String data handling

DBD::RDB supports the following string datatypes

    VARCHAR(size)
    CHAR(size)
    CHAR

CHAR and VARCHAR have a limit of 65,271 octets. CHAR is fixed-length and
blank-padded. NCHAR, NATIONAL CHR, etc. are not tested.

=head2 Date data handling

RDB stores all date/time columns in 64-Bit VMS format. That means that the 
driver does not see the choosen SQL datatype. From this internal format
the date/time is converted to string format using a given format. The
format is specified as a database handle attribute.

  $dbh->{rdb_dateformat} = '|!DB-!MAAU-!Y4|!H04:!M0:!S0.!C2|'

This is the VMS standard date format. Normally the attribute is used in
the connect statement. Every format the LIBRTL routines can take is allowed.
The default used in the connect is '|!Y4!MN0!D0|!H04!M0!S0!C2|'. This
format is used for the conversion from RDB to Perl The other direction use
the following list after checking the current output format.

    !DB-!MAAU-!Y4|!H04:!M0:!S0.!C2             1-DEC-2000 23:12:10.99
    !DB.!MAAU.!Y4|!H04:!M0:!S0.!C2             1.DEC.2000 23:12:10.99
    !D0.!MN0.!Y4|!H04:!M0:!S0.!C2              01.12.2000 23:12:10.99
    !D0.!MN0.!Y2|!H04:!M0:!S0.!C2              01.12.00 23:12:10.99
    !D0-!MN0-!Y4|!H04:!M0:!S0.!C2              01-12-2000 23:12:10.99
    !D0-!MN0-!Y2|!H04:!M0:!S0.!C2              01-12-00 23:12:10.99
    !Y4.!MN0.!D0|!H04:!M0:!S0.!C2              2000.12.01 23:12:10.99
    !Y4!MN0!D0|!H04!M0!S0!C7                   20001201 2312109912345
    !Y4!MN0!D0|!H04:!M0:!S0.!C7                20001201 23:12:10.9912345

The current value of SYS$LANGUAGE influence the meaning of MAAU (name of month)
as in the corresponding LIBRTL routines.

Date Intervals are supported in all flavours. The format cannot be changed
like for the date types. 

=head2 Parameter Binding

Parameter binding is supported either in standard ? style or using 
named parameters. Named parameters can be used only with bind_param_inout.
If the first parameter is not an integer then it is taken as parameter name
(string) and compared against the parameter names used in the SQL statement.
These are either the column names or whatever was suggested 
with SELECT xx AS yy.

=head2 Stored Procedures

Stored procedures are supported. The use of bind_param_input
together with named parameter markers is recommended. An example is

    $dbh->do( "CREATE MODULE test_module_2 LANGUAGE SQL " .
              "PROCEDURE proc_b( OUT :a integer, INOUT :b integer, " .
              "                  IN :c char(5),  INOUT :parD char(10) ); " .
              "  BEGIN " .
              "   SET :b = :b + 10; " .
	      "   SET :a = :b + 123; " .
	      "   SET :parD = :c || :parD; " .
              "  END; " .
              "END MODULE" );
    $st_call = $dbh->prepare( "CALL proc_b( ?, ?, ?, ?)" );
    $st_call->bind_param_inout( "A", \$a, 0 );
    $st_call->bind_param_inout( "B", \$b, 0 );
    $st_call->bind_param_inout( "C", \$c, 0 );
    $st_call->bind_param_inout( "PARD", \$d, 0 );

    $b = 32;
    $c = 'abcde';
    $d = 'fghij';
    $st_call->execute;

    die unless $a == 165;
    die unless $b == 42;
    die unless $d eq "abcdefghij";

=head2 Other data handling issues

The segmented string data type is not supported.

=head2 RDB specific extensions to DBI/DBD functionality

The first is the date/time format handling (see above). The second is
the possibility to open a CURSOR WITH HOLD. This option keeps
the cursor open even after a commit. This option is applied during a
prepare like

  $st = $dbh->prepare( "select column1 from table where " .
		       "       column2 > 10",
                       { rdb_hold => 1 } );

=head2 Examples

Examples can be found the test.pl file which tries to test all the
described features...


=head1 AUTHOR

DBD::RDB by Andreas Stiller. DBI by Tim Bunce.

=head1 COPYRIGHT

The DBD::RDB module is Copyright (c) 2000 Andreas Stiller. Germany.
The DBD::RDB module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself with the exception that it
cannot be placed on a CD-ROM or similar media for commercial distribution
without the prior approval of the author.

=cut
