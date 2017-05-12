use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Word::Segmenter::Chinese::Lite',
    VERSION_FROM      => 'lib/Word/Segmenter/Chinese/Lite.pm', 
    PREREQ_PM         => { 
							Encode => 0,
							JSON::XS => 0,
						}, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Word/Segmenter/Chinese/Lite.pm', 
       AUTHOR         => 'Chen Gang <yikuyiku.com@gmail.com>') : ()),
);
