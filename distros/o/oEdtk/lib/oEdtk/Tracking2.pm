package oEdtk::Tracking;    ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;

our $WARN2LOGGER;           # imported from oEdtk::logger below

my ( $_TRACK_SIG, $_TRACK_TRK, @_TRACK_JSON );

# xxx TO CHANGE : test if SQLite table already exist before creation

BEGIN {
	$SIG{'__WARN__'} = sub {
		if ($WARN2LOGGER) {
			&logger( 4, $_[0] );
		}
		else {
			warn $_[0];
		}

# when Tracking object is defined, $_TRACK_TRK is defined so that events can be catch and sent to tracker
		if ( defined $_TRACK_TRK && $_TRACK_SIG =~ /warn/i ) {

			# http://perldoc.perl.org/functions/warn.html
			my $message = $_[0];
			chomp($message);
			$_TRACK_TRK->track( 'Warn', 1, $message );
		}
	};

	$SIG{'__DIE__'} = sub {
		if ( defined $_TRACK_TRK ) {
			my $message = $_[0];
			chomp($message);
			$_TRACK_TRK->track( 'Halt', 1, $message );
		}
		die $_[0];
	};
}

use warnings;

use oEdtk::Main;
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(db_connect create_table_TRACKING);
use oEdtk::logger  qw(logger $WARN2LOGGER);
use oEdtk::Dict;
use Config::IniFiles;
use Sys::Hostname;
use Data::Dumper qw(Dumper);
use DBI;

#use JSON;
use Exporter;

our $VERSION   = 2.1131;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(stats_iddest stats_week stats_month);

#my  @JSON_TRACE;

sub new {

	# example call
	# 	$TRK = oEdtk::Tracking->new($ARGV[1] // '',
	#		ED_USER => "utest",
	#		ED_CORP => "Society",
	#		keys => ['T_CALLID', 'T_TYPE', 'O_TT_TYP', 'O_TT_ID', 'T_PARAM', 'O_DESIGN', 'T_STATUT' ]
	#		);

	my ( $class, $ED_SOURCE, %params ) = @_;

	# An explicit empty source means "no input file" and must stay empty; only
	# an omitted source falls back to the command line.
	if ( !defined $ED_SOURCE ) {
		$ED_SOURCE = $ARGV[1] || $ARGV[0] || '';
	}
	if ( $ED_SOURCE =~ /^\-/ ) {
		$ED_SOURCE = $ARGV[0] // '';
	}
	my $cfg = config_read('EDTK_DB');

	# Load the dictionary to normalize entity names.
	my $EDTK_TRACK_DICT = oEdtk::Dict->new( $cfg->{'EDTK_DICO'}, { invert => 1 } );

	my $EDTK_TRACK_MODE = uc( $cfg->{'EDTK_TRACK_MODE'} );
	if ( $EDTK_TRACK_MODE eq 'NONE' ) {
		warn "INFO: Tracking is currently disabled... (see EDTK_TRACK_MODE in config file)\n";

		# Return a dummy object if tracking is disabled.
		return bless { EDTK_TRACK_DICT => $EDTK_TRACK_DICT, mode => $EDTK_TRACK_MODE }, $class;
	}

	my $table = $cfg->{'EDTK_DBI_TRACKING'};
	my $dbh   = db_connect( $cfg, 'EDTK_DBI_DSN', { AutoCommit => 1 } );

	# XXX Should we ensure there is at least one key defined?
	$cfg->{'EDTK_TRACKING_KEYS'} =~ s/\s+//g;
	$cfg->{'EDTK_TRACKING_KEYS'} =~ s/[()"']+//g;

	my @userkeys =
		( split( /,/, uc( $cfg->{'EDTK_TRACKING_KEYS'} ), $cfg->{'EDTK_MAX_USER_KEY'} ) ) // [];

	#	print Dumper(@userkeys);

	#	my $keys = $params{'keys'} || [];

	#	if (@$keys > $cfg->{'EDTK_MAX_USER_KEY'}) {
	#		die "ERROR: too many tracking keys: got " . @$keys . ", max " .
	#		    $cfg->{'EDTK_MAX_USER_KEY'};
	#	}

	# Check that all the keys are at most 8 characters long, and otherwise
	# truncate them.  Also ensure we don't have the same key several times.
	my %seen = ();
	foreach ( my $i = 0 ; $i <= $#userkeys ; $i++ ) {
		if ( length( $userkeys[$i] ) > 8 ) {
			$userkeys[$i] =~ s/^(.{8}).*$/$1/;
			warn "userkeys[$i] = $userkeys[$i]\n";
			warn "INFO: column \"\U$_\E\" too long, truncated to \"$userkeys[$i])\"\n";
		}
		if ( exists( $seen{ $userkeys[$i] } ) ) {
			die "ERROR: duplicate column \"$userkeys[$i])\"";
		}

		#		push(@userkeys, $key);
		$seen{ $userkeys[$i] } = 1;
	}

	#	my @userkeys = ();
	#	foreach (@$keys) {
	#		my $key = uc($_);
	#		if (length($key) > 8) {
	#			$key =~ s/^(.{8}).*$/$1/;
	#			warn "INFO: column \"\U$_\E\" too long, truncated to \"$key\"\n";
	#		}
	#		if (exists($seen{$key})) {
	#			die "ERROR: duplicate column \"$key\"";
	#		}
	#		push(@userkeys, $key);
	#		$seen{$key} = 1;
	#	}

	# Extract application name from the script name.
	my $ED_APP = $0;
	$ED_APP =~ s/^.*?[\/\\]?([\w-]+[\.plmex]*$)/$1/;

	#	$ED_APP =~ s/^.*?[\/\\]?([A-Z0-9-_]+)\.pl$/$1/;
	if ( length($ED_APP) > 20 ) {
		$ED_APP =~ s/\.pl$//i;
		$ED_APP =~ /(.{20})$/;
		warn "INFO: application name \"$ED_APP\" too long, truncated to \"$1\"\n";
		$ED_APP = $1;
	}

	# Validate the editing mode.
	my $ED_MOD_ED = _validate_edmode( $params{'ED_MOD_ED'} );

	# Limit username length to 10 characters per the table schema.
	my $ED_USER = $params{'ED_USER'} || 'None';
	if ( length($ED_USER) > 10 ) {
		$ED_USER =~ s/^(.{10}).*$/$1/;
		warn "INFO: username \"$params{'user'}\" too long, truncated to \"$ED_USER\"\n";
	}

	# Truncate if necessary, by taking at most 128 characters on the right.
	if ( length($ED_SOURCE) > 128 ) {
		$ED_SOURCE = substr( $ED_SOURCE, -128, 128 );
	}

	my $self = bless {
		dbh             => $dbh,
		table           => $table,
		keys            => \@userkeys,
		EDTK_TRACK_DICT => $EDTK_TRACK_DICT,
		ED_SNGL_ID      => oe_ID_LDOC(),
		ED_SEQ          => 1,
		EDTK_TRACK_MODE => $EDTK_TRACK_MODE,
		ED_MOD_ED       => $ED_MOD_ED,
		ED_USER         => $ED_USER,
		ED_SOURCE       => $ED_SOURCE,
		ED_APP          => $ED_APP
	}, $class;

	my $entity = $params{'entity'} || $cfg->{'EDTK_CORP'};
	$self->set_entity($entity);

	# Create the table in the SQLite case
	if ( $dbh->{'Driver'}->{'Name'} eq 'SQLite' ) {
		eval { create_table_TRACKING( $dbh, $table, $cfg->{'EDTK_MAX_USER_KEY'} ); };
		if ($@) {
			warn "INFO: Table already exist : $@\n";
		}
	}

	$self->track( 'Job', 1, join( ' ', @ARGV ) )
		;    # keep the join to place all the free parameters in the message area
	if ( defined $cfg->{'EDTK_TRACK_SIG'} && $cfg->{'EDTK_TRACK_SIG'} !~ /no/i ) {
		$_TRACK_SIG = $cfg->{'EDTK_TRACK_SIG'};
		warn
"INFO: tracking catchs SIG messages = '$_TRACK_SIG' (see EDTK_TRACK_SIG : 'warn' for all, 'halt' for die only)\n";
		$_TRACK_TRK = $self;
	}

	#	if (defined $cfg->{'EDTK_TRACK_JSON'} && $cfg->{'EDTK_TRACK_JSON'} !~/no/i )  {
	#		# $_TRACK_TRK_JSON = $cfg->{'EDTK_TRACK_JSON'};
	#		push (@_TRACK_JSON, $cfg->{'EDTK_TRACK_JSON'});
	#	}
	#	} else {
	#		#$_TRACK_TRK_JSON = "no";
	#		$_TRACK_JSON[0] //= "no";
	#		#push (@_TRACK_JSON, "no");
	#	}
	#	warn "INFO: _TRACK_JSON = " . @_TRACK_JSON ." \n";

	return $self;
}

sub track {

	# example call
	# $TRK->track('Spool', 1, "K0val", "K1val", "K2val", "Knval" );
	my ( $self, $ED_JOB_EVT, $count, @data ) = @_;

	return if $self->{'EDTK_TRACK_MODE'} eq 'NONE';

	$count ||= 1;

	my @usercols = @{ $self->{'keys'} };
	if ( @data > ( @usercols + 1 ) ) {

		# max is @usercols nbcol + 1 for message col
		warn "INFO: Too much values : got "
			. @data
			. ", expected "
			. ( @usercols + 1 )
			. " maximum\n";
	}

	# Validate the job event.
	$ED_JOB_EVT = _validate_event($ED_JOB_EVT);

	# GENERATE SQL REQUEST.
	my $values = {
		ED_SNGL_ID   => $self->{'ED_SNGL_ID'},
		ED_SEQ       => $self->{'ED_SEQ'}++,
		ED_TSTAMP    => oe_now_time(),
		ED_USER      => $self->{'ED_USER'},
		ED_APP       => $self->{'ED_APP'},
		ED_CORP      => $self->{'entity'},
		ED_ACCOUNT   => $self->{'account'} // "",
		ED_MOD_ED    => $self->{'edmode'},
		ED_JOB_EVT   => $ED_JOB_EVT,
		ED_OBJ_TYP   => $self->{'obj_typ'},
		ED_OBJ_COUNT => $count,
		ED_CHILD_TYP => $self->{'child_typ'} // "",
		ED_CHILD_ID  => $self->{'child_id'}  // "",
		ED_PARENT_ID => $self->{'parent_id'} // "",

		ED_HOST   => hostname(),
		ED_SOURCE => $self->{'ED_SOURCE'}
	};

	foreach my $i ( 0 .. $#data ) {

		# add a message column to handle messages and warnings
		# to ensure compatibility with what exists, we reverse
		# the data to put the message first while waiting for job_evt
		##################  PBM  DATA NOT POPULATED, TO REVIEW
		my $val = $data[$i] // "";
		$values->{'ED_MESSAGE'} = $val . " " . ( $values->{'ED_MESSAGE'} // "" );

		# if there is only one data item, make sure not to put it needlessly in a user column
		if ( $#data > 0 ) {
			if ( defined( $data[$i] ) && length( $data[$i] ) > 128 ) {
				warn "INFO: \"$data[$i]\" truncated to 128 characters\n";
				$data[$i] =~ s/^(.{128}).*$/$1/;
			}
			$values->{"ED_K${i}_NAME"} = $usercols[$i];
			$values->{"ED_K${i}_VAL"}  = $val;
		}
	}

	if ( $ED_JOB_EVT eq 'W' || $ED_JOB_EVT eq 'H' ) {    # Halt or Warn event
		$values->{'ED_SOURCE'} = $self->{'ED_SOURCE'} if ( $ED_JOB_EVT eq 'H' );

	}
	elsif ( $ED_JOB_EVT eq 'J' ) {                       # ED_JOB_EVT event
		$values->{'ED_SOURCE'} = $self->{'ED_SOURCE'};

	}
	else {
		undef( $values->{'ED_MESSAGE'} );
	}

	# Normalize the message. When the caller supplied none, name the function
	# that recorded the event so the row stays informative.
	my $message = $values->{'ED_MESSAGE'} // '';
	$message =~ s/\s+/ /g;
	$message =~ s/^ //;
	$message =~ s/ $//;
	$message = _caller_name() if $message eq '';
	$message =~ s/^(.{256}).*$/$1/;
	$values->{'ED_MESSAGE'} = $message;

	my @cols  = keys(%$values);
	my $table = $self->{'table'};
	my $sql =
		  "INSERT INTO $table ("
		. join( ', ', @cols )
		. ") VALUES ("
		. join( ', ', ('?') x @cols ) . ")";

#warn "sql = $sql \n";
#sql = INSERT INTO EDTK_TRACKING (ED_JOB_EVT, ED_APP, ED_CORP, ED_OBJ_TYP, ED_USER, ED_MESSAGE, ED_TSTAMP, ED_SNGL_ID, ED_OBJ_COUNT, ED_MOD_ED, ED_SOURCE, ED_SEQ, ED_HOST) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

	my $dbh = $self->{'dbh'};
	my $sth = $dbh->prepare($sql);
	$sth->execute( values(%$values) ) or die $sth->errstr;

	if ( !$dbh->{'AutoCommit'} ) {
		$dbh->commit or die $dbh->errstr;
	}

	#if ($_TRACK_JSON[0] ne "no") { push (@_TRACK_JSON, $values) };
}

# Name of the function that recorded the event. The Tracking package and its
# signal-handler closures are skipped, so the caller's code is named instead.
sub _caller_name {
	for my $depth ( 1 .. 10 ) {
		my @frame = caller($depth);
		last unless @frame;
		my $name = $frame[3] // '';
		next if $name eq '' || $name =~ /__ANON__/;
		next if $name                =~ /^oEdtk::Tracking::/;
		return $name;
	}
	return 'main';
}

sub set_entity {
	my ( $self, $entity ) = @_;

	if ( !defined($entity) || length($entity) == 0 ) {
		warn "INFO: Tracking::set_entity() called with an undefined entity!\n";
		return;
	}

	# warn "INFO: translate >$entity< \n";
	$entity = $self->{'EDTK_TRACK_DICT'}->translate($entity);
	$self->{'entity'} = $entity;

	# warn $self->{'entity'}. " \$self->{'entity'}\n";
}

sub end {
	my $self = shift;
	$self->track( 'Halt', 1 );
}

# For each application, for each legal entity, and for each week
# the number of documents in the tracking.
sub stats_week {

	# pass the options as hash keys...
	my ( $dbh, $cfg, $start, $end, $excluded_users ) = @_;

	my $table = $cfg->{'EDTK_STATS_TRACKING'};
	my $innersql =
		  "SELECT ED_CORP, ED_APP, "
		. "'S' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'IW') AS ED_WEEK "
		. "FROM $table "
		. "WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= ? ";
	my @vals = ($start);
	if ( defined($end) ) {
		$innersql .= " AND ED_TSTAMP <= ? ";
		push( @vals, $end );
	}

	if ( defined $excluded_users ) {
		my @excluded = split( /,\s*/, $excluded_users );
		for ( my $i = 0 ; $i <= $#excluded ; $i++ ) {
			$innersql .= " AND ED_USER != ? ";
		}
		push( @vals, @excluded );
	}

	my $sql = "SELECT i.ED_CORP, i.ED_APP, i.ED_WEEK, COUNT(*) AS ED_COUNT "
		. "FROM ($innersql) i GROUP BY ED_CORP, ED_APP, ED_WEEK ";

#	warn "\nINFO: $sql \n";
#SELECT i.ED_CORP, i.ED_APP, i.ED_WEEK, COUNT(*) AS ED_COUNT
#	   FROM (
#	   		SELECT ED_CORP, ED_APP, 'S' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'IW') AS ED_WEEK
#			FROM EDTK_TRACKING_2010 WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= '20101212'
#			) i
#	GROUP BY ED_CORP, ED_APP, ED_WEEK;

	my $rows = $dbh->selectall_arrayref( $sql, { Slice => {} }, @vals );

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

	# pass the options as hash keys...
	my ( $dbh, $cfg, $start, $end, $excluded_users, $ed_app ) = @_;

	my $table = $cfg->{'EDTK_STATS_TRACKING'};
	my $innersql =
		  "SELECT ED_CORP, ED_K1_VAL AS ED_EMET, ED_K0_VAL AS ED_IDDEST, ED_APP, "
		. "'S' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'IW') AS ED_WEEK "
		. "FROM $table "
		. "WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= ? ";
	my @vals = ($start);
	if ( defined($end) ) {
		$innersql .= " AND ED_TSTAMP <= ? ";
		push( @vals, $end );
	}

	if ( defined $excluded_users ) {
		my @excluded = split( /,\s*/, $excluded_users );
		for ( my $i = 0 ; $i <= $#excluded ; $i++ ) {
			$innersql .= " AND ED_USER != ? ";
		}
		push( @vals, @excluded );
	}

	if ( defined $ed_app ) {
		$innersql .= " AND ED_APP = ? ";
		push( @vals, $ed_app );
	}

	my $sql = "SELECT i.ED_CORP, i.ED_EMET, i.ED_IDDEST, i.ED_APP, i.ED_WEEK, COUNT(*) AS ED_COUNT "
		. "FROM ($innersql) i GROUP BY i.ED_CORP, i.ED_EMET, i.ED_IDDEST, i.ED_APP, i.ED_WEEK ";

	#	warn "INFO: $sql \n";
	#	warn "INFO: @vals \n";
	# SELECT i.ED_CORP, i.ED_SECTION, i.ED_IDDEST, i.ED_APP, i.ED_WEEK, COUNT(*) AS ED_COUNT
	#	FROM (
	#		SELECT ED_CORP, ED_K1_VAL AS ED_SECTION, ED_K0_VAL AS ED_IDDEST, ED_APP,
	#		'S' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'IW') AS ED_WEEK
	#			FROM EDTK_TRACKING_2010 WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= ?
	#			AND ED_TSTAMP <= ?  AND ED_USER != ?  AND ED_APP = ? ) i
	#		GROUP BY i.ED_CORP, i.ED_SECTION, i.ED_IDDEST, i.ED_APP, i.ED_WEEK

	my $rows = $dbh->selectall_arrayref( $sql, { Slice => {} }, @vals );

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

# For each application, for each E.R., for each legal entity
# and for each month, the number of documents in the tracking.
sub stats_month {
	my ( $dbh, $cfg, $start, $end, $excluded_users ) = @_;

	my $table = $cfg->{'EDTK_STATS_TRACKING'};
	my $innersql =
		  "SELECT ED_APP, ED_CORP, ED_K1_VAL AS ED_EMET, "
		. "'M' || TO_CHAR(TO_DATE(ED_TSTAMP, 'YYYYMMDDHH24MISS'), 'MM') AS ED_MONTH "
		. "FROM $table WHERE ED_JOB_EVT = 'D' AND ED_TSTAMP >= ? ";    # AND ED_K1_NAME = 'SECTION'
	my @vals = ($start);

	if ( defined($end) ) {
		$innersql .= " AND ED_TSTAMP <= ? ";
		push( @vals, $end );
	}

	if ( defined $excluded_users ) {
		my @excluded = split( /,\s*/, $excluded_users );
		for ( my $i = 0 ; $i <= $#excluded ; $i++ ) {
			$innersql .= " AND ED_USER != ? ";
		}
		push( @vals, @excluded );
	}

	my $sql = "SELECT i.ED_APP, i.ED_CORP, i.ED_EMET, i.ED_MONTH, COUNT(*) AS ED_COUNT "
		. "FROM ($innersql) i GROUP BY ED_APP, ED_CORP, ED_EMET, ED_MONTH ";

	my $rows = $dbh->selectall_arrayref( $sql, { Slice => {} }, @vals );

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

	warn "INFO: Halt event in Tracking = $job\n" if ( $job =~ /^H/ );
	if ( !defined $job || $job !~ /^([JSDLWEHR])/ ) {
		die "ERROR: Invalid job event : "
			. ( defined $job ? $job : '(undef)' ) . "\n"
			. "\t valid events are : Job / Spool / Document / Line / Warning / Reject / Error / Halt (critic)\n";
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

	if ( !defined $edmode || $edmode !~ /^([BTMWG])/ ) {
		return 'U';
	}
	return $1;
}

#}

#END {
#	#if ($_TRACK_TRK_JSON !~/no/i) {
#	if ($_TRACK_JSON[0] ne "no") {
#		my $json = JSON->new;
#		#print $json->encode(\@_TRACK_JSON);
#	}
#}

1;

=head1 NAME

oEdtk::Tracking2 - legacy warn-based production tracking

=head1 SYNOPSIS

    use oEdtk::Tracking;

    my $trk = oEdtk::Tracking->new($source, entity => 'Corp');
    $trk->track('Job', 1, @values);
    $trk->end;

=head1 DESCRIPTION

Legacy, warn-based duplicate of L<oEdtk::Tracking>. It declares the same package
C<oEdtk::Tracking> and the same public interface, but reports its diagnostics
through C<warn> instead of the logger, and reads the user keys from the
configuration rather than from the constructor arguments. It is kept for
reference; use L<oEdtk::Tracking> for new code.

=head1 METHODS

=head2 new

    my $trk = oEdtk::Tracking->new($source, %params);

Build a tracker. C<$source> names the input, and C<%params> may carry C<entity>,
C<edmode>, C<account>, C<obj_typ>, C<child_typ>, C<child_id> and C<parent_id>.
An omitted C<$source> falls back to C<@ARGV>; an explicit empty string means no
input file and is kept. The user keys come from the C<EDTK_TRACKING_KEYS>
configuration. When C<EDTK_TRACK_MODE> is C<NONE> an inert object is returned.

=head2 track

    $trk->track($job, $count, @data);

Record one event: the job event, the number of objects, and the values of the
configured user keys (an optional trailing value is the message). When no
message is supplied, C<ED_MESSAGE> names the function that recorded the event.

=head2 set_entity

    $trk->set_entity($entity);

Normalise C<$entity> through the dictionary and store it.

=head2 end

    $trk->end;

Record the final C<Halt> event.

=head1 FUNCTIONS

=head2 stats_iddest

    my $rows = stats_iddest($dbh, $cfg, $start, $end, $excluded_users, $ed_app);

Per recipient destination, per week, the number of documents tracked between
C<$start> and C<$end>.

=head2 stats_week

    my $rows = stats_week($dbh, $cfg, $start, $end, $excluded_users);

Per application, per legal entity and per ISO week, the number of documents
tracked during the period.

=head2 stats_month

    my $rows = stats_month($dbh, $cfg, $start, $end, $excluded_users);

Per application, per legal entity and per month, the number of documents tracked
during the period.

The following subs are internal helpers and are not part of the public API:
C<_validate_event> and C<_validate_edmode>.

=head1 AUTHOR

The oEdtk team.

=cut
