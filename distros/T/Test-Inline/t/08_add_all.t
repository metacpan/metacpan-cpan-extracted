#!/usr/bin/perl

# Adding of all .pm files

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec::Functions ':ALL';
use File::Remove          'remove';
use Test::More tests => 11;
use Test::Inline ();





# Change to the correct directory
chdir catdir( 't', 'data', '06_multifile' ) or die "Failed to change to test directory";

# Create the Test::Inline object
ok( -d 't', 'Output directory exists' );
my $manifest = 't.manifest';
my $Inline = Test::Inline->new(
	output   => 't',
	manifest => $manifest,
	);
isa_ok( $Inline, 'Test::Inline' );

# Add the files
my $rv = $Inline->add_all;
is( $rv, 5, 'Adding lib results in 3 added scripts' );

# Save the file
my $out1 = catfile( 't', 'test_one.t'    );
my $out3 = catfile( 't', 'test_three.t'  );
my $out4 = catfile( 't', 'test_four.t'   );
my $out5 = catfile( 't', 'test_allone.t' );
my $out6 = catfile( 't', 'test_alltwo.t' );

is( $Inline->save, 5, '->save returns 3 as expected' );
ok( -f $out1,     'Found test_one.t'    );
ok( -f $out3,     'Found test_three.t'  );
ok( -f $out4,     'Found test_four.t'   );
ok( -f $out5,     'Found test_allone.t' );
ok( -f $out6,     'Found test_alltwo.t' );
ok( -f $manifest, 'Found manifest file' );

# Check the contents of the manifest
my $manifest_content = <<'END_MANIFEST';
t/test_allone.t
t/test_alltwo.t
t/test_four.t
t/test_one.t
t/test_three.t
END_MANIFEST
if ( $^O eq 'MSWin32' or $^O eq 'cygwin' ) {
	$manifest_content =~ s/\//\\/g;
}
is( $Inline->manifest, $manifest_content, 'manifest contains expected content' );

END {
	remove($out1)     if -f $out1;
	remove($out3)     if -f $out3;
	remove($out4)     if -f $out4;
	remove($out5)     if -f $out5;
	remove($out6)     if -f $out6;
	remove($manifest) if -f $manifest;
}
