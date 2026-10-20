#!/usr/bin/perl
#
# Non-regression tests for the two tracking fields filled from context:
#   - ED_SOURCE is empty when no input file is processed, and an explicit empty
#     source is not replaced by a command-line fallback;
#   - ED_MESSAGE names the function that recorded the row when no message is
#     supplied.
#
# The whole file is skipped when DBD::SQLite is not available. Tracking rows are
# written through the real track() method against an in-memory database; the
# constructor is exercised with its config and connection dependencies mocked.
#
use strict;
use warnings;
no warnings 'once';    # the localized symbols below are each assigned once
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use TestOEdtk qw(quiet_require reset_sig_handlers memory_dbh mute);

quiet_require('oEdtk::Tracking');
quiet_require('oEdtk::DBAdmin');
reset_sig_handlers();

my $dbh = memory_dbh();
plan skip_all => 'DBD::SQLite is not available' unless defined $dbh;

oEdtk::DBAdmin::create_table_TRACKING( $dbh, 'edtk_tracking', 0 );

# A tracker with no dependency beyond the given source and database handle.
sub _tracker {
	my ($source) = @_;
	return bless {
		dict      => bless( {}, 'oEdtk::Dict' ),
		mode      => 'SQLite',
		table     => 'edtk_tracking',
		edmode    => 'U',
		id        => 'TESTID',
		seq       => 1,
		keys      => [],
		user      => 'test',
		source    => $source,
		app       => 'test',
		entity    => 'TEST',
		account   => '',
		obj_typ   => '',
		child_typ => '',
		child_id  => '',
		parent_id => '',
		dbh       => $dbh,
		},
		'oEdtk::Tracking';
}

sub _latest {
	my ($job) = @_;
	return $dbh->selectrow_hashref(
'select ed_source, ed_message from edtk_tracking where ed_job_evt = ? order by rowid desc limit 1',
		undef, $job
	);
}

# The wrapper subs name the caller that _caller_name() must report.
sub _record_job  { my ($trk) = @_; return $trk->track( 'Job',      1 ); }
sub _record_warn { my ($trk) = @_; return $trk->track( 'Warn',     1, "  boom\n" ); }
sub _record_halt { my ($trk) = @_; return $trk->track( 'Halt',     1 ); }
sub _record_doc  { my ($trk) = @_; return $trk->track( 'Document', 1 ); }

# --- ED_SOURCE: the processed file, or empty --------------------------------
mute( sub { _record_job( _tracker('input.csv') ) } );
my $row = _latest('J');
is( $row->{ED_SOURCE},  'input.csv',         'ED_SOURCE names the input file' );
is( $row->{ED_MESSAGE}, 'main::_record_job', 'ED_MESSAGE names the recording function' );

mute( sub { _record_job( _tracker('') ) } );
$row = _latest('J');
is( $row->{ED_SOURCE}, '', 'an explicit empty source stays empty' );

# --- ED_MESSAGE: a supplied message is preserved -----------------------------
mute( sub { _record_warn( _tracker('input.csv') ) } );
$row = _latest('W');
is( $row->{ED_MESSAGE}, 'boom', 'a supplied message is normalized and kept' );

# --- ED_MESSAGE: no message names the function, for every event --------------
mute( sub { _record_halt( _tracker('input.csv') ) } );
$row = _latest('H');
is( $row->{ED_MESSAGE}, 'main::_record_halt', 'a Halt row names the recording function' );
is( $row->{ED_SOURCE},  'input.csv',          'a Halt row keeps the object source' );

mute( sub { _record_doc( _tracker('') ) } );
$row = _latest('D');
is( $row->{ED_MESSAGE}, 'main::_record_doc', 'a Document row names the recording function' );

# --- new(): an explicit empty source is not replaced by @ARGV ----------------
{
	local @ARGV                         = ( 'in.edtk', 'out.pdf' );
	local *oEdtk::Tracking::config_read = sub {
		return {
			EDTK_TRACK_MODE   => 'SQLite',
			EDTK_DBI_TRACKING => 'edtk_tracking',
			EDTK_MAX_USER_KEY => 0,
			EDTK_CORP         => 'TEST',
			EDTK_DICO         => 'unused',
		};
	};
	local *oEdtk::Tracking::db_connect = sub { return $dbh };
	local *oEdtk::Dict::new            = sub { return bless {}, 'oEdtk::Dict' };
	local *oEdtk::Dict::translate      = sub { return $_[1] };

	mute( sub { oEdtk::Tracking->new( '', user => 'test', entity => 'TEST', keys => [] ); } );
	$row = _latest('J');
	is( $row->{ED_SOURCE}, '', 'new() keeps an explicit empty source despite @ARGV' );

	mute( sub { oEdtk::Tracking->new( undef, user => 'test', entity => 'TEST', keys => [] ); } );
	$row = _latest('J');
	is( $row->{ED_SOURCE}, 'out.pdf', 'new() falls back to @ARGV only when the source is omitted' );
}

done_testing();
