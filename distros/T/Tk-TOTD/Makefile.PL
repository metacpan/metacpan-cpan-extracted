use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::TOTD',
    VERSION_FROM      => 'lib/Tk/TOTD.pm', # finds $VERSION
    PREREQ_PM         => {
        'Tk' => 0,
        'Tk::ROText' => 0,
        'Tk::DialogBox' => 0,
        'Tk::Widget' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/TOTD.pm', # retrieve abstract from module
       AUTHOR         => 'Noah Petherbridge <kirsle@cpan.org>') : ()),
);
