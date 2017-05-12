#line 1
package File::Which;

use 5.004;
use strict;
use Exporter   ();
use File::Spec ();

use vars qw{$VERSION @ISA @EXPORT @EXPORT_OK};
BEGIN {
	$VERSION   = '1.09';
	@ISA       = 'Exporter';
	@EXPORT    = 'which';
	@EXPORT_OK = 'where';
}

use constant IS_VMS => ($^O eq 'VMS');
use constant IS_MAC => ($^O eq 'MacOS');
use constant IS_DOS => ($^O eq 'MSWin32' or $^O eq 'dos' or $^O eq 'os2');

# For Win32 systems, stores the extensions used for
# executable files
# For others, the empty string is used
# because 'perl' . '' eq 'perl' => easier
my @PATHEXT = ('');
if ( IS_DOS ) {
	# WinNT. PATHEXT might be set on Cygwin, but not used.
	if ( $ENV{PATHEXT} ) {
		push @PATHEXT, split ';', $ENV{PATHEXT};
	} else {
		# Win9X or other: doesn't have PATHEXT, so needs hardcoded.
		push @PATHEXT, qw{.com .exe .bat};
	}
} elsif ( IS_VMS ) {
	push @PATHEXT, qw{.exe .com};
}

sub which {
	my ($exec) = @_;

	return undef unless $exec;

	my $all = wantarray;
	my @results = ();

	# check for aliases first
	if ( IS_VMS ) {
		my $symbol = `SHOW SYMBOL $exec`;
		chomp($symbol);
		unless ( $? ) {
			return $symbol unless $all;
			push @results, $symbol;
		}
	}
	if ( IS_MAC ) {
		my @aliases = split /\,/, $ENV{Aliases};
		foreach my $alias ( @aliases ) {
			# This has not been tested!!
			# PPT which says MPW-Perl cannot resolve `Alias $alias`,
			# let's just hope it's fixed
			if ( lc($alias) eq lc($exec) ) {
				chomp(my $file = `Alias $alias`);
				last unless $file;  # if it failed, just go on the normal way
				return $file unless $all;
				push @results, $file;
				# we can stop this loop as if it finds more aliases matching,
				# it'll just be the same result anyway
				last;
			}
		}
	}

	my @path = File::Spec->path;
	if ( IS_DOS or IS_VMS or IS_MAC ) {
		unshift @path, File::Spec->curdir;
	}

	foreach my $base ( map { File::Spec->catfile($_, $exec) } @path ) {
		for my $ext ( @PATHEXT ) {
			my $file = $base.$ext;

			# We don't want dirs (as they are -x)
			next if -d $file;

			if (
				# Executable, normal case
				-x _
				or (
					# MacOS doesn't mark as executable so we check -e
					IS_MAC
					||
					(
						IS_DOS
						and
						grep {
							$file =~ /$_\z/i
						} @PATHEXT[1..$#PATHEXT]
					)
					# DOSish systems don't pass -x on
					# non-exe/bat/com files. so we check -e.
					# However, we don't want to pass -e on files
					# that aren't in PATHEXT, like README.
					and -e _
				)
			) {
				return $file unless $all;
				push @results, $file;
			}
		}
	}

	if ( $all ) {
		return @results;
	} else {
		return undef;
	}
}

sub where {
	# force wantarray
	my @res = which($_[0]);
	return @res;
}

1;

__END__

#line 254
