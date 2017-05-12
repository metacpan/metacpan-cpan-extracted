use Devel::Peek qw( :ALL );
use DBI;
use strict;

$ENV{'SYS$LANGUAGE'} = 'ENGLISH';

my $debug = $ENV{DBD_RDB_DEBUG};
my ( $dbh, $sth, @types );
my $cur_test = 1;
my $std_attribs = { RaiseError => 0, PrintError => 0, AutoCommit => 0 };
my @types = (
    { sql_text => 'CHAR(111)', type => 453, precision => 111 },
    { sql_text => 'VARCHAR(12345)', type => 449, precision => 12345 },
    { sql_text => 'TINYINT', type => 515, precision => 2 },
    { sql_text => 'TINYINT(1)', type => 515, precision => 2, scale => 1 },
    { sql_text => 'SMALLINT', type => 501, precision => 4 },
    { sql_text => 'SMALLINT(3)', type => 501, precision => 4, scale => 3 },
    { sql_text => 'INTEGER', type => 497, precision => 9 },
    { sql_text => 'INTEGER(6)', type => 497, precision => 9, scale => 6 },
    { sql_text => 'BIGINT', type => 505, precision => 18 },
    { sql_text => 'BIGINT(10)', type => 505, precision => 18, scale => 10 },
    { sql_text => 'DATE VMS', type => 503, precision => 22 },
	# precision is length of last $dbh->{rdb_dateformat}
    { sql_text => 'FLOAT', type => 481, precision => 15 },
    { sql_text => 'FLOAT(24)', type => 481, precision => 6 },
    { sql_text => 'INTERVAL YEAR(6) TO MONTH', type => 521, precision => 17 },
    { sql_text => 'INTERVAL DAY(6) TO SECOND(2)', type => 521, precision => 19 }
       # RDB allows not determine the INTERVAL subtype, therefore the prec is
       # estimated with an upper bound using the longest format
       # DAY(scale) TO SECOND(precision) 
       # This upper bound is the sum of
       # 1           for sign
       # scale       for days
       # precision   for subseconds
       # 6           for hours, minutes, seconds
       # 4           for delimiters : : : .
       # (scale and precision are delivered from RDB, but not the subtype)       
);
my @tests = qw ( 
    test_load_dbd
    test_connect_error
    test_create_db
    test_connect
    test_do_set_trans_rw
    test_char_unchopped
    test_varchar_unchopped 
    test_char_chopped 
    test_varchar_chopped 
    test_tinyint_unchecked 
    test_tinyint_checked 
    test_smallint_unchecked 
    test_smallint_checked 
    test_integer_unchecked 
    test_integer_checked 
    test_bigint 
    test_tinyint_scaled 
    test_smallint_scaled 
    test_integer_scaled 
    test_double 
    test_float 
    test_date_1 
    test_date_2 
    test_interval_1 
    test_interval_2
    test_create_all_types 
    test_NAME 
    test_NAME_lc 
    test_NAME_uc 
    test_PRECISION 
    test_SCALE 
    test_TYPE 
    test_NULLABLE 
    test_CursorName 
    test_NUM_OF_FIELDS 
    test_NUM_OF_PARAMS
    test_hold_and_current_of
    test_bind
    test_bind_by_name
    test_get_info
 );


print "1..", scalar(@tests), "\n";
foreach my $test ( @tests ) {
    print "---- Start $test ----\n" if $debug;

    my $errors;
    DBI->trace(4) if $debug =~ /$test/i;
    eval {
	no strict 'refs';
	&{$test}();
    };
    DBI->trace(0);

    if ( !$@ ) {
	print "ok $cur_test\n";
    } else {
	print "not ok $cur_test\n";
	print "$@\n" if $debug;
    }
    $cur_test++;
}

########################## TEST ROUTINES ################################


#
#  load driver
#
sub test_load_dbd {
    my $ok = require DBD::RDB;
    check( $ok, 'require of DBD::RDB' );
}

#
# try to connect to a non existing database, expect error
#
sub test_connect_error {
    my $dbh = DBI->connect( 'dbi:RDB: ATTACH FILENAME XXXX.RDB', 
		            "", "", $std_attribs );
    my $ok = ($DBI::errstr =~ /RDB\-E\-BAD_DB_FORMAT/);
    check( $ok, 'connect to non existing DB', $DBI::errstr );
}

#
#  create test database
#  Additionally test return value of $dbh->do for non-select
#
sub test_create_db {
    $dbh = DBI->connect( 'dbi:RDB:', undef, undef, $std_attribs );
    check ( $dbh, 'connect', $DBI::errstr );
    my $ok = $dbh->do('CREATE DATABASE FILENAME TEST.RDB'); 
    check ( $ok == "0E0", 'CREATE DATABASE', $DBI::errstr );
    check ( $dbh->disconnect, 'disconnect', $DBI::errstr );
}    
#
#  connect to test database again and keep dbh
#
sub test_connect {
    $dbh = DBI->connect( 'dbi:RDB: ATTACH FILENAME TEST.RDB',
	                 "", "", $std_attribs );
    check( $dbh, 'connect', $DBI::errstr );
}

#
# set trans read write => to test 'do' and 'do' error handling
#
sub test_do_set_trans_rw {
    my $ok;

    $ok = $dbh->do('SET TRANSACTION READ WRITE');
    check( $ok == "0E0", 'do of SET TRANS READ WRITE', $DBI::errstr );

    $ok = $dbh->commit;
    check( $ok, 'COMMIT', $DBI::errstr );

    $ok = $dbh->rollback;
    check( !$ok, 'ROLLBACK', 'unexpected success' );

    check( ($DBI::errstr eq
            "%SQL-F-NOIMPTXN, no implicit transaction to commit or rollback"),
            'test DBI::errstr for double rollback (NOIMPTXN)', $DBI::errstr );
}

#
#  INSERT/FETCH of CHAR without option "chop"
#
sub test_char_unchopped {
    my $vals = [
	{ in => 'abcde' },
	{ in => 'abc ', out => 'abc  ' },
	{ in => '123456', out => '12345' },
	{ in => undef },
	{ in => 999, out => '999  ' },
	{ in => "", out => '     ' } ];
    
    $dbh->{ChopBlanks} = 0;
    my $chopped = $dbh->{ChopBlanks};
    check( !$chopped, 'set ChopBlanks = 0', $DBI::errstr );

    test_data_type( "CHAR(5)", 0, $vals  );
}


#
#  INSERT/FETCH of VARCHAR without option "chop"
#
sub test_varchar_unchopped {
    my $vals = [
	{ in => 'ABCdEFG' },
	{ in => 'GULP' },
	{ in => '123456789', out => '12345678' },
	{ in => undef },
	{ in => -101.12, out => '-101.12' },
	{ in => '' } ];
	
    test_data_type( "VARCHAR(8)", 0, $vals  );
}



#
#  INSERT/FETCH of CHAR with option "chop"
#
sub test_char_chopped {
    my $vals = [
	{ in => 'abcd' },
	{ in => '123 ', out => '123' },
	{ in => '54321', out => '5432' },
	{ in => undef },
	{ in => 87, out => '87' },
	{ in => '' } ];

    $dbh->{ChopBlanks} = 1;
    my $chopped = $dbh->{ChopBlanks};
    check ( $chopped, 'set ChopBlanks = 1', $DBI::errstr );

    test_data_type( "CHAR(4)", 0, $vals );
}


#
#  INSERT/FETCH of VARCHAR with (chop should affect VARCHAR at all,
#  there was a bug about this)
#
sub test_varchar_chopped {
    my $vals = [
	{ in => 'ABCdEFG' },
	{ in => 'GULP' },
	{ in => '123456789', out => '12345678' },
	{ in => undef },
	{ in => -101.12, out => '-101.12' },
	{ in => '' } ];
	
    test_data_type( "VARCHAR(8)", 0, $vals  );
}



#
#  INSERT/FETCH of TINYINT, not checking for integer overflows
#
sub test_tinyint_unchecked {
    my $vals = [
	{ in => 1 },
	{ in => 127 },
	{ in => -128 },
	{ in => 0 },
	{ in => undef },
	{ in => 128, out => -128 },
	{ in => -129, out => 127 } ];

    $dbh->{rdb_overflow_kills} = 0;
    my $checked = $dbh->{rdb_overflow_kills};
    check ( !$checked, 'set rdb_overflow_kills = 0', $DBI::errstr );

    test_data_type( "TINYINT", 1, $vals );
}


#
#  INSERT/FETCH of TINYINT, checking for integer overflows
#
sub test_tinyint_checked {
    my $vals = [
	{ in => 1 },
	{ in => 127 },
	{ in => -128 },
	{ in => 0 },
	{ in => undef },
	{ in => 128, expected_error => 1 },
	{ in => -129, expected_error => 1 } ];

    $dbh->{rdb_overflow_kills} = 1;
    my $checked = $dbh->{rdb_overflow_kills};
    check ( $checked, 'set rdb_overflow_kills = 0', $DBI::errstr );

    test_data_type( "TINYINT", 1, $vals );
}

#
#  INSERT/FETCH of SMALLINT, not checking for integer overflows
#
sub test_smallint_unchecked {
    my $vals = [
	{ in => 1 },
	{ in => 32767 },
	{ in => -32768 },
	{ in => 0 },
	{ in => undef },
	{ in => 40000, out => -25536 } ];

    $dbh->{rdb_overflow_kills} = 0;
    my $checked = $dbh->{rdb_overflow_kills};
    check ( !$checked, 'set rdb_overflow_kills = 0', $DBI::errstr );

    test_data_type( "SMALLINT", 1, $vals );
}

#
#  INSERT/FETCH of SMALLYINT, checking for integer overflows
#
sub test_smallint_checked {
    my $vals = [
	{ in => 1 },
	{ in => 32767 },
	{ in => -32768 },
	{ in => 0 },
	{ in => undef },
	{ in => 40000, expected_error => 1 } ];

    $dbh->{rdb_overflow_kills} = 1;
    my $checked = $dbh->{rdb_overflow_kills};
    check ( $checked, 'set rdb_overflow_kills = 0', $DBI::errstr );

    test_data_type( "SMALLINT", 1, $vals );
}

#
#  INSERT/FETCH of INTEGER, not checking for integer overflows
#
sub test_integer_unchecked {
    my $vals = [
	{ in => 1 },
	{ in => 123456789 },
	{ in => -987654321 },
	{ in => 0 },
	{ in => undef },
	{ in => 9876543210, out => 1286608618  } ];

    $dbh->{rdb_overflow_kills} = 0;
    my $checked = $dbh->{rdb_overflow_kills};
    check ( !$checked, 'set rdb_overflow_kills = 0', $DBI::errstr );

    test_data_type( "INTEGER", 1, $vals );
}

#
#  INSERT/FETCH of INTEGER, checking for integer overflows
#
sub test_integer_checked {
    my $vals = [
	{ in => 1 },
	{ in => 123456789 },
	{ in => -987654321 },
	{ in => 0 },
	{ in => undef },
	{ in => 9876543210, expected_error => 1 } ];

    $dbh->{rdb_overflow_kills} = 1;
    my $checked = $dbh->{rdb_overflow_kills};
    check ( $checked, 'set rdb_overflow_kills = 0', $DBI::errstr );

    test_data_type( "INTEGER", 1, $vals );
}

#
#  INSERT/FETCH of BIGINT, (fetched as string data)
#
sub test_bigint {
    my $vals = [
	{ in => 1 },
	{ in => 123456789012345, out => '123456789012345' },
	{ in => '-543210987654321' },
	{ in => 0 },
	{ in => undef } ];

    test_data_type( "BIGINT", 0, $vals );
}

#
#  INSERT/FETCH of scaled TINYINT (from now on integer overflows are
#  checked)
#
sub test_tinyint_scaled {
    my $vals = [
	{ in => 1.10, out => '1.10' },
	{ in => 1.27, out => '1.27' },
	{ in => -1.28, out => '-1.28' },
	{ in => 0, out => '0.00' },
	{ in => undef },
	{ in => 0.01, out => '0.01' },
	{ in => -0.2, out => '-0.20' } ];

    test_data_type( "TINYINT(2)", 1, $vals );
}

#
#  INSERT/FETCH of scaled SMALLINT
#
sub test_smallint_scaled {
    my $vals = [
	{ in => 1.12, out => '1.120' },
	{ in => 32.767, out => '32.767' },
	{ in => -32.768, out => '-32.768' },
	{ in => 0, out => '0.000' },
	{ in => undef },
	{ in => '0.03', out => '0.030' },
	{ in => -0.004, out => '-0.004' } ];

    test_data_type( "SMALLINT(3)", 1, $vals );
}


#
#  INSERT/FETCH of scaled INTEGER
#
sub test_integer_scaled {
    my $vals = [
	{ in => 1, out => '1.00' },
	{ in => 1234567.89, out => '1234567.89' },
	{ in => -9876543.21, out => '-9876543.21' },
	{ in => 0, out => '0.00' },
	{ in => undef },
	{ in => '+0.3', out => '0.30' },
	{ in => -20, out => '-20.00' } ];

    test_data_type( "INTEGER(2)", 1, $vals );
}

#
#  INSERT/FETCH of DOUBLE
#
sub test_double {
    my $vals = [
	{ in => 1.1 },
	{ in => -1.2345678901 },
	{ in => -1.27E34 },
	{ in => 0.000045 },
	{ in => 1.12E-330 },
	{ in => 0.012E-10 },
	{ in => 123456789 },
	{ in => -0.987E200 } ];

    test_data_type( "FLOAT", 1, $vals );
}

#
#  INSERT/FETCH of FLOAT(24), means it is stored as 4-byte FLOAT
#  floating under- and overflow is checked always
#
sub test_float {
    my $vals = [
	{ in => 1.123 },
	{ in => 32.767E30 },
	{ in => -1.0001E-34 },
	{ in => 1.1234E10 },
	{ in => undef },
	{ in => 0.000001 },
	{ in => 1.12E45, expected_error => 1 },
	{ in => -1.12E-45, expected_error => 1 },
	{ in => 1.23456780, out => 1.234568 } ];

    test_data_type( "FLOAT(24)", 1, $vals );
}

#
#  INSERT/FETCH of DATE VMS 
#
sub test_date_1 {
    my $vals = [
	{ in => '1-JAN-1963 13:15', out => '1963.01.01 13:15:00.00' },
	{ in => '15.OCT.2001', out => '2001.10.15 00:00:00.00' },
	{ in => '13.DEC.2000 12:12:12.12', out => '2000.12.13 12:12:12.12' },
	{ in => '01.07.1900 09:08:07.99', out => '1900.07.01 09:08:07.99' },
	{ in => '09.07.63 12', out => '2063.07.09 12:00:00.00' },
	{ in => '01-DEZ-2000', expected_error => 1 },
	{ in => '29-FEB-1999', expected_error => 1 }
    ];

    my $format = "|!Y4.!MN0.!D0|!H04:!M0:!S0.!C2|";
    $dbh->{rdb_dateformat} = $format;
    my $date_format = $dbh->{rdb_dateformat};
    check( $date_format eq $format, 'set dateformat', $format );

    test_data_type( "DATE VMS", 0, $vals );
}

#
#  INSERT/FETCH of DATE VMS, (SYS$LANGUAGE was set at the start)
#
sub test_date_2 {
    my $vals = [
	{ in => '1-JAN-1963 13:15', out => '19630101 1315000000000' },
	{ in => '15.OCT.2001', out => '20011015 0000000000000' },
	{ in => '13.DEC.2000 12:12:12.12', out => '20001213 1212121200000' },
	{ in => '01.07.1900 09:08:07.99', out => '19000701 0908079900000' },
	{ in => '09.07.63 12', out => '20630709 1200000000000' },
	{ in => '20010909 1234567654321', out => '20010909 1234567654321' },
    ];

    my $format = "|!Y4!MN0!D0|!H04!M0!S0!C7|";
    $dbh->{rdb_dateformat} = $format;
    my $date_format = $dbh->{rdb_dateformat};
    check( $date_format eq $format, 'set dateformat', $format );

    test_data_type( "DATE VMS", 0, $vals );
}


#
#  INSERT/FETCH of DATE INTERVAL (YEAR-MONTH)
#
sub test_interval_1 {
    my $vals = [
	{ in => '0000-11', out => ' 0000-11' },
	{ in => '-12-0', out => '-0012-00' },
	{ in => '1111-01', out => ' 1111-01' },
	{ in => '-9998-13', out => '-9998-13', expected_error => 1 }, 
	{ in => '12345-01', out => ' ****-01' }     # no exception !!!
];

    test_data_type( "INTERVAL YEAR(4) TO MONTH", 0, $vals );
}


#
#  INSERT/FETCH of DATE INTERVAL (DAY TO SECOND)
#
sub test_interval_2 {
    my $vals = [
	{ in => '1:1:1:1', out => ' 000001:01:01:01' },
	{ in => '11:11:11:11', out => ' 000011:11:11:11' },
	{ in => '123456:23:59:59', out => ' 123456:23:59:59' },
	{ in => '123456:24:59:59', out => ' 123456:24:59:59', 
			expected_error => 1 },
	{ in => '1234567:23:59:59', out => ' ******:23:59:59' },
];

    test_data_type( "INTERVAL DAY(6) TO SECOND(0)", 0, $vals );
}


#
#  creating a table holding all kind of datatypes,
#  check for statement handle info "Statement"
#
sub test_create_all_types {
    #
    #  start READ WRITE transaction
    #
    my $ok = $dbh->do('SET TRANSACTION READ WRITE');
    check ( ( $ok == "0E0" || $DBI::errstr !~ /%SQL-F-BAD_TXN_STATE/ ),
	    'do of SET TRANS READ WRITE', $DBI::errstr );

    my $st_table = "CREATE TABLE my_all_types (";
    my $col = 1;
    foreach my $type ( @types ) {
	$st_table .= "," if ( $col > 1 );
	$st_table .= "Col$col $type->{sql_text}";
	$col++;
    }
    $st_table .= ")";
    $ok = $dbh->do( $st_table );
    check ( $ok == "0E0", "create table with\n$st_table", $DBI::errstr );

    $ok = $dbh->commit;
    check( $ok, 'COMMIT', $DBI::errstr );

    $ok = $dbh->do('SET TRANSACTION READ ONLY');
    check( $ok == "0E0", 'do of SET TRANS READ ONLY', $DBI::errstr );

    my $st_sel = "SELECT ";
    my $col = 1;
    foreach my $type ( @types ) {
	$st_sel .= "," if ( $col > 1 );
	$st_sel .= "Col$col";
	$col++;
    }
    $st_sel .= " FROM my_all_types WHERE Col1 = ? and Col2 = ?";
    $sth = $dbh->prepare( $st_sel );
    check ( $sth, 'prepare of SELECT', $DBI::errstr );

    my $st_text = $sth->{Statement};
    check( $st_text eq $st_sel,
	   'sth->{Statement}', $st_text, $st_sel );
}

#
# check for sth_info NAME
#
sub test_NAME {

    my $col = 1;
    foreach my $name ( @{$sth->{NAME}} ) {
	check ( $name eq uc("Col$col"), "sth->{NAME}", $name, "Col$col" );
	$col++;
    }
}

#
# check for sth_info NAME_lc
#
sub test_NAME_lc {

    my $col = 1;
    foreach my $name ( @{$sth->{NAME_lc}} ) {
	check( $name eq "col$col", "sth->{NAME_lc}", $name, "COL$col" );
	$col++;
    }
}

#
# check for sth_info NAME_uc
#
sub test_NAME_uc {

    my $col = 1;
    foreach my $name ( @{$sth->{NAME_uc}} ) {
	check ( $name eq "COL$col", "sth->{NAME_uc}", $name, "COL$col" );
	$col++;
    }
}

#
# check for sth_info PRECISION
#
sub test_PRECISION {

    my $col = 1;
    foreach my $precision ( @{$sth->{PRECISION}} ) {
	my $expected = $types[$col-1]->{precision};
	my $sql_text = $types[$col-1]->{sql_text};
	check ( $precision == $expected, 
	        "sth->{PRECISION}, $sql_text", $precision, $expected );
	$col++;
    }
}

#
# check for sth_info SCALE
#
sub test_SCALE {

    my $col = 1;
    foreach my $scale ( @{$sth->{SCALE}} ) {
	my $expected = $types[$col-1]->{scale} || 0;
	my $sql_text = $types[$col-1]->{sql_text};
	check ( $scale == $expected,
	        "sth->{SCALE}, $sql_text", $scale, $expected );
	$col++;
    }
}

#
# check for sth_info TYPE
#
sub test_TYPE {

    my $col = 1;
    foreach my $type ( @{$sth->{TYPE}} ) {
	my $expected = $types[$col-1]->{type};
	my $sql_text = $types[$col-1]->{sql_text};
	check ( $type eq $expected,
	        "sth->{TYPE}, $sql_text", $type, $expected );
	$col++;
    }
}

#
# check for sth_info NULLABLE (not available, so it is always 2)
#
sub test_NULLABLE {

    my $col = 1;
    foreach my $nullable ( @{$sth->{NULLABLE}} ) {
	my $expected = 2;
	my $sql_text = $types[$col-1]->{sql_text};
	check ( $nullable == $expected,
	        "sth->{NULLABLE}, $sql_text", $nullable, $expected );
	$col++;
    }
}

#
# check for sth_info CursorName
#
sub test_CursorName {

    my $cursor = $sth->{CursorName};
    check ( $cursor =~ /^CUR_(\d+)$/, 'sth->{CursorName}', $cursor );
}

#
# check for sth_info NUM_OF_FIELDS
#
sub test_NUM_OF_FIELDS {
    
    my $num_of_fields = $sth->{NUM_OF_FIELDS};
    check( $num_of_fields == @types, 
	   'sth->{NUM_OF_FIELDS}', $num_of_fields, scalar(@types) )
}


#
# check for sth_info NUM_OF_PARAMS
#
sub test_NUM_OF_PARAMS {
    
    my $num_of_params = $sth->{NUM_OF_PARAMS};
    check ( $num_of_params == 2, 'sth->{NUM_OF_PARAMS}', $num_of_params, 2 );
    $dbh->commit;
}


#
# test of rdb_hold attribute of a statement handle. This cursor
# is kept open over commits
# Additionally execute return codes are checked;
#
sub test_hold_and_current_of {

    my $ok = $dbh->do( 'SET TRANSACTION READ WRITE' );
    check( $ok == "0E0", "SET TRANS RW 1", $DBI::errstr );

    $ok = $dbh->do( 'CREATE TABLE hold_test ( id integer, val integer )' );
    check( $ok == "0E0", "CREATE TABLE", $DBI::errstr );

    my $st_ins = $dbh->prepare( 'INSERT INTO hold_test VALUES(?,?)' );
    check( $st_ins, "PREPARE insert", $DBI::errstr );

    foreach my $i ( 1..100 ) {
	$ok = $st_ins->execute( $i, $i );
	check( $ok == 1, "INSERT", $i, $ok, $DBI::errstr );
    }
    $ok = $dbh->commit;
    check( $ok, "COMMIT 1", $DBI::errstr );

    $ok = $dbh->do( 'SET TRANSACTION READ WRITE' );
    check( $ok == "0E0", "SET TRANS RW 2", $DBI::errstr );

    my $st_sel = $dbh->prepare( 'SELECT id, val FROM hold_test',
		                { rdb_hold => 1 } );
    check( $st_sel, 'PREPARE select with hold', $DBI::errstr );     

    my $st_upd = $dbh->prepare( 'UPDATE hold_test SET val = NULL ' .
                                'WHERE CURRENT OF '. 
				$st_sel->{CursorName} );
    check( $st_upd, 'PREPARE update', $DBI::errstr );     

    $ok = $st_sel->execute;
    check( $ok == -1, "EXECUTE select", $DBI::errstr );
    my ( $id, $val );
    $ok = $st_sel->bind_columns( \$id, \$val );
    check( $ok, "bind params", $DBI::errstr );

    while ( $st_sel->fetch ) {
	if ( $val % 2 ) {
	    $ok = $st_upd->execute;
	    check( $ok == 1, "UPDATE", $DBI::errstr );
	    $ok = $dbh->commit;
	    check( $ok, "COMMIT 2", $DBI::errstr );
	    $ok = $dbh->do( "SET TRANSACTION READ WRITE" );
	    check( $ok == "0E0", "SET TRANS RW 3", $DBI::errstr );
	}
    }

    my $count = $dbh->selectrow_array( "SELECT COUNT(*) FROM hold_test " .
                                       "WHERE val IS NULL" );
    check( $count == 50, "unexpected number of NULL rows", $count,
	   $DBI::errstr );

    $ok = $dbh->do( "UPDATE hold_test SET VAL = ID" );
    check( $ok == 100, "unexpected number of rows affected in do UPDATE",
           $ok, $DBI::errstr );

    $ok = $dbh->commit;
    check( $ok, "COMMIT", $DBI::errstr );
}    

sub test_bind {

    my $ok = $dbh->do( "SET TRANSACTION READ WRITE" );
    check( $ok == "0E0", "SET TRANS RW", $DBI::errstr );

    $ok = $dbh->do( "CREATE MODULE test_module_1 LANGUAGE SQL " .
                    "PROCEDURE proc_a( IN :a integer, IN :b integer, " .
		    "                  OUT :c integer, OUT :d char(5) ); " .
		    "  BEGIN " .
		    "   SET :c = :a + :b; " .
		    "   SET :d = 'Gulp'; " .
		    "  END; " .
		    "END MODULE" );
    check( $ok == "0E0", "CREATE MODULE", $DBI::errstr );

    my $st_call = $dbh->prepare( "CALL proc_a( ?, ?, ?, ?)" );
    check( $st_call, "PREPARE call", $DBI::errstr );

    my ( $b, $c, $d );
    $ok = $st_call->bind_param( 1, 10 );
    check( $ok, "bind_param 1", $DBI::errstr );

    $ok = $st_call->bind_param_inout( 2, \$b, 0 );
    check( $ok, "bind_param 2", $DBI::errstr );

    $ok = $st_call->bind_param_inout( 3, \$c, 0 );
    check( $ok, "bind_param 3", $DBI::errstr );

    $ok = $st_call->bind_param_inout( 4, \$d, 0 );
    check( $ok, "bind_param 4", $DBI::errstr );

    $b = 32;
    $ok = $st_call->execute;
    check( $ok == "0E0", "execute of CALL", $DBI::errstr );

    check( $c == 42, "output par 3 <> 42", $c );
    check( $d eq "Gulp", "output par 4 <> Gulp", $d );

    $ok = $dbh->commit;
    check( $ok, "COMMIT", $DBI::errstr );
}    

#
#  bind using SQL-names of parameters (or fields)
#  additionally correct REF-counting of bound SVs is checked
#
sub test_bind_by_name {
    my $ok = $dbh->do( "SET TRANSACTION READ WRITE" );
    check( $ok == "0E0", "SET TRANS RW", $DBI::errstr );

    $ok = $dbh->do( "CREATE MODULE test_module_2 LANGUAGE SQL " .
                    "PROCEDURE proc_b( OUT :a integer, INOUT :b integer, " .
		    "                  IN :c char(5),  INOUT :parD char(10) ); " .
		    "  BEGIN " .
		    "   SET :b = :b + 10; " .
		    "   SET :a = :b + 123; " .
		    "   SET :parD = :c || :parD; " .
		    "  END; " .
		    "END MODULE" );
    check( $ok == "0E0", "CREATE MODULE", $DBI::errstr );

    my ( $a, $b, $c, $d );
    {
	my $st_call = $dbh->prepare( "CALL proc_b( ?, ?, ?, ?)" );
	check( $st_call, "PREPARE call", $DBI::errstr );

	$ok = $st_call->bind_param_inout( "A", \$a, 0 );
	check( $ok, "bind_param a", $DBI::errstr );
	check( SvREFCNT($a) == 2, "REFCNT of a <> 2", SvREFCNT($a) );

	$ok = $st_call->bind_param_inout( "B", \$b, 0 );
	check( $ok, "bind_param b", $DBI::errstr );
	check( SvREFCNT($b) == 3, "REFCNT of b <> 3", SvREFCNT($b) );

	$ok = $st_call->bind_param_inout( "C", \$c, 0 );
	check( $ok, "bind_param c", $DBI::errstr );
	check( SvREFCNT($c) == 2, "REFCNT of c <> 2", SvREFCNT($c) );

	$ok = $st_call->bind_param_inout( "PARD", \$d, 0 );
	check( $ok, "bind_param pard", $DBI::errstr );
	check( SvREFCNT($d) == 3, "REFCNT of d <> 3", SvREFCNT($d) );

	$b = 32;
	$c = 'abcde';
	$d = 'fghij';
	$ok = $st_call->execute;
	check( $ok == "0E0", "execute of CALL", $DBI::errstr );

	check( $a == 165, "output par a <> 165", $a );
	check( $b == 42, "output par b <> 42", $b );
	check( $d eq "abcdefghij", "output par parD <> abcdefghij", $d );
    }
    check( SvREFCNT($a) == 1, "REFCNT of a <> 1 after destroy", SvREFCNT($a) );
    check( SvREFCNT($b) == 1, "REFCNT of b <> 1 after destroy", SvREFCNT($b) );
    check( SvREFCNT($c) == 1, "REFCNT of c <> 1 after destroy", SvREFCNT($c) );
    check( SvREFCNT($d) == 1, "REFCNT of d <> 1 after destroy", SvREFCNT($d) );

    $ok = $dbh->commit;
    check( $ok, "COMMIT", $DBI::errstr );

}    
		    
sub test_get_info {
    my $ok = $dbh->get_info(17);
    check( $ok eq "Oracle RDB", "get_info(17) = $ok", $DBI::errstr );
    $ok = $dbh->get_info(18);
    check( scalar($ok =~ /^(\d+)\.(\d+)/), "get_info(18) = $ok", $DBI::errstr );
}    


###################### INTERNAL SUBROUTINES ##########################

#
#  signal error out of a test routine
#
sub check {
    my ( $ok, @info ) = @_;

    return if $ok;
    my $text = join "\n", @info;
    die $text;
}

#
#  subroutine to make a INSERT/FETCH test for a given "data_type"
#  the comparison use "is_numeric" for the comparison operator
#
sub test_data_type {
    my ( $data_type, $is_numeric, $vals ) = @_;

    my ( $ok, $row, $caller, $table );

    $caller = (caller(1))[3];
    ($table) = $caller =~ /([\w_\d]*)$/;

    #
    #  start READ WRITE transaction
    #
    $ok = $dbh->do('SET TRANSACTION READ WRITE');
    check ( ( $ok == "0E0" || $DBI::errstr =~ /%SQL-F-BAD_TXN_STATE/ ),
	    'do of SET TRANS READ WRITE', $DBI::errstr );

    #
    #  construct CREATE TABLE statement
    #
    my $cre_table = "CREATE TABLE $table (ID INTEGER, VAL $data_type)";
    #
    #  execute CREATE TABLE statement
    #
    $ok = $dbh->do($cre_table);
    check( $ok == "0E0", "create table with\n$cre_table", $DBI::errstr );

    #
    #  construct INSERT INTO statement
    #
    my $ins_table = "INSERT INTO $table (ID,VAL) VALUES(?,?)";
    
    #
    #  prepare INSERT statement
    #
    my $st_ins = $dbh->prepare( $ins_table );
    check( $st_ins, 'INSERT statement prepare', $DBI::errstr );

    #
    #  execute INSERT assuming that every column's "values" array has the
    #  same length
    #
    $row = 0;
    foreach my $val ( @$vals ) {
	$row++;
	$ok = $st_ins->execute( $row, $val->{in} );
	#
	#  check both:
	#  1) error AND expected success
	#  2) success AND expected error
	#
	if ( $ok != 1 && !$val->{expected_error} ) {
	    $dbh->commit;
	    check( 0, "INSERT execute (row $row)", 'unexpected error',
	           $DBI::errstr );
	}
	if ( $ok && $val->{expected_error} ) {
	    $dbh->commit;
	    check( 0, "INSERT execute (row $row)", 'unexpected success' );
	}
    }
    #
    #  finish the INSERT
    #
    $ok = $st_ins->finish;	
    check ( $ok, 'INSERT statement finish', $DBI::errstr );
    
    #
    #  commit the CREATE TABLE and INSERT operations
    #
    $ok = $dbh->commit;
    check ( $ok, 'commit', $DBI::errstr );


    #
    #  the fetching will run in READ ONLY mode
    #
    $ok = $dbh->do('SET TRANSACTION READ ONLY');
    check( $ok == "0E0", 'do of SET TRANS READ ONLY before fetch',
	   $DBI::errstr );

    #
    #  construct a SELECT
    #
    my $select = "SELECT ID, VAL FROM $table ORDER BY ID ASC";
    my $st_sel = $dbh->prepare( $select );
    check( $st_sel, 'SELECT statement prepare', $DBI::errstr );

    #
    #  execute the SELECT
    #
    $ok = $st_sel->execute;
    check( $ok == -1, 'SELECT statement execute', $DBI::errstr );

    #
    #  FETCH all the rows and compare with expected results
    #
    $row = 0;
    foreach my $val ( @$vals ) {
	$row++;
	next if $val->{expected_error};
	my $p_values = $st_sel->fetch;

	$val->{out} = $val->{in} if !exists $val->{out};

	if ( defined $val->{out} ) {
	    if ( $is_numeric && $val->{out} != $$p_values[1] ||
	         !$is_numeric && $val->{out} ne $$p_values[1] ) {
		$dbh->commit;
		check( 0, 
			 "compare fetched values at row $row",
			 "expected: |$val->{out}|",
			 "fetched: |$$p_values[1]|" );
	    }
	} elsif ( defined $$p_values[1] ) {
		$dbh->commit;
		check( 0,
			"compare fetched values at row $row",
			"expected: ||)",
			"fetched: $$p_values[1]" );
	}

	if ( $$p_values[0] != $row ) {
	    $dbh->commit;
	    check( 0, "ID check on row $row", $$p_values[0] );
	}

    }
    $ok = $st_sel->fetch;
    check ( !$ok, 'check end of cursor signalling' );

    $ok = $st_sel->finish;
    check ( $ok, 'finish', $DBI::errstr );

    $ok = $dbh->commit;
    check( $ok, 'COMMIT after fetching', $DBI::errstr );
}

