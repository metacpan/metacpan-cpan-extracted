package blx::xsdsql::schema_repository::sql::generic::name_generator;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use base qw(blx::xsdsql::ios::debuglogger);

my %INVALID_NAMES=map { ($_,undef) }  qw(
							A
							ABORT
							ABS
							ABSOLUTE
							ACCESS
							ACCESSIBLE
							ACTION
							ADA
							ADD
							ADMIN
							AFTER
							AGGREGATE
							ALIAS
							ALL
							ALLOCATE
							ALSO
							ALTER
							ALWAYS
							ANALYSE
							ANALYZE
							AND
							ANY
							ARE
							ARRAY
							AS
							ASC
							ASENSITIVE
							ASSERTION
							ASSIGNMENT
							ASYMMETRIC
							AT
							ATOMIC
							ATTRIBUTE
							ATTRIBUTES
							AUDIT
							AUTHORIZATION
							AUTO_INCREMENT
							AVG
							AVG_ROW_LENGTH
							BACKUP
							BACKWARD
							BEFORE
							BEGIN
							BERNOULLI
							BETWEEN
							BIGINT
							BINARY
							BIT
							BIT_LENGTH
							BITVAR
							BLOB
							BOOL
							BOOLEAN
							BOTH
							BREADTH
							BREAK
							BROWSE
							BULK
							BY
							C
							CACHE
							CALL
							CALLED
							CARDINALITY
							CASCADE
							CASCADED
							CASE
							CAST
							CATALOG
							CATALOG_NAME
							CEIL
							CEILING
							CHAIN
							CHANGE
							CHAR
							CHARACTER
							CHARACTERISTICS
							CHARACTER_LENGTH
							CHARACTERS
							CHARACTER_SET_CATALOG
							CHARACTER_SET_NAME
							CHARACTER_SET_SCHEMA
							CHAR_LENGTH
							CHECK
							CHECKED
							CHECKPOINT
							CHECKSUM
							CLASS
							CLASS_ORIGIN
							CLOB
							CLOSE
							CLUSTER
							CLUSTERED
							COALESCE
							COBOL
							COLLATE
							COLLATION
							COLLATION_CATALOG
							COLLATION_NAME
							COLLATION_SCHEMA
							COLLECT
							COLUMN
							COLUMN_NAME
							COLUMNS
							COMMAND_FUNCTION
							COMMAND_FUNCTION_CODE
							COMMENT
							COMMIT
							COMMITTED
							COMPLETION
							COMPRESS
							COMPUTE
							CONDITION
							CONDITION_NUMBER
							CONNECT
							CONNECTION
							CONNECTION_NAME
							CONSTRAINT
							CONSTRAINT_CATALOG
							CONSTRAINT_NAME
							CONSTRAINTS
							CONSTRAINT_SCHEMA
							CONSTRUCTOR
							CONTAINS
							CONTAINSTABLE
							CONTINUE
							CONVERSION
							CONVERT
							COPY
							CORR
							CORRESPONDING
							COUNT
							COVAR_POP
							COVAR_SAMP
							CREATE
							CREATEDB
							CREATEROLE
							CREATEUSER
							CROSS
							CSV
							CUBE
							CUME_DIST
							CURRENT
							CURRENT_DATE
							CURRENT_DEFAULT_TRANSFORM_GROUP
							CURRENT_PATH
							CURRENT_ROLE
							CURRENT_TIME
							CURRENT_TIMESTAMP
							CURRENT_TRANSFORM_GROUP_FOR_TYPE
							CURRENT_USER
							CURSOR
							CURSOR_NAME
							CYCLE
							DATA
							DATABASE
							DATABASES
							DATE
							DATETIME
							DATETIME_INTERVAL_CODE
							DATETIME_INTERVAL_PRECISION
							DAY
							DAY_HOUR
							DAY_MICROSECOND
							DAY_MINUTE
							DAYOFMONTH
							DAYOFWEEK
							DAYOFYEAR
							DAY_SECOND
							DBCC
							DEALLOCATE
							DEC
							DECIMAL
							DECLARE
							DEFAULT
							DEFAULTS
							DEFERRABLE
							DEFERRED
							DEFINED
							DEFINER
							DEGREE
							DELAYED
							DELAY_KEY_WRITE
							DELETE
							DELIMITER
							DELIMITERS
							DENSE_RANK
							DENY
							DEPTH
							DEREF
							DERIVED
							DESC
							DESCRIBE
							DESCRIPTOR
							DESTROY
							DESTRUCTOR
							DETERMINISTIC
							DIAGNOSTICS
							DICTIONARY
							DISABLE
							DISCONNECT
							DISK
							DISPATCH
							DISTINCT
							DISTINCTROW
							DISTRIBUTED
							DIV
							DO
							DOMAIN
							DOUBLE
							DROP
							DUAL
							DUMMY
							DUMP
							DYNAMIC
							DYNAMIC_FUNCTION
							DYNAMIC_FUNCTION_CODE
							EACH
							ELEMENT
							ELSE
							ELSEIF
							ENABLE
							ENCLOSED
							ENCODING
							ENCRYPTED
							END
							ENUM
							EQUALS
							ERRLVL
							ESCAPE
							ESCAPED
							EVERY
							EXCEPT
							EXCEPTION
							EXCLUDE
							EXCLUDING
							EXCLUSIVE
							EXEC
							EXECUTE
							EXISTING
							EXISTS
							EXIT
							EXP
							EXPLAIN
							EXTERNAL
							EXTRACT
							FALSE
							FETCH
							FIELDS
							FILE
							FILLFACTOR
							FILTER
							FINAL
							FIRST
							FLOAT
							FLOOR
							FLUSH
							FOLLOWING
							FOR
							FORCE
							FOREIGN
							FORTRAN
							FORWARD
							FOUND
							FREE
							FREETEXT
							FREETEXTTABLE
							FREEZE
							FROM
							FULL
							FULLTEXT
							FUNCTION
							FUSION
							G
							GENERAL
							GENERATED
							GET
							GLOBAL
							GO
							GOTO
							GRANT
							GRANTED
							GRANTS
							GREATEST
							GROUP
							GROUPING
							HANDLER
							HAVING
							HEADER
							HEAP
							HIERARCHY
							HIGH_PRIORITY
							HOLD
							HOLDLOCK
							HOST
							HOSTS
							HOUR
							HOUR_MICROSECOND
							HOUR_MINUTE
							HOUR_SECOND
							IDENTIFIED
							IDENTITY
							IDENTITYCOL
							IDENTITY_INSERT
							IF
							IGNORE
							ILIKE
							IMMEDIATE
							IMMUTABLE
							IMPLEMENTATION
							IMPLICIT
							IN
							INCLUDE
							INCLUDING
							INCREMENT
							INDEX
							INDICATOR
							INFILE
							INFIX
							INHERIT
							INHERITS
							INITIAL
							INITIALIZE
							INITIALLY
							INNER
							INOUT
							INPUT
							INSENSITIVE
							INSERT
							INSERT_ID
							INSTANCE
							INSTANTIABLE
							INSTEAD
							INT
							INTEGER
							INTERSECT
							INTERSECTION
							INTERVAL
							INTO
							INT0
							INT1 
							INT2 
							INT3 
							INT4 
							INVOKER
							IS
							ISAM
							ISNULL
							ISOLATION
							ITERATE
							JOIN
							K
							KEY
							KEY_MEMBER
							KEYS
							KEY_TYPE
							KILL
							LANCOMPILER
							LANGUAGE
							LARGE
							LAST
							LAST_INSERT_ID
							LATERAL
							LEADING
							LEAST
							LEAVE
							LEFT
							LENGTH
							LESS
							LEVEL
							LIKE
							LIMIT
							LINEAR
							LINENO
							LINES
							LISTEN
							LN
							LOAD
							LOCAL
							LOCALTIME
							LOCALTIMESTAMP
							LOCATION
							LOCATOR
							LOCK
							LOGIN
							LOGS
							LONG
							LONGBLOB
							LONGTEXT
							LOOP
							LOWER
							LOW_PRIORITY
							M
							MAP
							MASTER_SSL_VERIFY_SERVER_CERT
							MATCH
							MATCHED
							MAX
							MAXEXTENTS
							MAX_ROWS
							MAXVALUE
							MEDIUMBLOB
							MEDIUMINT
							MEDIUMTEXT
							MEMBER
							MERGE
							MESSAGE_LENGTH
							MESSAGE_OCTET_LENGTH
							MESSAGE_TEXT
							METHOD
							MIDDLEINT
							MIN
							MIN_ROWS
							MINUS
							MINUTE
							MINUTE_MICROSECOND
							MINUTE_SECOND
							MINVALUE
							MLSLABEL
							MOD
							MODE
							MODIFIES
							MODIFY
							MODULE
							MONTH
							MONTHNAME
							MORE
							MOVE
							MULTISET
							MUMPS
							MYISAM
							NAME
							NAMES
							NATIONAL
							NATURAL
							NCHAR
							NCLOB
							NESTING
							NEW
							NEXT
							NO
							NOAUDIT
							NOCHECK
							NOCOMPRESS
							NOCREATEDB
							NOCREATEROLE
							NOCREATEUSER
							NOINHERIT
							NOLOGIN
							NONCLUSTERED
							NONE
							NORMALIZE
							NORMALIZED
							NOSUPERUSER
							NOT
							NOTHING
							NOTIFY
							NOTNULL
							NOWAIT
							NO_WRITE_TO_BINLOG
							NULL
							NULLABLE
							NULLIF
							NULLS
							NUMBER
							NUMERIC
							OBJECT
							OCTET_LENGTH
							OCTETS
							OF
							OFF
							OFFLINE
							OFFSET
							OFFSETS
							OIDS
							OLD
							ON
							ONLINE
							ONLY
							OPEN
							OPENDATASOURCE
							OPENQUERY
							OPENROWSET
							OPENXML
							OPERATION
							OPERATOR
							OPTIMIZE
							OPTION
							OPTIONALLY
							OPTIONS
							OR
							ORDER
							ORDERING
							ORDINALITY
							OTHERS
							OUT
							OUTER
							OUTFILE
							OUTPUT
							OVER
							OVERLAPS
							OVERLAY
							OVERRIDING
							OWNER
							PACK_KEYS
							PAD
							PARAMETER
							PARAMETER_MODE
							PARAMETER_NAME
							PARAMETER_ORDINAL_POSITION
							PARAMETERS
							PARAMETER_SPECIFIC_CATALOG
							PARAMETER_SPECIFIC_NAME
							PARAMETER_SPECIFIC_SCHEMA
							PARTIAL
							PARTITION
							PASCAL
							PASSWORD
							PATH
							PCTFREE
							PERCENT
							PERCENTILE_CONT
							PERCENTILE_DISC
							PERCENT_RANK
							PLACING
							PLAN
							PLI
							POSITION
							POSTFIX
							POWER
							PRECEDING
							PRECISION
							PREFIX
							PREORDER
							PREPARE
							PREPARED
							PRESERVE
							PRIMARY
							PRINT
							PRIOR
							PRIVILEGES
							PROC
							PROCEDURAL
							PROCEDURE
							PROCESS
							PROCESSLIST
							PUBLIC
							PURGE
							QUOTE
							RAISERROR
							RANGE
							RANK
							RAW
							READ
							READ_ONLY
							READS
							READTEXT
							READ_WRITE
							REAL
							RECHECK
							RECONFIGURE
							RECURSIVE
							REF
							REFERENCES
							REFERENCING
							REGEXP
							REGR_AVGX
							REGR_AVGY
							REGR_COUNT
							REGR_INTERCEPT
							REGR_SLOPE
							REGR_SXX
							REGR_SXY
							REGR_SYY
							REINDEX
							RELATIVE
							RELEASE
							RELOAD
							RENAME
							REPEAT
							REPEATABLE
							REPLACE
							REPLICATION
							REQUIRE
							RESET
							RESIGNAL
							RESOURCE
							RESTART
							RESTORE
							RESTRICT
							RESULT
							RETURN
							RETURNED_CARDINALITY
							RETURNED_LENGTH
							RETURNED_OCTET_LENGTH
							RETURNED_SQLSTATE
							RETURNS
							REVOKE
							RIGHT
							RLIKE
							ROLE
							ROLLBACK
							ROLLUP
							ROUTINE
							ROUTINE_CATALOG
							ROUTINE_NAME
							ROUTINE_SCHEMA
							ROW
							ROWCOUNT
							ROW_COUNT
							ROWGUIDCOL
							ROWID
							ROWNUM
							ROW_NUMBER
							ROWS
							RULE
							SAVE
							SAVEPOINT
							SCALE
							SCHEMA
							SCHEMA_NAME
							SCHEMAS
							SCOPE
							SCOPE_CATALOG
							SCOPE_NAME
							SCOPE_SCHEMA
							SCROLL
							SEARCH
							SECOND
							SECOND_MICROSECOND
							SECTION
							SECURITY
							SELECT
							SELF
							SENSITIVE
							SEPARATOR
							SEQUENCE
							SERIALIZABLE
							SERVER_NAME
							SESSION
							SESSION_USER
							SET
							SETOF
							SETS
							SETUSER
							SHARE
							SHOW
							SHUTDOWN
							SIGNAL
							SIMILAR
							SIMPLE
							SIZE
							SMALLINT
							SOME
							SONAME
							SOURCE
							SPACE
							SPATIAL
							SPECIFIC
							SPECIFIC_NAME
							SPECIFICTYPE
							SQL
							SQL_BIG_RESULT
							SQL_BIG_SELECTS
							SQL_BIG_TABLES
							SQLCA
							SQL_CALC_FOUND_ROWS
							SQLCODE
							SQLERROR
							SQLEXCEPTION
							SQL_LOG_OFF
							SQL_LOG_UPDATE
							SQL_LOW_PRIORITY_UPDATES
							SQL_SELECT_LIMIT
							SQL_SMALL_RESULT
							SQLSTATE
							SQLWARNING
							SQL_WARNINGS
							SQRT
							SSL
							STABLE
							START
							STARTING
							STATE
							STATEMENT
							STATIC
							STATISTICS
							STATUS
							STDDEV_POP
							STDDEV_SAMP
							STDIN
							STDOUT
							STORAGE
							STRAIGHT_JOIN
							STRICT
							STRING
							STRUCTURE
							STYLE
							SUBCLASS_ORIGIN
							SUBLIST
							SUBMULTISET
							SUBSTRING
							SUCCESSFUL
							SUM
							SUPERUSER
							SYMMETRIC
							SYNONYM
							SYSDATE
							SYSID
							SYSTEM
							SYSTEM_USER
							TABLE
							TABLE_NAME
							TABLES
							TABLESAMPLE
							TABLESPACE
							TEMP
							TEMPLATE
							TEMPORARY
							TERMINATE
							TERMINATED
							TEXT
							TEXTSIZE
							THAN
							THEN
							TIES
							TIME
							TIMESTAMP
							TIMEZONE_HOUR
							TIMEZONE_MINUTE
							TINYBLOB
							TINYINT
							TINYTEXT
							TO
							TOAST
							TOP
							TOP_LEVEL_COUNT
							TRAILING
							TRAN
							TRANSACTION
							TRANSACTION_ACTIVE
							TRANSACTIONS_COMMITTED
							TRANSACTIONS_ROLLED_BACK
							TRANSFORM
							TRANSFORMS
							TRANSLATE
							TRANSLATION
							TREAT
							TRIGGER
							TRIGGER_CATALOG
							TRIGGER_NAME
							TRIGGER_SCHEMA
							TRIM
							TRUE
							TRUNCATE
							TRUSTED
							TSEQUAL
							TYPE
							UESCAPE
							UID
							UNBOUNDED
							UNCOMMITTED
							UNDER
							UNDO
							UNENCRYPTED
							UNION
							UNIQUE
							UNKNOWN
							UNLISTEN
							UNLOCK
							UNNAMED
							UNNEST
							UNSIGNED
							UNTIL
							UPDATE
							UPDATETEXT
							UPPER
							USAGE
							USE
							USER
							USER_DEFINED_TYPE_CATALOG
							USER_DEFINED_TYPE_CODE
							USER_DEFINED_TYPE_NAME
							USER_DEFINED_TYPE_SCHEMA
							USING
							UTC_DATE
							UTC_TIME
							UTC_TIMESTAMP
							VACUUM
							VALID
							VALIDATE
							VALIDATOR
							VALUE
							VALUES
							VARBINARY
							VARCHAR
							VARCHARACTER
							VARIABLE
							VARIABLES
							VAR_POP
							VAR_SAMP
							VARYING
							VERBOSE
							VIEW
							VOLATILE
							WAITFOR
							WHEN
							WHENEVER
							WHERE
							WHILE
							WIDTH_BUCKET
							WINDOW
							WITH
							WITHIN
							WITHOUT
							WORK
							WRITE
							WRITETEXT
							XOR
							YEAR
							YEAR_MONTH
							ZEROFILL
							ZONE
);

sub _new {
	my ($class,%params)=@_;
	return bless \%params,$class;
}

sub _adjdup_sql_name {
	my ($self,$name,$maxsize,%params)=@_;
	affirm { defined $params{DIGITS} } "param DIGITS not set";
	affirm { defined $params{LIST} } "param LIST not set";
	my $d=$params{DIGITS};
	my $l=$params{LIST};
	my $origname=$name;
	$name=~s/\d+$//;
	if (length($name) + $d > $maxsize) {
		$name=substr($name,0,$maxsize - $d);
	}
	my ($count,$max)=($d == 1 ? 0 : 10**($d - 1),10**$d - 1);
	while(1) {
		my $v=$name.sprintf("%0${d}d",$count++);
		return $v unless exists $l->{uc($v)};
		last if $count > $max;
	}
	return $self->_adjdup_sql_name($origname,$maxsize,%params,DIGITS => ++$d);
}

sub _translate_path  {
	my ($self,%params)=@_;
	croak "abstract method\n";
}

sub _resolve_invalid_name {
	my ($self,$name,%params)=@_;
	if (exists $INVALID_NAMES{uc($name)}) {
		$name=substr($name,0,$self->get_name_maxsize - 1) if length($name) >= $self->get_name_maxsize;
		$name.='_';
	}
	return $name;
}

sub _reduce_sql_name {
	my ($self,$name,$maxsize,%params)=@_;
	croak "abstract method\n";
	return $name;
}

sub _gen_name {
	my ($self,%params)=@_;
	affirm { defined $params{LIST} } "param LIST not set";
	affirm { defined $params{TY} } "param TY not set";
	affirm { defined $params{NAME} || defined $params{PATH} } "param NAME or PATH not set"; 
	my $l=$params{LIST};
	my $ty=$params{TY};	
	my $name= $self->_translate_path(%params);
	my $maxsize=defined $params{MAXSIZE} ? $params{MAXSIZE} : $self->get_name_maxsize();
	$name=$self->_reduce_sql_name($name,$maxsize,%params) if length($name) > $maxsize;
	$name=$self->_resolve_invalid_name($name,MAXSIZE => $maxsize);
	affirm  { length($name) <=  $maxsize } "$name: check length failed"; 

	if (exists $l->{uc($name)}) {
		my $v=$self->_adjdup_sql_name($name,$maxsize,%params,DIGITS => 1);
		unless (defined $v) {
			$v=$ty.'0'x($maxsize - length($ty));
			$name=$self->_adjdup_sql_name($v,$maxsize,%params,DIGITS => 1);
			affirm { defined $name } "$v: not generate name from this string";
		}
		else {
			$name=$v;
		}
	}
	return unless defined $name;
	affirm { ! exists $l->{uc($name)} } "$name: duplicate  name";
	affirm { length($name) <= $maxsize } "$name: name exceded  name database limit ($maxsize)";
	$l->{uc($name)}=1;
	return $name;
}


1;


__END__


=head1  NAME

blx::xsdsql::schema_repository::sql::generic::name_generator -  a name generator class

=cut

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
