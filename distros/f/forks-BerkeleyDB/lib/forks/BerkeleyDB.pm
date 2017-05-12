package forks::BerkeleyDB;

$VERSION = 0.060;

package
	CORE::GLOBAL;	#hide from PAUSE
use subs qw(fork);
{
	no warnings 'redefine';
	$forks::BerkeleyDB::_parent_fork = \&fork;
	*fork = \&forks::BerkeleyDB::_fork;
}

package forks::BerkeleyDB;

use forks::BerkeleyDB::Config;
use BerkeleyDB 0.27;
use Storable qw(freeze thaw);

use constant DEBUG => forks::BerkeleyDB::Config::DEBUG();
use constant ENV_ROOT => forks::BerkeleyDB::Config::ENV_ROOT();
use constant ENV_SUBPATH => forks::BerkeleyDB::Config::ENV_SUBPATH();
use constant ENV_PATH => forks::BerkeleyDB::Config::ENV_PATH();
use constant ENV_PATH_LOCKSIG => forks::BerkeleyDB::Config::ENV_PATH_LOCKSIG();

my $bdb_env;	#berkeleydb environment
my $bdb_locksig_env;	#berkeleydb lock/signal environment

### environment variable controls ###
my $USE_BDB_LOCKS;
my $BDB_ENV_CHMOD_OCTVAL;
my $BDB_ENV_CHOWN_ID;
my $BDB_ENV_CHGRP_ID;
BEGIN {
	no warnings 'redefine';

	### allow user to enable BDB locks (disabled by default) ###
	if (exists $ENV{'THREADS_BDB_LOCKS'}) {	#TODO: convert to import argument in future (i.e. lock_model => 'bdb')
		$ENV{'THREADS_BDB_LOCKS'} =~ m#^(.*)$#s;
		$USE_BDB_LOCKS = $ENV{'THREADS_BDB_LOCKS'} ? 1 : 0;
	} else {
		$USE_BDB_LOCKS = 0 ;
	}
	*USE_BDB_LOCKS = sub { $USE_BDB_LOCKS };

	### allow user to set ENV file permissions; default is 0666 (octal) ###
	if (exists $ENV{'THREADS_BDB_ENV_CHMOD'}) {	#TODO: convert to import argument in future (i.e. env_chmod => '0666')
		$ENV{'THREADS_BDB_ENV_CHMOD'} =~ m#^(.*)$#s;
		$BDB_ENV_CHMOD_OCTVAL = $ENV{'THREADS_BDB_ENV_CHMOD'} =~ m/^0[0-6]{3}/o
			? oct($ENV{'THREADS_BDB_ENV_CHMOD'})
			: 0666;
	} else {
		$BDB_ENV_CHMOD_OCTVAL = 0666;
	}
	*BDB_ENV_CHMOD_OCTVAL = sub { $BDB_ENV_CHMOD_OCTVAL };

	### allow user to set ENV directory structure owner ###
	if (exists $ENV{'THREADS_BDB_ENV_CHOWN'}) {	#TODO: convert to import argument in future (i.e. env_chown => 'root')
		$ENV{'THREADS_BDB_ENV_CHOWN'} =~ m#^(.*)$#s;
		my $uid = (getpwnam($ENV{'THREADS_BDB_ENV_CHOWN'}))[2];
		$BDB_ENV_CHOWN_ID = defined $uid ? $uid : -1;
	} else {
		$BDB_ENV_CHOWN_ID = -1;
	}
	*BDB_ENV_CHOWN_ID = sub { $BDB_ENV_CHOWN_ID };

	### allow user to set ENV directory structure group ###
	if (exists $ENV{'THREADS_BDB_ENV_CHGRP'}) {	#TODO: convert to import argument in future (i.e. env_chgrp => 'sys')
		$ENV{'THREADS_BDB_ENV_CHGRP'} =~ m#^(.*)$#s;
		my $gid = (getgrnam($ENV{'THREADS_BDB_ENV_CHGRP'}))[2];
		$BDB_ENV_CHGRP_ID = defined $gid ? $gid : -1;
	} else {
		$BDB_ENV_CHGRP_ID = -1;
	}
	*BDB_ENV_CHGRP_ID = sub { $BDB_ENV_CHGRP_ID };
}

use constant DEFAULT_ENV_PATHS => (ENV_PATH, (USE_BDB_LOCKS() ? ENV_PATH_LOCKSIG : ()));

BEGIN {
	$forks::DEFER_INIT_BEGIN_REQUIRE = 1;	#feature in forks 0.26 and later
	require forks; die "forks version 0.28 required--this is only version $forks::VERSION"
		unless defined($forks::VERSION) && $forks::VERSION >= 0.28;
	
	### set up environment characteristics ###
	*_croak = *_croak = \&threads::_croak;
	{
		### safely sync/close databases, close environment at important server states ###
		no warnings 'redefine';

		my $old_server_pre_startup = \&threads::_server_pre_startup;
		*threads::_server_pre_startup = sub {
			$old_server_pre_startup->(@_);
			eval {
				forks::BerkeleyDB::_untie_support_vars();
				forks::BerkeleyDB::_close_env();
			};
		};

		my $old_end_server_post_shutdown = \&threads::_end_server_post_shutdown;
		*threads::_end_server_post_shutdown = sub {
			$old_end_server_post_shutdown->(@_);
			eval {
				forks::BerkeleyDB::_purge_env();
			};
		};
	}

	sub _open_env () {
		### open the base environment ###
		$bdb_env = new BerkeleyDB::Env(
			-Home  => ENV_PATH,
			-Flags => DB_INIT_CDB | DB_CREATE | DB_INIT_MPOOL,
		) or _croak( "Can't create BerkeleyDB::Env (home=".ENV_PATH."): $BerkeleyDB::Error" );
		if (USE_BDB_LOCKS) {
			$bdb_locksig_env = new BerkeleyDB::Env(
				-Home  => ENV_PATH_LOCKSIG,
				-Flags => DB_INIT_CDB | DB_CREATE | DB_INIT_MPOOL,
			) or _croak( "Can't create BerkeleyDB::Env (home=".ENV_PATH_LOCKSIG."): $BerkeleyDB::Error" );
		}

		### set base environment file permissions ###
		my @env_dirs = DEFAULT_ENV_PATHS;
		my $env_root_regex = quotemeta ENV_ROOT;
		foreach my $env_dir (@env_dirs) {
			opendir(ENVDIR, $env_dir);
			my @env_files = grep(!/^(\.|\.\.)$/, readdir(ENVDIR));
			closedir(ENVDIR);
			foreach (@env_files) {
				my $file = "$env_dir/$_";
				$file =~ m/^(.+)$/so;	#untaint
				#TODO: do we need to modify owner and grp to use custom environment settings?
				chmod BDB_ENV_CHMOD_OCTVAL | 0111, $1;
			}
		}
	}

	sub _close_env () {
		### close and undefine the base environment ###
		eval { $bdb_env->close() };
		$bdb_env = undef;
	}

	sub _purge_env (;$) {
		my @env_dirs = @_ ? @_ : DEFAULT_ENV_PATHS;
		foreach my $env_dir (@env_dirs) {
			opendir(ENVDIR, $env_dir);
			my @files_to_del = reverse grep(!/^(\.|\.\.)$/, readdir(ENVDIR));
			closedir(ENVDIR);
			warn "unlinking: ".join(', ', map("$env_dir/$_", @files_to_del)) if DEBUG;
			foreach (@files_to_del) {
				my $file = "$env_dir/$_";
				$file =~ m/^(.+)$/so;	#untaint
				_croak( "Unable to unlink file '$1'. Please manually remove this file." )
					unless unlink $1;
			}
		}
	}

	sub _tie_support_vars () {

	}

	sub _untie_support_vars () {

	}
	
	sub _fork {
		### safely sync/close databases, close environment ###
		_untie_support_vars();
		_close_env();
		
		### do the fork ###
		my $pid = defined($_parent_fork) ? $_parent_fork->() : CORE::fork;

		if (!defined $pid || $pid) { #in parent
			### re-open environment and immediately retie to critical databases ###
			_open_env();
			_tie_support_vars();
		}
				
		return $pid;
	};
	
	*import = *import = \&forks::import;

	### create/purge necessary paths to create clean environment ###
	my @env_dirs = (ENV_PATH, (USE_BDB_LOCKS() ? ENV_PATH_LOCKSIG : ()));
	my $env_root_regex = quotemeta ENV_ROOT;
	foreach my $env_dir (@env_dirs) {
		if (-d $env_dir) {
			_purge_env($env_dir);
		}
		else {
			my $curpath = '';
			foreach (split(/\//o, $env_dir)) {
				$curpath .= $_ eq '' ? '/' : "$_/";
				unless (-d $curpath) {
					my $status = mkdir $curpath, BDB_ENV_CHMOD_OCTVAL | 0111;
					chown BDB_ENV_CHOWN_ID, BDB_ENV_CHGRP_ID, $curpath
						unless BDB_ENV_CHOWN_ID == -1 && BDB_ENV_CHGRP_ID == -1;
					_croak( "Can't create directory ".ENV_ROOT.': '.$! )
						unless $status || -d $curpath;
				}
				chmod BDB_ENV_CHMOD_OCTVAL | 0111, $curpath
					if $curpath =~ m/^$env_root_regex/o;
			}
		}
	}

	### create the base environment ###
	_open_env();
	_tie_support_vars();
}

END {
	local $@;
	eval { _untie_support_vars(); };
#	eval { _close_env(); };	#disabled: appears to reduce 100% CPU deadlock, main thread
	#also remove database if no threads connected to any databases (maybe use recno DB to monitor num of threads connected per shared var)?
}

sub bdb_env { return $bdb_env; }
sub bdb_locksig_env { return $bdb_locksig_env; }

sub CLONE {	#reopen environment and immediately retie to critical databases
	_open_env();
	_tie_support_vars();
}

1;

__END__
=pod

=head1 NAME

forks::BerkeleyDB - high-performance drop-in replacement for threads

=head1 VERSION

This documentation describes version 0.06.

=head1 SYNOPSYS

  use forks::BerkeleyDB;

  my $thread = threads->new( sub {       # or ->create or async()
    print "Hello world from a thread\n";
  } );

  $thread->join;

  threads->detach;
  $thread->detach;

  my $tid    = $thread->tid;
  my $owntid = threads->tid;

  my $self    = threads->self;
  my $threadx = threads->object( $tidx );

  threads->yield();

  $_->join foreach threads->list;

  unless (fork) {
    threads->isthread; # intended to be used in a child-init Apache handler
  }

  use forks qw(debug);
  threads->debug( 1 );

  perl -Mforks::BerkeleyDB -Mforks::BerkeleyDB::shared threadapplication

=head1 DESCRIPTION

forks::BerkeleyDB is a drop-in replacement for threads, written as an extension of L<forks>.
The goal of this module is to improve upon the core performance of L<forks> at a level
comparable to native ithreads.

=head1 REQUIRED MODULES

 BerkeleyDB (0.27)
 Devel::Required (0.07)
 forks (0.29)
 Storable (any)
 Tie::Restore (0.11)

=head1 USAGE

See L<forks> for common usage information.

=head1 Environment Variables

C<forks::BerkeleyDB> supports several environment variables.

=head2 TMPDIR

C<forks::BerkeleyDB> requires a temporary directory to store all BerkeleyDB environment
and database files.  This variable is controlled by L<File::Spec>, so the default location
for such files (in the case that TMPDIR is unset) will depend on your platform; e.g.
File::Spec::Unix checks C<$ENV{TMPDIR}> (unless taint is on) and C</tmp>.

=head2 THREADS_BDB_ENV_CHMOD

Sets the default file and directory permissions of BerkeleyDB environment and database files.
If unset, will use the Perl default; e.g. current process (thread) L<umask|perlfunc/"umask">
with defaults for L<mkdir|perlfunc/"mkdir"> and L<open|perlfunc/"open">.

=head2 THREADS_BDB_ENV_CHOWN

Sets the default group owner of BerkeleyDB environment and database files.  If unset,
will use the Perl default; e.g. current process (thread) effective user.

=head2 THREADS_BDB_ENV_CHGRP

Sets the default group owner of BerkeleyDB environment and database files.  If unset,
will use the Perl default; e.g. current process (thread) effective group.

=head1 NOTES

All database files created during runtime
will be automatically purged when the main thread exits.  If you have created a large number
of shared variables, you may experience a slight delay during process exit.  Note that these
files may not be cleaned up if the main thread or process group is terminated using SIGKILL,
although existance of these files after exit should not have an adverse affect on other
currently running or future forks::BerkeleyDB processes.

Testing has been performed against BerkeleyDB 4.3.x.  Full compatibility is expected with
BDB 4.x and likely with 3.x as well.  Unclear if all tie methods are compatible with 2.x.
This module is currently not compatible with BDB 1.x.

=head1 CAVIATS

This module defines CORE::GLOBAL::fork to insure BerkeleyDB resources are correctly managed
before and after a fork occurs.  This insures that processes will be able to safely use
threads->isthread.  You may encounter issues with your application or other modules it uses
also define CORE::GLOBAL::fork.  To work around this, you should modify your CORE::GLOBAL::fork
to support chaining, like the following

	use subs 'fork';
	*_oldfork = \&CORE::GLOBAL::fork;
	sub fork {
		#your code here
		...
		_oldfork->() if ref(*oldfork) eq 'SUB';
	}

=head1 TODO

See the TODO file in the distribution.

=head1 AUTHOR

Eric Rybski <rybskej@yahoo.com>.

=head1 COPYRIGHT

Copyright (c) 2006-2009 Eric Rybski <rybskej@yahoo.com>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<forks>, L<threads>

=cut

1;
