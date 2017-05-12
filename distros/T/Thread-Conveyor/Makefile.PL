require 5.008;

# do we have threads?
my $module;
BEGIN {
    $module = "Thread::Conveyor",

    require Config;
    Config->import;

    if ( !$Config{useithreads} ) {
        print "$module requires a version of perl that has threads enabled.\n";
        exit 0;
    }
}

# set up stuff
use ExtUtils::MakeMaker;

# set version and dependency info
eval "use Devel::Required";

# set up
WriteMakefile (
 NAME           => $module,
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'transport of any data-structure',
 VERSION_FROM	=> 'lib/Thread/Conveyor.pm',
 PREREQ_PM	=> { qw(
                    load               0
                    Thread::Serialize  0
                    Thread::Tie        0.09
                   ) },
);
