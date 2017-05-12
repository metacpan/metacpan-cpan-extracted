package Test::Text::FileTree;
# Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Test::More tests => 7;
use File::Slurp;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT = 'run_tests';

BEGIN { use_ok('Text::FileTree') }

sub _fh_file {
	my $ft = shift;
	my $filename = shift;
	my $ref = shift;

	open my $fh, '<', $filename or
		die "Could not open '$filename': $!";

	is_deeply($ft->from_fh($fh), $ref, 'from_fh: file');
}

sub _fh_pipe {
	my $ft = shift;
	my $cmd = shift;
	my $ref = shift;

	SKIP: {
		skip "pipe open is not available on $^O", 1 if $^O eq 'MSWin32';
		open my $fh, '-|', @$cmd or
			die "Could not open pipe: $!";

		is_deeply($ft->from_fh($fh), $ref, 'from_fh: pipe');
	}
}

sub run_tests {
	my $reffile = shift;
	my $ref = shift;
	my $new_opts = shift;

	my $str = read_file($reffile, err_mode => 'carp');
	my @arr = split /\n/, $str;

	my $ft = new_ok('Text::FileTree', $new_opts);
	is_deeply($ft->parse($str), $ref, 'parse: multiline string');
	is_deeply($ft->parse(@arr), $ref, 'parse: array');
	is_deeply(
		$ft->from_file( $reffile ), $ref,
		'from_file'
	);

	_fh_file($ft, $reffile, $ref);

	# This should be portable, as perl is needed to run this,
	# and File::Slurp is already a dependency.
	_fh_pipe($ft, [
		'perl',
		'-MFile::Slurp',
		'-e',
		'print read_file($ARGV[0])',
		$reffile,
	], $ref);
}

1;
