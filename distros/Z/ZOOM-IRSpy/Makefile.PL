
use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $yazver = `yaz-config --version`;
if (!$yazver) {
    die qq[
ERROR: Unable to call script: yaz-config
If you are using a YAZ installation from the Debian package "yaz", you
will also need to install "libyaz-dev" in order to build this module.
];
}

chomp($yazver);
# 2.1.53 is the first version with ZOOM-C fixed to properly support
# reconnection in asynchronous mode.
check_version($yazver, "2.1.53");

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ZOOM::IRSpy',
    VERSION_FROM      => 'lib/ZOOM/IRSpy.pm', # finds $VERSION
    PREREQ_PM         => {
	"Net::Z3950::ZOOM" => 1.19,
	"XML::LibXML::XPathContext" => 0.07, # For Web UI
        "XML::LibXML" => 1.58,
        "XML::LibXSLT" => 1.57,
	"URI::Escape" => 3.28, # For Web UI
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ZOOM/IRSpy.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@indexdata.com>') : ()),
    EXE_FILES    => [ 'bin/irspy.pl', 'bin/irspy-dump.pl' ],
);


sub check_version {
    my($got, $want) = @_;

    my($gmajor, $gminor, $gtrivial) = ($got =~ /(\d+)\.(\d+)\.(\d+)/);
    my($wmajor, $wminor, $wtrivial) = ($want =~ /(\d+)\.(\d+)\.(\d+)/);
    if (($gmajor < $wmajor) ||
	($gmajor == $wmajor && $gminor < $wminor) ||
	($gmajor == $wmajor && $gminor == $wminor && $gtrivial < $wtrivial)) {
	print <<__EOT__;
*** ERROR!
ZOOM-Perl requires at least version $want of YAZ,
but is currently you only have version $got.
__EOT__
	exit 1;
    }
}
