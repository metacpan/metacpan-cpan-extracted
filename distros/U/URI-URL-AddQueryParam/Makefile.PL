use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'URI::URL::AddQueryParam',
    VERSION_FROM      => 'lib/URI/URL/AddQueryParam.pm', 
    PREREQ_PM         => {
							'URI' => 0,
							'URI::URL' => 0,
							'URI::QueryParam' => 0,
							}, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/URI/URL/AddQueryParam.pm', 
       AUTHOR         => 'Chen Gang <yikuyiku.com@gmail.com>') : ()),
);
