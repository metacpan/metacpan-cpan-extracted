package oEdtk::Tracking;
use strict;
use warnings;

my ( $_TRACK_SIG, $_TRACK_TRK, @_TRACK_JSON );

BEGIN {
	$SIG{'__WARN__'} = sub {

		#		if ($WARN2LOGGER){
		#			&logger (4, $_[0]);
		#		} else {
		warn $_[0];

#		}
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

use oEdtk::Main;
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(db_connect create_table_TRACKING);
use oEdtk::logger  qw(logger $WARN2LOGGER);
use oEdtk::Dict;
use Config::IniFiles;
use Sys::Hostname;
use DBI;

#use JSON;
use Exporter;

our $VERSION   = 2.1129;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(stats_iddest stats_week stats_month);

#my  @JSON_TRACE;

sub new {

	# example call
	# 	$TRK = oEdtk::Tracking->new($ARGV[1] // '',
	#		user => "utest",
	#		entity => "Society",
	#		keys => ['T_CALLID', 'T_TYPE', 'O_TT_TYP', 'O_TT_ID', 'T_PARAM', 'O_DESIGN', 'T_STATUT' ]
	#		);

	my ( $class, $source, %params ) = @_;

	# An explicit empty source means "no input file" and must stay empty; only
	# an omitted source falls back to the command line.
	if ( !defined $source ) {
		$source = $ARGV[1] || $ARGV[0] || '';
	}
	if ( $source =~ /^\-/ ) {
		$source = $ARGV[0] // '';
	}
	my $cfg = config_read('EDTK_DB');

	# Load the dictionary to normalize entity names.
	my $dict = oEdtk::Dict->new( $cfg->{'EDTK_DICO'}, { invert => 1 } );

	my $mode = uc( $cfg->{'EDTK_TRACK_MODE'} );
	if ( $mode eq 'NONE' ) {
		&logger( 6, "Tracking is currently disabled... (see EDTK_TRACK_MODE in config file)" );

		# Return a dummy object if tracking is disabled.
		return bless { dict => $dict, mode => $mode }, $class;
	}

	my $table = $cfg->{'EDTK_DBI_TRACKING'};
	my $dbh   = db_connect( $cfg, 'EDTK_DBI_DSN', { AutoCommit => 1 } );

	# XXX Should we ensure there is at least one key defined?
	my $keys = $params{'keys'} || [];

	if ( @$keys > $cfg->{'EDTK_MAX_USER_KEY'} ) {
		die "ERROR: too many tracking keys: got " . @$keys . ", max " . $cfg->{'EDTK_MAX_USER_KEY'};
	}

	# Check that all the keys are at most 8 characters long, and otherwise
	# truncate them.  Also ensure we don't have the same key several times.
	my %seen     = ();
	my @userkeys = ();
	foreach (@$keys) {
		my $key = uc($_);
		if ( length($key) > 8 ) {
			$key =~ s/^(.{8}).*$/$1/;
			&logger( 4, "column too long, truncated to '$key'" );
		}
		if ( exists( $seen{$key} ) ) {
			die "ERROR: duplicate column \"$key\"";
		}
		push( @userkeys, $key );
		$seen{$key} = 1;
	}

	# Extract application name from the script name.
	my $app = $0;
	$app =~ s/^.*?[\/\\]?([\w-]+[\.plmex]*$)/$1/;

	#$app =~ s/^.*?[\/\\]?([A-Z0-9-_]+)\.pl$/$1/;
	if ( length($app) > 20 ) {
		$app =~ s/\.pl$//i;
		$app =~ /(.{20})$/;
		&logger( 4, "application name '$app' too long, truncated to '$1'" );
		$app = $1;
	}

	# Validate the editing mode.
	my $edmode = _validate_edmode( $params{'edmode'} );

	# Limit username length to 10 characters per the table schema.
	my $user = $params{'user'} || 'None';
	if ( length($user) > 10 ) {
		$user =~ s/^(.{10}).*$/$1/;
		&logger( 4, "username \"$params{'user'}\" too long, truncated to \"$user\"" );
	}

	# Truncate if necessary, by taking at most 128 characters on the right.
	if ( length($source) > 128 ) {
		$source = substr( $source, -128, 128 );
	}

	my $self = bless {
		dict   => $dict,
		mode   => $mode,
		table  => $table,
		edmode => $edmode,
		id     => oe_ID_LDOC(),
		seq    => 1,
		keys   => \@userkeys,
		user   => $user,
		source => $source,
		app    => $app,

		entity    => $params{'entity'}    // "",
		account   => $params{'account'}   // "",
		obj_typ   => $params{'obj_typ'}   // "",
		child_typ => $params{'child_typ'} // "",
		child_id  => $params{'child_id'}  // "",
		parent_id => $params{'parent_id'} // "",

		dbh => $dbh
	}, $class;

	my $entity = $params{'entity'} || $cfg->{'EDTK_CORP'};
	$self->set_entity($entity);

	# Create the table in the SQLite case
	if ( $dbh->{'Driver'}->{'Name'} eq 'SQLite' ) {
		eval { create_table_TRACKING( $dbh, $table, $cfg->{'EDTK_MAX_USER_KEY'} ); };
		if ($@) {
			&logger( 6, "Table already exist : $@" );
		}
	}

	$self->track( 'Job', 1, join( ' ', @ARGV ) )
		;    # keep the join to place all the free parameters in the message area
	if ( defined $cfg->{'EDTK_TRACK_SIG'} && $cfg->{'EDTK_TRACK_SIG'} !~ /no/i ) {
		$_TRACK_SIG = $cfg->{'EDTK_TRACK_SIG'};
		&logger( 6,
"tracking catchs SIG messages = '$_TRACK_SIG' (see EDTK_TRACK_SIG : 'warn' for all, 'halt' for die only)"
		);
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
	my ( $self, $job, $count, @data ) = @_;

	return if $self->{'mode'} eq 'NONE';

	$count ||= 1;

	my @usercols = @{ $self->{'keys'} };
	if ( @data > ( @usercols + 1 ) ) {

		# max is @usercols nbcol + 1 for message col
		&logger( 3,
			"Too much values : got " . @data . ", expected " . ( @usercols + 1 ) . " maximum" );
	}

	# Validate the job event.
	$job = _validate_event($job);

	# GENERATE SQL REQUEST.
	my $values = {
		ED_SNGL_ID   => $self->{'id'},
		ED_SEQ       => $self->{'seq'}++,
		ED_TSTAMP    => oe_now_time(),
		ED_USER      => $self->{'user'},
		ED_APP       => $self->{'app'},
		ED_CORP      => $self->{'entity'},
		ED_ACCOUNT   => $self->{'account'} // "",
		ED_MOD_ED    => $self->{'edmode'},
		ED_JOB_EVT   => $job,
		ED_OBJ_TYP   => $self->{'obj_typ'},
		ED_OBJ_COUNT => $count,
		ED_CHILD_TYP => $self->{'child_typ'} // "",
		ED_CHILD_ID  => $self->{'child_id'}  // "",
		ED_PARENT_ID => $self->{'parent_id'} // "",

		ED_HOST   => hostname(),
		ED_SOURCE => $self->{'source'}
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
				&logger( 4, "\"$data[$i]\" truncated to 128 characters" );
				$data[$i] =~ s/^(.{128}).*$/$1/;
			}
			$values->{"ED_K${i}_NAME"} = $usercols[$i];
			$values->{"ED_K${i}_VAL"}  = $val;
		}
	}

	if ( $job eq 'W' || $job eq 'H' ) {    # Halt or Warn event
		$values->{'ED_SOURCE'} = $self->{'source'} if ( $job eq 'H' );

	}
	elsif ( $job eq 'J' ) {                # JOB event
		$values->{'ED_SOURCE'} = $self->{'source'};

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

	my $dbh   = $self->{'dbh'};
	my @cols  = keys(%$values);
	my $table = $self->{'table'};
	$table = uc($table) if ( $dbh->{'Driver'}->{'Name'} eq 'mysql' );

	my $sql =
		  "INSERT INTO $table ("
		. join( ', ', @cols )
		. ") VALUES ("
		. join( ', ', ('?') x @cols ) . ")";

#warn "sql = $sql \n";
#sql = insert into edtk_tracking (ed_job_evt, ed_app, ed_corp, ed_obj_typ, ed_user, ed_message, ed_tstamp, ed_sngl_id, ed_obj_count, ed_mod_ed, ed_source, ed_seq, ed_host) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

	_tracking_insert( $dbh, $sql, $table, $values );

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

# Run the tracking INSERT. On failure, report a stale schema (READ-ONLY) and
# then die with the driver's message, as the historical code did. The check is
# fully inside eval() so it can never mask the original error.
sub _tracking_insert {
	my ( $dbh, $sql, $table, $values ) = @_;
	my $sth;
	my $ok = eval {
		$sth = $dbh->prepare($sql);
		$sth->execute( values(%$values) );
	};
	return if $ok;
	my $err = ( $@ ne '' ) ? $@ : ( $sth ? $sth->errstr : $dbh->errstr );
	_tracking_schema_warn( $dbh, $table );
	die $err;
}

# Warn once per process when a tracking write fails on a stale schema. The
# warning itself is emitted by oEdtk::DBAdmin::schema_StaleWarning (read-only).
my $_TRACK_STALE_WARNED = 0;

sub _tracking_schema_warn {
	my ( $dbh, $table ) = @_;
	return if $_TRACK_STALE_WARNED;
	return unless $dbh;
	my $warned = eval { oEdtk::DBAdmin::schema_StaleWarning( $dbh, tracking_table => $table ); };
	$_TRACK_STALE_WARNED = 1 if $warned;
	return;
}

sub set_entity {
	my ( $self, $entity ) = @_;

	if ( !defined($entity) || length($entity) == 0 ) {
		&logger( 3, "Tracking::set_entity() called with an undefined entity!" );
		return;
	}

	# warn "INFO: translate >$entity< \n";
	$entity = $self->{'dict'}->translate($entity);
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
		  "select ed_corp, ed_app, "
		. "'s' || to_char(to_date(ed_tstamp, 'YYYYMMDDHH24MISS'), 'IW') as ed_week "
		. "from $table "
		. "where ed_job_evt = 'd' and ed_tstamp >= ? ";
	my @vals = ($start);
	if ( defined($end) ) {
		$innersql .= " and ed_tstamp <= ? ";
		push( @vals, $end );
	}

	if ( defined $excluded_users ) {
		my @excluded = split( /,\s*/, $excluded_users );
		for ( my $i = 0 ; $i <= $#excluded ; $i++ ) {
			$innersql .= " and ed_user != ? ";
		}
		push( @vals, @excluded );
	}

	my $sql = "select i.ed_corp, i.ed_app, i.ed_week, count(*) as ed_count "
		. "from ($innersql) i group by ed_corp, ed_app, ed_week ";

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
		  "select ed_corp, ed_k1_val as ed_emet, ed_k0_val as ed_iddest, ed_app, "
		. "'s' || to_char(to_date(ed_tstamp, 'YYYYMMDDHH24MISS'), 'IW') as ed_week "
		. "from $table "
		. "where ed_job_evt = 'd' and ed_tstamp >= ? ";
	my @vals = ($start);
	if ( defined($end) ) {
		$innersql .= " and ed_tstamp <= ? ";
		push( @vals, $end );
	}

	if ( defined $excluded_users ) {
		my @excluded = split( /,\s*/, $excluded_users );
		for ( my $i = 0 ; $i <= $#excluded ; $i++ ) {
			$innersql .= " and ed_user != ? ";
		}
		push( @vals, @excluded );
	}

	if ( defined $ed_app ) {
		$innersql .= " and ed_app = ? ";
		push( @vals, $ed_app );
	}

	my $sql = "select i.ed_corp, i.ed_emet, i.ed_iddest, i.ed_app, i.ed_week, count(*) as ed_count "
		. "from ($innersql) i group by i.ed_corp, i.ed_emet, i.ed_iddest, i.ed_app, i.ed_week ";

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
		  "select ed_app, ed_corp, ed_k1_val as ed_emet, "
		. "'m' || to_char(to_date(ed_tstamp, 'YYYYMMDDHH24MISS'), 'MM') as ed_month "
		. "from $table where ed_job_evt = 'd' and ed_tstamp >= ? ";
	my @vals = ($start);

	if ( defined($end) ) {
		$innersql .= " and ed_tstamp <= ? ";
		push( @vals, $end );
	}

	if ( defined $excluded_users ) {
		my @excluded = split( /,\s*/, $excluded_users );
		for ( my $i = 0 ; $i <= $#excluded ; $i++ ) {
			$innersql .= " and ed_user != ? ";
		}
		push( @vals, @excluded );
	}

	my $sql = "select i.ed_app, i.ed_corp, i.ed_emet, i.ed_month, count(*) as ed_count "
		. "from ($innersql) i group by ed_app, ed_corp, ed_emet, ed_month ";

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

sub _validate_event {

	# Job Event : looking for one of the following :
	#	 Job (default), Spool, Document, Line, Warning, Error, Halt (critic), Reject, Track
	my $job = shift;

	&logger( 3, "Halt event in Tracking = $job" ) if ( $job =~ /^H/ );
	if ( !defined $job || $job !~ /^([JSDLWEHRT])/ ) {
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

oEdtk::Tracking - object-oriented production tracking

=head1 SYNOPSIS

    use oEdtk::Tracking qw(stats_week);

    my $trk = oEdtk::Tracking->new($source, user => 'utest', entity => 'Corp');
    $trk->track('Job', 1, @values);
    $trk->end;

=head1 DESCRIPTION

Records tracking events (job, spool, document, warn, halt) for a batch run into
the table named by the C<EDTK_DB> configuration, and offers a few statistics
queries over that table. When C<EDTK_TRACK_MODE> is C<NONE> the constructor
returns an inert object and every method becomes a no-op. This is the current
module; C<Tracking2.pm> is the older, warn-based duplicate that declares the same
package C<oEdtk::Tracking>.

=head1 METHODS

=head2 new

    my $trk = oEdtk::Tracking->new($source, %params);

Build a tracker. C<$source> names the input, and C<%params> may carry C<user>,
C<entity>, C<keys>, C<edmode>, C<account>, C<obj_typ>, C<child_typ>,
C<child_id> and C<parent_id>. An omitted C<$source> falls back to C<@ARGV>; an
explicit empty string means no input file and is kept. Dies when there are too
many keys or a duplicate key.

=head2 track

    $trk->track($job, $count, @data);

Record one event: the job event, the number of objects, and the values of the
configured user keys (an optional trailing value is the message). Values longer
than the schema allows are truncated. When no message is supplied, C<ED_MESSAGE>
names the function that recorded the event.

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
C<_tracking_insert>, C<_tracking_schema_warn>, C<_validate_event> and
C<_validate_edmode>.

=head1 AUTHOR

The oEdtk team.

=cut
