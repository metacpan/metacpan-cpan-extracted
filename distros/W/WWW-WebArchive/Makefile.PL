
######################################################################
## File: $Id: Makefile.PL 3400 2005-01-07 13:03:36Z spadkins $
######################################################################

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @programs = (
    "bin/webarchive",
);

%opts = (
    'NAME'         => 'WWW-WebArchive',
    'DISTNAME'     => 'WWW-WebArchive',
    'VERSION_FROM' => 'lib/WWW/WebArchive.pm',
    'EXE_FILES'    => [ @programs ],
    'PREREQ_PM'    => {
        "App::Options"   => 0.01,  # command line processing
        "App::Trace"     => 0.01,  # debugging
        "WWW::Mechanize" => 0.01,  # control page retrieval
    },
    'dist'         => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
                       'ZIP'=>'/usr/bin/zip', 'ZIPFLAGS'=>'-rl'},
);

WriteMakefile(%opts);

