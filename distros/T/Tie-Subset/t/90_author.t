#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl modules L<Tie::Subset::Array> and L<Tie::Subset::Hash>.

=head1 Author, Copyright, and License

Copyright (c) 2018-2023 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use Tie_Subset_Testlib;

use File::Spec::Functions qw/ catfile catdir abs2rel updir /;
use File::Glob 'bsd_glob';

our ($BASEDIR,@PODFILES,@PERLFILES);
BEGIN {
	$BASEDIR = catdir($FindBin::Bin,updir);
	@PERLFILES = (
		catfile($BASEDIR,qw/ lib Tie Subset.pm /),
		catfile($BASEDIR,qw/ lib Tie Subset Array.pm /),
		catfile($BASEDIR,qw/ lib Tie Subset Hash.pm /),
		catfile($BASEDIR,qw/ lib Tie Subset Hash Masked.pm /),
		bsd_glob("$BASEDIR/t/*.{t,pm}"),
	);
	@PODFILES = (
		catfile($BASEDIR,qw/ lib Tie Subset.pm /),
		catfile($BASEDIR,qw/ lib Tie Subset Array.pm /),
		catfile($BASEDIR,qw/ lib Tie Subset Hash.pm /),
		catfile($BASEDIR,qw/ lib Tie Subset Hash Masked.pm /),
	);
}

use Test::More $AUTHOR_TESTS ? ( tests => @PODFILES + 2*@PERLFILES + 1 )
	: (skip_all=>'author tests (set $ENV{TIE_SUBSET_AUTHOR_TESTS} to enable)');

use File::Temp qw/tempfile/;
my $critfn;
BEGIN {
	my $fh; ($fh,$critfn) = tempfile UNLINK=>1;
	print $fh <<'END_CRITIC';
severity = 3
verbose = 9
[ErrorHandling::RequireCarping]
severity = 4
[RegularExpressions::RequireExtendedFormatting]
severity = 2
[Variables::ProhibitReusedNames]
severity = 4
END_CRITIC
	close $fh;
}
use Test::Perl::Critic -profile=>$critfn;
use Test::MinimumVersion;
use Test::Pod;
use Test::DistManifest;

subtest 'MANIFEST' => sub { manifest_ok() };

for my $podfile (@PODFILES) {
	pod_file_ok($podfile);
}

my @tasks;
for my $file (@PERLFILES) {
	critic_ok($file);
	minimum_version_ok($file, '5.006');
	open my $fh, '<', $file or die "$file: $!";  ## no critic (RequireCarping)
	while (<$fh>) {
		s/\A\s+|\s+\z//g;
		push @tasks, [abs2rel($file,$BASEDIR), $., $_] if /TO.?DO/i;
	}
	close $fh;
}
diag "To-","Do Report: ", 0+@tasks, " To-","Dos found";
diag "### TO","DOs ###" if @tasks;
diag "$$_[0]:$$_[1]: $$_[2]" for @tasks;
diag "### ###" if @tasks;

diag "To run coverage tests:\nperl Makefile.PL && make authorcover && firefox cover_db/coverage.html\n"
	. "To clean up after: git clean -dxf";

