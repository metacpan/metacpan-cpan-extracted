
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$Test::Harness::verbose = 1;
WriteMakefile(
	      'NAME'  => 'Toolbox',
	      
	      'PM'    =>  {
		  	'CryptOTP.pm'          => '$(INST_LIBDIR)/Toolbox/CryptOTP.pm',
		  	'Simple.pm' 	 	   => '$(INST_LIBDIR)/Toolbox/Simple.pm'
	      },
	      

	      
          'PREREQ_PM' => {
                  'IO::File'      => 0,
                  'MIME::Base64'  => 0,
                  'Socket'        => 0,
                  'Digest::MD5'   => 0,
                  'Net::SMTP'     => 0,
                  'Sys::Hostname' => 0,
              },
	      'VERSION_FROM' => 'Simple.pm', # finds $VERSION
              'dist' => { 'COMPRESS' => 'gzip --best' },
);
