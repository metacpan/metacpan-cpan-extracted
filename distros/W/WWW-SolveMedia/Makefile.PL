
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'WWW::SolveMedia',
    VERSION_FROM        => 'SolveMedia.pm',
    ABSTRACT_FROM       => 'SolveMedia.pm',
    AUTHOR              => 'Jeff Weisberg <http://www.tcp4me.com/>',
    PREREQ_PM           => { JSON => 0, LWP => 0, Digest::SHA1 => 0, Carp => 0 },
   );
