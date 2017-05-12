use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::BF2Player',
    VERSION_FROM      => 'lib/WWW/BF2Player.pm', # finds $VERSION
    PREREQ_PM         => {
				'XML::Simple' => '0',
				'Data::Dumper' => '0',
				'LWP::Simple' => '0',
				'Hey::Common' => '0.01',
				'Hey::Cache' => '0.01',
			},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/BF2Player.pm', # retrieve abstract from module
       AUTHOR         => 'Dusty Wilson <www-bf2player-module@dusty.hey.nu>') : ()),
);
