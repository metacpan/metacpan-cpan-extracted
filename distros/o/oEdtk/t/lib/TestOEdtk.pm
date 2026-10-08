package TestOEdtk;

# Shared helpers for the oEdtk non-regression test suite.
# This file is pure ASCII on purpose: accented bytes are written as "\xE9",
# never as \x{...} (the oEdtk modules expect ISO-8859 bytes).
use strict;
use warnings;

use Exporter        qw(import);
our @EXPORT_OK = qw(quiet_require memory_dbh reset_sig_handlers mute);

use File::Spec;
use DBI;

# require($module) with the module's load-time banner kept off STDOUT.
# Returns 1 on success, dies with the captured error otherwise.
# The module name is turned into a real path ('oEdtk' => 'oEdtk.pm',
# 'oEdtk::Main' => 'oEdtk/Main.pm') because require() treats a string
# without '::' as a literal filename.
sub quiet_require {
	my ($module) = @_;
	die "quiet_require: missing module name\n" unless defined $module && $module ne '';
	my $file = $module =~ /\.pm$/ ? $module : do { (my $p = $module) =~ s{::}{/}g; "$p.pm" };
	my $ok;
	{
		local *STDOUT;
		open STDOUT, '>', File::Spec->devnull
		    or die "quiet_require: cannot open devnull: $!\n";
		$ok = eval { require $file; 1 };
	}
	die "require $module failed: $@" unless $ok;
	return 1;
}

# In-memory SQLite handle, or undef when DBD::SQLite is not installed.
# FetchHashKeyName mirrors db_connect() so fetchrow_hashref returns upper-case keys.
sub memory_dbh {
	return undef unless eval { require DBD::SQLite; 1 };
	return DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
		{ RaiseError => 1, AutoCommit => 1, PrintError => 0,
		  FetchHashKeyName => 'NAME_uc' });
}

# oEdtk::Tracking installs global $SIG{__WARN__}/$SIG{__DIE__} at BEGIN.
# Neutralize them right after loading it.
sub reset_sig_handlers {
	$SIG{__WARN__} = 'DEFAULT';
	$SIG{__DIE__}  = 'DEFAULT';
	return 1;
}

# Run $code while discarding the oEdtk logger output (STDERR) and any Perl
# warning, so a deliberately noisy call does not clutter the TAP stream.
# Test::More writes to STDOUT, which is left untouched. A die inside $code
# still propagates.
sub mute {
	my ($code) = @_;
	my @ret;
	{
		local *STDERR;
		open STDERR, '>', File::Spec->devnull
		    or die "mute: cannot open devnull: $!\n";
		local $SIG{__WARN__} = sub { };
		@ret = $code->();
	}
	return wantarray ? @ret : $ret[0];
}

1;
