package oEdtk::Tracking;

my ($_TRACK_SIG, $_TRACK_TRK);

BEGIN { 
	$SIG{'__WARN__'} = sub { 
		warn $_[0];
		if (defined $_TRACK_TRK && $_TRACK_SIG=~/warn/i) {
			# http://perldoc.perl.org/functions/warn.html
			$_TRACK_TRK->track('Warn', 1, $_[0]);
		} 
	};

	$SIG{'__DIE__'} = sub { 
		die $_[0];
		if (defined $_TRACK_TRK) {
			$_TRACK_TRK->track('Halt', 1, $_[0]);
		} 
	};
}


use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect create_table_TRACKING);
use oEdtk::Dict;
use Config::IniFiles;
use Sys::Hostname;
use DBI;

use Exporter;

our $VERSION		= 0.8022;
our @ISA			= qw(Exporter);
our @EXPORT_OK		= qw(stats_iddest stats_week stats_month);


sub new {
	my ($class, $source, %params) = @_;
	$source = $source || ($ARGV[1] || $ARGV[0]);
	if ($source=~/^\-/){
			$source = $ARGV[0];
	}
	my $cfg = config_read('EDTK_DB');

	# Load the dictionary to normalize entity names.
	my $dict = oEdtk::Dict->new($cfg->{'EDTK_DICO'}, { invert => 1 });

	my $mode = uc($cfg->{'EDTK_TRACK_MODE'});
	if ($mode eq 'NONE') {
		warn "INFO : Tracking is currently disabled...\n";
		# Return a dummy object if tracking is disabled.
		return bless { dict => $dict, mode => $mode }, $class;
	}

	my $table = $cfg->{'EDTK_DBI_TRACKING'};
	my $dbh = db_connect($cfg, 'EDTK_DBI_DSN', { AutoCommit => 1 });

	# XXX Should we ensure there is at least one key defined?
	my $keys = $params{'keys'} || [];

	if (@$keys > $cfg->{'EDTK_MAX_USER_KEY'}) {
		die "ERROR: too many tracking keys: got " . @$keys . ", max " .
		    $cfg->{'EDTK_MAX_USER_KEY'};
	}

	# Check that all the keys are at most 8 characters long, and otherwise
	# truncate them.  Also ensure we don't have the same key several times.
	my %seen = ();
	my @userkeys = ();
	foreach (@$keys) {
		my $key = uc($_);
		if (length($key) > 8) {
			$key =~ s/^(.{8}).*$/$1/;
			warn "INFO : column \"\U$_\E\" too long, truncated to \"$key\"\n";
		}
		if (exists($seen{$key})) {
			die "ERROR: duplicate column \"$key\"";
		}
		push(@userkeys, $key);
		$seen{$key} = 1;
	}

	# Extract application name from the script name.
	my $app = $0;
	$app =~ s/^.*?[\/\\]?([A-Z0-9-_]+)\.pl$/$1/;
	if (length($app) > 20) {
		$app =~ s/\.pl$//i;
		$app =~ /(.{20})$/;
		warn "INFO : application name \"$app\" too long, truncated to \"$1\"\n";
		$app = $1;
	}

	# Validate the editing mode.
	my $edmode = _validate_edmode($params{'edmode'});

	# Limit username length to 10 characters per the table schema.
	my $user = $params{'user'} || 'None';
	if (length($user) > 10) {
		$user =~ s/^(.{10}).*$/$1/;
		warn "INFO : username \"$params{'user'}\" too long, truncated to \"$user\"\n";
	}

	# Truncate if necessary, by taking at most 128 characters on the right.
	if (length($source) > 128) {
		$source = substr($source, -128, 128);
	}

	my $self = bless {
		dict	=> $dict,
		mode	=> $mode,
		table=> $table,
		edmode=>$edmode,
		id	=> oe_ID_LDOC(),
		seq	=> 1,
		keys	=> \@userkeys,
		user	=> $user,
		source=>$source,
		app	=> $app,
		dbh	=> $dbh
	}, $class;

	my $entity = $params{'entity'} || $cfg->{'EDTK_CORP'};
	$self->set_entity($entity);

	# Create the table in the SQLite case.
	if ($dbh->{'Driver'}->{'Name'} eq 'SQLite') {
		eval { create_table_TRACKING($dbh, $table, $cfg->{'EDTK_MAX_USER_KEY'}); };
		if ($@) {
			warn "INFO : Could not create table : $@\n";
		}
	}

	$self->track('Job', 1, join (' ', @ARGV)); # conserver le join pour placer tous les parametres libres dans la zone de message
	if (defined $cfg->{'EDTK_TRACK_SIG'} && $cfg->{'EDTK_TRACK_SIG'}!~/no/i) {
		$_TRACK_SIG = $cfg->{'EDTK_TRACK_SIG'};
		warn "INFO : tracking catchs SIG messages -> '$_TRACK_SIG' set ('warn' for all, 'halt' for die only)\n";
		$_TRACK_TRK = $self;
	}
	return $self;
}


sub track {
	my ($self, $job, $count, @data) = @_;

	return if $self->{'mode'} eq 'NONE';

	$count ||= 1;

	my @usercols = @{$self->{'keys'}};
	if (@data > (@usercols +1)) {
		# max is @usercols nbcol + 1 for message col
		warn "INFO : Too much values : got " . @data . ", expected " .  (@usercols +1) . " maximum\n";
	}

	# Validate the job event.
	$job = _validate_event($job);

	# GENERATE SQL REQUEST.
	my $values = {
		ED_TSTAMP		=> oe_now_time(),
		ED_USER		=> $self->{'user'},
		ED_SEQ		=> $self->{'seq'}++,
		ED_SNGL_ID	=> $self->{'id'},
		ED_APP		=> $self->{'app'},
		ED_MOD_ED		=> $self->{'edmode'},
		ED_JOB_EVT	=> $job,
		ED_OBJ_COUNT	=> $count,
		ED_CORP		=> $self->{'entity'},
		ED_SOURCE		=> $self->{'source'},
		ED_HOST		=> hostname()
	};

	foreach my $i (0 .. $#data) {
		# ajout d'une colonne message pour gérer les messages et les warning 
		# pour assurer la compatibilité avec l'existant on va inverser
		# les data pour mettre le message en tête en attendant le job_evt
		##################  PBM  DONNEES NON ALIMENTEES A REGARDER DE PRES
		my $val = $data[$i] || "";
		$values->{'ED_MESSAGE'}			= $val . " " . ($values->{'ED_MESSAGE'} || "");

		# s'il n'y a qu'une data, on s'assure de ne pas la mettre inutilement dans une colonne utilisateur
		if ($#data > 0) {
			if (defined($data[$i]) && length($data[$i]) > 128) {
				warn "INFO : \"$data[$i]\" truncated to 128 characters\n";
				$data[$i] =~ s/^(.{128}).*$/$1/;
			}
			$values->{"ED_K${i}_NAME"}	= $usercols[$i];
			$values->{"ED_K${i}_VAL"}	= $val;
		}
	}

	if ($job eq 'W' || $job eq 'H') { # Halt or Warn event
		# si le job_evt est 'Warning' ou 'Halt' on gère les messages et la source
		$values->{'ED_MESSAGE'}	=~ s/\s+/ /g;
		$values->{'ED_MESSAGE'}	=~ s/^(.{256}).*$/$1/;
		$values->{'ED_SOURCE'}	= $self->{'source'} if ($job eq 'H');

	} elsif ($job eq 'J') { # JOB event
		$values->{'ED_SOURCE'}	= $self->{'source'};

	} else {
		undef ($values->{'ED_MESSAGE'});
	}

	my @cols	= keys(%$values);
	my $table	= $self->{'table'};
	my $sql	= "INSERT INTO $table (" . join(', ', @cols) . ") VALUES (" .
	    join(', ', ('?') x @cols) . ")";

	my $dbh	= $self->{'dbh'};
	my $sth	= $dbh->prepare($sql);
	$sth->execute(values(%$values)) or die $sth->errstr;

	if (!$dbh->{'AutoCommit'}) {
		$dbh->commit or die $dbh->errstr;
	}
}


sub set_entity {
	my ($self, $entity) = @_;

	if (!defined($entity) || length($entity) == 0) {
		warn "INFO : Tracking::set_entity() called with an undefined entity!\n";
		return;
	}
	# warn "INFO : translate >$entity< \n";
	$entity =$self->{'dict'}->translate($entity);
	$self->{'entity'} = $entity;
	# warn $self->{'entity'}. " \$self->{'entity'}\n";
}


sub end {
	my $self = shift;
	$self->track('Halt', 1);
} 


# Pour chaque application, pour chaque entité juridique, et pour chaque semaine
# le nombre de documents dans le tracking.
sub stats_week {
	# passer les options par clefs de hash...
	my ($dbh, $cfg, $start, $end, $excluded_users) = @_;

	my $table = $cfg->{'EDTK_STATS_TRACKING'};
	my $innersql = "SELECT ED_CORP, ED_APP, "
			. "'S' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'IW') AS ED_WEEK "
			. "FROM $table "
			. "WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= ? ";
	my @vals = ($start);
	if (defined($end)) {
		$innersql .= " AND ED_TSTAMP <= ? ";
		push(@vals, $end);
	}

	if (defined $excluded_users ) {
		my @excluded = split (/,\s*/, $excluded_users);
		for (my $i =0 ; $i <= $#excluded ; $i++ ){
			$innersql .= " AND ED_USER != ? "; 
		}
		push(@vals, @excluded);
	}

	my $sql = "SELECT i.ED_CORP, i.ED_APP, i.ED_WEEK, COUNT(*) AS ED_COUNT " .
	    "FROM ($innersql) i GROUP BY ED_CORP, ED_APP, ED_WEEK ";

#	warn "\nINFO : $sql \n";
#SELECT i.ED_CORP, i.ED_APP, i.ED_WEEK, COUNT(*) AS ED_COUNT 
#	   FROM (
#	   		SELECT ED_CORP, ED_APP, 'S' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'IW') AS ED_WEEK 
#			FROM EDTK_TRACKING_2010 WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= '20101212'
#			) i 
#	GROUP BY ED_CORP, ED_APP, ED_WEEK;

	my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, @vals);
	# use Data::Dumper;
	# print Dumper($rows);
        #  {
        #    'ED_COUNT' => '4',
        #    'ED_APP' => 'FUS-AC007',
        #    'ED_CORP' => 'CPLTR',
        #    'ED_WEEK' => 'S51'
        #  },

	return $rows;
}


sub stats_iddest {
	# passer les options par clefs de hash...
	my ($dbh, $cfg, $start, $end, $excluded_users, $ed_app) = @_;

	my $table = $cfg->{'EDTK_STATS_TRACKING'};
	my $innersql = "SELECT ED_CORP, ED_K1_VAL AS ED_EMET, ED_K0_VAL AS ED_IDDEST, ED_APP, "
			. "'S' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'IW') AS ED_WEEK "
			. "FROM $table "
			. "WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= ? ";
	my @vals = ($start);
	if (defined($end)) {
		$innersql .= " AND ED_TSTAMP <= ? ";
		push(@vals, $end);
	}

	if (defined $excluded_users ) {
		my @excluded = split (/,\s*/, $excluded_users);
		for (my $i =0 ; $i <= $#excluded ; $i++ ){
			$innersql .= " AND ED_USER != ? "; 
		}
		push(@vals, @excluded);
	}

	if (defined $ed_app ) {
		$innersql .= " AND ED_APP = ? "; 
		push(@vals, $ed_app);
	}


	my $sql = "SELECT i.ED_CORP, i.ED_EMET, i.ED_IDDEST, i.ED_APP, i.ED_WEEK, COUNT(*) AS ED_COUNT " .
	    "FROM ($innersql) i GROUP BY i.ED_CORP, i.ED_EMET, i.ED_IDDEST, i.ED_APP, i.ED_WEEK ";
	    
#	warn "INFO : $sql \n";
#	warn "INFO : @vals \n";
# SELECT i.ED_CORP, i.ED_SECTION, i.ED_IDDEST, i.ED_APP, i.ED_WEEK, COUNT(*) AS ED_COUNT 
#	FROM (
#		SELECT ED_CORP, ED_K1_VAL AS ED_SECTION, ED_K0_VAL AS ED_IDDEST, ED_APP, 
#		'S' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'IW') AS ED_WEEK 
#			FROM EDTK_TRACKING_2010 WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= ?  
#			AND ED_TSTAMP <= ?  AND ED_USER != ?  AND ED_APP = ? ) i 
#		GROUP BY i.ED_CORP, i.ED_SECTION, i.ED_IDDEST, i.ED_APP, i.ED_WEEK

	my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, @vals);
	# use Data::Dumper;
	# print Dumper($rows);
	#           {
        #    'ED_COUNT' => '2',
        #    'ED_APP' => 'CTP-AC001',
        #    'ED_IDDEST' => '0000428193',
        #    'ED_CORP' => 'CORP_1',
        #    'ED_WEEK' => 'S50',
        #    'ED_EMET' => 'P004'
        #  },

	return $rows;
}


# Pour chaque application, pour chaque E.R., pour chaque entité juridique
# et pour chaque mois, le nombre de documents dans le tracking.
sub stats_month {
	my ($dbh, $cfg, $start, $end, $excluded_users) = @_;

	my $table = $cfg->{'EDTK_STATS_TRACKING'};
	my $innersql = "SELECT ED_APP, ED_CORP, ED_K1_VAL AS ED_EMET, "
			. "'M' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'MM') AS ED_MONTH "
			. "FROM $table WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= ? "; # AND ED_K1_NAME = 'SECTION'
	my @vals = ($start);

	if (defined($end)) {
		$innersql .= " AND ED_TSTAMP <= ? ";
		push(@vals, $end);
	}
				
	if (defined $excluded_users ) {
		my @excluded = split (/,\s*/, $excluded_users);
		for (my $i =0 ; $i <= $#excluded ; $i++ ){
			$innersql .= " AND ED_USER != ? "; 
		}
		push(@vals, @excluded);
	}

	my $sql = "SELECT i.ED_APP, i.ED_CORP, i.ED_EMET, i.ED_MONTH, COUNT(*) AS ED_COUNT " .
	    "FROM ($innersql) i GROUP BY ED_APP, ED_CORP, ED_EMET, ED_MONTH ";

	my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, @vals);

#	use Data::Dumper;
#	print Dumper($rows);
#          'ED_MONTH' => 'M12',
#          'ED_COUNT' => '1',
#          'ED_CORP' => 'CORP_1',
#          'ED_APP' => 'DEV-CAMELEON',
#          'ED_EMET' => '37043'

	return $rows;
}



#my $_PRGNAME;

sub _validate_event {
	# Job Event : looking for one of the following : 
	#	 Job (default), Spool, Document, Line, Warning, Error, Halt (critic), Reject
	my $job = shift;

	warn "INFO : Halt event in Tracking = $job\n" if ($job =~/^H/);
	if (!defined $job || $job !~ /^([JSDLWEHR])/) {
		die "ERROR: Invalid job event : " . (defined $job ? $job : '(undef)') . "\n"
			. "\t valid events are : Job / Spool / Document / Line / Warning / Reject / Error / Halt (critic)\n"
			;
	}
	return $1;
}

#{
#my $_edmode;
#
#	sub display_edmode {
#		if (!defined $_edmode) {
#			$_edmode = _validate_edmode(shift);
#		}
#	return $_edmode;
#	}

	sub _validate_edmode {
		# Printing Mode : looking for one of the following :
		#	 Undef (default), Batch, Tp, Web, Mail, probinG
		my $edmode = shift;
	
		if (!defined $edmode || $edmode !~ /^([BTMWG])/) {
			return 'U';
		}
		return $1;
	}
#}

1;
