use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::MODIS',
    VERSION_FROM      => 'lib/WebService/MODIS.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
      'Carp'           => 0,
      'LWP::Online'    => 0,
      'LWP::UserAgent' => 0,
      'File::HomeDir'  => 0,
      'File::Path'     => 0,
      'File::Basename' => 0,
      'Date::Simple'   => 0,
      'List::Util'     => 1.33
}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/WebService/MODIS.pm', # retrieve abstract from module
    AUTHOR            => 'Joerg Steinkamp <joergsteinkamp@yahoo.de>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
