#!/usr/bin/env perl

# The release checks that are easy to forget: every module carries the same
# $VERSION as the distribution, the topmost entry of Changes is that version
# and has a date, and the README and the POD VERSION sections say the same.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use FindBin qw($Bin);

my $root = File::Spec->catdir($Bin, File::Spec->updir());
my $lib = File::Spec->catdir($root, 'lib');

# Loaded by name, from lib/, and not by the path of the file.  Devel::Cover asks
# Pod::Coverage about every package at the end of the run, and that does
# "require Web::VWF"; a module that was loaded by path has no entry in %INC under
# that name, so the whole file was compiled a second time and every subroutine in
# it reported as "redefined" in the coverage step of CI.
BEGIN { unshift @INC, File::Spec->catdir($Bin, File::Spec->updir(), 'lib') }
require Web::VWF;
my $version = "$Web::VWF::VERSION";

my @modules = glob("$lib/Web/VWF/*.pm $lib/Web/VWF/*/*.pm");
push @modules, "$lib/Web/VWF.pm";
ok(scalar(@modules) > 10, 'found the modules');

sub slurp
{
	my $path = shift;

	open(my $fh, '<', $path) or die "Cannot read $path: $!";
	local $/;
	return scalar <$fh>;
}

foreach my $file (@modules) {
	my $source = slurp($file);
	(my $name = $file) =~ s/^\Q$lib\E.//;

	if($source =~ /our \$VERSION = version->declare\('([^']+)'\)/) {
		is($1, $version, "$name has the distribution's version");
	} else {
		fail("$name declares \$VERSION with version->declare");
	}

	if($source =~ /^=head1 VERSION\s+Version (\S+)/m) {
		is($1, $version, "${name}'s VERSION section agrees");
	}
}

# The first version line, whether or not it has a date: an entry that has not
# been dated yet is the one about to be released, and its version must still be
# the current one - skipping it in favour of the previous release's entry would
# make this test pass at the one moment it matters.  The date is put in when the
# release is made, so it is only required when RELEASE_TESTING says that is now.
my $changes = slurp(File::Spec->catfile($root, 'Changes'));
if($changes =~ /^(\d+\.\d+\.\d+)(?:\t(\S.*))?$/m) {
	my ($top_version, $top_date) = ($1, $2);
	is($top_version, $version, 'the topmost Changes entry is the current version');
	SKIP: {
		skip 'the date is added when the release is made; set RELEASE_TESTING to require it', 1
			unless($ENV{'RELEASE_TESTING'} || defined($top_date));
		like($top_date // '', qr/\b20\d\d\b/, 'and it has a date');
	}
} else {
	fail('Changes has a top entry with a version');
}

# Every module that ships, the example site's too
my @example = glob("$root/example/lib/Web/VWF/*/*.pm");
foreach my $file (@example) {
	my $source = slurp($file);
	(my $name = $file) =~ s/^\Q$root\E.//;
	if($source =~ /our \$VERSION = version->declare\('([^']+)'\)/) {
		is($1, $version, "$name has the distribution's version");
	} else {
		fail("$name declares \$VERSION with version->declare");
	}
}

like(slurp(File::Spec->catfile($root, 'README.md')), qr/^Version \Q$version\E$/m, 'README.md has the current version');

done_testing();
