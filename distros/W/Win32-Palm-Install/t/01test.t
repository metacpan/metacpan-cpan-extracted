use strict;
use Test::More tests => 2;
use File::Spec;
use Win32::Palm::Install::Testconfig;

BEGIN {
	use_ok( 'Win32::Palm::Install' );
}

my $install = Win32::Palm::Install->new;
isa_ok( $install, 'Win32::Palm::Install' );

my $palmuser = $Win32::Palm::Install::Testconfig::palmuser;

if ($palmuser ne "") {
	my $file = File::Spec->catfile( 't', 'Win32Install.prc' );
	$install->install( $file, $palmuser );
}
