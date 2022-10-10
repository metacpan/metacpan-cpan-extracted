use 5.008000;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME              => 'SMS::Send::IN::NICSMS',
              VERSION_FROM      => 'lib/SMS/Send/IN/NICSMS.pm', 
              PREREQ_PM         => { 'SMS::Send::Driver'   => 0,
                                     'LWP::UserAgent'      => 0,
                                },
              TEST_REQUIRES     => {
                                     'Test::More'          => 0,
                                     'Test::Exception'     => 0,
                                },
              ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM  => 'lib/SMS/Send/IN/NICSMS.pm', 
                AUTHOR         => 'Indranil Das Gupta <indradg@l2c2.co.in>') : ()),
	     'LICENSE'  => 'perl_5',
);
