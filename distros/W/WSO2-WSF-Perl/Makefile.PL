use ExtUtils::MakeMaker;
use Getopt::Long;

my $libpath;
my $incpath;

my @replacement_args;
my $WSFC_DIR = "/opt/wso2/wsf_c";

sub validate_versions {
    $home = shift;

    # crapping out if libs cannot be found
    -e "$home/lib" || die "Can't find the lib folder, please reinstall WSF/C";

    # crapping out if the WSF/C version differ
    -e "$home/include/axis2-1.4.0" || die "WSF/Perl 1.1 require WSF/C version 1.3, please install WSF/C 1.3";
}

# Tries to get WSFC_HOME first from the standard installation folder.
# If that's unseccessful checks the environment variable.  If that also
# fails try to get it from ARGV.  Crap out if everything fails, cannot
# continue without WSF/C.
if ( -e $WSFC_DIR ) {
    # ah, looks like we have a standard installation of WSF/C
    validate_versions( $WSFC_DIR );

    $libpath = "$WSFC_DIR/lib";
    $incpath = "-I$WSFC_DIR/include/axis2-1.4.0 -I$WSFC_DIR/include/rampart-1.2.0";

} elsif ( defined $ENV{WSFC_HOME} ) {
    # environment variable is set, let's try to get the dir from there
    validate_versions( $ENV{WSFC_HOME} );

    $libpath = $ENV{WSFC_HOME} . "/lib";
    $incpath = "-I" . $ENV{WSFC_HOME} . "/include/axis2-1.4.0 " .
               "-I" . $ENV{WSFC_HOME} . "/include/rampart-1.2.0";
} else {
    # let's see we can get the folder from ARGV
    if ( defined @ARGV ) {
	my $wsfc_home;
	GetOptions( "with-wsfc=s", \$wsfc_home );
	if ( defined $wsfc_home ) {
	    validate_versions( $wsfc_home );

	    $libpath = "$wsfc_home/lib";
	    $incpath = "-I$wsfc_home/include/axis2-1.4.0 -I$wsfc_home/include/rampart-1.2.0";
	} else {
	     die "Please install WSF/C and then retry the WSF/Perl installation";
	}
    } else {
	die "Please install WSF/C and then retry the WSF/Perl installation";
    }
}

$libs = "-L$libpath " if( defined( $libpath ) );

$libs .= "-laxutil -laxis2_minizip -lperl -laxis2_parser -laxis2_libxml2 " .
         "-laxis2_axiom -laxis2_engine -laxis2_http_common " .
         "-laxis2_http_sender -laxis2_http_receiver -lneethi_util -lneethi " .
         "-laxis2_parser -lhtpwcb -lomopenssl -lomxmlsec -lsaml " .
         "-lsandesha2_client -lmod_rampart";

my @options;

push @options, ( LIBS => [ $libs ], );

push @options, ( INC => "$incpath", ) if( defined( $incpath ) );

WriteMakefile(
        'NAME'    => 'WSO2::WSF::C',
	'AUTHOR'  => 'WSO2 WSF/Perl Team',
	'OBJECT'  => 'WSFC_wrap.o',
	@options
);
