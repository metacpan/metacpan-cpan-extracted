use 5.00503;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Vonage::Click2Call',
    VERSION_FROM      => 'lib/Vonage/Click2Call.pm',
    PREREQ_PM         => {
          LWP::UserAgent =>  1.0,
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Vonage/Click2Call.pm',
       AUTHOR         => 'Matt Sanford <mzsanford@cpan.org>') : ()),
);
