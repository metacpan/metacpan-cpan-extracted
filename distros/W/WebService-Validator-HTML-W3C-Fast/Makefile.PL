use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::Validator::HTML::W3C::Fast',
    VERSION_FROM      => 'lib/WebService/Validator/HTML/W3C/Fast.pm', # finds $VERSION
    PREREQ_PM         => {
                              'WebService::Validator::HTML::W3C' => 0,
                              'HTTP::Daemon' => 0,
                              'POSIX' => 0,
			},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/Validator/HTML/W3C/Fast.pm', # retrieve abstract from module
       AUTHOR         => 'David Dick <ddick@cpan.org>') : ()),
    ($ExtUtils::MakeMaker::VERSION ge '6.30_00' ? # shamelessly copied this from Template Toolkit
      (LICENSE           => 'perl') : ()),
);
