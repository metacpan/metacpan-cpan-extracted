#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Author tests for the Perl module L<Util::H2O>.

=head1 Author, Copyright, and License

Copyright (c) 2020 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use FindBin ();
use File::Spec::Functions qw/ updir catfile abs2rel catdir /;
use File::Glob 'bsd_glob';

our ($BASEDIR,@PERLFILES);
BEGIN {
	$BASEDIR = catdir($FindBin::Bin,updir);
	@PERLFILES = (
		catfile($BASEDIR,qw/ lib Util H2O.pm /),
		bsd_glob("$BASEDIR/{t,xt}/*.{t,pm}"),
	);
}

use Test::More tests => 3*@PERLFILES + 2;
note explain \@PERLFILES;

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
use Pod::Simple::SimpleTree;
use Capture::Tiny qw/capture_merged/;

subtest 'MANIFEST' => sub { manifest_ok() };

pod_file_ok($_) for @PERLFILES;

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

diag "To run coverage tests:\nperl Makefile.PL && make authorcover && firefox cover_db/coverage.html";

subtest 'code in POD' => sub { plan tests=>9;
	my $verbatim = getverbatim($PERLFILES[0], qr/\b(?:synopsis)\b/i);
	is @$verbatim, 1, 'verbatim block count' or diag explain $verbatim;
	is capture_merged {
		ok eval('{'.<<"END_CODE".';1}'), 'synopsis runs' or diag explain $@; ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
			use warnings; use strict;
			$$verbatim[0];
			is_deeply \$hash, { foo=>'bar', x=>'z', more=>'quz' }, 'synopsis \$hash';
			is_deeply \$struct, { hello => { perl => "world!" } }, 'synopsis \$struct';
			isa_ok \$one, 'Point';
			is_deeply \$one, { x=>1, y=>2 }, 'synopsis \$one';
			isa_ok \$two, 'Point';
			is_deeply \$two, { x=>3, y=>4 }, 'synopsis \$two';
END_CODE
	}, "bar\nworld!\nbeans\n0.927\n", 'output of synopsis correct';
};

sub getverbatim {
	my ($file,$regex) = @_;
	my $tree = Pod::Simple::SimpleTree->new->parse_file($file)->root;
	my ($curhead,@v);
	for my $e (@$tree) {
		next unless ref $e eq 'ARRAY';
		if (defined $curhead) {
			if ($e->[0]=~/^\Q$curhead\E/) { $curhead = undef }
			elsif ($e->[0] eq 'Verbatim') { push @v, $e->[2] }
		}
		elsif ($e->[0]=~/^head\d\b/ && $e->[2]=~$regex)
			{ $curhead = $e->[0] }
	}
	return \@v;
}
