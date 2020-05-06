require 5.008001;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

if ($ENV{FORKS_FOR_THREADS}) {
	eval {
		require forks; forks->import;
		require forks::shared; forks::shared->import;
	};
}

use threads;
use threads::shared;

WriteMakefile (
 NAME		=> "Thread::Bless",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'make blessed objects thread-aware',
 VERSION_FROM	=> 'lib/Thread/Bless.pm',
 PREREQ_PM	=> {
		    'Scalar::Util'	=> '1.08', # need refaddr()
                   },
);
