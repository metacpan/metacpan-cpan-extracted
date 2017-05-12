#!perl -w

require 5.008002;
use strict;
use ExtUtils::MakeMaker;

print <<MESSAGE;

Starting XUL-Node installation.

MESSAGE

my $NAME                 = 'XUL::Node';
my $MODULE               = 'lib/XUL/Node.pm';
my $SERVER_ROOT_DIR      = 'xul-node';
my $BLIB_SERVER_ROOT_DIR = "blib/$SERVER_ROOT_DIR";
my $SERVER_SCRIPT_NAME   = 'xul-node-server';
my $SERVER_SCRIPT        = "bin/$SERVER_SCRIPT_NAME";

my $PORT = prompt("\nEnter port for $SERVER_SCRIPT_NAME:\n", 8077);
my $INSTALL_DIR = prompt(
	"\nWhere do you want to install the server root directory?\n",
	$^O eq 'MSWin32'?
		"C:/perl/$SERVER_ROOT_DIR":
		"/usr/local/$SERVER_ROOT_DIR"
);
print "\n=> Writing Makefile... (look here for missing requirements)\n";

WriteMakefile(
	NAME          => $NAME,
	VERSION_FROM  => $MODULE,
	ABSTRACT      => 'server-side XUL for Perl',
	AUTHOR        => 'Ran Eilam <eilara@cpan.org>',
	dist          => {COMPRESS => 'gzip --force --best'},
	PL_FILES      => {"$SERVER_SCRIPT.PL" => $SERVER_SCRIPT},
	EXE_FILES     => [$SERVER_SCRIPT],
	clean         => {FILES => "$SERVER_SCRIPT"},
	PREREQ_PM     => {
		'XML::Parser'                        => '2.34',
		'Digest::MD5'                        => '2.3',
		'Scalar::Util'                       => '1.13',
		'LWP'                                => '5.75',
		'MIME::Types'                        => '1.13',
		'POE'                                => '0.2802',
		'POE::Component::Server::HTTPServer' => '0.9',
		'Aspect'                             => '0.12',
	},
);

print "=> Done with writing Makefile.\n";

print <<FINAL_MESSAGE;

When installation is complete (after the 'make install' stage), you can
start the XUL-Node server using the command:

  xul-node-server

And access the examples by pointing Firefox at the default page:

  firefox http://localhost${\( $PORT == 80? '': ":$PORT" )}

FINAL_MESSAGE

package MY;

# add targets for building server, and installing it
sub postamble {qq[
build_server :: pm_to_blib
	\@\$(ECHO) "building server root directory in blib..."
	\@\$(MOD_INSTALL) $SERVER_ROOT_DIR $BLIB_SERVER_ROOT_DIR

install_server :: build_server
	\@\$(ECHO) "installing server root directory from blib to $INSTALL_DIR..."
	\@\$(MOD_INSTALL) $BLIB_SERVER_ROOT_DIR $INSTALL_DIR
	\@\$(RM_F) $SERVER_SCRIPT
]}

# add install_server target to install as dependency
sub install {
	my $class = shift;
	my $basic = $class->SUPER::install(@_);
	my $add   = 'install_server';
	$basic    =~ s/^(install\s+::\s+.*)$/$1 $add/m;
	$basic;
}

# add port and install_dir to script generator command line args
sub processPL {
	my $inherited = shift->SUPER::processPL(@_);
	$inherited =~ s
		|($SERVER_SCRIPT\.PL $SERVER_SCRIPT)|$1 $PORT $INSTALL_DIR|;
	$inherited;
}
