use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'		=> 'ddb',
  'VERSION_FROM'	=> 'ddb.pm',
  'PREREQ_PM'		=> {
    Digest::MD5		=> 0,
    File::Sync		=> 0,
    POSIX		=> 0,
    Fcntl		=> 0,
  },
  ($] >= 5.005 ? (AUTHOR => 'Dan Brumleve <dan_brumleve@yahoo.com>') : ()),
);
