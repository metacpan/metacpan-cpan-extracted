
use strict;
require ExtUtils::MakeMaker;

eval { require 5.008; } or die << 'EOD';
#######################################
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#######################################
EOD

use Config;
die "
#######################################
#	This module requires that your Perl
#	be built with useithreads.
#######################################
"
	unless $Config{useithreads};

print "\nConfiguring Thread::Resource::RWLock...\n
";

my %opts =
    ('NAME' => 'Thread::Resource::RWLock',
     'VERSION_FROM' => 'lib/Thread/Resource/RWLock.pm',
     'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf' }
     );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Dean Arnold, Presicient Corp. (darnold@presicient.com)';
    $opts{'ABSTRACT'} = 'read/write locking for ithreads';
    $opts{'PREREQ_PM'} = {};
}

ExtUtils::MakeMaker::WriteMakefile(%opts);
