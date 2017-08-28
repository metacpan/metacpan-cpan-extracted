# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use ExtUtils::MakeMaker;

use Config;
use English;

# We needed perl >= 5.6.0 (use warnings...) but trying to do without
#use 5.006;

WriteMakefile(
    'NAME'              => 'W3C::LogValidator',
    'DISTNAME'          => 'W3C-LogValidator',
    'AUTHOR'            => 'Olivier Thereaux <ot@w3.org>',
    'ABSTRACT'		=> 'The W3C Log Validator',
    'VERSION'      	=> '1.5', 
    'PREREQ_PM'         => { 'Exporter'       => 0,
                             'Sys::Hostname'  => 0,
                             'LWP::UserAgent' => 0,
                             'URI::Escape'    => 0,
			     'Config::General' => 0,
			     'File::Temp' => 0,
			     'DB_File' => 0,
			     'Mail::Sendmail' => 0,
                           },
    'EXE_FILES'         => [ 'bin/logprocess.pl' ],
    'dist'              => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
);
