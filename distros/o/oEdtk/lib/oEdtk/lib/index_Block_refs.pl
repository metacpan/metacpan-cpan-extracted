#!/usr/bin/perl

use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(db_connect);
use Term::ReadKey;
use Sys::Hostname;

sub usage () {
	warn "Usage: $0 <ANO|DUPLE|STOP|RESET> <idldoc|seqlot> [idseqpg|STOP_status] \n\n"
		. "\tThis changes docs status for omgr administration.\n\n"
		. "\t ANO\tblock doc(s) for anomaly in doc\n"
		. "\t DUPLE\tblock duplicated doc(s)\n"
		. "\t STOP\tblock to stop doc(s)\t(index_Purge_DCLIB won't delete DCLIB)\n"
		. "\t RESET\tunblock to redo doc(s)\t(index_Purge_DCLIB won't delete DCLIB)\n\n"
		. "\t idldoc is a complete UUID (ie. 5ADF7A26-C0B7-11EC-B330-EC8130CC0BFB),\n"
		. "\t or its legacy 16-digit form (ie. 2241234567894561)\n"
		. "\t or idldoc is a part of idldoc (ie. 2241% or 5ADF7A26%), with at least 4 chars \n"
		. "\t STOP_status to change only documents set previously as 'STOP' \n";
	exit 1;
}

if ( @ARGV < 2 or $ARGV[0] =~ /-h/i ) {
	usage();
}

my ( $event, $key1, $key2 ) = ( $ARGV[0], $ARGV[1], $ARGV[2] );
if ( $event =~ /^ANO$/i ) {
}
elsif ( $event =~ /^DUPLE$/i ) {
}
elsif ( $event =~ /^STOP$/i ) {
}
elsif ( $event =~ /^RESET$/i ) {
}
else {
	usage();
}

my $type = "";
if ( oe_is_IDLDOC($key1) ) {    # 1392153206001881 or a 36-char UUID
	$type = 'idldoc';

}
elsif ( $key1 =~ /^[0-9A-Fa-f-]{4,35}\%$/ ) {    # 2241% or a UUID prefix
	$type = 'idldoc';

}
elsif ( $key1 =~ /^\d{7}$/ ) {    # 1411123
	$type = 'seqlot';

}
else {
	usage();
}
$key2 = $key2 || 0;

my $cfg = config_read('EDTK_STATS');
my $dbh = db_connect( $cfg, 'EDTK_DBI_STATS', { AutoCommit => 1, RaiseError => 1 } );

################################################################################

my $sql =
	  "SELECT ED_REFIDDOC, ED_SOURCE, ED_IDLDOC, ED_SEQDOC, ED_DTEDTION, ED_NOMDEST"
	. " FROM "
	. $cfg->{'EDTK_DBI_OUTMNGR'};

#		. " FROM EDTK_INDEX ";
my $where;
my @values;
push( @values, $key1 );
my $sequence = 0;

if ( $type eq 'idldoc' ) {
	if ( $key1 =~ /\%$/ ) {
		$where .= " WHERE ED_IDLDOC like ? ";
	}
	else {
		$where .= " WHERE ED_IDLDOC = ? ";
	}

	if ( defined $key2 && ( $key2 =~ /^STOP$/i ) ) {
		$where .= "  AND ED_STATUS = ? ";
		push( @values, $key2 );

	}
	elsif ( defined $key2 && $key2 > 0 && $key1 !~ /\%$/ ) {    # key2 is the page number
			#} elsif (defined $key2 && $key2 > 0 ){
		$where .=
			  "  AND ED_SEQDOC  = (SELECT ED_SEQDOC FROM "
			. $cfg->{'EDTK_DBI_OUTMNGR'}
			. " WHERE ED_IDLDOC = ? AND ED_IDSEQPG = ? )";

#		$where .="  AND ED_SEQDOC  = (SELECT ED_SEQDOC FROM EDTK_INDEX WHERE ED_IDLDOC = ? AND ED_IDSEQPG = ? )";
		push( @values, $key1, $key2 );
		$sequence = $key2;
	}

}
elsif ( $type eq 'seqlot' ) {
	$where .= " WHERE ED_SEQLOT = ? ";
}

my $present = " GROUP BY ED_REFIDDOC, ED_IDLDOC, ED_SEQDOC, ED_NOMDEST, ED_DTEDTION, ED_SOURCE ";
$present .= " ORDER BY ED_REFIDDOC, ED_IDLDOC, ED_SEQDOC, ED_NOMDEST, ED_DTEDTION, ED_SOURCE ";

my $sth = $dbh->prepare( $sql . $where . $present );
$sth->execute(@values);
my $rows = $sth->fetchall_arrayref();

if ( !scalar @{$rows} ) {
	warn "INFO: no associated data.\n";

	# track the action
	exit;
}

my $row_count = $#$rows + 1;
if ( $row_count <= 10 ) {
	foreach my $row (@$rows) {
		printf "%14s  %6s %16s %09d %8s %-30s \n", @$row, "";    # 1391152325098839
	}
}
warn "INFO: Confirm Block request to set " . $row_count . " doc(s) for '$event' event ? (y/n)\n";

ReadMode('raw');
my $key = ReadKey();
if ( $key !~ /^y$/i ) {
	die "INFO: abort request\n";
}
ReadMode('restore');

my $updt =
	  "UPDATE "
	. $cfg->{'EDTK_DBI_OUTMNGR'}
	. " SET ED_DTLOT = ?, ED_SEQLOT = ?, ED_DTPOSTE = ?, ED_STATUS = ? ";

#my 	$updt = "UPDATE EDTK_INDEX SET ED_DTLOT = ?, ED_SEQLOT = ?, ED_DTPOSTE = ?, ED_STATUS = ? ";
$sth = $dbh->prepare( $updt . $where );

if ( $event !~ /^RESET$/i && $event !~ /^STOP$/i ) {

	# for all other events the docs are not replayed; they will be purged (index_Purge_DCLIB)
	# warn "INFO: $updt \n $event, $event, $event, $event, @values\n";
	$sth->execute( $event, $event, $event, $event, @values );

}
else {
	my $NULL = "";

	# warn "INFO: $updt \n $NULL, $NULL, $NULL, $event, @values\n";
	$sth->execute( $NULL, $NULL, $NULL, $event, @values );
}

# REVIEW THE TRACKING: SET A REAL TIMESTAMP, THE RIGHT ED_APP
$sql =
"INSERT INTO EDTK_TRACKING(ED_TSTAMP, ED_USER, ED_SEQ, ED_SNGL_ID, ED_APP, ED_JOB_EVT, ED_OBJ_COUNT, ED_CORP, ED_HOST, ED_K4_VAL) ";
$sql .= " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
my $trk = $dbh->prepare($sql);
$trk->execute(
	'20111003111111', 'idx_Block', $sequence,  $key1,
	'idx_Block',      'W',         $row_count, $cfg->{'EDTK_CORP'},
	hostname(),       "$event for @values"
);

print "DONE ";
################################################################################

1;
