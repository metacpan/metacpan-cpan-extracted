use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::UPS',
    VERSION_FROM      => 'lib/WebService/UPS/TrackRequest.pm', # finds $VERSION
    PREREQ_PM         => {'Mouse' => 0.19,
						  'LWP::UserAgent' => 5.810,
						  'HTTP::Request::Common' => 5.811,
						  'XML::Simple' => 2.18,
						  'Data::Dumper' => 2.121_14,
						 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ( AUTHOR         => 'Kyle Brandt <kyle@kbrandt.com>') : ()),
);
