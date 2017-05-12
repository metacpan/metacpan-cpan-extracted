use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Hotmail',
    'VERSION_FROM'	=> 'Hotmail.pm', # finds $VERSION
    'PREREQ_PM'		=> {
         WWW::Mechanize => 0,
         Mail::Audit    => 2.1,
         Crypt::SSLeay  => 0,
		 # Mail::Audit does this, but for some reason I
		 # got an automated error.
		 Mail::Internet => 0,
    },
	'dist'         => {
		'SUFFIX'       => ".gz",
		'DIST_DEFAULT' => 'all tardist',
		'COMPRESS'     => "gzip -9vf",
	},
    ($] >= 5.005 ?  
       (AUTHOR     => 'David Davis <xantus@cpan.org>') : ()),
);
