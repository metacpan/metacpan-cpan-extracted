use strict;
use warnings;
use Test::More tests => 2;

#use Test::Differences qw(eq_or_diff);
use File::Temp qw(tempdir);
use Path::Tiny qw(path);

my $dir = tempdir( CLEANUP => 1 );

subtest usage => sub {
	plan tests => 1;
	my $out = qx{$^X script/trac2html};
	like $out, qr{Usage: script/trac2html};

	#diag $out;
};

my @cases = qw(
	padre_download_debian
	padre_download_fedora
	padre_download_opensuse
	padre_download_ubuntu
	padre_download_netbsd
	padre_development
	padre_download_mandriva
	padre_download_freebsd
	padre_features
	padre_download_osx
	padre_download_windows
	padre_download_activeperl

	padre_download_cpan
	padre_download_perlbrew
	padre_download_repository
	padre_faq
	padre_wxformbuilder
	padre_wxwidgets
	padre_translationstyle
	padre_wikistart

);

# Ubuntu generates warnings
subtest full_html => sub {
	plan tests => 2 * @cases;
	foreach my $case (@cases) {
		my $out = qx{$^X script/trac2html --infile t/corpus/$case.trac --outfile $dir/$case.html};
		is $out, '', 'out';
		my $html_generated = path("$dir/$case.html")->slurp_utf8;
		my $html_expected  = path("t/expected/${case}_noclass_noid_nospan.html")->slurp_utf8;

		#eq_or_diff $html_generated, $html_expected, 'Mandriva';
		is $html_generated, $html_expected, $case;
	}
};

