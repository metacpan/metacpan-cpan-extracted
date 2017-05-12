use ExtUtils::MakeMaker;

# It is bad that the default WordNet directories are in two places,
# here and at the beginning of QueryData.pm ($wnHomeUnix and
# $wnHomePC).  These need to be synchronized.  I need to import those
# variables from QueryData.pm.

die "*** Please set the WNHOME environment variable to the location of your\n***   WordNet installation.  QueryData.pm will not work otherwise.\n*** Alternatively, you can make the installation in the default\n***   location, C:\\Program Files\\WordNet\\3.0 on Windows, or /usr/local/WordNet-3.0 on unix.\n" unless exists $ENV{WNHOME} or exists $ENV{WNSEARCHDIR} or -d "C:\\Program Files\\WordNet\\3.0" or -d "/usr/local/WordNet-3.0";

WriteMakefile(
    'dist'      => { 'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz', },
    'NAME'	=> 'WordNet::QueryData',
    'VERSION'	     => '1.49',
);
