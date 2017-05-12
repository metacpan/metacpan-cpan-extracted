#!/usr/bin/perl

use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config 		qw(config_read);
use oEdtk::DBAdmin 		qw(db_connect);

use Date::Calc		qw(Today Gmtime Week_of_Year);
my $YWWD;
{	my $time = time;
	my ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst) =
		Gmtime($time);
	my ($week,) = Week_of_Year($year,$month,$day);
$YWWD = sprintf ("%1d%02d%1d", $year % 10, $week, $dow );
}

if (@ARGV < 1 or $ARGV[0] =~/-h/i) {
	die "Usage: $0 <today|week|yweek_value|idldoc|ALL> [refiddoc] [SEQLOT|SOURCE|source_name]\n"
		."\t week\t\t: number of week in the year \n"
		."\t yweek_value\t: number of week in the year as YWW\n"
		."\t idldoc\t\t: unique id doc lot (4 - 16 digits)\n" 
		."\t source_name\t: job name in tracking\n\n"
		." This checks references for tracked sources\n (ie today YWWD = $YWWD)\n\n";
}

my $period=	$ARGV[0] || "today";
my $refiddoc=	$ARGV[1] || 0;
my $lot	= 	$ARGV[2] || 0;

my $cfg = config_read('EDTK_STATS');
my $dbh = db_connect($cfg, 'EDTK_DBI_STATS',
    { AutoCommit => 1, RaiseError => 1 });




################################################################################

#use Date::Calc		qw(Today Gmtime Week_of_Year);
	my $time = time;
	my ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst) =
		Gmtime($time);
	my ($week,) = Week_of_Year($year,$month,$day);
	my ($idldocKey, $select, $sql, $groupby, $orderby, @sql_values);

	if ($period =~ /^today$/i) {
		$idldocKey = sprintf ("%1d%02d%1d", $year % 10, $week, $dow );
		
	} elsif ($period=~ /^all$/i){
		
	} elsif ($period=~ /^(\d{3,15})$/){	# références au format YWW ou idldoc...
		$idldocKey = sprintf("%d",$1 );

	} elsif ($period=~ /^(\d{1,2})$/){ 	# références au format WW...
		$idldocKey = sprintf("%1d%d", $year % 10, $1 );

	} elsif ($period=~ /^week$/i){
		$idldocKey = sprintf("%1d%02d", $year % 10, $week );

	} else { 
		$idldocKey = sprintf("%1d%02d", $year % 10, $week );
	}
	$idldocKey .="%"; # étrangement pour les cas week et \d2 on a le message suivant si on met % dans le sprintf : Invalid conversion in sprintf: end of string at C:\Sources\edtk_MNT\lib\index_Check_docs_omgr.pl line 44. 
	push (@sql_values, $idldocKey);

	$select	= "SELECT COUNT (DISTINCT A.ED_IDLDOC||TO_CHAR(A.ED_SEQDOC,'FM0000000')) AS NB_DOCS, "
				. " NVL(C.ED_STATUS, NVL(A.ED_STATUS, 'NONE')) AS STATUS,"
				. " B.ED_APP, B.ED_SNGL_ID "; 
	$sql		= " FROM " . $cfg->{'EDTK_STATS_OUTMNGR'} . " A, " . $cfg->{'EDTK_STATS_TRACKING'} . " B, EDTK_ACQ C "
				. " WHERE B.ED_SNGL_ID=A.ED_IDLDOC (+) AND B.ED_JOB_EVT='J' AND  B.ED_SNGL_ID LIKE ? "
				. " AND A.ED_SEQLOT = C.ED_SEQLOT (+)";
#				. " AND ROWNUM<1000 "; # le probleme c'est que ROWNUM contient le détail des lignes avant regroupement par lot
#				. " WHERE A.ED_IDLDOC=B.ED_SNGL_ID AND B.ED_JOB_EVT='J' AND A.ED_SEQLOT != 'ANO' AND A.ED_SEQLOT LIKE ? ";
	$groupby  = " GROUP BY B.ED_APP, B.ED_SNGL_ID, A.ED_STATUS, C.ED_STATUS ";
	$orderby	= " ORDER BY B.ED_APP, NB_DOCS, B.ED_SNGL_ID, A.ED_STATUS, C.ED_STATUS ASC";

	my $col = "";
	if 		($refiddoc) { 
		$sql .= " AND B.ED_APP = ? ";
		push (@sql_values, $refiddoc);
	}

	if		($lot =~/^SEQLOT$/i) { 
		$select	.=", A.ED_SEQLOT ";
		$groupby 	.=", A.ED_SEQLOT ";
		$orderby	= ", A.ED_SEQLOT ";
		$col = uc ($lot);

	} elsif	($lot =~/^SOURCE$/i) { 
		$select	.=", B.ED_SOURCE ";
		$groupby 	.=", B.ED_SOURCE ";
		$orderby	= ", B.ED_SOURCE ";
		$col = uc ($lot);
	
	} elsif 	($lot) {
		$select	.=", B.ED_SOURCE ";
		$sql		.="  AND B.ED_SOURCE = ? ";
		$groupby 	.=", B.ED_SOURCE ";
		$orderby	= ", B.ED_SOURCE ";
		push (@sql_values, $lot);
	}

	$sql = $select . $sql . $groupby . $orderby;

#warn "\nINFO : $sql\n\n";

	my $sth = $dbh->prepare($sql);
	$sth->execute(@sql_values);

	my $rows= $sth->fetchall_arrayref();
		foreach my $row (@$rows) {
		for (my $i=0; $i<=$#$row ; $i++){
			$$row[$i] = $$row[$i] || ""; # DANS LE CAS DE SEQLOT IL PEUT ARRIVER QU'IL NE SOIT PAS ENCORE RENSEIGNE	
		}
		# push (@tlist, printf ("%-16s %9s %9s %9s %8s %8s %7s %-10s %s\n", @$row));
	}

	warn sprintf "%9s %-7s %-15s %-16s %s  from EDTK_STATS_OUTMNGR\n", "NB_DOCS", "STATUS", "REFIDDOC", "IDLDOC", $col;


################################################################################


if ($#$rows<0) {
	warn "INFO : pas de donnees associees.\n";
	exit;
}

foreach my $row (@$rows) {
		for (my $i=0; $i<=$#$row ; $i++){
			$$row[$i] = $$row[$i] || ""; # CERTAINES VALEURS PEUVENT NE PAS ÊTRE RENSEIGNÉES DANS CERTAINS CAS	
		}
	printf "%9s %7s %-15s %-16s %s \n", @$row, ""; # 1391152325098839
}
