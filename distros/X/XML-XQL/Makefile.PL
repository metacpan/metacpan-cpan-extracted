use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::XQL',
    'VERSION_FROM' => 'lib/XML/XQL.pm', # finds $VERSION
    'PREREQ_PM' => { 'XML::Parser' => '2.30',
		   # Maybe requiring Date::Manip 5.33 is too strict,
		   # it's what I was using. I know 5.20 doesn't work.
		   # I also know that 5.36 works.
		   'Date::Manip' => '5.33', 
		   'Parse::Yapp' => '0',
		   # LWP::UserAgent is used when parsing XML from URLs
		   # It's part of libwww-perl, and you don't strictly need it
		   # (some test cases may fail)
		   'LWP::UserAgent' => '0',
		   'XML::DOM' => '1.29'},
 EXE_FILES => [ 'bin/xql.pl' ],
);
