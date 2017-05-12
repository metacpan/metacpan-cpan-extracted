use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Offline::Toolkit',
    VERSION_FROM      => 'lib/WWW/Offline/Toolkit.pm',
    PREREQ_PM         => {
		'Data::Dumper' => '1.0',
		'Parse::RecDescent' => '1.0',
		'File::Find' => '1.0',
	},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/Offline/Toolkit.pm',
       AUTHOR         => 'Tom Kirchner <tom@tkirchner.com>') : ()),
);
