use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Combine',
    'VERSION_FROM'	=> 'Combine/Config.pm', # finds $VERSION 
    'PMLIBDIRS'		=> ['Combine'],
    'EXE_FILES'		=> ['bin/combine', 'bin/combineCtrl', 'bin/combineRun', 'bin/combineExport', 'bin/combineUtil', 'bin/combineINIT', 'bin/combineRank', 'bin/combineReClassify', 'bin/combineSVM'],
    'PREREQ_PM'		=> {  DBI => 0, DBD::mysql => 0,
	      Digest::MD5 => 0, Encode => 0,
	      Config::General => 0, Compress::Zlib => 0,
              Getopt::Long => 0, HTML::Entities => 0,
              HTML::TokeParser => 0, HTML::Tidy => 1.06,
              HTTP::Date => 0, HTTP::Request => 0, HTTP::Status => 0,
              Lingua::Stem => 0, Lingua::Identify => 0, LWP::UserAgent => 0,
	      XML::LibXML => 0, XML::Parser => 0, XML::LibXSLT => 0,
	      MIME::Base64 => 0, Net::hostent => 0, ZOOM => 1.20,
	      Image::ExifTool => 0, Algorithm::SVMLight => 0, Geo::IP => 0,
              URI=>0}, #OLD: HTML::Summary => 0, HTML::TreeBuilder => 0,

#    'ABSTRACT'          => 'Combine focused Web crawler',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'bin/combine', # retrieve abstract from main application
       AUTHOR     => 'Anders Ardo <anders.ardo@eit.lth.se>') : ()),
);
