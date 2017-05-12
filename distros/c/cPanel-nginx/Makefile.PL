use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'cPanel::nginx',
    VERSION_FROM      => 'lib/cPanel/nginx.pm', 
    PREREQ_PM         => {
				'LWP::UserAgent'	=> '0'
			}, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/cPanel/nginx.pm', 
       AUTHOR         => 'Aleksey Vaganov <avaganov@idivision.ru>') : ()),
);
