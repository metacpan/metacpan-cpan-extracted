package Test::Permissions;

use strict;
use warnings;
use autodie qw(:all);

# Nothing is imported: every external function is called by its full name,
# so the only subroutines in this package are its own.
use Carp ();
use Cwd ();
use Errno ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use Params::Get ();
use Params::Validate::Strict ();
use Readonly ();
use Return::Set ();
use overload ();

# Exporter is inherited rather than imported, for the same reason.
require Exporter;
our @ISA = ('Exporter');	## no critic (ClassHierarchies::ProhibitExplicitISA)

=head1 NAME

Test::Permissions - Find out whether chmod can really take access away, so tests know when to skip

=head1 VERSION

0.001.2

=cut

our $VERSION = '0.001.2';

# One tag per family of functions.  A new family gets its own tag and
# prefix, and is added to :all.
our @EXPORT_OK = qw(
	can_revoke_read can_revoke_write can_revoke_create can_revoke_search
	can_revoke_exec can_revoke_delete can_revoke_sticky
	can_revoke why_not skip_unless_can_revoke
	acl_denies with_revoked permissions_report
	clear_cache set_cache_scope set_messages
);
our %EXPORT_TAGS = (
	all    => [ @EXPORT_OK ],
	revoke => [ qw(
		can_revoke_read can_revoke_write can_revoke_create can_revoke_search
		can_revoke_exec can_revoke_delete can_revoke_sticky
		can_revoke why_not skip_unless_can_revoke
	) ],
	acl    => [ qw(acl_denies) ],
	guard  => [ qw(with_revoked) ],
	report => [ qw(permissions_report) ],
);

# -----------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------

# Modes given to the scratch objects.  Every object gets an explicit mode
# after it is created, so the result never depends on the caller's umask.
Readonly::Scalar my $MODE_NONE       => 0;
Readonly::Scalar my $MODE_FILE_RW    => oct '0600';
Readonly::Scalar my $MODE_FILE_RO    => oct '0400';
Readonly::Scalar my $MODE_FILE_RWX   => oct '0700';
Readonly::Scalar my $MODE_DIR_RWX    => oct '0700';
Readonly::Scalar my $MODE_DIR_RX     => oct '0500';
Readonly::Scalar my $MODE_DIR_ALL    => oct '0777';
Readonly::Scalar my $MODE_DIR_STICKY => oct '01777';

# The permission bits of st_mode, and the owner's share of them.  The
# probe runs as the owner of its scratch objects, so only the owner bits
# decide whether access is allowed.  Comparing just those bits also copes
# with Windows, where perl reports a read-only file as 0444: chmod 0 there
# still gives owner bits 0400 (caught), and chmod 0400 gives owner bits
# 0400 (correct).  The sticky probe compares every bit, because the bit it
# is about is not an owner bit.
Readonly::Scalar my $MODE_BITS  => oct '07777';
Readonly::Scalar my $OWNER_BITS => oct '0700';
Readonly::Scalar my $ANY_EXEC   => oct '0111';

# Where the owner, group and other permission bits start in st_mode, and
# the bit for each access within them.
Readonly::Scalar my $OWNER_SHIFT => 6;
Readonly::Scalar my $GROUP_SHIFT => 3;
Readonly::Scalar my $OTHER_SHIFT => 0;
Readonly::Hash my %ACCESS_BIT => (read => 4, write => 2, exec => 1);

# Indexes into the list returned by stat.
Readonly::Scalar my $STAT_DEV  => 0;
Readonly::Scalar my $STAT_MODE => 2;
Readonly::Scalar my $STAT_UID  => 4;
Readonly::Scalar my $STAT_GID  => 5;

# The superuser.
Readonly::Scalar my $ROOT_UID => 0;

# The two users the sticky probe acts as: the owner of the file, and
# another user who tries to delete it.  They need not exist in the
# password file; 65534 is "nobody" on most systems.
Readonly::Scalar my $STICKY_OWNER_UID => 65_534;
Readonly::Scalar my $STICKY_OTHER_UID => 65_533;

# Names inside the probe directory P.
Readonly::Scalar my $PROBE_TEMPLATE => 'test-permissions-XXXXXXXX';
Readonly::Scalar my $PROBE_FILE     => 'f';
Readonly::Scalar my $PROBE_SUBDIR   => 'd';
Readonly::Scalar my $PROBE_NEW      => 'new';
Readonly::Scalar my $PROBE_CONTENT  => 'x';	# the one byte of a read probe
Readonly::Scalar my $PROBE_SCRIPT   => "#!/bin/sh\nexit 0\n";

# open() modes used by the probes.
Readonly::Scalar my $OPEN_READ     => '<';
Readonly::Scalar my $OPEN_APPEND   => '>>';
Readonly::Scalar my $OPEN_TRUNCATE => '>';

# The errnos that mean "permission denied".  Any other failure of the
# attempt says nothing about permissions.
Readonly::Hash my %DENIED_ERRNO => map { $_ => 1 } (Errno::EACCES(), Errno::EPERM());

# The errno reported when the exec probe's script runs but does not exit 0.
Readonly::Scalar my $ERRNO_BAD_EXIT => Errno::ENOEXEC();

# Environment variables removed while the exec probe runs its script:
# taint mode refuses to run anything while they are set, and they could
# change what /bin/sh does.
Readonly::Array my @UNSAFE_ENV => qw(PATH IFS CDPATH ENV BASH_ENV);

# Separates the parts of a cache key; cannot appear in a path.
Readonly::Scalar my $KEY_SEP => "\0";

# Control characters and Unicode bidirectional controls ("Trojan Source",
# CVE-2021-42574).  They are escaped in every path and error text placed
# in a message, so a hostile directory name cannot send escape sequences
# to the terminal or make a message display differently from its content.
Readonly::Scalar my $UNSAFE_CHARS_RE =>
	qr/[\x00-\x1F\x7F-\x9F\x{061C}\x{200E}\x{200F}\x{202A}-\x{202E}\x{2066}-\x{2069}]/;

# Characters that are unsafe in a byte string that is not valid UTF-8
# (C0 and C1 controls in Latin-1).
Readonly::Scalar my $UNSAFE_BYTES_RE => qr/[\x00-\x1F\x7F-\x9F]/;

# Matches any string, capturing all of it: used to untaint a path that has
# already been checked (see _untaint).
Readonly::Scalar my $ANYTHING_RE => qr/\A(.*)\z/s;

# How each kind of access is probed.  Every kind follows the same steps
# (see _probe); this table holds what differs:
#   precondition - optional; returns false if the probe cannot run here
#                  (reason_needs_root)
#   setup        - creates the scratch objects in P with explicit modes and
#                  returns { target => path to chmod, object => path to use,
#                  as => uid to act as (optional) }
#   op           - the operation; returns (ok, errno) and never throws
#   tidy         - optional; undoes a successful baseline so the attempt
#                  starts from the same state (runs under autodie)
#   permissive   - the mode of the target while the operation is allowed
#   restricted   - the mode that should forbid it
#   bits         - optional; which mode bits the check after chmod
#                  compares (default: the owner bits)
# The ops call the seams by name, so that tests can mock them.
Readonly::Hash my %PROBE => (
	read => {
		setup      => sub { _setup_file($_[0], $PROBE_CONTENT, $MODE_FILE_RW) },
		op         => sub { _try_open($_[0]{object}, $OPEN_READ) },
		permissive => $MODE_FILE_RW,
		restricted => $MODE_NONE,
	},
	write => {
		setup      => sub { _setup_file($_[0], $PROBE_CONTENT, $MODE_FILE_RW) },
		op         => sub { _try_open($_[0]{object}, $OPEN_APPEND) },
		permissive => $MODE_FILE_RW,
		restricted => $MODE_FILE_RO,
	},
	create => {
		setup      => sub { _setup_subdir($_[0], 0) },
		op         => sub { _try_open($_[0]{object}, $OPEN_TRUNCATE) },
		tidy       => sub { unlink $_[0]{object} },
		permissive => $MODE_DIR_RWX,
		restricted => $MODE_DIR_RX,
	},
	search => {
		setup      => sub { _setup_subdir($_[0], 1) },
		op         => sub { _try_stat($_[0]{object}) },
		permissive => $MODE_DIR_RWX,
		restricted => $MODE_NONE,
	},
	exec => {
		setup      => sub { _setup_file($_[0], $PROBE_SCRIPT, $MODE_FILE_RWX) },
		op         => sub { _try_exec($_[0]{object}) },
		permissive => $MODE_FILE_RWX,
		restricted => $MODE_FILE_RW,
	},
	delete => {
		setup      => sub { _setup_subdir($_[0], 1) },
		op         => sub { _try_unlink($_[0]{object}) },
		tidy       => sub { _make_file($_[0]{object}, q{}); _set_mode($_[0]{object}, $MODE_FILE_RW) },
		permissive => $MODE_DIR_RWX,
		restricted => $MODE_DIR_RX,
	},
	sticky => {
		precondition => sub { _can_switch_uid() },
		setup        => sub { _setup_sticky($_[0]) },
		op           => sub { _try_unlink($_[0]{object}, $_[0]{as}) },
		tidy         => sub { _make_file($_[0]{object}, q{}); _give_away($_[0]{object}, $STICKY_OWNER_UID) },
		permissive   => $MODE_DIR_ALL,
		restricted   => $MODE_DIR_STICKY,
		bits         => $MODE_BITS,
	},
);

# The kinds, in the order they are listed in messages and reports.
Readonly::Array my @KINDS => qw(read write create search exec delete sticky);

# The kinds acl_denies() and with_revoked() accept.  with_revoked() leaves
# out sticky: setting the sticky bit does not take the owner's access away.
Readonly::Array my @ACL_KINDS   => qw(read write exec);
Readonly::Array my @GUARD_KINDS => qw(read write create search exec delete);

# The kinds whose restricted mode applies to a file; the others apply to a
# directory.
Readonly::Hash my %FILE_KIND => map { $_ => 1 } qw(read write exec);

# How answers are shared between directories (set_cache_scope).
Readonly::Array my @CACHE_SCOPES => qw(directory device);
Readonly::Scalar my $DEFAULT_SCOPE => 'directory';

# Input schemas (Params::Validate::Strict), as documented in the POD.
# 'position' gives the order of positional arguments.
Readonly::Hash my %INPUT_SCHEMA => (
	dir => {
		dir => { type => 'string', optional => 1, min => 1, position => 0 },
	},
	kind_dir => {
		kind => { type => 'string', memberof => [ @KINDS ], position => 0 },
		dir  => { type => 'string', optional => 1, min => 1, position => 1 },
	},
	kind_count_dir => {
		kind  => { type => 'string', memberof => [ @KINDS ], position => 0 },
		count => { type => 'integer', min => 1, position => 1 },
		dir   => { type => 'string', optional => 1, min => 1, position => 2 },
	},
	acl => {
		kind => { type => 'string', memberof => [ @ACL_KINDS ], position => 0 },
		path => { type => 'string', min => 1, position => 1 },
	},
	guard => {
		kind => { type => 'string', memberof => [ @GUARD_KINDS ], position => 0 },
		path => { type => 'string', min => 1, position => 1 },
		code => { type => 'coderef', position => 2 },
	},
	scope => {
		scope => { type => 'string', memberof => [ @CACHE_SCOPES ], position => 0 },
	},
);

# Output schemas (Return::Set).
Readonly::Hash my %OUTPUT_SCHEMA => (
	answer => { type => 'boolean' },
	reason => { type => 'string', optional => 1 },
	report => { type => 'string', min => 1 },
	void   => { type => 'void' },
);

# Every user-facing text, as sprintf formats.  set_messages() overrides
# them by key; see MESSAGES in the POD.
Readonly::Hash my %MESSAGES => (
	error_unknown_kind       => q{Unknown access kind '%s'; expected one of: %s},
	error_not_a_directory    => q{'%s' is not a directory},
	error_not_a_file         => q{'%s' is a directory; %s access is revoked on a file},
	error_no_such_path       => q{'%s' does not exist},
	error_unknown_message    => q{Unknown message key '%s'},
	error_too_many_arguments => q{Too many arguments: expected at most %d, got %d},
	error_chmod_failed       => q{Could not chmod '%s' to %04o: %s},
	error_restore_failed     => q{Could not restore mode %04o on '%s': %s},
	reason_not_enforced      => q{chmod cannot revoke %s access in '%s' (running as root, or the filesystem ignores permissions)},
	reason_chmod_ignored     => q{chmod did not set mode %04o in '%s' (got %04o)},
	reason_baseline_failed   => q{%s access fails in '%s' even when it is allowed: %s},
	reason_other_error       => q{%s access in '%s' failed for a reason other than permissions: %s},
	reason_setup_failed      => q{Could not set up the %s probe in '%s': %s},
	reason_cleanup_failed    => q{%s; also could not clean up '%s': %s},
	reason_probe_succeeded   => q{chmod revoked %s access in '%s'},
	reason_needs_root        => q{The %s probe in '%s' must act as two users, which needs root (not Windows)},
	report_header            => q{Test::Permissions %s in '%s' (effective uid %s):},
	report_yes               => q{  %s: yes},
	report_no                => q{  %s: no - %s},
);

# -----------------------------------------------------------------------
# Package state
# -----------------------------------------------------------------------

# Answers already found:
#   "kind\0euid\0egids\0scope key" => [ answer, reason ].
my %cache;

# How answers are shared between directories: 'directory' or 'device'.
my $cache_scope = $DEFAULT_SCOPE;

# Message texts set by set_messages(), by key.
my %message_override;

=head1 SYNOPSIS

	use Test::Most;
	use File::Temp qw(tempdir);
	use Test::Permissions qw(:revoke :guard :report);

	my $dir = tempdir(CLEANUP => 1);	# where the fixtures live
	diag(permissions_report($dir));	# once, for CPAN Testers reports

	SKIP: {
		skip why_not('read', $dir), 1 unless can_revoke_read($dir);

		with_revoked(read => "$dir/fixture", sub {
			ok(!open(my $fh, '<', "$dir/fixture"), 'unreadable file is refused');
		});	# the mode is restored, even if the block dies
	}

	SKIP: {
		skip_unless_can_revoke('search', 1, $dir);
		...
	}

	done_testing();

=head1 DESCRIPTION

Test suites often need to know whether C<chmod> really takes access away,
so they can skip tests that rely on an unreadable file or an unsearchable
directory.  The usual guess, C<skip ... if $E<gt> == 0>, is wrong on:

=over 4

=item * Windows, where C<chmod> only sets the read-only attribute;

=item * C<fakeroot>, and containers where a non-root user holds
C<CAP_DAC_OVERRIDE>;

=item * filesystems that ignore mode bits (FAT, some SMB/NFS/FUSE mounts,
Cygwin C<noacl> mounts);

=item * root in a user namespace, where root may I<not> be able to bypass
modes;

=item * root on an NFS export with C<root_squash>, where root is treated
as "nobody".

=back

Test::Permissions does not guess.  It tries the operation on a scratch
file in the directory you care about, and reports what actually happened.
Results are cached per process.

Seven kinds of access can be probed:

	Kind     Question                                          Restricted mode
	read     can a file be made unreadable?                    file 0
	write    can a file be made unwritable?                    file 0400
	create   can a directory be made to refuse new files?      directory 0500
	search   can a directory be made unsearchable (stat of a   directory 0
	         file inside it fails)?
	exec     can a script be made unrunnable?                  file 0600
	delete   can a directory be made to keep its files?        directory 0500
	sticky   does the sticky bit stop one user deleting        directory 01777
	         another user's file?

What to expect (your tests must not rely on these; that is the point):

	Environment                        read write create search exec delete sticky
	Linux/BSD/macOS, normal user        1    1     1      1      1    1      0 (a)
	Unix root, or CAP_DAC_OVERRIDE      0    0     0      0      1(b) 0      1
	fakeroot                            0    0     0      0      1(b) 0      0
	Windows (NTFS)                      0    1     0 (c)  0      0    0 (c)  0
	FAT or a mount that ignores modes   0    0     0      0      0    0      0
	a noexec mount                      .    .     .      .      0    .      .

	(a) the sticky probe must act as two users, so it needs root
	(b) even root cannot run a file that has no execute bit at all
	(c) Windows ignores the read-only attribute on directories

=head2 Which directory to probe

The answer depends on the filesystem, so pass the directory your fixtures
live in (usually your own C<tempdir>).  If you pass nothing, the probe
runs in C<< File::Spec->tmpdir >>, which may be on a different filesystem
from your fixtures (a C<tmpfs>, for example) and give a different answer.

=head2 How a probe works

Each probe creates a fresh directory C<P> inside the target directory and
then:

=over 4

=item 1. B<Setup>: creates the scratch objects with explicit modes, so the
answer does not depend on your C<umask>.

=item 2. B<Baseline>: does the operation while it is allowed.  If that
fails, the filesystem cannot tell us anything, and the answer is 0.

=item 3. B<Restrict>: C<chmod>s to the restricted mode and checks, with
C<stat>, that the owner's permission bits (for C<sticky>: all the mode
bits) really changed.  If not (this is what happens on Windows), the
answer is 0.

=item 4. B<Attempt>: does the operation again.  It must fail with
C<EACCES> or C<EPERM> for the answer to be 1.

=item 5. B<Restore and clean up>: always, even if an earlier step failed.
Nothing is left in the target directory.

=back

A probe never dies and never warns: anything that goes wrong becomes an
answer of 0, and L</why_not(kind, dir)> tells you why.  Only mistakes in
the call itself (an unknown kind, a directory that does not exist) croak.

=head2 Paths with non-ASCII characters

Directory and file names are used exactly as perl's own file functions
use them: as byte strings.  On Unix, pass the same (usually UTF-8
encoded) bytes you would pass to C<open>.  On Windows, perl's file
functions use the ANSI code page, so a name with characters outside it
cannot be found, and the call croaks with C<error_not_a_directory> or
C<error_no_such_path>.  Names in messages are shown as they are, except
that control and bidirectional-override characters are escaped.

=head2 Taint mode

The functions work under C<perl -T>.  The directory you pass is checked
with C<-d>, and its canonical path is then untainted, because the probe
only creates its own scratch directory inside it.  C<with_revoked>
likewise untaints the path you give it, because changing its mode is what
you asked for.  The C<exec> probe runs its script with C<PATH>, C<IFS>,
C<CDPATH>, C<ENV> and C<BASH_ENV> removed from the environment.

=head1 SUBROUTINES/METHODS

Nothing is exported by default.  Import what you need by name, or use a
tag:

	:revoke   can_revoke_* , can_revoke, why_not, skip_unless_can_revoke
	:acl      acl_denies
	:guard    with_revoked
	:report   permissions_report
	:all      all of these, plus clear_cache, set_cache_scope, set_messages

Every function that takes C<dir> accepts it in any of these forms:

	f()                  # dir is File::Spec->tmpdir
	f($dir)
	f(dir => $dir)
	f({ dir => $dir })

An object that stringifies (such as a L<Path::Tiny> object) is accepted
wherever a directory or path name is.

=head2 can_revoke_read(dir)

=head3 PURPOSE

Find out whether a file with mode 0 refuses C<< open '<' >>: that is,
whether C<chmod> can make a file unreadable in C<dir>.  The same as
C<can_revoke('read', $dir)>.

=head3 ARGUMENTS

=over 4

=item * C<dir> - optional.  The directory to probe in.  It must exist
and be a directory.  Default: C<< File::Spec->tmpdir >>.

=back

=head3 RETURNS

1 if C<chmod> can take that access away in C<dir>, otherwise 0.  Never
undef.

=head3 SIDE EFFECTS

=over 4

=item * The first call for a kind and directory creates and removes a
probe directory inside C<dir>.  Later calls use the cache and do not touch
the filesystem.

=item * Never dies or warns because of what it finds; see
L</FAILURE POLICY>.

=item * Does not change the caller's C<$@>, C<$!> or C<umask>.

=back

=head3 USAGE EXAMPLE

	SKIP: {
		skip 'chmod cannot make a file unreadable here', 1
			unless Test::Permissions::can_revoke_read($dir);
		...
	}

=head3 API SPECIFICATION

=head4 Input

	{
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 0,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

Errors (the call dies):

	'$dir' is not a directory                     (error_not_a_directory)
	    dir does not exist, or is not a directory.
	    What to do: pass the directory your fixtures live in.

	Too many arguments: expected at most 1, got N (error_too_many_arguments)
	    More than one positional argument was given.
	    What to do: pass only the directory.

	(an error from Params::Validate::Strict or Params::Get)
	    dir is not a string (for example an array reference), is empty,
	    or the named form has an unknown key.

The reason for a 0 answer is available from L</why_not(kind, dir)>, which
lists every C<reason_*> message.

=cut

sub can_revoke_read { return _revoke_wrapper('read', \@_) }

=head2 can_revoke_write(dir)

=head3 PURPOSE

Find out whether a file with mode 0400 refuses C<<< open '>>' >>>: that
is, whether C<chmod> can make a file unwritable in C<dir>.  The same as
C<can_revoke('write', $dir)>.

=head3 ARGUMENTS

=over 4

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

=head3 RETURNS

1 or 0, never undef.

=head3 SIDE EFFECTS

As for L</can_revoke_read(dir)>.

=head3 USAGE EXAMPLE

	SKIP: {
		skip 'chmod cannot make a file read-only here', 1
			unless Test::Permissions::can_revoke_write($dir);
		chmod 0400, $file;
		ok(!open(my $fh, '>>', $file), 'read-only file is refused');
		chmod 0600, $file;
	}

=head3 API SPECIFICATION

=head4 Input

	{
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 0,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

The same as L</can_revoke_read(dir)>.

=cut

sub can_revoke_write { return _revoke_wrapper('write', \@_) }

=head2 can_revoke_create(dir)

=head3 PURPOSE

Find out whether a directory with mode 0500 refuses C<< open '>' >> of a
new file in it: that is, whether C<chmod> can stop files being created
in a directory in C<dir>.  The same as C<can_revoke('create', $dir)>.

Note: in App-makefilepl2cpanfile's private copy of this module, this
question was called C<can_revoke_write>.  L</can_revoke_write(dir)> now
asks about a file's own write bit.

On Windows the answer is 0 with C<reason_not_enforced>: Windows ignores
the read-only attribute on directories.

=head3 ARGUMENTS

=over 4

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

=head3 RETURNS

1 or 0, never undef.

=head3 SIDE EFFECTS

As for L</can_revoke_read(dir)>.

=head3 USAGE EXAMPLE

	SKIP: {
		skip Test::Permissions::why_not('create', $dir), 1
			unless Test::Permissions::can_revoke_create($dir);
		chmod 0500, $outdir;
		ok(!eval { write_report($outdir) }, 'cannot write the report');
		chmod 0700, $outdir;
	}

=head3 API SPECIFICATION

=head4 Input

	{
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 0,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

The same as L</can_revoke_read(dir)>.

=cut

sub can_revoke_create { return _revoke_wrapper('create', \@_) }

=head2 can_revoke_search(dir)

=head3 PURPOSE

Find out whether a directory with mode 0 makes C<stat> of a file inside
it fail: that is, whether C<chmod> can make a directory in C<dir>
unsearchable.  The same as C<can_revoke('search', $dir)>.

=head3 ARGUMENTS

=over 4

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

=head3 RETURNS

1 or 0, never undef.

=head3 SIDE EFFECTS

As for L</can_revoke_read(dir)>.

=head3 USAGE EXAMPLE

	SKIP: {
		skip 'chmod cannot hide a directory here', 1
			unless Test::Permissions::can_revoke_search($dir);
		chmod 0, $subdir;
		ok(!-e "$subdir/file", 'file inside is hidden');
		chmod 0700, $subdir;
	}

=head3 API SPECIFICATION

=head4 Input

	{
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 0,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

The same as L</can_revoke_read(dir)>.

=cut

sub can_revoke_search { return _revoke_wrapper('search', \@_) }

=head2 can_revoke_exec(dir)

=head3 PURPOSE

Find out whether a script with mode 0600 refuses to run: that is, whether
C<chmod> can take away the execute bit in C<dir>.  The probe runs a
two-line C</bin/sh> script with C<system>, so it needs C</bin/sh>, and a
filesystem not mounted C<noexec>.  The same as C<can_revoke('exec', $dir)>.

Unlike the other kinds, the answer is usually 1 even for root: root can
run a file only if at least one of its execute bits is set.

=head3 ARGUMENTS

=over 4

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

=head3 RETURNS

1 or 0, never undef.

=head3 SIDE EFFECTS

As for L</can_revoke_read(dir)>; also starts two short-lived processes.

=head3 USAGE EXAMPLE

	SKIP: {
		skip Test::Permissions::why_not('exec', $dir), 1
			unless Test::Permissions::can_revoke_exec($dir);
		chmod 0600, $hook;
		ok(!run_hook($hook), 'a hook without the execute bit is not run');
	}

=head3 API SPECIFICATION

=head4 Input

	{
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 0,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

The same as L</can_revoke_read(dir)>.  On a C<noexec> mount, or without
C</bin/sh>, the reason is C<reason_baseline_failed>.

=cut

sub can_revoke_exec { return _revoke_wrapper('exec', \@_) }

=head2 can_revoke_delete(dir)

=head3 PURPOSE

Find out whether a directory with mode 0500 refuses C<unlink> of a file
in it: that is, whether C<chmod> can stop files being deleted from a
directory in C<dir>.  The same as C<can_revoke('delete', $dir)>.

=head3 ARGUMENTS

=over 4

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

=head3 RETURNS

1 or 0, never undef.

=head3 SIDE EFFECTS

As for L</can_revoke_read(dir)>.

=head3 USAGE EXAMPLE

	SKIP: {
		skip Test::Permissions::why_not('delete', $dir), 1
			unless Test::Permissions::can_revoke_delete($dir);
		chmod 0500, $spool;
		ok(!eval { purge($spool) }, 'purge reports the failure');
		chmod 0700, $spool;
	}

=head3 API SPECIFICATION

=head4 Input

	{
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 0,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

The same as L</can_revoke_read(dir)>.

=cut

sub can_revoke_delete { return _revoke_wrapper('delete', \@_) }

=head2 can_revoke_sticky(dir)

=head3 PURPOSE

Find out whether the sticky bit works in C<dir>: in a directory with mode
01777, can one user be stopped from deleting another user's file?  The
same as C<can_revoke('sticky', $dir)>.

This needs two users, so the probe only runs as root (real and effective
uid 0), and not on Windows.  It gives its file to uid 65534 and tries to
delete it as uid 65533, by setting C<< $> >> for the moment of the
C<unlink>.  Anywhere else the answer is 0 with C<reason_needs_root>.

=head3 ARGUMENTS

=over 4

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

=head3 RETURNS

1 or 0, never undef.

=head3 SIDE EFFECTS

As for L</can_revoke_read(dir)>.  While it runs, the process briefly
changes its effective uid and its working directory; both are restored
before it returns.

=head3 USAGE EXAMPLE

	SKIP: {
		skip Test::Permissions::why_not('sticky', $dir), 1
			unless Test::Permissions::can_revoke_sticky($dir);
		...
	}

=head3 API SPECIFICATION

=head4 Input

	{
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 0,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

The same as L</can_revoke_read(dir)>.  When not running as root, the
reason is C<reason_needs_root>.

=cut

sub can_revoke_sticky { return _revoke_wrapper('sticky', \@_) }

# _revoke_wrapper
#
# Purpose:  The shared body of the can_revoke_<kind> functions.
# Entry:    $kind - a kind from @KINDS; $args - arrayref of the caller's @_.
# Exit:     1 or 0.  Croaks (from the caller's line) on bad arguments.
sub _revoke_wrapper {
	my ($kind, $args) = @_;

	my ($params, $error) = _check_args('dir', $args);
	Carp::croak($error) if defined $error;

	return _set_return(_answer($kind, $params->{dir})->[0], 'answer');
}

=head2 can_revoke(kind, dir)

=head3 PURPOSE

The general form of the C<can_revoke_*> functions: answer the question
for the kind of access named by C<kind>.

=head3 ARGUMENTS

=over 4

=item * C<kind> - required.  One of C<read>, C<write>, C<create>,
C<search>, C<exec>, C<delete> or C<sticky>.

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

Positional (C<can_revoke('read', $dir)>), named
(C<< can_revoke(kind => 'read', dir => $dir) >>) and hash reference
(C<< can_revoke({ kind => 'read' }) >>) forms are all accepted.

=head3 RETURNS

1 or 0, never undef.

=head3 SIDE EFFECTS

As for L</can_revoke_read(dir)>.

=head3 USAGE EXAMPLE

	for my $kind (qw(read search)) {
		SKIP: {
			skip "cannot revoke $kind access", 1
				unless Test::Permissions::can_revoke($kind, $dir);
			...
		}
	}

=head3 API SPECIFICATION

=head4 Input

	{
		kind => {
			type     => 'string',
			memberof => [ 'read', 'write', 'create', 'search', 'exec', 'delete', 'sticky' ],
			position => 0,
		},
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 1,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

Errors (the call dies):

	Unknown access kind '$kind'; expected one of: read, write, create,
	search, exec, delete, sticky                  (error_unknown_kind)
	    What to do: use one of the listed kinds.

	'$dir' is not a directory                     (error_not_a_directory)
	    What to do: pass an existing directory.

	Too many arguments: expected at most 2, got N (error_too_many_arguments)

	(an error from Params::Validate::Strict or Params::Get)
	    kind is missing or not a string, dir is not a string or is empty,
	    or the named form has an unknown key.

=cut

sub can_revoke {
	my ($params, $error) = _check_args('kind_dir', \@_);
	Carp::croak($error) if defined $error;

	return _set_return(_answer($params->{kind}, $params->{dir})->[0], 'answer');
}

=head2 why_not(kind, dir)

=head3 PURPOSE

Say why the answer for C<kind> in C<dir> is 0, in words suitable for a
skip message.

=head3 ARGUMENTS

The same as L</can_revoke(kind, dir)>.

=head3 RETURNS

undef when the answer is 1.  Otherwise a non-empty string: one of the
C<reason_*> messages below.

=head3 SIDE EFFECTS

Runs the probe if it has not run yet for this kind and directory, exactly
as L</can_revoke(kind, dir)> would, and caches the result.

=head3 USAGE EXAMPLE

	SKIP: {
		my $why = Test::Permissions::why_not('search', $dir);
		skip $why, 2 if defined $why;
		...
	}

=head3 API SPECIFICATION

=head4 Input

	{
		kind => {
			type     => 'string',
			memberof => [ 'read', 'write', 'create', 'search', 'exec', 'delete', 'sticky' ],
			position => 0,
		},
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 1,
		},
	}

=head4 Output

	{ type => 'string', optional => 1 }

=head3 MESSAGES

Errors: the same as L</can_revoke(kind, dir)>.

Reasons (returned, never thrown or warned).  C<$dir> is the canonical
path of the directory; C<$error> is the system's error text, in the
current locale (so a reason may mix these English texts, or your own from
L</set_messages(%overrides)>, with another language).

	chmod cannot revoke $kind access in '$dir' (running as root, or the
	filesystem ignores permissions)               (reason_not_enforced)
	    The operation still worked after chmod.  You are root, hold
	    CAP_DAC_OVERRIDE, run under fakeroot, or the filesystem ignores
	    modes.  On Windows, create and delete give this reason because
	    Windows ignores the read-only attribute on directories.
	    What to do: nothing; skip the test.  To run it, run the suite as
	    an ordinary user on a filesystem that honours modes.

	chmod did not set mode $wanted in '$dir' (got $got)
	                                              (reason_chmod_ignored)
	    chmod "worked" but the permission bits did not change.  This is
	    Windows, or a FAT or noacl mount.
	    What to do: nothing; skip the test.

	$kind access fails in '$dir' even when it is allowed: $error
	                                              (reason_baseline_failed)
	    The operation failed before any permission was removed, so the
	    probe learnt nothing.  The filesystem may be read-only or broken;
	    for exec, it may be mounted noexec, or /bin/sh may be missing.
	    What to do: check the directory and the filesystem.

	$kind access in '$dir' failed for a reason other than permissions: $error
	                                              (reason_other_error)
	    After chmod the operation failed, but not with EACCES or EPERM
	    (for example ENOSPC).
	    What to do: check the error; the directory may be full or odd.

	Could not set up the $kind probe in '$dir': $error
	                                              (reason_setup_failed)
	    The probe could not create its scratch files, usually because you
	    cannot write to dir.
	    What to do: pass a directory you can write to.

	The sticky probe in '$dir' must act as two users, which needs root
	(not Windows)                                 (reason_needs_root)
	    Only the sticky probe gives this reason.
	    What to do: nothing; run the suite as root to probe it.

	$reason; also could not clean up '$probe_dir': $error
	                                              (reason_cleanup_failed)
	    Restoring the modes or removing the probe directory failed, so
	    the answer is 0 whatever the probe found.  $reason is one of the
	    reasons above, or, if the probe itself succeeded, the text of
	    reason_probe_succeeded:

	chmod revoked $kind access in '$dir'          (reason_probe_succeeded)
	    Only ever seen as the first part of reason_cleanup_failed.
	    What to do: remove $probe_dir by hand; it is also removed when
	    the process exits.

Paths and error texts in reasons have control characters and Unicode
direction-override characters replaced by C<\x{..}> escapes.

=cut

sub why_not {
	my ($params, $error) = _check_args('kind_dir', \@_);
	Carp::croak($error) if defined $error;

	my $entry = _answer($params->{kind}, $params->{dir});
	return _set_return($entry->[0] ? undef : $entry->[1], 'reason');
}

=head2 skip_unless_can_revoke(kind, count, dir)

=head3 PURPOSE

Skip the rest of the enclosing C<SKIP:> block, with the reason from
L</why_not(kind, dir)>, when C<chmod> cannot revoke C<kind> access.

=head3 ARGUMENTS

=over 4

=item * C<kind> - required.  As for L</can_revoke(kind, dir)>.

=item * C<count> - required.  The number of tests in the block, as for
C<Test::More::skip>.  A whole number, 1 or more.

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

=head3 RETURNS

Nothing, when the answer is 1.  When the answer is 0 it does not return:
it records C<count> skipped tests and leaves the enclosing C<SKIP:> block,
exactly as a direct C<skip> call would.

=head3 SIDE EFFECTS

=over 4

=item * Runs the probe, as L</can_revoke(kind, dir)> does.

=item * When the answer is 0, records C<count> skipped tests.  With
L<Test::More> (or anything else that loads L<Test::Builder>) it calls
C<Test::More::skip>.  In a L<Test2::V0> suite, which does not load
Test::Builder, it records the skips through L<Test2::API> instead.

=item * Must be called inside a C<SKIP:> block, like C<Test::More::skip>.
Outside one, perl dies with C<Label not found for "last SKIP">.

=back

=head3 USAGE EXAMPLE

	SKIP: {
		Test::Permissions::skip_unless_can_revoke('search', 2, $dir);
		chmod 0, $subdir;
		ok(!-e "$subdir/file", 'file hidden');
		ok(!opendir(my $dh, $subdir), 'directory unreadable');
		chmod 0700, $subdir;
	}

=head3 API SPECIFICATION

=head4 Input

	{
		kind => {
			type     => 'string',
			memberof => [ 'read', 'write', 'create', 'search', 'exec', 'delete', 'sticky' ],
			position => 0,
		},
		count => {
			type     => 'integer',
			min      => 1,
			position => 1,
		},
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 2,
		},
	}

=head4 Output

	{ type => 'void' }

Returns nothing (an empty list) when the answer is 1.

=head3 MESSAGES

Errors: the same as L</can_revoke(kind, dir)>, plus an error from
Params::Validate::Strict when C<count> is missing, not a whole number, or
less than 1.

The skip message is one of the reasons listed under
L</why_not(kind, dir)>.

=cut

sub skip_unless_can_revoke {
	my ($params, $error) = _check_args('kind_count_dir', \@_);
	Carp::croak($error) if defined $error;

	my $entry = _answer($params->{kind}, $params->{dir});
	if($entry->[0]) {
		_set_return(undef, 'void');
		return;
	}

	# A Test2::V0 suite has Test2::API but not Test::Builder; loading
	# Test::More there would work, but is not what the suite asked for.
	if($INC{'Test2/API.pm'} && !$INC{'Test/Builder.pm'}) {
		my $context = Test2::API::context();
		$context->skip(q{}, $entry->[1]) for 1 .. $params->{count};
		$context->release();
		no warnings 'exiting';	## no critic (TestingAndDebugging::ProhibitNoWarnings)
		last SKIP;	## no critic (ControlStructures::ProhibitLastInSubroutine)
	}

	# Loaded here, not at compile time, so that code which never skips does
	# not load Test::Builder.  skip() leaves the SKIP block with 'last SKIP',
	# which unwinds through this sub.
	require Test::More;
	Test::More::skip($entry->[1], $params->{count});
	return;	# not reached inside a SKIP block
}

=head2 acl_denies(kind, path)

=head3 PURPOSE

Find out whether something other than the mode bits - usually an access
control list - denies you C<kind> access to an existing C<path>, even
though its mode bits allow it.  Use it to skip or explain a test that
fails because of a fixture's ACL, not its mode.

It compares what the mode bits say (for your effective uid and groups)
with what the system says, using C<access(2)> (perl's C<-r>, C<-w> and
C<-x> under C<use filetest 'access'>), which takes ACLs into account.  It
does not open, change or run C<path>.

=head3 ARGUMENTS

=over 4

=item * C<kind> - required.  C<read>, C<write> or C<exec> (for a
directory, C<exec> means search).

=item * C<path> - required.  An existing file or directory.

=back

=head3 RETURNS

1 if the mode bits allow the access but the system denies it, otherwise 0
(including when the mode bits themselves deny it).

=head3 SIDE EFFECTS

None.  It is not cached: each call looks at C<path> again.

Besides ACLs, a read-only mount, an immutable flag or a mandatory access
control policy (SELinux, AppArmor) can also make it return 1.  On Windows,
perl's file tests do not consult ACLs, so it returns 0.

=head3 USAGE EXAMPLE

	SKIP: {
		skip "an ACL denies reading $fixture", 1
			if Test::Permissions::acl_denies(read => $fixture);
		ok(load($fixture), 'fixture loads');
	}

=head3 API SPECIFICATION

=head4 Input

	{
		kind => {
			type     => 'string',
			memberof => [ 'read', 'write', 'exec' ],
			position => 0,
		},
		path => {
			type     => 'string',
			min      => 1,
			position => 1,
		},
	}

=head4 Output

	{ type => 'boolean' }

=head3 MESSAGES

Errors (the call dies):

	Unknown access kind '$kind'; expected one of: read, write, exec
	                                              (error_unknown_kind)

	'$path' does not exist                        (error_no_such_path)
	    What to do: pass an existing file or directory.

	Too many arguments: expected at most 2, got N (error_too_many_arguments)

	(an error from Params::Validate::Strict or Params::Get)

=cut

sub acl_denies {
	my ($params, $error) = _check_args('acl', \@_);
	Carp::croak($error) if defined $error;

	local $!;
	my @stat = stat $params->{path};
	my $allowed = _mode_allows($params->{kind}, \@stat, -d _);
	my $denied = $allowed && !_access($params->{kind}, $params->{path}) ? 1 : 0;
	return _set_return($denied, 'answer');
}

=head2 with_revoked(kind, path, code)

=head3 PURPOSE

Take C<kind> access away from C<path>, run C<code>, and put the mode back
- always, even if C<code> dies.  It uses the same restricted modes as the
probes, so a test written as

	SKIP: {
		skip_unless_can_revoke('read', 1, $dir);
		with_revoked(read => $file, sub { ok(!load($file), 'refused') });
	}

cannot leave an unreadable file behind for the next test, or for
C<File::Temp>'s cleanup.

=head3 ARGUMENTS

=over 4

=item * C<kind> - required.  C<read> (mode 0), C<write> (0400) or
C<exec> (0600), which apply to a file; or C<create> (0500), C<search>
(0) or C<delete> (0500), which apply to a directory.

=item * C<path> - required.  An existing file (for read, write, exec) or
directory (for create, search, delete).

=item * C<code> - required.  A code reference, called with no arguments.

=back

=head3 RETURNS

Whatever C<code> returns, in the same (list, scalar or void) context.  If
C<code> dies, the mode is restored and the exception is passed on
unchanged.

=head3 SIDE EFFECTS

=over 4

=item * Changes the mode of C<path> while C<code> runs, then restores the
mode it had before.

=item * Does not check that C<chmod> really takes the access away: use
L</can_revoke(kind, dir)> (or C<skip_unless_can_revoke>) first.

=item * Under taint mode, C<path> is untainted; see L</Taint mode>.

=back

=head3 USAGE EXAMPLE

	my $content = Test::Permissions::with_revoked(search => $dir, sub {
		return eval { read_config("$dir/app.conf") };
	});
	ok(!defined $content, 'config in an unsearchable directory is not read');

=head3 API SPECIFICATION

=head4 Input

	{
		kind => {
			type     => 'string',
			memberof => [ 'read', 'write', 'create', 'search', 'exec', 'delete' ],
			position => 0,
		},
		path => {
			type     => 'string',
			min      => 1,
			position => 1,
		},
		code => {
			type     => 'coderef',
			position => 2,
		},
	}

=head4 Output

Whatever C<code> returns; it is not checked.

=head3 MESSAGES

Errors (the call dies):

	Unknown access kind '$kind'; expected one of: read, write, create,
	search, exec, delete                          (error_unknown_kind)
	    sticky is not accepted: it does not take the owner's access away.

	'$path' does not exist                        (error_no_such_path)

	'$path' is not a directory                    (error_not_a_directory)
	    create, search and delete apply to a directory.

	'$path' is a directory; $kind access is revoked on a file
	                                              (error_not_a_file)
	    read, write and exec apply to a file.

	Could not chmod '$path' to $mode: $error      (error_chmod_failed)
	    code was not run.
	    What to do: check that you own path.

	Could not restore mode $mode on '$path': $error
	                                              (error_restore_failed)
	    code ran (and any exception it threw is lost), but the old mode
	    could not be put back.
	    What to do: fix the mode by hand.

	(an error from Params::Validate::Strict or Params::Get)
	    For example, code is not a code reference.

	(anything code dies with, unchanged)

=cut

sub with_revoked {
	my ($params, $error) = _check_args('guard', \@_);
	Carp::croak($error) if defined $error;

	my ($kind, $code) = @{$params}{qw(kind code)};
	my $path = _untaint($params->{path});
	my $shown = _printable($path);

	if($FILE_KIND{$kind}) {
		Carp::croak(_msg('error_not_a_file', $shown, $kind)) if -d $path;
	} else {
		Carp::croak(_msg('error_not_a_directory', $shown)) unless -d $path;
	}

	my ($old_mode, $restricted) = (_mode_of($path), $PROBE{$kind}{restricted});
	$error = _chmod_error($path, $restricted);
	Carp::croak(_msg('error_chmod_failed', $shown, $restricted, $error)) if defined $error;

	# Run the code in the caller's context.  $@ is localised only around
	# the eval, so that the exception can be rethrown outside it (on
	# perl < 5.14 a die inside a 'local $@' scope loses the exception).
	my $want = wantarray;
	my (@result, $ok, $exception);
	{
		local $@;
		$ok = eval {
			if($want) {
				@result = $code->();
			} elsif(defined $want) {
				$result[0] = $code->();
			} else {
				$code->();
			}
			1;
		};
		$exception = $@;
	}

	$error = _chmod_error($path, $old_mode);
	Carp::croak(_msg('error_restore_failed', $old_mode, $shown, $error)) if defined $error;

	# Pass the code's exception on unchanged (objects included); croak
	# would add a location to it.
	die $exception unless $ok;	## no critic (ErrorHandling::RequireCarping)

	return $want ? @result : $result[0];
}

=head2 permissions_report(dir)

=head3 PURPOSE

Describe, in a few lines, what C<chmod> can revoke in C<dir>: every kind,
with the reason for each 0.  Print it once with C<diag> (or C<note>) so
that a CPAN Testers report shows the environment the tests ran in.

=head3 ARGUMENTS

=over 4

=item * C<dir> - optional.  As for L</can_revoke_read(dir)>.

=back

=head3 RETURNS

A string of lines, ending without a newline:

	Test::Permissions 0.001.0 in '/tmp/abc' (effective uid 1000):
	  read: yes
	  ...
	  sticky: no - The sticky probe in '/tmp/abc' must act as two users, ...

=head3 SIDE EFFECTS

Probes every kind that is not already cached for C<dir>, as
L</can_revoke(kind, dir)> would.

=head3 USAGE EXAMPLE

	diag(Test::Permissions::permissions_report($dir));

=head3 API SPECIFICATION

=head4 Input

	{
		dir => {
			type     => 'string',
			optional => 1,
			min      => 1,
			position => 0,
		},
	}

=head4 Output

	{ type => 'string', min => 1 }

=head3 MESSAGES

Errors: the same as L</can_revoke_read(dir)>.

The lines come from the messages C<report_header> (arguments: version,
directory, effective uid), C<report_yes> (kind) and C<report_no> (kind,
reason), which L</set_messages(%overrides)> can translate.

=cut

sub permissions_report {
	my ($params, $error) = _check_args('dir', \@_);
	Carp::croak($error) if defined $error;

	my $dir = $params->{dir};
	my @lines = _msg('report_header', $VERSION, _printable(_canonical($dir)), $>);
	for my $kind (@KINDS) {
		my $entry = _answer($kind, $dir);
		push @lines, $entry->[0] ? _msg('report_yes', $kind) : _msg('report_no', $kind, $entry->[1]);
	}
	return _set_return(join("\n", @lines), 'report');
}

=head2 clear_cache()

=head3 PURPOSE

Forget every answer, so the next call probes again.  This is mainly for
the module's own tests, and for a directory whose permissions or mount
have changed since it was probed.

=head3 ARGUMENTS

None.

=head3 RETURNS

Nothing.

=head3 SIDE EFFECTS

Empties the cache.

=head3 USAGE EXAMPLE

	Test::Permissions::clear_cache();

=head3 API SPECIFICATION

=head4 Input

	{}

=head4 Output

	{ type => 'void' }

=head3 MESSAGES

None.

=cut

sub clear_cache {
	%cache = ();
	_set_return(undef, 'void');
	return;
}

=head2 set_cache_scope(scope)

=head3 PURPOSE

Choose how answers are shared between directories.

=over 4

=item * C<directory> (the default) - each directory is probed on its own.
This is always right, because ACLs, bind mounts and mount options can
differ between directories on one device.

=item * C<device> - directories on the same device (the same C<st_dev>)
share answers.  A suite that makes a new C<tempdir> for every test can
use this to probe once instead of once per directory, when it knows its
directories are alike.  The reason text names the first directory probed
on the device.

=back

=head3 ARGUMENTS

=over 4

=item * C<scope> - required.  C<directory> or C<device>.

=back

=head3 RETURNS

Nothing.

=head3 SIDE EFFECTS

Applies to later calls.  Answers already cached under the other scope
stay in the cache but are not used.

=head3 USAGE EXAMPLE

	Test::Permissions::set_cache_scope('device');

=head3 API SPECIFICATION

=head4 Input

	{
		scope => {
			type     => 'string',
			memberof => [ 'directory', 'device' ],
			position => 0,
		},
	}

=head4 Output

	{ type => 'void' }

=head3 MESSAGES

Errors (the call dies): an error from Params::Validate::Strict when scope
is missing or not one of the two names.

=cut

sub set_cache_scope {
	my ($params, $error) = _check_args('scope', \@_);
	Carp::croak($error) if defined $error;

	$cache_scope = $params->{scope};
	_set_return(undef, 'void');
	return;
}

=head2 set_messages(%overrides)

=head3 PURPOSE

Replace message texts by key, for example to translate them.

=head3 ARGUMENTS

Pairs of message key and text, as a list or a hash reference.  The keys
are those listed under MESSAGES for each function (C<error_*>, C<reason_*>
and C<report_*>).  Each text is a C<sprintf> format taking the same
arguments, in the same order, as the default text.

=head3 RETURNS

Nothing.

=head3 SIDE EFFECTS

=over 4

=item * Changes the texts for the rest of the process.

=item * Reasons are worded when a probe runs, so answers already in the
cache keep their old wording until L</clear_cache()>.

=item * All pairs are checked before any is applied: if one is invalid,
nothing changes.

=item * A text with more or fewer C<%s> than the default does not warn:
missing arguments are empty and extra ones are ignored.

=back

=head3 USAGE EXAMPLE

	Test::Permissions::set_messages(
		reason_not_enforced => q{chmod ne peut pas retirer l'acces %s dans '%s'},
	);

=head3 API SPECIFICATION

=head4 Input

	{
		error_unknown_kind       => { type => 'string', min => 1, optional => 1 },
		error_not_a_directory    => { type => 'string', min => 1, optional => 1 },
		error_not_a_file         => { type => 'string', min => 1, optional => 1 },
		error_no_such_path       => { type => 'string', min => 1, optional => 1 },
		error_unknown_message    => { type => 'string', min => 1, optional => 1 },
		error_too_many_arguments => { type => 'string', min => 1, optional => 1 },
		error_chmod_failed       => { type => 'string', min => 1, optional => 1 },
		error_restore_failed     => { type => 'string', min => 1, optional => 1 },
		reason_not_enforced      => { type => 'string', min => 1, optional => 1 },
		reason_chmod_ignored     => { type => 'string', min => 1, optional => 1 },
		reason_baseline_failed   => { type => 'string', min => 1, optional => 1 },
		reason_other_error       => { type => 'string', min => 1, optional => 1 },
		reason_setup_failed      => { type => 'string', min => 1, optional => 1 },
		reason_cleanup_failed    => { type => 'string', min => 1, optional => 1 },
		reason_probe_succeeded   => { type => 'string', min => 1, optional => 1 },
		reason_needs_root        => { type => 'string', min => 1, optional => 1 },
		report_header            => { type => 'string', min => 1, optional => 1 },
		report_yes               => { type => 'string', min => 1, optional => 1 },
		report_no                => { type => 'string', min => 1, optional => 1 },
	}

=head4 Output

	{ type => 'void' }

=head3 MESSAGES

Errors (the call dies, and no text is changed):

	Unknown message key '$key'                    (error_unknown_message)
	    What to do: use a key listed under MESSAGES.

	(an error from Params::Validate::Strict or Params::Get)
	    A text is empty or not a string, or the arguments are not pairs.

=cut

sub set_messages {
	my ($texts, $error) = _check_messages(\@_);
	Carp::croak($error) if defined $error;

	@message_override{keys %{$texts}} = values %{$texts};
	_set_return(undef, 'void');
	return;
}

# -----------------------------------------------------------------------
# Argument handling
# -----------------------------------------------------------------------

# _check_args
#
# Purpose:  Turn a public function's @_ into a validated hashref.
#           Errors are returned rather than thrown, so the caller can
#           croak outside the local($@, $!) scope here (on perl < 5.14 a
#           die inside a 'local $@' scope loses the message).
# Entry:    $schema_name - a key of %INPUT_SCHEMA; $args - arrayref of @_.
# Exit:     ($params, undef) on success, with dir set (default tmpdir);
#           (undef, $message) on a caller error.
sub _check_args {
	my ($schema_name, $args) = @_;
	local ($@, $!);

	my $schema = $INPUT_SCHEMA{$schema_name};
	my @names = sort { $schema->{$a}{position} <=> $schema->{$b}{position} } keys %{$schema};

	my $params;
	my $ok = eval {
		$params = _normalise_args(\@names, $args);
		1;
	};
	return (undef, _exception_text($@)) unless $ok;
	return (undef, $params) if !ref $params;	# an error message

	# Our own message for an unknown kind, before the generic validator.
	my $kind = $params->{kind};
	if(defined $kind && !ref $kind) {
		my @allowed = @{ $schema->{kind}{memberof} };
		if(!grep { $_ eq $kind } @allowed) {
			return (undef, _msg('error_unknown_kind', _printable($kind), join(', ', @allowed)));
		}
	}

	# The documented schemas carry 'position'; the validator's positional
	# mode mis-reports missing arguments, so validate the hash form.
	my %hash_schema = map { $_ => _hash_rule($schema->{$_}) } @names;
	$ok = eval {
		$params = Params::Validate::Strict::validate_strict(schema => \%hash_schema, input => $params);
		1;
	};
	return (undef, _exception_text($@)) unless $ok;

	if(exists $schema->{dir}) {
		$params->{dir} = File::Spec->tmpdir() unless defined $params->{dir};
		return (undef, _msg('error_not_a_directory', _printable($params->{dir})))
			unless -d $params->{dir};
	}
	if(exists $schema->{path}) {
		return (undef, _msg('error_no_such_path', _printable($params->{path})))
			unless -e $params->{path};
	}
	return ($params, undef);
}

# _hash_rule
#
# Purpose:  A plain (not Readonly) copy of one schema rule, without
#           'position', for validating the hash form of the arguments.
# Entry:    $rule - a hashref from %INPUT_SCHEMA.
# Exit:     A new hashref.
sub _hash_rule {
	my $rule = $_[0];
	my %copy = %{$rule};
	delete $copy{position};
	$copy{memberof} = [ @{ $copy{memberof} } ] if $copy{memberof};
	return \%copy;
}

# _normalise_args
#
# Purpose:  Accept every calling form: f(), f(@positional),
#           f(name => value, ...), f({ name => value }).
#           Params::Get's positional mode does not recognise named pairs,
#           so the named form is detected here: an even number of
#           arguments, the first of which is an argument name.  (No valid
#           positional call looks like that: a kind is never 'kind', 'count'
#           or 'dir', and a lone directory is a single argument.)  Unknown
#           names in the rest are then reported by the validator.
# Entry:    $names - argument names in positional order; $args - arrayref.
# Exit:     A new hashref (the caller's hash is never modified), with
#           undefined values removed and stringifiable objects turned into
#           strings; or a plain string, the error message for too many
#           positional arguments.  Params::Get may croak on malformed
#           input.
sub _normalise_args {
	my ($names, $args) = @_;

	my %known = map { $_ => 1 } @{$names};
	my $params;
	if(@{$args} == 1 && ref $args->[0] eq 'HASH') {
		$params = { %{ Params::Get::get_params(undef, $args->[0]) } };
	} elsif(@{$args} >= 2 && @{$args} % 2 == 0 && defined $args->[0] && !ref $args->[0] && $known{$args->[0]}) {
		$params = { %{ Params::Get::get_params(undef, @{$args}) } };
	} else {
		return _msg('error_too_many_arguments', scalar @{$names}, scalar @{$args})
			if @{$args} > @{$names};
		$params = @{$args} ? { %{ Params::Get::get_params([ @{$names} ], @{$args}) } } : {};
	}

	for my $name (keys %{$params}) {
		my $value = $params->{$name};
		if(!defined $value) {
			delete $params->{$name};
		} elsif(ref $value && overload::Method($value, q{""})) {
			$params->{$name} = "$value";
		}
	}
	return $params;
}

# _check_messages
#
# Purpose:  Validate set_messages() arguments, all before any is applied.
# Entry:    $args - arrayref of @_.
# Exit:     ($hashref, undef) or (undef, $message).
sub _check_messages {
	my $args = $_[0];
	local ($@, $!);

	return ({}, undef) unless @{$args};

	my $texts;
	my $ok = eval {
		$texts = { %{ Params::Get::get_params(undef, @{$args}) } };
		1;
	};
	return (undef, _exception_text($@)) unless $ok;

	for my $key (sort keys %{$texts}) {
		return (undef, _msg('error_unknown_message', _printable($key))) unless exists $MESSAGES{$key};
	}

	# Every key given is required, so an undef text is refused too.
	my %schema = map { $_ => { type => 'string', min => 1 } } keys %{$texts};
	$ok = eval {
		Params::Validate::Strict::validate_strict(schema => \%schema, input => $texts);
		1;
	};
	return (undef, _exception_text($@)) unless $ok;
	return ($texts, undef);
}

# _set_return
#
# Purpose:  Return a value checked against an output schema (Return::Set),
#           without letting Return::Set's eval change the caller's $@.
# Entry:    $value; $schema_name - a key of %OUTPUT_SCHEMA.
# Exit:     $value.
sub _set_return {
	my ($value, $schema_name) = @_;
	local ($@, $!);
	return Return::Set::set_return($value, { %{ $OUTPUT_SCHEMA{$schema_name} } });
}

# -----------------------------------------------------------------------
# Messages
# -----------------------------------------------------------------------

# _msg
#
# Purpose:  Format a user-facing text from the message dictionary.
# Entry:    $key - a key of %MESSAGES; @args - sprintf arguments, already
#           passed through _printable where they come from outside.
# Exit:     The text.  Never warns or dies: a translated text with the
#           wrong number of arguments must not fail the caller's tests.
#           The caller's $@ is restored.
sub _msg {
	my ($key, @args) = @_;

	my $format = defined $message_override{$key} ? $message_override{$key} : $MESSAGES{$key};
	local $@;
	my $text = eval {
		no warnings;	## no critic (TestingAndDebugging::ProhibitNoWarnings)
		sprintf $format, @args;
	};
	return defined $text ? $text : join ': ', $key, @args;
}

# _printable
#
# Purpose:  Make a path or error text safe to put in a message.  Control
#           characters and bidirectional-override characters become \x{..}
#           escapes; everything else is kept.
#           A byte string that is valid UTF-8 (the usual form of a
#           non-ASCII path on Unix) is checked as characters and returned
#           as bytes again, so its letters are not escaped; other byte
#           strings are checked for C0 and C1 controls.
# Entry:    $_[0] - any value (stringified; undef is '').
# Exit:     The escaped string.
sub _printable {
	my $text = defined $_[0] ? "$_[0]" : q{};
	my $escape = sub { sprintf '\\x{%X}', ord $_[0] };

	if(!utf8::is_utf8($text)) {
		my $chars = $text;
		if(utf8::decode($chars)) {
			$chars =~ s/($UNSAFE_CHARS_RE)/$escape->($1)/ge;
			utf8::encode($chars);
			return $chars;
		}
		$text =~ s/($UNSAFE_BYTES_RE)/$escape->($1)/ge;
		return $text;
	}
	$text =~ s/($UNSAFE_CHARS_RE)/$escape->($1)/ge;
	return $text;
}

# _exception_text
#
# Purpose:  Turn an exception (a string, or an autodie::exception object)
#           into one printable line.
# Entry:    $_[0] - the exception.
# Exit:     The text, without trailing newlines or a trailing
#           "at FILE line N.", via _printable.
sub _exception_text {
	my $text = defined $_[0] ? "$_[0]" : q{};
	$text = substr($text, 0, -1) while length $text && substr($text, -1) eq "\n";
	# A croak from inside this module (the validator, Params::Get) names a
	# line here; croak adds the caller's line instead.
	$text =~ s/ at \S+ line [0-9]+\.\z//;
	return _printable($text);
}

# _errno_text
#
# Purpose:  The system's text for an errno, in the current locale.
# Entry:    $errno - a number.
# Exit:     The printable text.
sub _errno_text {
	my ($errno) = @_;
	local $! = $errno;
	return _printable("$!");
}

# _untaint
#
# Purpose:  Untaint a path the caller has named and this module has
#           checked (-d or -e).  The module only ever creates its own
#           scratch directory inside such a path, or changes its mode at
#           the caller's request, so taint mode's protection is not lost.
#           Without this, every probe under perl -T fails its setup
#           ("Insecure dependency in mkdir") and answers 0.
# Entry:    $path.
# Exit:     The same string, untainted.
sub _untaint {
	my ($path) = @_;
	my ($clean) = $path =~ $ANYTHING_RE;
	return $clean;
}

# -----------------------------------------------------------------------
# Probing
# -----------------------------------------------------------------------

# _answer
#
# Purpose:  Look up, or probe and cache, the answer for a kind and dir.
# Entry:    $kind - a kind from @KINDS; $dir - an existing directory.
# Exit:     Arrayref [ answer (1 or 0), reason (undef when 1) ].
# Effects:  May create and remove a probe directory in $dir.  $@ and $!
#           are restored.
sub _answer {
	my ($kind, $dir) = @_;
	local ($@, $!);

	my $canonical = _canonical($dir);
	my $key = _cache_key($kind, $canonical);
	$cache{$key} = [ _probe($kind, $canonical) ] unless $cache{$key};
	return $cache{$key};
}

# _cache_key
#
# Purpose:  The cache key for a kind and directory.  It includes the
#           effective uid and groups, because the answer depends on who
#           asks: a root suite that drops privileges must not reuse
#           root's answers.  The directory part depends on the cache scope.
# Entry:    $kind; $canonical - canonical directory path.
# Exit:     The key.
sub _cache_key {
	my ($kind, $canonical) = @_;
	my $where = "dir:$canonical";
	if($cache_scope eq 'device') {
		my @stat = stat $canonical;
		$where = "dev:$stat[$STAT_DEV]" if @stat;
	}
	return join $KEY_SEP, $kind, $>, $), $where;
}

# _canonical
#
# Purpose:  The canonical absolute path of a directory: the cache key, and
#           where the probe runs.  Not the device number: ACLs and bind
#           mounts can differ within one device, and inode numbers are 0
#           on Windows.  Untainted (see _untaint).
# Entry:    $dir - an existing directory.
# Exit:     Cwd::abs_path($dir), or the absolute form of $dir if that fails.
# Effects:  None; $@ and $! are restored.
sub _canonical {
	my ($dir) = @_;
	local ($@, $!);
	my $abs = eval { Cwd::abs_path($dir) };
	$abs = File::Spec->rel2abs($dir) unless defined $abs && length $abs;
	return _untaint($abs);
}

# _probe
#
# Purpose:  Find out whether chmod can revoke $kind access in $dir, by
#           trying it (see "How a probe works" in the POD).
#           Strategy: steps 1-4 run inside one eval, so an exception from
#           any of them (autodie during setup, a mocked seam dying) becomes
#           reason_setup_failed.  Step 5 (restore and clean up) runs after
#           the eval, whatever happened, and any failure there overrides
#           the answer with 0 and reason_cleanup_failed.
# Entry:    $kind - a kind from @KINDS; $dir - canonical directory path.
# Exit:     (answer, reason): (1, undef) or (0, text).  Never dies or warns.
# Effects:  Creates and removes a probe directory in $dir.
sub _probe {
	my ($kind, $dir) = @_;
	my $probe = $PROBE{$kind};
	my $shown = _printable($dir);

	if($probe->{precondition} && !$probe->{precondition}->()) {
		return (0, _msg('reason_needs_root', $kind, $shown));
	}

	# Internal exceptions are expected; the caller's die hook (for example
	# a stack-trace printer) must not see them.
	local $SIG{__DIE__};

	my ($probe_dir, $paths, $restore_target);
	my ($answer, $reason) = (0, undef);
	my $bits = defined $probe->{bits} ? $probe->{bits} : $OWNER_BITS;

	my $ok = eval {
		# 1. Setup.
		$probe_dir = _make_probe_dir($dir);
		$paths = $probe->{setup}->($probe_dir);

		# 2. Baseline: the operation must work while it is allowed.
		my ($baseline_ok, $baseline_errno) = $probe->{op}->($paths);
		if(!$baseline_ok) {
			$reason = _msg('reason_baseline_failed', $kind, $shown, _errno_text($baseline_errno));
			return 1;
		}
		$probe->{tidy}->($paths) if $probe->{tidy};

		# 3. Restrict, and check that chmod really changed the mode bits.
		$restore_target = $paths->{target};
		_set_mode($paths->{target}, $probe->{restricted});
		my $got = _mode_of($paths->{target});
		if(!defined $got) {
			$reason = _msg('reason_setup_failed', $kind, $shown, _printable("$!"));
			return 1;
		}
		if(($got & $bits) != ($probe->{restricted} & $bits)) {
			$reason = _msg('reason_chmod_ignored', $probe->{restricted}, $shown, $got & $MODE_BITS);
			return 1;
		}

		# 4. Attempt: only EACCES or EPERM means chmod took access away.
		my ($attempt_ok, $attempt_errno) = $probe->{op}->($paths);
		if($attempt_ok) {
			$reason = _msg('reason_not_enforced', $kind, $shown);
		} elsif($DENIED_ERRNO{$attempt_errno}) {
			$answer = 1;
		} else {
			$reason = _msg('reason_other_error', $kind, $shown, _errno_text($attempt_errno));
		}
		1;
	};
	if(!$ok) {
		($answer, $reason) = (0, _msg('reason_setup_failed', $kind, $shown, _exception_text($@)));
	}

	# 5. Restore and clean up, always.
	my $problem = _cleanup($probe_dir, $restore_target, $probe->{permissive});
	if(defined $problem) {
		$reason = _msg('reason_probe_succeeded', $kind, $shown) if $answer;
		($answer, $reason) = (0, _msg('reason_cleanup_failed', $reason,
			_printable(defined $probe_dir ? $probe_dir : $dir), $problem));
	}

	return ($answer, $answer ? undef : $reason);
}

# _cleanup
#
# Purpose:  Step 5 of a probe: restore the permissive mode, then remove the
#           probe directory.  Both are attempted even if the first fails.
# Entry:    $probe_dir - P, or undef if it was never created;
#           $target - the path that was chmod-ed, or undef;
#           $mode - the permissive mode to restore.
# Exit:     undef on success, or the printable text of what went wrong.
sub _cleanup {
	my ($probe_dir, $target, $mode) = @_;

	my @problems;
	if(defined $target) {
		my $restored = eval { _set_mode($target, $mode) };
		push @problems, _exception_text($@ || "$target: $!") unless $restored;
	}
	if(defined $probe_dir) {
		my $errors;
		my $ok = eval {
			File::Path::remove_tree($probe_dir, { error => \$errors });
			1;
		};
		push @problems, _exception_text($@) unless $ok;
		for my $error (@{ $errors || [] }) {
			my ($path, $text) = %{$error};
			push @problems, _printable(length $path ? "$path: $text" : $text);
		}
	}
	return @problems ? join('; ', @problems) : undef;
}

# _chmod_error
#
# Purpose:  chmod a path for with_revoked, reporting failure as text.
# Entry:    $path; $mode.
# Exit:     undef on success, else the printable error text.
sub _chmod_error {
	my ($path, $mode) = @_;
	local ($@, $!);
	my $ok = eval { _set_mode($path, $mode) };
	return $ok ? undef : _exception_text($@ || "$!");
}

# _setup_file
#
# Purpose:  Setup for the read, write and exec kinds: file P/f with the
#           given content and mode.
# Entry:    $probe_dir - P; $content; $mode.
# Exit:     { target => P/f, object => P/f }.  Throws (autodie) on failure.
sub _setup_file {
	my ($probe_dir, $content, $mode) = @_;
	my $file = File::Spec->catfile($probe_dir, $PROBE_FILE);
	_make_file($file, $content);
	_set_mode($file, $mode);
	return { target => $file, object => $file };
}

# _setup_subdir
#
# Purpose:  Setup for the create, search and delete kinds: directory P/d,
#           mode 0700, optionally holding file P/d/f (mode 0600).
# Entry:    $probe_dir - P; $with_file - true to create P/d/f.
# Exit:     { target => P/d, object => P/d/f or P/d/new }.  Throws on
#           failure.
sub _setup_subdir {
	my ($probe_dir, $with_file) = @_;
	my $subdir = File::Spec->catdir($probe_dir, $PROBE_SUBDIR);
	mkdir $subdir;
	_set_mode($subdir, $MODE_DIR_RWX);
	if($with_file) {
		my $file = File::Spec->catfile($subdir, $PROBE_FILE);
		_make_file($file, q{});
		_set_mode($file, $MODE_FILE_RW);
		return { target => $subdir, object => $file };
	}
	return { target => $subdir, object => File::Spec->catfile($subdir, $PROBE_NEW) };
}

# _setup_sticky
#
# Purpose:  Setup for the sticky kind: directory P/d, mode 0777, holding
#           file P/d/f owned by $STICKY_OWNER_UID.  The op deletes it as
#           $STICKY_OTHER_UID.
# Entry:    $probe_dir - P.
# Exit:     { target => P/d, object => P/d/f, as => other uid }.  Throws
#           on failure.
sub _setup_sticky {
	my ($probe_dir) = @_;
	my $subdir = File::Spec->catdir($probe_dir, $PROBE_SUBDIR);
	mkdir $subdir;
	_set_mode($subdir, $MODE_DIR_ALL);
	my $file = File::Spec->catfile($subdir, $PROBE_FILE);
	_make_file($file, q{});
	_give_away($file, $STICKY_OWNER_UID);
	return { target => $subdir, object => $file, as => $STICKY_OTHER_UID };
}

# _make_file
#
# Purpose:  Create a file with exactly the given bytes (binmode: on
#           Windows, text mode would turn the script's "\n" into "\r\n").
#           Setup step: autodie.
# Entry:    $path; $content.
# Exit:     Nothing useful.  Throws on failure (close reports write errors).
sub _make_file {
	my ($path, $content) = @_;
	open(my $fh, $OPEN_TRUNCATE, $path);
	binmode $fh;
	print {$fh} $content if length $content;
	close $fh;
	return;
}

# _mode_allows
#
# Purpose:  What the mode bits alone say about $kind access for the
#           effective uid and groups (acl_denies).  Root may read and
#           write anything, and search any directory, but may run a file
#           only if some execute bit is set.  On Windows, where $> is
#           always 0, the owner bits decide.
# Entry:    $kind - read, write or exec; $stat - arrayref from stat;
#           $is_dir - true for a directory.
# Exit:     1 or 0.
sub _mode_allows {
	my ($kind, $stat, $is_dir) = @_;
	my $mode = $stat->[$STAT_MODE];
	my (undef, $euid) = _uids();

	if($euid == $ROOT_UID && $^O ne 'MSWin32') {
		return 1 unless $kind eq 'exec';
		return $is_dir || ($mode & $ANY_EXEC) ? 1 : 0;
	}
	my %group = map { $_ => 1 } split ' ', $);
	my $shift = $stat->[$STAT_UID] == $euid ? $OWNER_SHIFT
		: $group{ $stat->[$STAT_GID] } ? $GROUP_SHIFT
		: $OTHER_SHIFT;
	return ($mode >> $shift) & $ACCESS_BIT{$kind} ? 1 : 0;
}

# -----------------------------------------------------------------------
# Seams: every probe step goes through one of these, so that tests can
# simulate any environment by mocking them.
# -----------------------------------------------------------------------

# _make_probe_dir
#
# Purpose:  Create the probe directory P inside $dir, mode 0700.
#           CLEANUP is only a fallback; _cleanup removes P explicitly.
# Entry:    $dir - the target directory (untainted).
# Exit:     The path of P.  Throws on failure.
sub _make_probe_dir {
	my ($dir) = @_;
	my $probe_dir = File::Temp::tempdir($PROBE_TEMPLATE, DIR => $dir, CLEANUP => 1);
	_set_mode($probe_dir, $MODE_DIR_RWX);
	return $probe_dir;
}

# _try_open
#
# Purpose:  The attempt for read, write and create: open a file.
# Entry:    $path; $mode - an open() mode.
# Exit:     (1, 0) if it opened (the handle is closed again), else
#           (0, errno).  Never throws.
sub _try_open {
	my ($path, $mode) = @_;
	no autodie;
	if(open my $fh, $mode, $path) {
		close $fh;
		return (1, 0);
	}
	return (0, 0 + $!);
}

# _try_stat
#
# Purpose:  The attempt for search: stat a file.
# Entry:    $path.
# Exit:     (1, 0) or (0, errno).  Never throws.
sub _try_stat {
	my ($path) = @_;
	no autodie;
	my @stat = stat $path;
	return @stat ? (1, 0) : (0, 0 + $!);
}

# _try_exec
#
# Purpose:  The attempt for exec: run the probe's script, without a shell,
#           with the variables in @UNSAFE_ENV removed (taint mode refuses
#           to run anything while they are set).
# Entry:    $path.
# Exit:     (1, 0) if it ran and exited 0; (0, errno) if it could not be
#           run; (0, ENOEXEC) if it ran but did not exit 0.  Never throws.
sub _try_exec {
	my ($path) = @_;
	no autodie;
	no warnings 'exec';	## no critic (TestingAndDebugging::ProhibitNoWarnings) - "Can't exec" is expected

	local %ENV = %ENV;
	delete @ENV{@UNSAFE_ENV};
	my $status = system { $path } $path;
	return (0, 0 + $!) if $status == -1;
	return $? == 0 ? (1, 0) : (0, $ERRNO_BAD_EXIT);
}

# _try_unlink
#
# Purpose:  The attempt for delete and sticky: unlink a file, optionally
#           as another user.  To act as another user it changes directory
#           to the file's directory first (as root), then sets the
#           effective uid only for the unlink of the bare name, so that
#           the other user needs no access to the directories above.  Both
#           are restored before it returns.
# Entry:    $path; $as - a uid to act as, or undef.
# Exit:     (1, 0) or (0, errno).  Throws only if it cannot change
#           directory or effective uid, or cannot change back.
sub _try_unlink {
	my ($path, $as) = @_;
	no autodie;

	if(!defined $as) {
		return unlink($path) ? (1, 0) : (0, 0 + $!);
	}

	my ($volume, $directories, $name) = File::Spec->splitpath($path);
	my $dir = File::Spec->catpath($volume, $directories, q{});
	my $cwd = _untaint(Cwd::getcwd());
	chdir $dir or die "chdir $dir: $!\n";	## no critic (ErrorHandling::RequireCarping)

	my ($switched, $ok, $errno) = _unlink_as($name, $as);
	chdir $cwd or die "chdir $cwd: $!\n";	## no critic (ErrorHandling::RequireCarping)
	die "cannot act as uid $as\n" unless $switched;	## no critic (ErrorHandling::RequireCarping)
	return $ok ? (1, 0) : (0, $errno);
}

# _unlink_as
#
# Purpose:  The privileged core of _try_unlink: set the effective uid,
#           unlink a name in the current directory, and set it back.
#           Kept this small because only real root can run it: tests mock
#           it to reach every other path of _try_unlink.
# Entry:    $name - a file name in the current directory; $uid.
# Exit:     ($switched, $ok, $errno): whether the effective uid could be
#           changed, and if so whether unlink worked and its errno.
sub _unlink_as {
	my ($name, $uid) = @_;
	no autodie;
	local $> = $uid;
	return (0) unless $> == $uid;
	my $ok = unlink $name;
	return (1, $ok, 0 + $!);
}

# _can_switch_uid
#
# Purpose:  The sticky probe's precondition: can this process act as
#           another user?  Only root (real and effective) outside Windows.
# Entry:    None.
# Exit:     1 or 0.
sub _can_switch_uid {
	my ($ruid, $euid) = _uids();
	return $^O ne 'MSWin32' && $ruid == $ROOT_UID && $euid == $ROOT_UID ? 1 : 0;
}

# _uids
#
# Purpose:  The real and effective uid, through a seam, so that tests can
#           exercise the root branches without being root.
# Entry:    None.
# Exit:     ($<, $>).
sub _uids {
	return ($<, $>);
}

# _give_away
#
# Purpose:  Give a file to another user (sticky setup).  autodie.
# Entry:    $path; $uid.
# Exit:     Nothing.  Throws on failure.
sub _give_away {
	my ($path, $uid) = @_;
	chown $uid, -1, $path;
	return;
}

# _access
#
# Purpose:  What the system says about $kind access to $path for this
#           process, using access(2), which takes ACLs into account
#           (acl_denies).
# Entry:    $kind - read, write or exec; $path.
# Exit:     1 or 0.
sub _access {
	my ($kind, $path) = @_;
	use filetest 'access';
	return ($kind eq 'read' ? -r $path : $kind eq 'write' ? -w $path : -x $path) ? 1 : 0;
}

# _set_mode
#
# Purpose:  chmod one path.
# Entry:    $path; $mode.
# Exit:     1.  Throws (autodie) on failure.
sub _set_mode {
	my ($path, $mode) = @_;
	chmod $mode, $path;
	return 1;
}

# _mode_of
#
# Purpose:  The permission bits of a path.
# Entry:    $path.
# Exit:     mode & 07777, or undef if stat fails ($! says why).
sub _mode_of {
	my ($path) = @_;
	my @stat = stat $path;
	return @stat ? $stat[$STAT_MODE] & $MODE_BITS : undef;
}

=head1 FAILURE POLICY

=over 4

=item * B<Caller errors croak>: an unknown kind, a C<dir> that is not an
existing directory, a C<path> that does not exist, bad arguments
(reported by Params::Validate::Strict or Params::Get), or an unknown
message key.  C<with_revoked> also croaks if it cannot change or restore
the mode it was asked to change.

=item * B<Probe errors never escape.>  Anything that goes wrong inside a
probe becomes a 0 answer with a reason.  A helper whose job is to decide
whether to skip must never be the thing that fails your test file.

=item * B<No warnings.>  Many suites run under L<Test::Warnings> or C<-W>,
so a warning would itself fail them.  Use L</why_not(kind, dir)> for
diagnostics.

=item * A failed restore or cleanup makes the answer 0, and is added to
the reason (C<reason_cleanup_failed>).

=back

=head1 LIMITATIONS

=over 4

=item * Results are per directory (or per device, see
L</set_cache_scope(scope)>), per effective user and groups, and per
process.

=item * A directory whose permissions or mount change after the first
call keeps its cached answer until L</clear_cache()>.

=item * Probing needs write access to C<dir>: the probe creates a scratch
directory there.  Without it the answer is 0 (C<reason_setup_failed>).

=item * The probes change only mode bits.  L</acl_denies(kind, path)>
detects an ACL that denies access to an existing path, but no probe
creates ACLs.

=item * The mode check after C<chmod> compares the owner's permission
bits (all bits for C<sticky>), because the probe runs as the owner of its
scratch files, and because perl on Windows reports a read-only file as
0444.

=item * The C<sticky> probe needs root, and assumes that uids 65533 and
65534 can own files.  In a user namespace that maps only one uid (such as
C<unshare -r>), giving the file away fails and the answer is 0 with
C<reason_setup_failed>.

=item * Reasons embed the system's error text in the current locale.

=item * Needs perl 5.26 or later, because Params::Validate::Strict does.

=back

=head1 SEE ALSO

L<Test::More>, L<Test2::V0>, L<Test::Warnings>, L<File::Temp>,
L<filetest>.

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report bugs and feature requests at
L<https://github.com/nigelhorne/Test-Permissions/issues>.

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

=head1 STATE DIAGRAM

The cache, for one key: a kind, the effective uid and groups, and the
canonical directory (or, with the C<device> scope, its device).
C<can_revoke>, C<can_revoke_*>, C<why_not>, C<skip_unless_can_revoke> and
C<permissions_report> are all "queries".  A call that croaks does not
change the state.

	                   query: probe, answer 1
	    +---------+ ---------------------------> +------------+
	    |  EMPTY  |                              | CACHED_YES | --+ query: no probe
	    +---------+ ---------------------------> +------------+ <-+
	      ^  ^  ^      query: probe, answer 0          |
	      |  |  |                                      |
	      |  |  +------------- clear_cache ------------+
	      |  |                                      +-----------+
	      |  +-------------- clear_cache ---------- | CACHED_NO | --+ query: no probe
	      |                                         +-----------+ <-+
	      +-- clear_cache (from EMPTY: no change)

There is no edge between CACHED_YES and CACHED_NO: a cached answer stays
until C<clear_cache>, even if the environment changes.  C<set_messages>
changes no state; a cached reason keeps the wording it was given when the
probe ran.  C<set_cache_scope> and a change of effective uid or groups do
not change any key's state; they change which key later queries use.

=encoding utf-8

=head1 FORMAL SPECIFICATION

The specification below uses Z notation.  The English sections above are
the normative description for everyday use.

	[PATH, ERRNO, CHAR, UID, GID, DEV]
	Kind   ::= read | write | create | search | exec | delete | sticky
	Answer == { 0, 1 }
	DENIED == { EACCES, EPERM }
	Reason == seq₁ CHAR
	Scope  ::= directory | device

	-- Outcome of one probe step.
	Outcome ::= ok | failed⟨⟨ERRNO⟩⟩ | threw

	restricted : Kind → ℕ
	restricted = { read ↦ 0, write ↦ 0400, create ↦ 0500, search ↦ 0,
	               exec ↦ 0600, delete ↦ 0500, sticky ↦ 01777 }
	bits : Kind → ℕ
	bits = (λ k : Kind • 0700) ⊕ { sticky ↦ 07777 }

	Env ≙ [ ruid, euid : UID; egids : 𝔽 GID; windows : 𝔹 ]
	precondition : Kind × Env → 𝔹
	precondition(k, e) ⇔ k ≠ sticky ∨ (e.ruid = 0 ∧ e.euid = 0 ∧ ¬ e.windows)

	Probe
	  kind? : Kind
	  dir?  : PATH
	  env   : Env
	  setup, baseline, attempt, cleanup : Outcome
	  gotMode : ℕ
	  modeSet : 𝔹
	  answer! : Answer
	  reason! : Reason ∪ {⊥}
	  ---------------------------------------------
	  modeSet ⇔ gotMode ∧ bits(kind?) = restricted(kind?) ∧ bits(kind?)
	  answer! = 1 ⇔ precondition(kind?, env)
	                ∧ setup = ok ∧ baseline = ok ∧ modeSet
	                ∧ (∃ e : DENIED • attempt = failed(e))
	                ∧ cleanup = ok
	  answer! = 1 ⇔ reason! = ⊥

	Key   == Kind × UID × 𝔽 GID × (PATH ∪ DEV)
	Cache == Key ⇸ Answer × (Reason ∪ {⊥})
	scope : Scope

	key : Kind × Env × PATH → Key
	key(k, e, p) = (k, e.euid, e.egids, if scope = device then dev(p) else canon(p))

	CanRevoke
	  ΔCache ; Probe
	  ---------------------------------------------
	  key(kind?, env, dir?) ∈ dom cache  ⇒ cache' = cache
	                                       ∧ answer! = first(cache key(kind?, env, dir?))
	  key(kind?, env, dir?) ∉ dom cache  ⇒ cache' = cache ∪ { key(kind?, env, dir?) ↦ (answer!, reason!) }

	WhyNot
	  ΞCache after CanRevoke
	  why! : Reason ∪ {⊥}
	  ---------------------------------------------
	  why! = second(cache key(kind?, env, dir?))

	SkipUnlessCanRevoke
	  CanRevoke
	  count? : ℕ₁
	  skipped! : ℕ
	  ---------------------------------------------
	  answer! = 1 ⇒ skipped! = 0 ∧ the SKIP block continues
	  answer! = 0 ⇒ skipped! = count? ∧ the SKIP block is left,
	                 each skip carrying second(cache key(kind?, env, dir?))

	ClearCache
	  ΔCache
	  ---------------------------------------------
	  cache' = ∅

	SetCacheScope
	  ΞCache
	  scope?, scope, scope' : Scope
	  ---------------------------------------------
	  scope' = scope?

	SetMessages
	  texts, texts' : KEY ⇸ seq₁ CHAR
	  overrides? : KEY ⇸ seq CHAR
	  ---------------------------------------------
	  (dom overrides? ⊆ dom DEFAULTS ∧ ⊥ ∉ ran overrides? ∧ ⟨⟩ ∉ ran overrides?)
	      ⇒ texts' = texts ⊕ overrides?
	  ¬ (...) ⇒ texts' = texts ∧ croak

	AclDenies
	  kind? : { read, write, exec }
	  path? : PATH
	  denied! : Answer
	  ---------------------------------------------
	  denied! = 1 ⇔ modeAllows(kind?, stat(path?), env) ∧ ¬ access(kind?, path?)

	WithRevoked
	  kind? : Kind \ { sticky }
	  path? : PATH
	  code? : ⊤ → ⊤
	  ---------------------------------------------
	  mode'(path?) = mode(path?)                   -- restored, even if code? dies
	  during code? : mode(path?) = restricted(kind?)
	  result! = code?() ∨ code?'s exception, unchanged

	-- Invariant: a probe leaves the target directory as it found it.
	entries'(dir?) = entries(dir?)

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
