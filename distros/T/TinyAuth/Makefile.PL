use strict;
use inc::Module::Install;

name           'TinyAuth';
all_from       'lib/TinyAuth.pm';
requires       'Carp'                     => 0;
requires       'FindBin'                  => 0;
requires       'File::Spec'               => '0.80';
requires       'Scalar::Util'             => '1.15';
requires       'CGI'                      => '3.00';
requires       'CGI::Cookie'              => 0;
requires       'YAML::Tiny'               => '1.12';
requires       'Authen::Htpasswd'         => '0.15';
requires       'Email::MIME'              => '1.859';
requires       'Email::MIME::Creator'     => '1.453';
requires       'Email::Send'              => '2.182';
requires       'Module::CGI::Install'     => '0.04';
build_requires 'Test::More'               => '0.42';
build_requires 'IPC::Run3'                => '0.034';
build_requires 'File::Copy'               => 0;
build_requires 'File::Remove'             => '0.37';
install_script 'script/tinyauth.pl';

# Generate the script
print "Generating script/tinyauth...\n";
if ( generate_tinyauth() ) {
	install_script 'script/tinyauth';
}

WriteAll;
exit(0);





#####################################################################
# Support Functions

# Merge tinyauth.pl and TinyAuth.pm to create the final 'tinyauth' script
sub generate_tinyauth {
	$INC{'File/Spec.pm'} or return 0;

	my $pl  = File::Spec->catfile( 'script', 'tinyauth.pl' );
	my $pm  = File::Spec->catfile( 'lib',    'TinyAuth.pm' );
	my $out = File::Spec->catfile( 'script', 'tinyauth'    );

	# Read in the .pl file
	open( READPL, $pl )   or die "open: $!";
	my @readpl = <READPL> or die "read: $!";
	close( READPL )       or die "close: $!";

	# Read in the .pm file
	open( READPM, $pm )   or die "open: $!";
	my @readpm = <READPM> or die "read: $!";
	close( READPM )       or die "close: $!";

	# Write out the combined script
	open( WRITEOUT, ">$out" ) or die "open: $!";
	print WRITEOUT @readpl    or die "write: #!";
	print WRITEOUT @readpm    or die "write: #!";

	return 1;
}
