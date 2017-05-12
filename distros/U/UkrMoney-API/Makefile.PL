
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'UkrMoney::API',
    VERSION_FROM      => 'lib/UkrMoney/API.pm', 
    PREREQ_PM         => {'XML::Simple' => 0,
                          'LWP::Simple' => 0}, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/UkrMoney/API.pm', 
       AUTHOR         => 'Dmitry Nikolayev <dmitry@cpan.org>') : ()),
);
