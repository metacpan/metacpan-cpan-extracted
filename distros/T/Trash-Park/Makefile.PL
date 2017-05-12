######################################################################
# Makefile.PL for Trash::Park
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Trash::Park',
    'VERSION_FROM' => 'lib/Trash/Park.pm', # finds $VERSION
    'PREREQ_PM'    => {
      Log::Log4perl   => 0,
      Sysadm::Install => 0,
      Test::More      => 0,
      File::Basename  => 0,
      Stat::lsMode    => 0,
      File::Temp      => 0,
      File::Path      => 0,
      File::Copy      => 0,
      File::Find      => 0,
      Pod::Usage      => 0,
      DBI             => 0,
      DBD::CSV        => 0,
      Class::Accessor => 0,
    }, # e.g., Module::Name => 1.1
    'EXE_FILES' => ['eg/trashpark'],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Trash/Park.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
