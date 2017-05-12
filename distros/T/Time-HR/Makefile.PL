use 5.006;
use ExtUtils::MakeMaker;
use Config;
use Carp;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

croak "unsupported OS [$Config{'osname'}] - see README!!!\n"
   unless grep($Config{'osname'}, qw(linux solaris cygwin));
WriteMakefile(
    'NAME'		=> 'Time::HR',
    'VERSION_FROM'	=> 'HR.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'HR.pm', # retrieve abstract from module
       AUTHOR     => 'Alexander Golomshtok <golomshtok_alexander@jpmorgan.com>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'CONFIGURE' => sub {{ 'DEFINE' => 
       '-D_'.uc((grep(/$Config{'osname'}/, qw(solaris linux cygwin)))[0]),
       'LIBS' => $Config{'osname'} eq 'linux' ? ['-lrt'] : []
       }}
);
