use lib qw(inc);
use Devel::CheckLib;

# Prompt the user here for any paths and other configuration

check_lib_or_exit(
    # fill in what you prompted the user for here
    lib => [qw(X11 Xext Xss)]
);


use 5.008;
use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'X11::IdleTime',
    'VERSION_FROM'	=> 'IdleTime.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    'LICENSE'		=> 'perl',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'IdleTime.pm', # retrieve abstract from module
       AUTHOR     => 'Adam Wendt <thelsdj@gmail.com>') : ()),
);
