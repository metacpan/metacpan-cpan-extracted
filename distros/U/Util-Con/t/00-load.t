#!/usr/bin/env perl
# Compile-load the module, confirm every advertised symbol is exported, and
# check what `use Util::Con` installs besides: p() and np(), and autodie.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Capture::Tiny 'capture';
use File::Spec;
use File::Temp 'tempdir';

BEGIN { use_ok('Util::Con') or BAIL_OUT('Util::Con failed to compile') }

my @exported = qw(
	dir execute file2string format_commas
	json_file_to_ref random_key random_value ref_to_json_file
	st structure
);

for my $sym (@exported) {
	ok( main->can($sym), "exported: $sym" );
}

# @EXPORT and this list must not drift apart in either direction.
is_deeply( [sort @Util::Con::EXPORT], [sort @exported],
	'@EXPORT matches the list checked above' );

# p() and np() are installed into the caller's package by Util::Con as lazy
# stubs that pull in DDP on first call, so scripts get them without a `use DDP`
# of their own.
ok( main->can('p'),  'p() is available in main::' );
ok( main->can('np'), 'np() is available in main::' );
ok( !$INC{'DDP.pm'}, 'DDP is not loaded until p()/np() is actually called' );

# A package other than main gets them too, and a p() it already has is kept.
# Util.pm, which this module was before it was Util::Con, compiled its stubs
# into main:: alone, whoever loaded it.
{
	package Some::Caller;
	sub p { return 'own p' }
	Util::Con->import;
}
ok( Some::Caller->can('np'), 'np() is installed into a package other than main' );
is( Some::Caller::p(), 'own p', 'a p() the caller already had is not replaced' );

{
	my @data = ('first', 'second');
	my ($out) = capture { main::p(@data) };
	like( $out, qr/first.*second/s, 'the p() stub prints through DDP on first call' );
	ok( $INC{'DDP.pm'}, 'calling p() loaded DDP' );
}

# autodie reaches the file that said `use Util::Con`: a bare open of a missing
# file dies there rather than returning false.  It is checked in a script of
# its own because autodie is lexical, and the `use` above is compiled by
# use_ok() inside a string eval, so this file is outside its scope.  The
# script is run with the list form of system() and given its paths in @ARGV,
# so no shell ever reads them.
{
	my $tmp = tempdir(CLEANUP => 1);
	my $script  = File::Spec->catfile($tmp, 'autodie.pl');
	my $missing = File::Spec->catfile($tmp, 'missing.txt');
	open my $fh, '>', $script or die "$script: $!";
	print $fh "use Util::Con;\nopen my \$fh, '<', \$ARGV[0];\nprint qq{open returned\\n};\n";
	close $fh or die "$script: $!";
	my ($out, $err, $exit) = capture {
		system($^X, (map { "-I$_" } grep { !ref } @INC), $script, $missing);
	};
	isnt( $exit, 0, 'autodie is in effect in the file that used Util::Con' );
	like( $err, qr/\Q$missing\E/, 'the autodie error names the file' );
	unlike( $out, qr/open returned/, 'the open did not return' );
}

done_testing;
