package Test::NoShadow;

use strict;
use warnings;

use parent 'Exporter';
our @ISA = qw(Exporter);

use Cwd qw(abs_path);
use File::Find;
use File::Spec;
use Test::Builder;

our @EXPORT_OK = qw(shadowed_ok lib_ok find_shadows);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $TEST = Test::Builder->new();

=head1 NAME

Test::NoShadow - Fail CI when two distributions provide the same Perl package, or when t/ exercises a copy other than the one under test

=head1 VERSION

Version 0.001.0

=cut

our $VERSION = '0.001.0';

my @SKIP_DIRS = qw(.git .github .svn CVS blib _build cover_db node_modules .pc);

=head1 SYNOPSIS

  # In your CI, over a directory of checkouts:
  use Test::More;
  use Test::NoShadow qw(shadowed_ok lib_ok find_shadows);

  shadowed_ok('/home/njh');    # fails if any Perl package is provided by two checkouts

  # In a distribution's own t/, after using its modules:
  use My::Module;
  lib_ok('My::Module');        # fails if My::Module came from anywhere but this distribution

  # Or inspect the data yourself:
  my $shadows = find_shadows('/home/njh');
  foreach my $package (sort keys %$shadows) {
      diag("$package: @{ $shadows->{$package} }");
  }

=head1 DESCRIPTION

C<Test::NoShadow> fails your test suite when two distributions provide the same
Perl package, and when a distribution's tests exercise a copy other than the
one under test (an older installed copy, or a vendored copy in C<t/>).

It was written to police a workspace of many checkouts: pairs such as
C<Schema::Validator> in both C<schema-validator> and C<Schema-Validator>,
or a vendored C<VWF::*> inside another distribution, ship identical package
names, so C<use> can silently load the wrong code.

No other CPAN module checks for the multi-checkout variant; the closest
relative, L<Test::CleanNamespaces>, works on installed distributions only.

Two checks are provided:

=over 4

=item * L</"shadowed_ok"> - a directory of checkouts (or the installed C<@INC>)
must not contain a Perl package in more than one place

=item * L</"lib_ok"> - each named module must have been loaded from the
distribution's own C<lib/> or C<blib/lib>

=back

=head1 FUNCTIONS/METHODS

=head2 shadowed_ok [@dirs, [ \%options ]]

Scans each directory (recursively) for C<.pm> files and extracts the package
names they declare. Passes if no Perl package is declared in more than one
file; otherwise fails, with a diagnostic naming both providers.

With no directories given, C<@INC> is scanned - for example:

  prove -Ilib t/shadow.t

The following options are recognised in the optional hash reference:

=over 4

=item * C<ignore> - array reference of regexps. Each is matched against
both the C<"provider/package"> pair and the file's path; if either matches,
the file is excluded, e.g. C<< { ignore => [qr{^WWW-Scrape-BillionGraves/}, qr{/t/lib/}] } >>.
The file's path is also matched with backslashes converted to forward
slashes, so patterns such as C<qr{/t/lib/}> work on Windows as well

=back

Each top-level directory beneath the scanned directory is treated as a
"provider" (in this workspace, a checkout); files directly beneath the
scanned directory are labelled with their own file name. To check a single
checkout for vendored copies, pass the checkout itself: its top-level
directory (usually C<lib>) becomes the provider, and copies under C<t/> are
reported alongside copies under C<lib>.

Returns true on success, false on failure.

=head2 lib_ok @modules, [ \%options ]

For use in the distribution's own tests, after the modules have been
C<use>d. Passes if each named module was loaded from this distribution's
F<lib> or F<blib/lib>; fails if a module was loaded from anywhere else
(a shadowing copy installed in C<@INC>), or was not loaded at all.

One test is run per module.

The following options are recognised:

=over 4

=item * C<dir> - the root of the distribution, default F<.>

=item * C<lib> - array reference of library directories beneath C<dir>
that count as "the copy under test", default C<[qw(lib blib/lib)]>

=back

Returns true if all modules passed.

=head2 find_shadows $dir, [ \%options ]

The non-TAP interface: returns a hash reference mapping each shadowed
package name to a sorted array reference of the files that declare it.
Accepts the same options as L</"shadowed_ok">.

=cut

# Extract the package names declared in a .pm file
sub _packages_in_file {
	my ($file) = @_;

	open(my $fh, '<', $file) or return [];
	my %packages;
	while (my $line = <$fh>) {
		# Handles "package Foo::Bar;", "package Foo::Bar 1.23;" and "package Foo::Bar {"
		if($line =~ /^\s*package\s+([A-Za-z_][A-Za-z0-9_:]*)(?:\s+v?[\d._]+)?\s*[;{]/) {
			$packages{$1} = 1 unless($1 eq 'main');
		}
	}
	close($fh);

	return [sort keys %packages];
}

# The "provider" of a file is the first directory beneath the root
sub _provider_for {
	my ($root, $file) = @_;

	my $rel = File::Spec->abs2rel($file, $root);
	my @parts = File::Spec->splitdir($rel);

	return $parts[0];
}

# Recursively scan a directory for .pm files.
# Returns { package => { abspath => provider } }
sub _scan {
	my ($root, $opts) = @_;

	my $abs = abs_path($root);
	unless(defined($abs) && -d $abs) {
		die "Test::NoShadow: $root is not a directory";
	}

	my %skip = map { $_ => 1 } (@SKIP_DIRS);
	my %found;

	File::Find::find({
		wanted => sub {
			my $name = $File::Find::name;

			if(-d $name) {
				$File::Find::prune = 1 if($skip{(File::Spec->splitdir($name))[-1]});
				return;
			}
			return unless($name =~ /\.pm$/);

			my $provider = _provider_for($abs, $name);
			my $file = abs_path($name) || $name;
			# Match ignore patterns against the path with backslashes as
			# slashes too, so qr{/t/lib/} works on Windows
			(my $fwd = $file) =~ s{\\}{/}g;

			foreach my $package (@{_packages_in_file($name)}) {
				if($opts->{'ignore'} && grep { "$provider/$package" =~ $_ || $file =~ $_ || $fwd =~ $_ } @{$opts->{'ignore'}}) {
					next;
				}
				$found{$package}{$file} = $provider;
			}
		},
		no_chdir => 1,
	}, $abs);

	return \%found;
}

sub find_shadows {
	my ($dir, @args) = @_;

	unless(defined($dir)) {
		die 'Test::NoShadow: find_shadows needs a directory to scan';
	}

	my %opts;
	if(ref($args[0]) eq 'HASH') {
		%opts = %{$args[0]};
	}

	my $found = _scan($dir, \%opts);

	return {
		map { $_ => [sort keys %{$found->{$_}}] }
		(grep { scalar(keys %{$found->{$_}}) > 1 } (keys %$found))
	};
}

sub shadowed_ok {
	my @args = @_;
	my %opts;
	if(@args && ref($args[-1]) eq 'HASH') {
		%opts = %{pop(@args)};
	}

	my @roots = @args ? @args : (grep { -d $_ } @INC);

	unless(@roots) {
		$TEST->skip('Test::NoShadow: no directories to scan');
		return 0;
	}

	my %found;	# package => { file => provider }
	foreach my $root (@roots) {
		my $scanned = _scan($root, \%opts);
		while (my ($package, $files) = each %$scanned) {
			while (my ($file, $provider) = each %$files) {
				$found{$package}{$file} = $provider;
			}
		}
	}

	my @shadowed = grep { scalar(keys %{$found{$_}}) > 1 } (keys %found);

	unless(@shadowed) {
		$TEST->ok(1, 'No shadowed Perl packages');
		return 1;
	}

	my @messages;
	foreach my $package (sort @shadowed) {
		my $count = scalar(keys %{$found{$package}});
		push @messages, "$package is provided by $count files:";
		push @messages, map { "\t$found{$package}{$_}: $_" } (sort keys %{$found{$package}});
	}

	$TEST->ok(0, scalar(@shadowed) . ' shadowed Perl package(s) found');
	$TEST->diag(join("\n", @messages));

	return 0;
}

sub lib_ok {
	my @modules = @_;
	my %opts;
	if(@modules && ref($modules[-1]) eq 'HASH') {
		%opts = %{pop(@modules)};
	}

	unless(@modules) {
		$TEST->ok(0, 'lib_ok was given modules to check');
		$TEST->diag('lib_ok: no modules specified');
		return 0;
	}

	my $dir = abs_path(exists($opts{'dir'}) ? $opts{'dir'} : '.');
	# abs_path returns undef for directories that do not exist (blib/lib is
	# absent when tests are run from the source tree rather than from a
	# built distribution), so fall back to a normalised absolute path
	my @libs = map {
		my $path = File::Spec->catdir(defined($dir) ? $dir : File::Spec->curdir(), $_);
		abs_path($path) || File::Spec->rel2abs($path);
	} (@{$opts{'lib'} || [qw(lib blib/lib)]});

	my $return = 1;
	foreach my $module (@modules) {
		# %INC is keyed by file path, not by package name
		(my $path = $module) =~ s/::/\//g;
		my $file = $INC{"$path.pm"} || $INC{$module};

		unless(defined($file)) {
			$TEST->ok(0, "$module was loaded from this distribution's lib");
			$TEST->diag("$module has not been loaded; use it before calling lib_ok");
			$return = 0;
			next;
		}

		my $abs = abs_path($file) || File::Spec->rel2abs($file);
		my $ok = 0;
		foreach my $lib (@libs) {
			next unless(defined($lib));
			my $rel = File::Spec->abs2rel($abs, $lib);
			if($rel !~ /^\.\.(?:\/|\\|$)/ && !File::Spec->file_name_is_absolute($rel)) {
				$ok = 1;
				last;
			}
		}

		if($ok) {
			$TEST->ok(1, "$module was loaded from this distribution's lib ($abs)");
		}
		else {
			$TEST->ok(0, "$module was loaded from this distribution's lib");
			$TEST->diag("$module was loaded from $abs, not from " . join(' or ', @libs) . ' - is a shadowing copy installed?');
			$return = 0;
		}
	}

	return $return;
}

1;

__END__

=head1 DIAGNOSTICS

=over 4

=item C<No shadowed Perl packages>

All packages were found in exactly one file.

=item C<Foo::Bar is provided by 2 files:>

Each provider is listed on its own line, indented, as C<provider: file>.

=item C<Foo::Bar was loaded from /path/to/Foo/Bar.pm, not from ... - is a shadowing copy installed?>

The module was loaded from outside this distribution's C<lib> or C<blib/lib>.
An older copy installed in C<@INC>, or a vendored copy in C<t/>, will be
loaded by the test suite instead of the code being tested.

=item C<Foo::Bar has not been loaded; use it before calling lib_ok>

C<lib_ok> can only check modules that are already in C<%INC>.

=item C<Test::NoShadow: $root is not a directory>

The directory passed to L</"shadowed_ok"> or L</"find_shadows"> does not
exist.

=back

=head1 LIMITATIONS

=over 4

=item * Package detection is a line-based heuristic: C<package Foo::Bar;>,
C<package Foo::Bar 1.23;> and C<package Foo::Bar {> are recognised, but a
declaration split across lines, or the string C<package Foo::Bar;> inside a
here-document or data section, will confuse it.

=item * Packages provided only by an XS boot file, without a C<.pm>, are not
seen.

=item * Files under C<t/> that intentionally duplicate a C<lib/> package
(test fixtures) are reported as shadows. Use the C<ignore> option to exclude
them.

=item * Scanning a large C<@INC> reads every C<.pm> file in it and can take
a few seconds.

=back

=head1 SEE ALSO

L<Test::Which> - skip tests if external programs are missing from PATH

L<Test::CleanNamespaces> - check for leftover subroutines in installed distributions

L<Test::Builder> - the test framework this module is built on

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
