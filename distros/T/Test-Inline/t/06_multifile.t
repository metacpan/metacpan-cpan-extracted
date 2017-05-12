#!/usr/bin/perl

# Tests the parsing and generation of multiple files

# This test is also used to test the readonly param

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec::Functions ':ALL';
use File::Remove          'remove';
use Test::More tests => 23;
use Test::Inline ();

# Are we the root user
use constant ROOT => ! $<;





# Change to the correct directory
chdir catdir( 't', 'data', '06_multifile' )
	or die "Failed to change to test directory";

# Create the Test::Inline object
ok( -d 't', 'Output directory exists' );
my $manifest = 't.manifest';
my $Inline = Test::Inline->new(
	output   => 't',
	readonly => 1,
	manifest => $manifest,
	);
isa_ok( $Inline, 'Test::Inline' );

# Add the files
my $one   = catfile( 'lib', 'Test', 'One.pm'   );
my $two   = catfile( 'lib', 'Test', 'Two.pm'   );
my $three = catfile( 'lib', 'Test', 'Three.pm' );
ok( -f $one,   'One.pm exists'   );
ok( -f $two,   'Two.pm exists'   );
ok( -f $three, 'Three.pm exists' );
is( $Inline->add($one),   1, "Added $one, found 1 class"     );
is( $Inline->add($two),   0, "Added $two, found 0 classes"   );
is( $Inline->add($three), 2, "Added $three, found 2 classes" );

# Save the file
my $out1 = catfile( 't', 'test_one.t'   );
my $out3 = catfile( 't', 'test_three.t' );
my $out4 = catfile( 't', 'test_four.t'  );
is( $Inline->save, 3, '->save returns 3 as expected' );
ok(   -f $out1,     'Found test_one.t'    );
ok(   -r $out1,     'Found test_one.t'    );
SKIP: {
	skip("Skipping readonly test for root", 1) if ROOT;
	ok( ! -w $out1,     'Found test_one.t'    );
}
ok(   -f $out3,     'Found test_three.t'  );
ok(   -r $out3,     'Found test_three.t'  );
SKIP: {
	skip("Skipping readonly test for root", 1) if ROOT;
	ok( ! -w $out3,     'Found test_three.t'  );
}
ok(   -f $out4,     'Found test_four.t'   );
ok(   -r $out4,     'Found test_four.t'   );
SKIP: {
	skip("Skipping readonly test for root", 1) if ROOT;
	ok( ! -w $out4,     'Found test_four.t'   );
}
ok(   -f $manifest, 'Found manifest file' );
ok(   -r $manifest, 'Found manifest file' );
SKIP: {
	skip("Skipping readonly test for root", 1) if ROOT;
	ok( ! -w $manifest, 'Found manifest file' );
}

# Run the install again, overwriting the readonly files
is( $Inline->save, 3, '->save returns 3 as expected on overwrite' );

# Check the contents of the manifest
my $manifest_content = <<'END_MANIFEST';
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
	remove($manifest) if -f $manifest;
}
