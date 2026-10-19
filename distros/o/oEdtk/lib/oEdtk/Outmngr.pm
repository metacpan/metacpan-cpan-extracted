package oEdtk::Outmngr;

use strict;
use warnings;

use File::Basename;
use Sys::Hostname;
use Text::CSV;
use Date::Calc     qw(Today Gmtime Week_of_Year Add_Delta_Days Day_of_Week);
use List::Util     qw(max sum);
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(db_connect db_backup_agent create_table_OUTMNGR @INDEX_COLS);
use oEdtk::logger  qw(logger);
use POSIX          qw(strftime);
use DBI;

# use Sys::Hostname;

use Exporter;
our $VERSION   = 2.1126;         # release number : Y.YSSS -> Year, Sequence
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
	omgr_check_acquit
	omgr_check_doclibs
	omgr_check_seqlot_ref
	omgr_depot_poste
	omgr_export
	omgr_import
	omgr_lot_pending
	omgr_purge_fs
	omgr_stats
	omgr_stats_referent
	omgr_track_folds
	omgr_track_report
);

# The default lot.
use constant DEFLOT => 'DEF';
use constant DEFFIL => 'DEF';

# Description of the processings applied to our document batches, with
# the list of fields updated at each step.
#
# 1. Insert each index line into the $cfg->{'EDTK_DBI_OUTMNGR'} table, filling in
#    a number of extra fields, using the information
#    taken from the EDTK_REFIDDOC and EDTK_SUPPORTS tables.
#      ED_PORTADR, ED_CATDOC, ED_REFIMP, ED_TYPED, ED_FORMATP, ED_PGORIEN,
#      ED_FORMDEF, ED_PAGEDEF, ED_FORMS, ED_NUMPGPLI
#
# 2. Once all the lines have been inserted, we can now perform
#    additional computations and enrich our entries again.
#      ED_NBPGPLI, ED_NBPGDOC, ED_MODEDI
#
# 3. We can now select a batch for our documents.  We try
#    each batch in turn, in the priority order defined in the
#    EDTK_LOTS table.  If the batch matches entries, we assign those entries to the
#    matching batch.
#      ED_IDLOT
#
# 4. Once a batch has been assigned, we infer a manufacturer from the
#    EDTK_LOTS table.  Depending on that manufacturer, we select a list
#    of possible production lines, in the priority order defined in the
#    EDTK_FILIERES table.  As in step 3, we try to match our entries
#    against each of these lines, according to their constraints.
#      ED_IDFILIERE
#
# 5. Once the production line has been determined, we know whether we will print
#    double-sided or single-sided; we can therefore compute new
#    additional fields.
#      ED_PDSPLI, ED_NBFPLI
#
# 6. Finally we can export our entries to create our final batches to send
#    to the manufacturer.  To do so, we select the (idlot,idfiliere) pairs
#    unique in our $cfg->{'EDTK_DBI_OUTMNGR'} table, and for each of these pairs, we try
#    to satisfy the minimum and maximum folded-item/page count constraints.  If
#    possible, we assign a unique shipment batch number to the documents.
#      ED_SEQLOT

# READ AND PROCESS AN INDEX FILE, STORING IT IN THE DATABASE, WHILE COMPUTING SOME VALUES.
sub omgr_import {
	my ( $app, $in, $corp ) = @_;

	# Retrieve the database connection parameters.
	my $cfg = config_read('EDTK_DB');

	my $pdbh = db_connect( $cfg, 'EDTK_DBI_PARAM' );
	my $dbh  = db_connect( $cfg, 'EDTK_DBI_DSN', { AutoCommit => 0, RaiseError => 1 } );

	# Create the $cfg->{'EDTK_DBI_OUTMNGR'} table if we're using SQLite.
	if ( $dbh->{'Driver'}->{'Name'} eq 'SQLite' ) {
		create_table_OUTMNGR( $dbh, $cfg->{'EDTK_DBI_OUTMNGR'} );
	}

	eval {
		my ( $idldoc, $numencs, $encpds ) = _omgr_insert( $dbh, $pdbh, $app, $in, $corp );
		_omgr_lot( $dbh, $pdbh, $idldoc );
		_omgr_filiere( $dbh, $pdbh, $app, $idldoc, $numencs, $encpds );
		$dbh->commit;
	};
	if ($@) {
		&logger( 3, "ERROR: $@\n" );
		eval { $dbh->rollback };
		die "ERROR: rollback done before dying in omgr_import\n";
	}

	$dbh->disconnect;
	$pdbh->disconnect;
}

sub omgr_track_folds {

	# EDIT LIST AND STATUS FROM START TO END
	# LIST OF BATCHES PRODUCED UP TO MAILING
	my $dbh             = shift;
	my $cfg             = config_read( 'EDTK_DB', 'EDTK_STATS' );
	my $nb_j_historique = shift || $cfg->{'EDTK_STATS_DAYS_FROM'} || 10;
	&logger( 6, "INFO: omgr_track_folds for last $nb_j_historique days\n" );
	my ($sql);

	# QUERY FOR THE BUSINESS-TRACKING MAIL
	###########################################################################
# SELECT A.ED_REFIDDOC, COUNT (DISTINCT A.ED_IDLDOC||TO_CHAR(A.ED_SEQDOC,'FM0000000')) AS NB_DOCS,
#  A.ED_DTEDTION, COUNT (DISTINCT A.ED_SEQLOT||TO_CHAR(A.ED_IDPLI,'FM0000000')) AS NB_PLIS,
#  B.ED_DTPOST, B.ED_DTPOST2, COUNT (DISTINCT A.ED_SEQLOT) AS NB_LOTS,
#  NVL(B.ED_STATUS, NVL(A.ED_STATUS, 'PENDING...')) AS STATUS
#  FROM EDTK_INDEX A, EDTK_ACQ B
#  WHERE A.ED_SEQLOT=B.ED_SEQLOT (+)
#	AND (A.ED_DTEDTION IS NULL OR A.ED_DTEDTION > TO_CHAR(SYSDATE-20, 'IYYYMMDD'))
#  GROUP BY C.ED_MAIL_REFERENT, A.ED_REFIDDOC, A.ED_DTEDTION, B.ED_DTPOST, B.ED_DTPOST2, B.ED_STATUS, A.ED_STATUS
#  ORDER BY C.ED_MAIL_REFERENT, A.ED_REFIDDOC;

# SELECT A.ED_REFIDDOC, COUNT (DISTINCT A.ED_IDLDOC||TO_CHAR(A.ED_SEQDOC,'FM0000000')) AS NB_DOCS,
#  A.ED_DTEDTION, COUNT (DISTINCT A.ED_SEQLOT||TO_CHAR(A.ED_IDPLI,'FM0000000')) AS NB_PLIS,
#  B.ED_DTPOST, B.ED_DTPOST2, COUNT (DISTINCT A.ED_SEQLOT) AS NB_LOTS,
#  NVL(B.ED_STATUS, NVL(A.ED_STATUS, 'PENDING...')) AS STATUS,
#  C.ED_MAIL_REFERENT
#  FROM EDTK_INDEX A, EDTK_ACQ B, EDTK_REFIDDOC C
#  WHERE A.ED_SEQLOT=B.ED_SEQLOT (+)
#  AND  A.ED_REFIDDOC=C.ED_REFIDDOC
#  AND (A.ED_DTEDTION IS NULL OR A.ED_DTEDTION > TO_CHAR(SYSDATE-20, 'IYYYMMDD'))
#  GROUP BY C.ED_MAIL_REFERENT, A.ED_REFIDDOC, A.ED_DTEDTION, B.ED_DTPOST, B.ED_DTPOST2, B.ED_STATUS, A.ED_STATUS
#  ORDER BY C.ED_MAIL_REFERENT, A.ED_REFIDDOC, A.ED_DTEDTION;

	$sql =
		  "SELECT A.ED_CORP, A.ED_REFIDDOC,"
		. " NVL(B.ED_STATUS, NVL(A.ED_STATUS, 'PENDING...')) AS STATUS,"
		. " COUNT (DISTINCT A.ED_IDLDOC||TO_CHAR(A.ED_SEQDOC,'FM0000000')) AS NB_DOCS,"
		. " A.ED_DTEDTION, "
		. " COUNT (DISTINCT A.ED_SEQLOT) AS NB_LOTS,"
		. " COUNT (DISTINCT A.ED_SEQLOT||TO_CHAR(A.ED_IDPLI,'FM0000000')) AS NB_PLIS,"
		. " B.ED_DTPOST, B.ED_DTPOST2, "
		. " C.ED_MAIL_REFERENT AS REFERENT"
		. " FROM "
		. $cfg->{'EDTK_STATS_OUTMNGR'}
		. " A, EDTK_ACQ B, EDTK_REFIDDOC C"
		. " WHERE A.ED_SEQLOT=B.ED_SEQLOT (+)"
		. "   AND  A.ED_REFIDDOC=C.ED_REFIDDOC"
		. "   AND (A.ED_DTEDTION IS NULL OR A.ED_DTEDTION > TO_CHAR(SYSDATE-?, 'IYYYMMDD'))"
		. " GROUP BY C.ED_MAIL_REFERENT, A.ED_CORP, A.ED_REFIDDOC, A.ED_DTEDTION, B.ED_DTPOST, B.ED_DTPOST2, B.ED_STATUS, A.ED_STATUS"
		. " ORDER BY C.ED_MAIL_REFERENT, A.ED_CORP, A.ED_REFIDDOC, STATUS, A.ED_DTEDTION";

	my $sth = $dbh->prepare($sql);
	$sth->execute($nb_j_historique);

	my $rows = $sth->fetchall_arrayref();

	my $fmt  = "%10s %-20s %-10s %7s %9s %7s %7s %8s %8s";
	my @head = (
		"CORP",    "REFIDDOC", "STATUS", "NB_DOCS", "DTEDITION", "NB_LOTS",
		"NB_PLIS", "DTPOST",   "DTPOST2"
	);
	_filled_rows($rows);

	@$rows = ( \$fmt, \@head, @$rows );
	return $rows;
}

sub omgr_track_report {
	my $dbh = shift;
	my $cfg = config_read( 'EDTK_DB', 'EDTK_STATS' );

	my ($sql);

#select A.ED_REFIDDOC,
#        (CASE A.ED_MODEDI WHEN 'R' THEN 2 ELSE 1 END * SUM(A.ED_NBFPLI)) AS NB_FACES,
#        COUNT (DISTINCT A.ED_SEQLOT||TO_CHAR(A.ED_IDPLI,'FM0000000')) AS NB_PLIS_SENT,
#        B.ED_STATUS, B.ED_LOTNAME, A.ED_SEQLOT, C.ED_IDMANUFACT,
#        B.ED_NBFACES AS NB_FACES_MANUFACT, B.ED_NBPLIS AS NB_PLIS_MANUFACT, B.ED_DTPOST
#        FROM EDTK_INDEX A, EDTK_ACQ B, EDTK_LOTS C
#        WHERE A.ED_SEQLOT = B.ED_SEQLOT AND B.ED_STATUS != 'SENT' AND A.ED_IDLOT = C.ED_IDLOT (+)
#        GROUP BY C.ED_IDMANUFACT, A.ED_REFIDDOC, A.ED_SEQLOT, A.ED_MODEDI, B.ED_STATUS, B.ED_DTPOST, B.ED_LOTNAME, B.ED_NBFACES, B.ED_NBPLIS;
	$sql =
		  "SELECT A.ED_REFIDDOC, "
		. " (CASE A.ED_MODEDI WHEN 'R' THEN 2 ELSE 1 END * SUM(A.ED_NBFPLI)) AS NB_FACES, "
		. " COUNT (DISTINCT A.ED_SEQLOT||TO_CHAR(A.ED_IDPLI,'FM0000000')) AS NB_PLIS, "
		. " B.ED_STATUS, B.ED_LOTNAME, A.ED_SEQLOT, C.ED_IDMANUFACT, "
		. " B.ED_NBFACES AS NB_FACES_MANUFACT, B.ED_NBPLIS AS NB_PLIS_MANUFACT, B.ED_DTPOST "
		. "FROM "
		. $cfg->{'EDTK_STATS_OUTMNGR'}
		. " A, EDTK_ACQ B, EDTK_LOTS C "
		. "WHERE A.ED_SEQLOT = B.ED_SEQLOT AND B.ED_STATUS != 'SENT' AND A.ED_IDLOT = C.ED_IDLOT (+) "
		. "GROUP BY C.ED_IDMANUFACT, A.ED_REFIDDOC, A.ED_SEQLOT, A.ED_MODEDI, B.ED_STATUS, B.ED_DTPOST, B.ED_LOTNAME, B.ED_NBFACES, B.ED_NBPLIS ";

	my $sth = $dbh->prepare($sql);
	$sth->execute();

	my $rows = $sth->fetchall_arrayref();

	my $fmt  = "%15s %6s %6s %7s %16s %7s %16s %14s %14s %8s ";
	my @head = (
		"REFIDDOC",      "FACES",  "PLIS",         "STATUS",
		"LOTNAME",       "SEQLOT", "MANUFACTURER", "MANUFACT_FACES",
		"MANUFACT_PLIS", "DTPOST"
	);
	_filled_rows($rows);

	# return @tlist;
	@$rows = ( \$fmt, \@head, @$rows );
	return $rows;
}

sub omgr_track_no_omgr() {

	#	select B.ed_refiddoc, count (DISTINCT A.ED_SOURCE) as NBREQUEST, A.ED_message
	#	  from edtk_tracking A, edtk_refiddoc B, edtk_index C
	#	  where B.ed_refiddoc = A.ed_app
	#	    AND A.ED_JOB_EVT = 'J'
	#	    and B.ed_massmail = 'C'
	#	    and A.ED_SNGL_ID = C.ED_IDLDOC (+)
	#	    and C.ED_dtedtion is null
	#	    and (A.ed_sngl_id like '202%')
	#	  group by B.ed_refiddoc, A.ED_message
	#	  order by B.ed_refiddoc, A.ED_message
	#	  ;

	1;
}

sub omgr_check_acquit {
	my $dbh             = shift;
	my $cfg             = config_read( 'EDTK_DB', 'EDTK_STATS' );
	my $nb_j_historique = shift || $cfg->{'EDTK_STATS_DAYS_FROM'} || 100;

	# from the acknowledgment database, check:
	# 1 - check the number of pages per seqlot
	# 2 - check the number of folded items per seqlot
	# 3 - fill in the status in acq
	# 4 - fill in the check date

#SELECT A.ED_SEQLOT,
#  COUNT (DISTINCT A.ED_SEQLOT||TO_CHAR(A.ED_IDPLI,'FM0000000')) AS NB_PLIS, B.ED_NBPLIS,
#  FROM EDTK_INDEX A, EDTK_ACQ B
#  WHERE A.ED_SEQLOT=B.ED_SEQLOT
#    AND ((B.ED_DTCHECK IS NULL OR B.ED_DTPRINT > TO_CHAR(SYSDATE-20, 'IYYYMMDD')) OR (B.ED_STATUS IS NULL OR B.ED_STATUS != 'SENT'))
#  GROUP BY A.ED_SEQLOT, A.ED_MODEDI, B.ED_NBPLIS;
	my ( $sql, $num );
	$sql = "SELECT A.ED_SEQLOT, "
		. " COUNT (DISTINCT A.ED_SEQLOT||TO_CHAR(A.ED_IDPLI,'FM0000000')) AS NB_PLIS, B.ED_NBPLIS"

  # see $sqlnbfpli
  #	. ", (CASE A.ED_MODEDI WHEN 'R' THEN 2 ELSE 1 END * SUM(A.ED_NBFPLI)) AS NB_FACES, B.ED_NBFACES"
		. " FROM "
		. $cfg->{'EDTK_STATS_OUTMNGR'}
		. " A, EDTK_ACQ B"
		. " WHERE A.ED_SEQLOT=B.ED_SEQLOT"
		. "   AND ((B.ED_DTCHECK IS NULL OR B.ED_DTPRINT > TO_CHAR(SYSDATE-?, 'IYYYMMDD')) OR (B.ED_STATUS IS NULL OR B.ED_STATUS != 'SENT'))"
		. " GROUP BY A.ED_SEQLOT, A.ED_MODEDI, B.ED_NBPLIS";
	my $sth = $dbh->prepare($sql);
	$sth->execute($nb_j_historique);

	while ( my $seqlot = $sth->fetchrow_hashref() ) {

		#	# WE UPDATE EACH SEQLOT
		$sql =
			  "UPDATE EDTK_ACQ "
			. " SET ED_DTCHECK = TO_CHAR(SYSDATE, 'IYYYMMDD'), ED_STATUS = "
			. " CASE "
			. "      WHEN ED_NBPLIS = ? THEN "
			. " 			CASE WHEN (ED_DTPOST IS NOT NULL) THEN 'SENT' "
			. "                 ELSE 'GOOD' "
			. "            END "
			. "      ELSE 'LACK' " . " END "
			. " WHERE ED_SEQLOT = ? ";
		$num += $dbh->do( $sql, undef, $seqlot->{'NB_PLIS'}, $seqlot->{'ED_SEQLOT'} );
	}
	return $num;
}

sub _omgr_insert {

	# - INJECT THE COMPO INDEX PAGE/PAGE DATA INTO THE DATABASE
	# - COMPLETE THE INDEX WITH THE INFO FROM THE REFIDDOC AND SUPPORTS SETUP TABLES
	# - COMPUTE THE PAGE/SUPPORT QUANTITIES
	# TODO REVIEW THE INSERT HANDLING   XXXXXXXXXX
	my ( $dbh, $pdbh, $app, $in, $corp ) = @_;
	my $cfg = config_read('EDTK_DB');

################################################################################
	# TO MANAGE THE INDEX DYNAMICALLY, THE READ OPERATIONS BELOW SHOULD
	# either be part of the index read loop, or be replaced by links
################################################################################
	#
	# Retrieve the document application parameters.
	my $doc = $pdbh->selectrow_hashref(
		"SELECT * FROM EDTK_REFIDDOC WHERE ED_REFIDDOC = ? " . "AND (ED_CORP = ? OR ED_CORP = '%')",
		undef, $app, $corp
	);
	die( "ERROR: die in _omgr_insert, message is " . $pdbh->errstr . "\n" ) if $pdbh->err;
	if ( !defined($doc) ) {
		die "ERROR: Could not find document \"$app\" in EDTK_REFIDDOC\n";
	}

	# Retrieve the support for the first page and the following ones.
	my $p1 = $pdbh->selectrow_hashref( 'SELECT * FROM EDTK_SUPPORTS WHERE ED_REFIMP = ?',
		undef, $doc->{'ED_REFIMP_P1'} );
	die( "ERROR: die in _omgr_insert, message is " . $pdbh->errstr . "\n" ) if $pdbh->err;
	if ( !defined($p1) ) {
		die "ERROR: Could not find support \"$doc->{'ED_REFIMP_P1'}\" in EDTK_SUPPORTS\n";
	}

	my $ps = $pdbh->selectrow_hashref( 'SELECT * FROM EDTK_SUPPORTS WHERE ED_REFIMP = ?',
		undef, $doc->{'ED_REFIMP_PS'} );
	die( "ERROR: die in _omgr_insert, message is " . $pdbh->errstr . "\n" ) if $pdbh->err;
	if ( !defined($ps) ) {
		die "ERROR: Could not find support \"$doc->{'ED_REFIMP_PS'}\" in EDTK_SUPPORTS\n";
	}

	# Retrieve the list of inserts to join for this document,
	# and deduce the extra weight to add to each folded item
	my @encrefs = split( /,/, $doc->{'ED_REFIMP_REFIDDOC'} || "" );
	my $now     = strftime( "%Y%m%d", localtime() );
	my $sth     = $pdbh->prepare('SELECT * FROM EDTK_SUPPORTS WHERE ED_REFIMP = ?')
		or die( "ERROR: die in _omgr_insert, message is " . $pdbh->errstr );
	my $encpds = 0;
	my @needed = ();

	foreach my $encref (@encrefs) {

# THE ERROR IS HERE: WE SHOULD ADD INDEX LINES PER INSERT WITH TYPIMP = E duplicated for each insert starting from the last line of the document xxxxxx
		my $enc = $pdbh->selectrow_hashref( $sth, undef, $encref )
			or die( "ERROR: in omgr for encref $encref " . $pdbh->errstr . "\n" );

		#&logger(7, "DEBUG: looking for encart ".$enc->{'ED_REFIMP'}." for $now\n");
		if (   defined( $enc->{'ED_DEBVALID'} )
			&& length( $enc->{'ED_DEBVALID'} ) > 0
			&& $enc->{'ED_DEBVALID'} ne '99999999' )
		{
			next if $now < $enc->{'ED_DEBVALID'};
		}
		if ( defined( $enc->{'ED_FINVALID'} ) && length( $enc->{'ED_FINVALID'} ) > 0 ) {
			next if $now > $enc->{'ED_FINVALID'};
		}
		$encpds += $enc->{'ED_POIDSUNIT'};
		push( @needed, $encref );
	}
	my $listerefenc = join( ', ', @needed )
		|| "none"
		; # xxx TODO think about the mailing impact, hard-coded or configurable in the supports table ?
		  #&logger(7, "DEBUG: selected listerefenc => $listerefenc\n");

	# TO MANAGE THE INDEX DYNAMICALLY, THE READ OPERATIONS ABOVE SHOULD
	# either be part of the index read loop, or be replaced by links
################################################################################

	# LOOP THROUGH THE INDEX FILE, GATHERING ENTRIES AND COUNTING THE NUMBER OF PAGES, ETC...
	my $numpgpli = 0;
	my $seqpgdoc = 0;
	my $idldoc   = undef;
	open( my $fh, '<', $in ) or die "ERROR: Cannot open index file \"$in\": $!\n";
	my $prevseq = -1;
	my $count   = 0;

	my $csv = Text::CSV->new( { binary => 1, sep_char => ';' } );
	while (<$fh>) {

		# Parse the CSV data and extract all the fields.

		$csv->parse($_);
		my @data = $csv->fields();

# Truncate the CP field if necessary.
# If the postal code is longer than 10 characters, it is truncated to 10 by keeping the first 4 followed by the last 6
		if ( length( $data[4] ) > 10 ) {
			&logger( 4, "INFO: \"$data[4]\" truncated to 10 characters\n" );
			$data[4] = substr( $data[4], 0, 4 ) . substr( $data[4], -6 );
		}

		# Truncate the name of city field if necessary.
		if ( length( $data[5] ) > 30 ) {
			&logger( 4, "INFO: \"$data[5]\" truncated to 30 characters\n" );
			$data[5] =~ s/^(.{30}).*$/$1/;
		}

		# Truncate the name field if necessary.
		if ( length( $data[7] ) > 38 ) {
			&logger( 4, "INFO: \"$data[7]\" truncated to 38 characters\n" );
			$data[7] =~ s/^(.{38}).*$/$1/;
		}

		my $first = $prevseq != $data[3];    # Is this the first page?
		$idldoc = $data[1] unless defined $idldoc;

		# XXX These two values are identical for now because we have only one document
		# per folded item, but this will not hold once batching is implemented.
		if ($first) {
			$numpgpli = 1;
			$seqpgdoc = 1;
		}
		else {
			$numpgpli++;
			$seqpgdoc++;
		}

		# ECM columns (D-S52) come from the index-format header, not from the fork:
		# the fork read ED_CLEGED5/ED_IDPMSIR from the wrong fields (it put ED_IDLOT
		# into ED_IDPMSIR). ed_idjob is NOT NULL in both key modes
		# (EDTK_DB_PK_IDJOB), so its value always comes from the ini.
		my $entry = {
			ED_REFIDDOC   => $data[0],
			ED_IDLDOC     => $idldoc,
			ED_IDSEQPG    => $data[2],
			ED_SEQDOC     => $data[3],
			ED_CPDEST     => $data[4],
			ED_VILLDEST   => $data[5],
			ED_IDDEST     => $data[6],
			ED_NOMDEST    => $data[7],
			ED_IDEMET     => $data[8],
			ED_DTEDTION   => $data[9],
			ED_TYPPROD    => $data[10],
			ED_PORTADR    => $doc->{'ED_PORTADR'},  # check whether we can handle it like ED_TYPPROD
			ED_ADRLN1     => $data[12],
			ED_CLEGED1    => $data[13],
			ED_ADRLN2     => $data[14],
			ED_CLEGED2    => $data[15],
			ED_ADRLN3     => $data[16],
			ED_CLEGED3    => $data[17],
			ED_ADRLN4     => $data[18],
			ED_CLEGED4    => $data[19],
			ED_ADRLN5     => $data[20],
			ED_CORP       => $data[21],
			ED_DOCLIB     => $data[22],
			ED_REFIMP     => $data[23],
			ED_ADRLN6     => $data[24],
			ED_SOURCE     => $data[25],
			ED_OWNER      => $data[26],
			ED_HOST       => $data[27],
			ED_IDIDX      => $data[28],
			ED_CATDOC     => $data[29] || $doc->{'ED_CATDOC'},
			ED_CODRUPT    => $data[30],
			ED_IDJOB      => ( $cfg->{'EDTK_DB_IDJOB_DEFAULT'} // '' ),
			ED_TYPDOC     => $data[31],
			ED_IDCOLL     => $data[32],
			ED_IDMNT      => $data[33],
			ED_IDPMSIR    => $data[34],
			ED_CLEGED5    => $data[44],
			ED_SEQPGDOC   => $seqpgdoc,
			ED_POIDSUNIT  => $first ? $p1->{'ED_POIDSUNIT'} : $ps->{'ED_POIDSUNIT'},
			ED_NBENC      => scalar @needed, # this is a hack incompatible with folded-item batching
			ED_ENCPDS     => $encpds,        # this is a hack incompatible with folded-item batching
			ED_BAC_INSERT => $first ? $p1->{'ED_BAC_INSERT'} : $ps->{'ED_BAC_INSERT'},
			ED_TYPED      => $doc->{'ED_TYPED'},
			ED_MODEDI     => $doc->{'ED_MODEDI'},
			ED_FORMATP    => $doc->{'ED_FORMATP'},
			ED_PGORIEN    => $doc->{'ED_PGORIEN'},

			#			ED_FORMDEF		=> $doc->{'ED_FORMDEF'},
			#			ED_PAGEDEF		=> $doc->{'ED_PAGEDEF'},
			#			ED_FORMS		=> $doc->{'ED_FORMS'},
			#ED_IDPLI		=>
			ED_NBDOCPLI    => 1,              # XXX Will differ from 1 once we do batching
			ED_NUMPGPLI    => $numpgpli,
			ED_LISTEREFENC => $listerefenc,
			ED_TYPOBJ      => 'I'             # XXX We are missing data for this field
		};

		# We only fill the pre-printed field if it is not set in the index.
		if ( length( $entry->{'ED_REFIMP'} ) == 0 ) {
			$entry->{'ED_REFIMP'} = $first ? $doc->{'ED_REFIMP_P1'} : $doc->{'ED_REFIMP_PS'};
		}

		my @cols = keys(%$entry);
		my $sql =
			  "INSERT INTO "
			. $cfg->{'EDTK_DBI_OUTMNGR'} . " ("
			. join( ',', @cols )
			. ") VALUES ("
			. join( ',', ('?') x @cols ) . ")";
		my $sth = $dbh->prepare_cached($sql);

# &logger(7, "INFO: insert Query = $sql\n");
# &logger(7, "INFO: insert values = ". dump (%$entry) . "\n"); # bug inserting some values into Postgres

		eval { $sth->execute( values(%$entry) ); };
		if ($@) {
			&logger( 3, "ERROR: $@\n" );
			eval { $dbh->rollback };
			die "ERROR: rollback done before dying in omgr_insert\n";
		}

		$prevseq = $entry->{'ED_SEQDOC'};
		$count++;
	}
	close($fh);

	# Update ED_NBPGDOC.
	my $sql =
		  'UPDATE '
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. ' i SET ED_NBPGDOC = '
		. '(SELECT COUNT(*) FROM '
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. ' WHERE ED_IDLDOC = ? AND ED_SEQDOC = i.ED_SEQDOC) WHERE ED_IDLDOC = ?';
	$dbh->do( $sql, undef, $idldoc, $idldoc );

	# Initialize ED_NBPGPLI to ED_NBPGDOC; will differ if we do batching.
	$sql =
		  'UPDATE '
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. ' i SET ED_NBPGPLI = ED_NBPGDOC '
		. 'WHERE ED_IDLDOC = ?';
	$dbh->do( $sql, undef, $idldoc );

	# Now that ED_NBPGPLI is computed we can update ED_MODEDI.
	$sql =
		  "UPDATE "
		. $cfg->{'EDTK_DBI_OUTMNGR'} . " SET "
		. "ED_MODEDI = "
		. "CASE ED_MODEDI WHEN 'S' THEN 'R' ELSE CASE ED_NBPGPLI WHEN 1 THEN 'R' ELSE 'V' END END "
		. "WHERE ED_IDLDOC = ?";
	$dbh->do( $sql, undef, $idldoc );
	&logger( 6, "INFO: Imported $count pages\n" );
	return ( $idldoc, scalar @needed, $encpds );
}

sub _omgr_lot {

	# MATCHING INDEX DOCUMENTS AGAINST THE BATCH TABLE => BATCH ASSIGNMENT
	my ( $dbh, $pdbh, $idldoc ) = @_;
	my $cfg = config_read('EDTK_DB');

	# Select the appropriate batches.
	my $sql =
		'SELECT ED_IDLOT, ED_REFIDDOC, ED_CPDEST, ED_FILTER, ED_GROUPBY, ED_IDMANUFACT, ED_IDGPLOT '
		. 'FROM EDTK_LOTS ORDER BY ED_PRIORITE';
	my $sth = $pdbh->prepare($sql);
	$sth->execute();
	while ( my $lot = $sth->fetchrow_hashref() ) {

		# We try to match documents with this batch.
		$sql = 'UPDATE ' . $cfg->{'EDTK_DBI_OUTMNGR'} . ' SET ED_IDLOT = ? ';

		#XXX ADD REFENC / BATCH HANDLING: ADD ED_REFENC TO ED_LISTREFENC
		# if (defined $lot->{'ED_REFENC'}) {
		#	add ED_REFENC to ED_LISTREFENC
		# }

		my $where = ' WHERE ED_IDLOT IS NULL AND ED_IDLDOC = ? ';
		if ( $lot->{'ED_REFIDDOC'} =~ /\%/ ) {
			$where .= " AND ED_REFIDDOC LIKE ? ";
		}
		else {
			$where .= " AND ED_REFIDDOC = ? ";
		}
		my @values = ( $lot->{'ED_IDLOT'}, $idldoc, $lot->{'ED_REFIDDOC'} );

		if ( defined $lot->{'ED_CPDEST'} ) {
			$where .= " AND ED_CPDEST LIKE ? ";
			push( @values, $lot->{'ED_CPDEST'} );
		}
		if ( defined $lot->{'ED_FILTER'} and $lot->{'ED_FILTER'} =~ /\=/ ) {
			$where .= " AND " . $lot->{'ED_FILTER'};
		}

		my $num = $dbh->do( $sql . $where, undef, @values );

		if ( $num > 0 ) {
			&logger( 6, "INFO: Assigned $num pages to lot \"$lot->{'ED_IDLOT'}\"\n" );
		}
	}

	# Assign the remaining entries to the default batch.
	my $num = $dbh->do(
		"UPDATE "
			. $cfg->{'EDTK_DBI_OUTMNGR'}
			. " SET ED_IDLOT = ? "
			. "WHERE ED_IDLDOC = ? AND ED_IDLOT IS NULL",
		undef, DEFLOT, $idldoc
	);
	if ( $num > 0 ) {
		&logger( 6, "INFO: Assigned $num remaining pages to default lot \"" . DEFLOT . "\"\n" );
	}
}

sub _get_next_filiere {
	my ( $pdbh, $filiere ) = @_;

	# Retrieve the assignment parameters of the production line.
	my ( $ed_priorite, $ed_idmanufact, $ed_typed, $ed_modedi, $ed_idgplot, $ed_nbbacprn ) =
		$pdbh->selectrow_array(
'select ED_PRIORITE, ED_IDMANUFACT, ED_TYPED, ED_MODEDI, ED_IDGPLOT, ED_NBBACPRN from EDTK_FILIERES where ED_IDFILIERE =? ',
		undef, $filiere
		) or die( "ERROR: in _get_next_filiere, message is " . $pdbh->errstr );

	# Retrieve the first element of the ordered list of production lines.
	my $next_filiere = $pdbh->selectrow_array(
'select ED_IDFILIERE from EDTK_FILIERES where ED_IDMANUFACT =? and ED_TYPED =? and ED_MODEDI =? and ED_NBBACPRN >=? and ED_ACTIF =? and ED_IDFILIERE !=? and ED_PRIORITE >? and (ED_IDGPLOT = ? or ED_IDGPLOT = ?) order by ED_PRIORITE',
		undef,
		$ed_idmanufact,
		$ed_typed,
		$ed_modedi,
		$ed_nbbacprn,
		'O',
		$filiere,
		$ed_priorite,
		$ed_idgplot,
		'%'
	);

	$next_filiere ||= DEFFIL;

	#&logger(7, "DEBUG: next_filiere is $next_filiere\n");
	return $next_filiere;
}

sub _omgr_filiere {
	my ( $dbh, $pdbh, $app, $idldoc, $numencs, $encpds ) = @_;
	my $cfg = config_read('EDTK_DB');

	# Retrieve the document application parameters.
	my $doc =
		$pdbh->selectrow_hashref( 'SELECT * FROM EDTK_REFIDDOC WHERE ED_REFIDDOC = ?', undef, $app )
		or die( "ERROR: die in _omgr_filiere, message is " . $pdbh->errstr );

	#	# Retrieve the list of inserts to join to this document,
	#	# and deduce the extra weight to add to each folded item.
	#	my @encarts = split(/,/, $doc->{'ED_REFIMP_REFIDDOC'});
	#	my $encpds = 0;
	#	my $sth = $pdbh->prepare('SELECT ED_POIDSUNIT FROM EDTK_SUPPORTS '
	#			. 'WHERE ED_REFIMP = ?')
	#			or die "ERROR: select on supports failed " . $pdbh->errstr;
	#	foreach my $encart (@encarts) {
	#		my $pref = $pdbh->selectrow_arrayref($sth, undef, $encart)
	#			or die "ERROR: on support weight " . $pdbh->errstr;
	#		$encpds += $pref->[0];
	#	}

	# Retrieve the support for the first page and the following ones.
	my $p1 = $pdbh->selectrow_hashref( 'SELECT * FROM EDTK_SUPPORTS WHERE ED_REFIMP = ?',
		undef, $doc->{'ED_REFIMP_P1'} )
		or die( "ERROR: die in _omgr_filiere, message is " . $pdbh->errstr );
	my $ps = $pdbh->selectrow_hashref( 'SELECT * FROM EDTK_SUPPORTS WHERE ED_REFIMP = ?',
		undef, $doc->{'ED_REFIMP_PS'} )
		or die( "ERROR: die in _omgr_filiere, message is " . $pdbh->errstr );

	# Look for all entries that have an assigned batch
	# but no production line yet, see EDTK LOTS
	my $sql =
		  'SELECT DISTINCT ED_IDLOT FROM '
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. ' WHERE ED_IDLDOC = ? AND ED_IDLOT IS NOT NULL AND ED_IDFILIERE IS NULL';
	my $lotids = $dbh->selectcol_arrayref( $sql, undef, $idldoc );

	foreach my $lotid (@$lotids) {
		my $lot =
			$pdbh->selectrow_hashref( 'SELECT * FROM EDTK_LOTS WHERE ED_IDLOT = ?', undef, $lotid )
			or die( "ERROR: die in _omgr_filiere, message is " . $pdbh->errstr );

		# Now we try to match the documents with each of the production lines.
		my $sql =
			  "SELECT * FROM EDTK_FILIERES WHERE ED_ACTIF = 'O' "
			. "AND (ED_IDMANUFACT IS NULL OR ED_IDMANUFACT = '' OR ED_IDMANUFACT = ?) "
			. "ORDER BY ED_PRIORITE ASC";
		my $sth = $pdbh->prepare($sql)
			or die( "ERROR: die in _omgr_filiere, message is " . $pdbh->errstr );
		$sth->execute( $lot->{'ED_IDMANUFACT'} );

		# THE MINIMUM/MAXIMUM PAGE AND FOLDED-ITEM COUNT CONSTRAINTS ARE CHECKED
		# ONLY WHEN EXPORTING THE BATCHES IN OMGR_EXPORT() TO ALLOW
		# BATCHING.
		while ( my $fil = $sth->fetchrow_hashref() ) {

			# backward compatibility
			if ( defined $fil->{'ED_IDGPLOT'} && length( $fil->{'ED_IDGPLOT'} ) > 0 ) {
				if ( $lot->{'ED_IDGPLOT'} ne $fil->{'ED_IDGPLOT'} and $fil->{'ED_IDGPLOT'} ne "%" )
				{
					next;
				}
			}

			if ( defined $fil->{'ED_NBENCMAX'} && length( $fil->{'ED_NBENCMAX'} ) > 0 ) {
				next if $numencs > $fil->{'ED_NBENCMAX'};
			}

			# The formula that lets us compute the number of sheets in a folded item.
			# to be evolved for batching xxxxx
			my $sqlnbfpli = "$numencs + "
				. ( $fil->{'ED_MODEDI'} eq 'V' ? 'CEIL(ED_NBPGPLI / 2)' : 'ED_NBPGPLI' );

# The formula computing the total folded-item weight, and the associated values.
# xxxx the formula is wrong because $sqlnbfpli already counts the inserts
# xxxx  we should sum the weights of the front-side objects of the folded item (provided we really have 1 line / element)
			my $sqlpdspli =
				"$encpds + $p1->{'ED_POIDSUNIT'} + $ps->{'ED_POIDSUNIT'} * ($sqlnbfpli - 1)";

			my $sql =
				  "UPDATE "
				. $cfg->{'EDTK_DBI_OUTMNGR'}
				. " SET ED_IDFILIERE = ?, "
				. "ED_FORMFLUX = ?, ED_NBFPLI = $sqlnbfpli, ED_PDSPLI = $sqlpdspli "
				. "WHERE ED_IDLDOC = ? AND ED_IDLOT = ? AND ED_IDFILIERE IS NULL "
				. "AND ED_MODEDI LIKE ? AND ED_TYPED LIKE ? ";
			my @vals = (
				$fil->{'ED_IDFILIERE'},
				$fil->{'ED_FORMFLUX'}, $idldoc, $lotid, $fil->{'ED_MODEDI'}, $fil->{'ED_TYPED'}
			);
			if ( defined $fil->{'ED_POIDS_PLI'} && length( $fil->{'ED_POIDS_PLI'} ) > 0 ) {
				$sql .= " AND $sqlpdspli <= ?";
				push( @vals, $fil->{'ED_POIDS_PLI'} );
			}
			if ( defined $fil->{'ED_FEUILPLI'} && length( $fil->{'ED_FEUILPLI'} ) > 0 ) {
				$sql .= " AND $sqlnbfpli <= ?";
				push( @vals, $fil->{'ED_FEUILPLI'} );
			}
			my $num = $dbh->do( $sql, undef, @vals );
			if ( $num > 0 ) {
				&logger( 6,
						  "INFO: Assigned $num pages to production line \"$fil->{'ED_IDFILIERE'}\" "
						. "($fil->{'ED_DESIGNATION'})\n" );
			}
		}
	}
}

sub omgr_export {
	my (%conds) = @_;

	my $cfg = config_read('EDTK_DB');
	my $dbh = db_connect( $cfg, 'EDTK_DBI_DSN', { AutoCommit => 0, RaiseError => 1 } );
	omgr_check_doclibs($dbh);

	my $pdbh = db_connect( $cfg, 'EDTK_DBI_PARAM' );

	# _omgr_filiere2($dbh, $pdbh, $app, $idldoc, $numencs, $encpds);

	my $basedir = $cfg->{'EDTK_DIR_OUTMNGR'};

	my @done = ();
	eval {
		# Turn the optional user filters into a WHERE clause.
		my $user_where = join( ' AND ', map { "$_ = ?" } keys(%conds) );

		# This query selects the (idlot,idfiliere) pairs containing unassigned folded items.
		my $idsql =
			  'SELECT DISTINCT ED_IDLOT, ED_IDFILIERE, ED_CORP FROM '
			. $cfg->{'EDTK_DBI_OUTMNGR'}
			. ' WHERE ED_IDLOT IS NOT NULL AND ED_IDFILIERE IS NOT NULL AND ED_SEQLOT IS NULL';
		if ( length($user_where) > 0 ) {
			$idsql .= " AND $user_where";
		}
		my $ids = $dbh->selectall_arrayref( $idsql, undef, values(%conds) );

		foreach (@$ids) {    # we must take the production-line priority order into account
			my ( $idlot, $idfiliere, $idcorp ) = @$_;

		CHECK_FIL:
			{
				&logger( 6, "INFO: Considering OMGR tuple : $idlot, $idfiliere, $idcorp\n" );

				# The WHERE clause that we reuse in most queries so as to
				# process only the entries we care about.
				my $where =
					'WHERE ED_IDLOT = ? AND ED_IDFILIERE = ? AND ED_CORP = ? AND ED_SEQLOT IS NULL';
				if ( length($user_where) > 0 ) {
					$where .= " AND $user_where";
				}
				my @wvals = ( $idlot, $idfiliere, $idcorp, values(%conds) );

				my $fil =
					$pdbh->selectrow_hashref( 'SELECT * FROM EDTK_FILIERES WHERE ED_IDFILIERE = ?',
					undef, $idfiliere );
				my $lot = $pdbh->selectrow_hashref( 'SELECT * FROM EDTK_LOTS WHERE ED_IDLOT = ?',
					undef, $idlot );

				# Lock the $cfg->{'EDTK_DBI_OUTMNGR'} table to make sure entries are not
				# added between when we do our computations and when we run the UPDATE.
				$dbh->do(
					'LOCK TABLE ' . $cfg->{'EDTK_DBI_OUTMNGR'} . ' IN SHARE ROW EXCLUSIVE MODE' );

				# If the batch defines a column for the ED_GROUPBY value, we must split
				# the shipment batches according to that column.  Moreover, we always split
				# by issuing entity, paper format, production type and insert list.
				my @gcols = ( 'ED_CORP', 'ED_FORMATP', 'ED_TYPPROD', 'ED_LISTEREFENC' );

				if ( defined( $lot->{'ED_GROUPBY'} ) && length( $lot->{'ED_GROUPBY'} ) > 0 ) {
					push( @gcols, split( /,/, $lot->{'ED_GROUPBY'} ) );
				}
				my $groups = $dbh->selectall_arrayref(
					"SELECT DISTINCT "
						. join( ', ', @gcols )
						. " FROM "
						. $cfg->{'EDTK_DBI_OUTMNGR'}
						. " $where",
					{ Slice => {} },
					@wvals
				);

				foreach my $gvals (@$groups) {
					my $where2 = $where;    # check that we really use it ...
					my @wvals2 = @wvals;

					if ( keys(%$gvals) > 0 ) {

		# check if every value is defined and could be used (ED_LISTEREFENC could be defined or not)
						## which can produce this message : Issuing rollback() for database handle being DESTROY'd without explicit disconnect()
						foreach my $key ( keys(%$gvals) ) {
							if   ( defined $$gvals{$key} ) { }
							else                           { delete $$gvals{$key} }
						}

						push( @wvals2, values(%$gvals) );
						$where2 .= ' AND ' . join( ' AND ', map { "$_ = ?" } keys(%$gvals) );
					}

					# Compute the number of folded items of each size.
					my $innersql = 'SELECT DISTINCT ED_IDLDOC, ED_SEQDOC, ED_NBPGPLI FROM '
						. $cfg->{'EDTK_DBI_OUTMNGR'};

					my $sql = "SELECT COUNT(*), i.ED_NBPGPLI FROM ($innersql $where2) i "
						. "GROUP BY i.ED_NBPGPLI ORDER BY i.ED_NBPGPLI DESC";
					my $res = $dbh->selectall_arrayref( $sql, undef, @wvals2 );
					next if @$res == 0;

					# Compute the total number of folded items and pages available to us.
					my $availplis = sum( map { $$_[0] } @$res );
					my $availpgs  = sum( map { $$_[0] * $$_[1] } @$res );

					# Will we need to run the processing again for this (idlot/idfiliere) pair
					# and for the group defined by the @gcols columns?
					my $more = 0;

					# The maximum number of folded items/pages we can take (either the
					# production-line limit, or everything available).
					if ( defined( $fil->{'ED_MAXPLIS'} ) && $availplis > $fil->{'ED_MAXPLIS'} ) {
						$availplis = $fil->{'ED_MAXPLIS'};
						$more      = 1;
					}

					if ( defined( $fil->{'ED_MAXFEUIL_L'} ) ) {
						my $maxpgs = $fil->{'ED_MAXFEUIL_L'};
						if ( $fil->{'ED_MODEDI'} eq 'V' ) {
							$maxpgs *= 2;
						}
						if ( $availpgs > $maxpgs ) {
							$availpgs = $maxpgs;
							$more     = 1;
						}
					}

					my @plis    = ();
					my $selplis = 0;
					my $selpgs  = 0;
					foreach (@$res) {
						my ( $numplis, $nbpgpli ) = @$_;

						# If we can no longer add folded items or pages, we stop.
						last if $availplis == 0 || $availpgs == 0;

						# There are not enough pages available to add a
						# folded item of this size, so we try with smaller folded items.
						next if $availpgs < $nbpgpli;

						my $nbplis = int( $availpgs / $nbpgpli );
						if ( $nbplis > $availplis ) {
							$nbplis = $availplis;
						}
						if ( $nbplis > $numplis ) {
							$nbplis = $numplis;
						}
						my $nbpgs = $nbplis * $nbpgpli;

						push( @plis, [ $nbplis, $nbpgpli ] );
						$availplis -= $nbplis;
						$availpgs  -= $nbpgs;
						$selplis   += $nbplis;
						$selpgs    += $nbpgs;
					}

					# Check that we selected enough pages and folded items to
					# meet the lower limits of the production line, if any.
					my $min_feuilles = $fil->{'ED_MINFEUIL_L'} || 1;
					if ( $selpgs < $min_feuilles ) {
						&logger( 5,
								  "INFO: Not enough pages for production line \"$idfiliere\" : "
								. "got $selpgs, need $min_feuilles\n" );
						$more = 1;    # TODO check that we really need it
									  # _get_next_filiere($pdbh, $idfiliere);
						 # reset the production line with an eval restart or by completing the @$ids list?  xxxxxxxxxxxxx
						 # see 388
						my $sql =
							  "UPDATE "
							. $cfg->{'EDTK_DBI_OUTMNGR'}
							. " SET ED_IDFILIERE = ? "
							. "WHERE ED_IDLOT = ? AND ED_IDFILIERE = ? AND ED_CORP = ? AND ED_SEQLOT IS NULL ";
						my $next_filiere = _get_next_filiere( $pdbh, $idfiliere );
						my @vals         = ( $next_filiere, $idlot, $idfiliere, $idcorp );
						my $num          = $dbh->do( $sql, undef, @vals );
						$dbh->commit
							; # see whether we can avoid it to benefit from rollback when a retry is needed
						 #&logger(7, "DEBUG: downgrade production line to $next_filiere for $num pages\n");
						$idfiliere = $next_filiere;
						redo CHECK_FIL;
					}
					my $minplis = $fil->{'ED_MINPLIS'} || 1;
					if ( $selplis < $minplis ) {
						&logger( 5,
							"INFO: Not enough folded items for production line \"$idfiliere\" : "
								. "got $selplis, need $minplis\n" );
						$more = 1;    # TODO check that we really need it
									  # _get_next_filiere($pdbh, $idfiliere);
						 # reset the production line with an eval restart or by completing the @$ids list?  xxxxxxxxxxxxx
						 # see 388
						my $sql =
							  "UPDATE "
							. $cfg->{'EDTK_DBI_OUTMNGR'}
							. " SET ED_IDFILIERE = ? "
							. "WHERE ED_IDLOT = ? AND ED_IDFILIERE = ? AND ED_CORP = ? AND ED_SEQLOT IS NULL ";
						my $next_filiere = _get_next_filiere( $pdbh, $idfiliere );
						my @vals         = ( $next_filiere, $idlot, $idfiliere, $idcorp );
						my $num          = $dbh->do( $sql, undef, @vals );
						$dbh->commit
							; # see whether we can avoid it to benefit from rollback when a retry is needed
						&logger( 6,
							"INFO: downgrade production line to $next_filiere for $num pages\n" );
						$idfiliere = $next_filiere;
						redo CHECK_FIL;
					}

					my $seqlot = _get_seqlot($dbh);
					my $name =
"$gvals->{'ED_CORP'}.$lot->{'ED_IDMANUFACT'}.$seqlot.$lot->{'ED_LOTNAME'}.$fil->{'ED_IDFILIERE'}";

					# Prepare the sort order for this production line.
					my $order;
					if ( defined $fil->{'ED_SORT'} && length( $fil->{'ED_SORT'} ) > 0 ) {
						$order = $fil->{'ED_SORT'};
						if ( defined $fil->{'ED_DIRECTION'}
							&& length( $fil->{'ED_DIRECTION'} ) > 0 )
						{
							$order .= " $fil->{'ED_DIRECTION'}";
						}
					}
					else {
						$order = "ED_IDLDOC, ED_SEQDOC";
					}

					# Today's date.
					my $dtlot = sprintf( "%04d%02d%02d", Today() );

					foreach (@plis) {
						my ( $nbplis, $nbpgpli ) = @$_;

					#&logger(7, "DEBUG: Assigning $nbplis of $nbpgpli pages each to lot $seqlot\n");
					# This query selects the first N unassigned folded items
					# of a given size, the folded items being identified only by
					# a document batch id + a folded-item id.
						$innersql =
							  "SELECT j.ED_IDLDOC, j.ED_SEQDOC FROM ("
							. "SELECT i.ED_IDLDOC, i.ED_SEQDOC, ROW_NUMBER() "
							. "OVER (ORDER BY PGNUM) AS PLINUM FROM "
							. "(SELECT "
							. $cfg->{'EDTK_DBI_OUTMNGR'}
							. ".*, ROW_NUMBER() OVER (ORDER BY $order) AS PGNUM " . "FROM "
							. $cfg->{'EDTK_DBI_OUTMNGR'}
							. " $where2 AND ED_NBPGPLI = ?) i "
							. "WHERE ED_SEQPGDOC = 1) j WHERE PLINUM <= ?";

						# Assign the batch to all the selected folded items. We also take the
						# opportunity to set the batch creation date.
						$sql =
							  "UPDATE "
							. $cfg->{'EDTK_DBI_OUTMNGR'}
							. " SET ED_SEQLOT = ?, ED_DTLOT = ? "
							. "WHERE (ED_IDLDOC, ED_SEQDOC) IN ($innersql)";
						my $count =
							$dbh->do( $sql, undef, $seqlot, $dtlot, @wvals2, $nbpgpli, $nbplis );
						my $pages = $nbplis * $nbpgpli;
						if ( $count != $pages ) {
							die "ERROR: Unexpected UPDATE row count ($count != $pages)\n";
						}
					}
					&logger( 6, "INFO: Assigned $selpgs pages to lot \"$name\"\n" );

					# Compute the folded-item ids.  XXX Should be done differently...
					$sql =
						  "SELECT ED_IDLDOC, ED_SEQDOC, "
						. "DENSE_RANK() OVER (ORDER BY ED_IDLDOC, ED_SEQDOC) AS ED_IDPLI " . "FROM "
						. $cfg->{'EDTK_DBI_OUTMNGR'}
						. " WHERE ED_SEQLOT = ? ORDER BY $order";
					my $rows = $dbh->selectall_arrayref( $sql, { Slice => {} }, $seqlot );

					$sql =
						  'UPDATE '
						. $cfg->{'EDTK_DBI_OUTMNGR'}
						. ' SET ED_IDPLI = ? '
						. 'WHERE ED_IDLDOC = ? AND ED_SEQDOC = ? AND ED_SEQLOT = ?';
					my $sth = $dbh->prepare($sql);
					foreach my $row (@$rows) {
						$sth->execute(
							$row->{'ED_IDPLI'},  $row->{'ED_IDLDOC'},
							$row->{'ED_SEQDOC'}, $seqlot
						);
					}

					# Retrieve the list of print items needed for this batch.
					$sql =
						  'SELECT DISTINCT ED_REFIMP FROM '
						. $cfg->{'EDTK_DBI_OUTMNGR'}
						. ' WHERE ED_SEQLOT = ?';
					my @refimps = $dbh->selectrow_array( $sql, undef, $seqlot );

					# Compute the total number of sheets in the batch.
					$sql =
						  "SELECT SUM(i.ED_NBFPLI) "
						. " FROM (SELECT DISTINCT ED_IDLDOC, ED_SEQDOC, ED_NBFPLI "
						. " FROM "
						. $cfg->{'EDTK_DBI_OUTMNGR'}
						. " WHERE ED_SEQLOT = ?) i ";
					my ($nbfeuillot) = $dbh->selectrow_array( $sql, undef, $seqlot );
					my $nbfaceslot = $nbfeuillot;
					if ( $fil->{'ED_MODEDI'} ne 'R' ) { $nbfaceslot *= 2; }

					# Extract the data.
					my $lotdir = "$basedir/$name";
					mkdir("$lotdir") or die "ERROR: Cannot create directory \"$lotdir\": $!\n";
					my $file = "$name.idx";
					&logger( 6, "INFO: Creating index file \"$file\"\n" );
					$sql =
						  "SELECT * FROM "
						. $cfg->{'EDTK_DBI_OUTMNGR'}
						. " WHERE ED_SEQLOT = ? ORDER BY $order";
					$sth = $dbh->prepare($sql);
					$sth->execute($seqlot);

					open( my $fh, '>', "$lotdir/$file" )
						or die( "ERROR: die in omgr_export, message is " . $! );

					# Generate the header line.
					my $csv = Text::CSV->new( { binary => 1, eol => "\n", quote_space => 0 } );
					$csv->print( $fh, [ map { $$_[0] } @INDEX_COLS ] );
					my $doclib;
					while ( my $row = $sth->fetchrow_hashref() ) {

						# Gather the values in the same order as @INDEX_COLS.
						my @fields = map { $row->{ $$_[0] } } @INDEX_COLS;
						$csv->print( $fh, \@fields );

						$doclib = $row->{'ED_DOCLIB'} unless defined $doclib;
					}
					close($fh);

					# Generate a job ticket file.
					$file = "$name.job";
					&logger( 6, "INFO: Creating job ticket file \"$file\"\n" );
					my @jobfields = (
						[ 'ED_PRIORITE',    $lot->{'ED_PRIORITE'} ],
						[ 'ED_REFIDDOC',    $lot->{'ED_REFIDDOC'} ],
						[ 'ED_IDLOT',       $idlot ],
						[ 'ED_SEQLOT',      $seqlot ],
						[ 'ED_CORP',        $gvals->{'ED_CORP'} ],
						[ 'ED_GROUPBY',     $lot->{'ED_GROUPBY'} ],
						[ 'ED_CPDEST',      $lot->{'ED_CPDEST'} ],
						[ 'ED_REFENC',      $lot->{'ED_REFENC'} ],
						[ 'ED_LOTNAME',     $lot->{'ED_LOTNAME'} ],
						[ 'ED_IDMANUFACT',  $lot->{'ED_IDMANUFACT'} ],
						[ 'ED_IDFILIERE',   $idfiliere ],
						[ 'ED_DESIGNATION', $fil->{'ED_DESIGNATION'} ],
						[ 'ED_MODEDI',      $fil->{'ED_MODEDI'} ],
						[ 'ED_TYPED',       $fil->{'ED_TYPED'} ],
						[ 'ED_NBBACPRN',    $fil->{'ED_NBBACPRN'} ],
						[ 'ED_MINFEUIL_L',  $fil->{'ED_MINFEUIL_L'} ],
						[ 'ED_MAXFEUIL_L',  $fil->{'ED_MAXFEUIL_L'} ],
						[ 'ED_FEUILPLI',    $fil->{'ED_FEUILPLI'} ],
						[ 'ED_MINPLIS',     $fil->{'ED_MINPLIS'} ],
						[ 'ED_MAXPLIS',     $fil->{'ED_MAXPLIS'} ],
						[ 'ED_POIDS_PLI',   $fil->{'ED_POIDS_PLI'} ],
						[ 'ED_REF_ENV',     $fil->{'ED_REF_ENV'} ],
						[ 'ED_FORMFLUX',    $fil->{'ED_FORMFLUX'} ],
						[ 'ED_POSTCOMP',    $fil->{'ED_POSTCOMP'} ],
						[ 'ED_NBFACESLOT',  $nbfaceslot ],
						[ 'ED_NBFEUILLOT',  $nbfeuillot ],
						[ 'ED_NBPLISLOT',   $selplis ],
						[ 'ED_FORMATP',     $gvals->{'ED_FORMATP'} ],
						[ 'ED_CONSIGNE',    $lot->{'ED_CONSIGNE'} ],
						[ 'ED_LISTEREFENC', $gvals->{'ED_LISTEREFENC'} || "" ],
						[ 'ED_LISTEREFIMP', join( ', ', @refimps )     || "" ]
						,    # if I put this field last, I crash latex...
						[ 'ED_DTLOT', $dtlot ]

					);
					open( $fh, '>', "$lotdir/$file" )
						or die( "ERROR: die in omgr_export, message is " . $! );
					$csv->print( $fh, [ map { $$_[0] } @jobfields ] );
					$csv->print( $fh, [ map { $$_[1] } @jobfields ] );
					close($fh);

					# Add this lot to the list of created ones.
					$dbh->commit;
					push( @done, [ $name, $doclib ] );

					# Loop the processing again if we reached the maximum limits in
					# pages/folded items and we must process other batches.
					redo if $more;
				}
			}
		}
	};
	if ($@) {
		&logger( 3, "ERROR: $@\n" );
		eval { $dbh->rollback };
		die "ERROR: die after outmngr rollback !\n";
	}
	return @done;
}

sub omgr_depot_poste {
	my ( $dbh, $seqlot, $dt_depot ) = @_;
	my $cfg = config_read('EDTK_DB');

	$dt_depot =~ /^\d{8}$/ or die "ERROR: $dt_depot should be formated as yyyymmdd\n";

	my $sql = 'UPDATE ' . $cfg->{'EDTK_DBI_OUTMNGR'} . ' SET ED_STATUS = ? WHERE ED_SEQLOT like ?';
	$dbh->do( $sql, undef, $dt_depot, $seqlot ) or die "ERROR: can't update $seqlot with $dt_depot";
}

# True if $value looks like a document id (idldoc). Since S70/D1 it is a
# 36-char UUID; the legacy 16-digit YWWWDHHMMSSPPPP.r form is still
# accepted. Mirror of oEdtk::Main::oe_is_IDLDOC -- duplicated because
# Main requires Outmngr (a use of Main here would be a cycle).
sub _is_IDLDOC {
	my $value = shift;
	return 0 unless defined $value;
	return $value =~ /^[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$/
		|| $value =~ /^\d{16}$/;
}

sub _omgr_purge_db {
	my ( $dbh, $value ) = @_;
	my $cfg  = config_read('EDTK_STATS');
	my $type = "";
	my $sql;

	if ( $value =~ /^\d{6,7}$/ ) {    # 381123 or 1381123
		$type = "SEQLOT";
		&logger( 6, "INFO: delete $type $value from EDTK_STATS_OUTMNGR\n" );
		$sql = 'DELETE FROM ' . $cfg->{'EDTK_STATS_OUTMNGR'} . ' WHERE ED_SEQLOT = ?';
		$dbh->do( $sql, undef, $value )
			or die "ERROR: delete $type $value from EDTK_STATS_OUTMNGR\n";

		#} elsif (length ($value) == 16) { # 1282152443057128
	}
	elsif ( _is_IDLDOC($value) ) {    # 1282152443057128 or a 36-char UUID
		$type = "SNGL_ID";            # EDTK_STATS_TRACKING
		&logger( 6, "INFO: delete $type $value from EDTK_STATS_TRACKING\n" );
		$sql = 'DELETE FROM ' . $cfg->{'EDTK_STATS_TRACKING'} . ' WHERE ED_SNGL_ID = ?';
		$dbh->do( $sql, undef, $value )
			or die "ERROR: delete $type $value from EDTK_STATS_TRACKING\n";

		&logger( 6, "INFO: delete $type $value from EDTK_STATS_OUTMNGR\n" );
		$sql = 'DELETE FROM ' . $cfg->{'EDTK_STATS_OUTMNGR'} . ' WHERE ED_IDLDOC = ?';
		$dbh->do( $sql, undef, $value )
			or die "ERROR: delete $type $value from EDTK_STATS_OUTMNGR\n";

	}
	else {
		die "ERROR: $value doesn't seem to be SNGL_ID or SEQLOT";
	}
}

sub omgr_check_seqlot_ref {
	my ( $dbh, $value, $idseqpg ) = @_;
	my $cfg  = config_read('EDTK_STATS');
	my $type = "SEQLOT";
	my $sql;
	$sql =
		  "SELECT COUNT (DISTINCT A.ED_IDLDOC||TO_CHAR(A.ED_SEQDOC,'FM0000000')) AS NBDOCS,"
		. " A.ED_REFIDDOC, A.ED_IDLDOC,"
		. " COUNT (DISTINCT A.ED_IDLDOC||TO_CHAR(A.ED_IDSEQPG,'FM0000000')) AS NBPGS,"
		. " A.ED_SEQLOT,"
		. " COUNT (DISTINCT A.ED_IDLDOC||A.ED_SEQLOT||TO_CHAR(A.ED_IDPLI,'FM0000000')) AS NBPLIS,"
		. " NVL(B.ED_STATUS, NVL(A.ED_STATUS, 'PENDING...')) AS STATUS,"
		. " B.ED_DTPOST AS DTPOST, B.ED_DTPOST2 AS DTPOST2"
		. " FROM "
		. $cfg->{'EDTK_STATS_OUTMNGR'}
		. " A, EDTK_ACQ B"
		. " WHERE A.ED_SEQLOT=B.ED_SEQLOT (+)";

	if ( $value =~ /^\d{6,7}$/ ) {    # 381123 or 1381123
		$type = "SEQLOT";
		$sql .= " AND A.ED_SEQLOT = ?"
			. " GROUP BY A.ED_REFIDDOC, A.ED_IDLDOC, A.ED_SEQLOT, B.ED_STATUS, A.ED_STATUS, B.ED_DTPOST, B.ED_DTPOST2 ";
		$idseqpg = 0;

	}
	elsif ( _is_IDLDOC($value) ) {    # 1282152443057128 or a 36-char UUID
		$type = "IDLDOC";
		$sql .= " AND A.ED_IDLDOC = ?";
		if ( defined $idseqpg && $idseqpg > 0 ) {
			$sql .= " AND A.ED_IDSEQPG = ?";
		}
		$sql .=
" GROUP BY A.ED_REFIDDOC, A.ED_IDLDOC, A.ED_SEQLOT, B.ED_STATUS, A.ED_STATUS, B.ED_DTPOST, B.ED_DTPOST2 ";

	}
	else {
		die "ERROR: $value doesn't seem to be SEQLOT OR IDLDOC\n";
	}

	my $sth = $dbh->prepare($sql);
	if ( defined $idseqpg && $idseqpg > 0 ) {
		$sth->execute( $value, $idseqpg );
	}
	else {
		$sth->execute($value);
	}

	my $rows = $sth->fetchall_arrayref();
	if ( $#$rows < 0 ) {
		&logger( 6, "INFO: no associated data.\n" );
		exit;
	}
	my $fmt  = "%7s %-16s %-16s %6s %-7s %7s %10s %8s %8s";
	my @head = (
		"NB_DOCS", "REFIDDOC", "IDLDOC", "NB_PG", "SEQLOT", "NB_PLIS",
		"STATUS",  "DTPOST",   "DTPOST2"
	);

	_filled_rows($rows);
	@$rows = ( \$fmt, \@head, @$rows );

	return $rows;
}

sub omgr_stats_referent {
	my ( $dbh, $pdbh ) = @_;
	my $cfg = config_read('EDTK_STATS');
	my ( $sql, $key );

	$sql = "SELECT A.ED_MAIL_REFERENT, A.ED_REFIDDOC ";
	$sql .= " FROM EDTK_REFIDDOC A, " . $cfg->{'EDTK_STATS_OUTMNGR'} . " B ";
	$sql .= " WHERE A.ED_REFIDDOC = B.ED_REFIDDOC ";
	$sql .= " AND A.ED_MASSMAIL != 'N' AND A.ED_MAIL_REFERENT IS NOT NULL ";
	$sql .= " AND B.ED_SEQLOT IS NULL AND B.ED_DTLOT IS NULL ";
	$sql .= " GROUP BY A.ED_MAIL_REFERENT, A.ED_REFIDDOC ";
	$sql .= " ORDER BY A.ED_MAIL_REFERENT ";

	my $sth = $dbh->prepare($sql);
	$sth->execute();

	my $rows = $sth->fetchall_arrayref();
	return $rows;
}

# EDTK_STATS_MANUFACT (D-S52): a comma- or space-separated list of ED_IDMANUFACT
# codes, the subcontractors ("faconniers") whose shipments omgr_stats reports.
# When the key is absent or empty, no filter is applied (mainline behaviour). The
# codes (the subcontractor manufacturer ids) live in the ini, never in this code.
sub _stats_manufact {
	my ($cfg) = @_;
	my $list = $cfg->{'EDTK_STATS_MANUFACT'};
	return {} unless defined $list and $list =~ /\S/;
	my %codes;
	$codes{ uc $_ } = 1 for grep { length } split /[\s,]+/, $list;
	return \%codes;
}

sub omgr_stats {
	my ( $dbh, $pdbh, $period, $typeRqt ) = @_;
	$typeRqt = $typeRqt || "idlot";
	my $cfg = config_read('EDTK_STATS');
	my ( $sql, $key );
	my $time = time;
	my ( $year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst ) = Gmtime($time);
	my ( $week, ) = Week_of_Year( $year, $month, $day );

	if ( $period =~ /^day$/i ) {
		$key = sprintf( "%1d%02d%1d", $year % 10, $week, $dow );
	}
	elsif ( $period =~ /^week$/i ) {
		$key = sprintf( "%1d%02d", $year % 10, $week );
	}
	elsif ( $period =~ /^all$/i ) {
		$key = "";
	}
	elsif ( $period =~ /^\d+$/ ) {
		$key = $period;
	}
	else {
		&logger( 6, "INFO: implementation awaiting database evolution\n" );
	}

	my @head;
	if ( $typeRqt !~ /idlot/i ) {
		@head = ( "CORP", "LOT", "PLIS", "DOCS", "FEUILLES", "PAGES", "FACES", "FIL." );
		$sql  = "SELECT ED_CORP, ED_IDLOT, ";
	}
	else {
		@head =
			( "CORP", "LOT", "ID_SEQLOT", "PLIS", "DOCS", "FEUILLES", "PAGES", "FACES", "FIL." );
		$sql = "SELECT ED_CORP, ED_IDLOT, ED_SEQLOT, ";
	}
	$sql .= "COUNT (DISTINCT ED_IDLDOC||TO_CHAR(ED_SEQDOC,'FM0000000')), "
		; # NB PLIS # does not account for possible batching, to review: (DISTINCT TO_CHAR(ED_SEQLOT,'FM0000000')||TO_CHAR(ED_IDPLI,'FM0000000'))
	$sql .= "COUNT (DISTINCT ED_IDLDOC||TO_CHAR(ED_SEQDOC,'FM0000000')), ";    # NB DOCS
	$sql .= "SUM(ED_NBFPLI), ";                                                # NB SHEETS
	$sql .= "SUM(ED_NBPGDOC), ";                                               # NB PRINTED FACES
	$sql .= "CASE ED_MODEDI WHEN 'R' THEN 1 ELSE 2 END * SUM(ED_NBFPLI) ";     # NB FACES

	if ( $typeRqt !~ /idlot/i ) {
		$sql .= ", ED_MODEDI ";
		$sql .= " FROM " . $cfg->{'EDTK_STATS_OUTMNGR'};
		$sql .= " GROUP BY ED_CORP, ED_IDLOT, ED_MODEDI ";
		$sql .= " ORDER BY ED_CORP, ED_IDLOT, ED_MODEDI ";
	}
	else {
		$sql .= ", ED_IDFILIERE ";
		$sql .= " FROM " . $cfg->{'EDTK_STATS_OUTMNGR'};
		$sql .= " WHERE ED_SEQLOT LIKE ? AND ED_SEQPGDOC = 1 ";
		$sql .= " GROUP BY ED_CORP, ED_IDLOT, ED_SEQLOT, ED_IDFILIERE, ED_MODEDI ";
		$sql .= " ORDER BY ED_CORP, ED_IDFILIERE, ED_SEQLOT ";
	}

	my $sth = $dbh->prepare($sql);
	if ( $typeRqt !~ /idlot/i ) {
		$sth->execute();
	}
	else {
		$sth->execute("$key%");
	}

	my $manufact = _stats_manufact($cfg);
	my @kept;
	my $rows = $sth->fetchall_arrayref();
	foreach my $row (@$rows) {
		my ( $lot, $idmanufact ) = $pdbh->selectrow_array(
			'SELECT ED_LOTNAME, ED_IDMANUFACT FROM EDTK_LOTS WHERE ED_IDLOT = ?',
			undef, @$row[1] );
		next if keys(%$manufact) and !$manufact->{ uc( defined $idmanufact ? $idmanufact : '' ) };
		@$row[1] = $lot;
		push @kept, $row;
	}

	my $fmt = "%-8s%-16s" . "%9s" x ( @head - 3 ) . "  %-6s\n";
	@$rows = ( \$fmt, \@head, @kept );

	#my $fmt  = shift (@$rows);
	#my $head = shift (@$rows);
	#printf $$fmt . "\n", @$head;
	#
	#foreach my $row (@$rows) {
	#	printf $$fmt . "\n", @$row;
	#}

	return $rows;
}

sub omgr_lot_pending {

	# SEARCH FOR DOCUMENTS PENDING BATCHING
	# that is, the documents whose seqlot is null
	# Used by index_Purge_DCLIB
	my ($dbh) = @_;
	my $cfg = config_read('EDTK_DB');

	#-- SEARCH FOR DOCUMENTS PENDING BATCHING --
	my $ctrl_sql =
		  'SELECT ED_CORP, ED_REFIDDOC, ED_IDLDOC, ED_DTEDTION FROM '
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. ' WHERE ED_SEQLOT IS NULL'
		. ' GROUP BY ED_CORP, ED_REFIDDOC, ED_DTEDTION, ED_IDLDOC'
		. ' ORDER BY ED_CORP, ED_REFIDDOC, ED_DTEDTION, ED_IDLDOC';

	my $sth = $dbh->prepare($ctrl_sql);
	$sth->execute();

	my $rows = $sth->fetchall_arrayref();
	return $rows;
}

# LOOKS IF NEEDED DOCLIBS ARE IN EDTK_DIR_DOCLIB
sub omgr_check_doclibs {
	my ($dbh) = shift;

	my $cfg  = config_read('EDTK_DB');
	my $dir  = $cfg->{'EDTK_DIR_DOCLIB'};
	my $host = hostname();

	my $sql =
		  'SELECT DISTINCT ED_DOCLIB FROM '
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. ' WHERE ED_SEQLOT IS NULL AND ED_HOST = ? ';

	# Transform the list of needed doclibs into a hash for speed.
	my %needed = map { $_->[0] => 1 } @{ $dbh->selectall_arrayref( $sql, undef, $host ) };

	foreach my $key ( keys %needed ) {
		if ( -e "$dir/$key" ) {
		}
		else {
			die "ERROR: missing DOCLIB $key for current DSN\n";
		}
	}

}

# PURGE DOCLIBS THAT ARE NO LONGER REFERENCED IN THE DATABASE.
sub omgr_purge_fs {
	my ($dbh) = shift;
	db_backup_agent($dbh);

	my $cfg        = config_read('EDTK_DB');
	my $dir        = $cfg->{'EDTK_DIR_DOCLIB'};
	my @doclibs    = glob("$dir/*.pdf");
	my $weeks_kept = 0;

	unless ( defined( $cfg->{'EDTK_DCLIB_PURGE_WEEKS_KEPT'} )
		&& $cfg->{'EDTK_DCLIB_PURGE_WEEKS_KEPT'} > 0 )
	{
		&logger( 6, "INFO: EDTK_DCLIB_PURGE_WEEKS_KEPT not defined for optimization purge.\n" );
	}
	else {
		$weeks_kept = $cfg->{'EDTK_DCLIB_PURGE_WEEKS_KEPT'};
	}

	my ( $year, $month, $day ) = Today();
	( $year, $month, $day ) = Add_Delta_Days( $year, $month, $day, ( -7 * $weeks_kept ) );
	my $search_date = sprintf( "%04d%02d%02d", $year, $month, $day );

	my $sql =
		  "SELECT DISTINCT ED_DOCLIB FROM "
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. " WHERE ED_SEQLOT IS NULL OR ED_DTEDTION > '"
		. $search_date . "' ";

	# Transform the list of needed doclibs into a hash for speed.
	&logger( 6, "INFO: omgr_purge_fs identifies needed doclibs to safe them.\n" );
	my %needed = map { $_->[0] => 1 } @{ $dbh->selectall_arrayref($sql) };

	my @torm = ();
	foreach my $path (@doclibs) {
		my $file = basename($path);
		if ( $file =~ /^DCLIB_/ ) {
			if ( !$needed{$file} ) {
				push( @torm, $path );
			}
		}
		else {
			&logger( 3, "INFO: Unexpected filename : \"$file\"\n" );
		}
	}

	&logger( 6, "INFO: omgr_purge_fs done.\n" );
	return @torm;
}

# PRIVATE, NON-EXPORTED FUNCTIONS BELOW.
########################################

# Compute a new and unique lot sequence.
sub _get_seqlot {
	my $dbh = shift;

	# SQLite has no SEQUENCE and no to_char(): read the counter table set up by
	# create_lot_sequence (0..999, wrapping) and build the ISO week + day-of-week
	# prefix in Perl. This is what lets SQLite serve as the main database in tests.
	if ( $dbh->{'Driver'}->{'Name'} =~ m/SQLite/i ) {
		my ( $year, $month, $day ) = Today();
		my ($week) = Week_of_Year( $year, $month, $day );
		my $prefix = sprintf( "%02d%d", $week, Day_of_Week( $year, $month, $day ) );
		$dbh->do("update edtk_idlot_seq set id_val = ( id_val + 1 ) % 1000")
			or &logger( 3, "SQL execute failed " . $dbh->errstr );
		my ($seq) = $dbh->selectrow_array("select id_val from edtk_idlot_seq");
		$seq = 0 unless defined $seq;
		return sprintf( "%s%03d", $prefix, $seq );
	}

	my $sql;
	if ( $dbh->{'Driver'}->{'Name'} eq 'Oracle' ) {

		# sysdate produces the seqlot so the iso year fits on 1 character I
		# http://www.techonthenet.com/oracle/functions/to_char.php
		$sql = "SELECT to_char(sysdate, 'IIWD') || "
			. "to_char(EDTK_IDLOT.NEXTVAL, 'FM000') FROM dual";

	}
	else {
		# http://developer.postgresql.org/pgdocs/postgres/functions-formatting.html
		$sql =
			"SELECT to_char(current_date, 'IIWID') || " . "to_char(nextval('EDTK_IDLOT'), 'FM000')";
	}
	my ($seqlot) = $dbh->selectrow_array($sql);
	return $seqlot;
}

sub _filled_rows(\@) {    ## no critic (ProhibitSubroutinePrototypes)

# to make sure each cell holds at least a blank and avoid printf warnings when merging with an undefined cell
	my $refRows = shift;

	foreach my $row (@$refRows) {
		for ( my $i = 0 ; $i <= $#$row ; $i++ ) {
			$$row[$i] = $$row[$i] || "";    # IN THE CASE OF SEQLOT IT MAY NOT BE SET YET
		}
	}

	return @{$refRows};
}

sub _print_All_rTab {

	# PRINT ALL THE DATA OF A TABLE PASSED BY REFERENCE
	#  display the table in columns
	my $rTab = shift;

	for ( my $i = 0 ; $i <= $#{$rTab} ; $i++ ) {
		my $cols = $#{ $$rTab[$i] };
		print "\n$i:\t";

		for ( my $j = 0 ; $j <= $cols ; $j++ ) {
			print "$$rTab[$i][$j]" if ( defined $$rTab[$i][$j] );
		}
	}
	print "\n";
	1;
}

END {

}

1;

=head1 NAME

oEdtk::Outmngr - output management for printed document batches

=head1 SYNOPSIS

    use oEdtk::Outmngr qw(omgr_import omgr_export);

    omgr_import($app, $index_file, $corp);   # insert the index, assign lot/filiere
    my @lots = omgr_export(%conds);          # batch and export the print lots

=head1 DESCRIPTION

Output Management. It inserts the composition index into the Outmngr database,
assigns each document a lot and a production line, batches and exports print
lots (writing the C<.idx> and C<.job> files per lot), and provides the
statistics, purge and acknowledgment tooling around that pipeline. The
processing steps (insert and enrich, assign the lot, infer the manufacturer,
export) are described in the module source.

=head1 FUNCTIONS

=head2 omgr_import

    omgr_import($app, $in, $corp);

Read an index file into the C<EDTK_DBI_OUTMNGR> database, then assign the lot
and the production line (rolling back on error).

=head2 omgr_export

    my @lots = omgr_export(%conds);

Group the pending documents under the batch constraints, build the batch
sequence, and write the C<.idx> and C<.job> files for each lot. Returns the
list of name and doclib pairs.

=head2 omgr_check_acquit

    omgr_check_acquit($dbh, $nb_j_historique);

Reconcile the acknowledgment status and counts in the C<EDTK_ACQ> tables;
returns the number of rows updated.

=head2 omgr_check_seqlot_ref

    omgr_check_seqlot_ref($dbh, $value, $idseqpg);

Report, per batch or per document id, the status of its documents, pages and
plis.

=head2 omgr_check_doclibs

    omgr_check_doclibs($dbh);

Die when a needed document library is missing from C<EDTK_DIR_DOCLIB>.

=head2 omgr_depot_poste

    omgr_depot_poste($dbh, $seqlot, $dt_depot);

Set the posting date (C<ED_STATUS>) for a batch.

=head2 omgr_lot_pending

    omgr_lot_pending($dbh);

List the documents that are still pending batching.

=head2 omgr_purge_fs

    omgr_purge_fs($dbh);

List the document-library PDFs that are safe to purge (older than the keep
window).

=head2 omgr_stats

    omgr_stats($dbh, $pdbh, $period, $typeRqt);

Report batch, pli, document, sheet and face statistics for a period, optionally
filtered by manufacturer.

=head2 omgr_stats_referent

    omgr_stats_referent($dbh, $pdbh);

Report the mailing referent and document listing.

=head2 omgr_track_folds

    omgr_track_folds($dbh, $nb_j_historique);

Produce the batch status tracking report.

=head2 omgr_track_report

    omgr_track_report($dbh);

Produce the per-referent and manufacturer faces and plis report.

The internal subs C<_omgr_insert>, C<_omgr_lot>, C<_get_next_filiere>,
C<_omgr_filiere>, C<_omgr_purge_db>, C<_stats_manufact>, C<_get_seqlot>,
C<_is_IDLDOC>, C<_filled_rows> and C<_print_All_rTab>, and the empty
C<omgr_track_no_omgr> stub, are not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut
