#!/usr/bin/perl
#
# Smoke-load every Perl module shipped under lib/, plus a couple of
# release/API identity checks.
#
# Each module is required in an isolated subprocess so that load-time side
# effects (banners on STDOUT, global $SIG handlers installed by Tracking or
# FatalsToEmail, ...) cannot leak between modules or into the TAP stream.
# A module that fails to load is reported with its captured diagnostics.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Find qw(find);
use File::Spec;
use File::Temp qw(tempfile);
use TestOEdtk qw(quiet_require);

my $lib = File::Spec->rel2abs("$FindBin::Bin/../lib");

# require($module) inside a subprocess, with STDOUT sent to devnull and
# STDERR captured. Returns (ok, diagnostics).
sub module_loads {
	my ($libdir, $module) = @_;
	my ($errfh, $errfile) = tempfile('oedtk_load_XXXXXX', UNLINK => 1);
	my ($devnull, $rc);
	open($devnull, '>', File::Spec->devnull) or die "devnull: $!";
	{
		local *STDOUT;
		local *STDERR;
		open STDOUT, '>&', $devnull or die "redirect STDOUT: $!";
		open STDERR, '>&', $errfh    or die "redirect STDERR: $!";
		$rc = system($^X, "-I$libdir", '-e', "require $module");
	}
	close($devnull);
	close($errfh);
	open(my $rd, '<', $errfile) or die "read $errfile: $!";
	local $/;
	my $err = <$rd>;
	close($rd);
	return ($rc == 0, $err // '');
}

# Collect every module name from its lib-relative path (lib/oEdtk/Main.pm
# => oEdtk::Main, lib/oEdtk.pm => oEdtk).
my @modules;
find(
	{
		wanted   => sub {
			return unless /\.pm$/;
			my $rel = File::Spec->abs2rel($File::Find::name, $lib);
			$rel =~ s{\.pm$}{} or return;
			push @modules, join('::', File::Spec->splitdir($rel));
		},
		no_chdir => 1,
	},
	$lib,
);
@modules = sort @modules;

for my $module (@modules) {
	my ($ok, $err) = module_loads($lib, $module);
	ok($ok, "require $module");
	diag("$module failed to load:\n$err") unless $ok;
}

# The release banner helper lives in oEdtk.pm (banner itself suppressed by
# quiet_require).
quiet_require('oEdtk');
like(
	oEdtk::oEdtk_release(),
	qr/^\(c\) 2005-\d{4} oedtk\@free\.fr - oEdtk v[\d.]+\n$/,
	'oEdtk_release() returns the version banner',
);
cmp_ok(scalar(@modules), '>=', 30, 'found at least 30 modules under lib/');

quiet_require('oEdtk::Util');
ok(oEdtk::Util->can('_uc_hash_keys'), 'oEdtk::Util exposes _uc_hash_keys');

done_testing();
