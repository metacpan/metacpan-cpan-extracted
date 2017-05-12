use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'X10',
  VERSION_FROM => 'X10.pm',
  PREREQ_PM =>
    {
      Astro::SunTime => 0.01,
      Device::SerialPort => 0,
      File::Basename => 0,
      FileHandle => 0,
      IO::Select => 0,
      IO::Socket => 0,
      POSIX => 0,
      Storable => 0,
      Time::ParseDate => 0,
    },
  EXE_FILES => [ qw(x10server x10client) ],
  LICENSE => 'gpl_3',
);

