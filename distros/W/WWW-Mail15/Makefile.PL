use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Mail15',
    'VERSION_FROM'	=> 'Mail15.pm', # finds $VERSION
    'PREREQ_PM'		=> {
         WWW::Mechanize => 0,
         Mail::Audit    => 2.1,
         Crypt::SSLeay  => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?  
       (AUTHOR     => 'Sir Reflog <reflog@mail15.com>') : ()),
);
