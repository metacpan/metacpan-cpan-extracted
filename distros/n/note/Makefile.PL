use ExtUtils::MakeMaker;

my %optional = (
                'Crypt::CBC'      => "Required by encryption support",
                'Crypt::Rijndael' => "Required by encryption support",
                'Data::Dumper'    => "Required by dumper DB backend",
                'MIME::Base64'    => "Required by varios optional backends",
                'Storable'        => "Required by text DB backend",
                'Config::General' => "Required by general DB backend",
                'DB_File'         => "Required by dbm DB backend",
                'DBI'             => "Required by mysql DB backend",
                'DBD::mysql'      => "Required by mysql DB backend",
                'Crypt::PWSafe3'  => "Required by Password Safe v3 backend"
               );

foreach my $module (sort keys %optional) {
  eval "require $module";
  if ($@) {
    warn("Optional module $module not installed, $optional{$module}\n");
  }
}


WriteMakefile(
              'NAME'         => 'note',
              'VERSION_FROM' => 'bin/note', # finds $VERSION
              'EXE_FILES'    => [ 'bin/note' ],
              'PREREQ_PM'    => {
                                 'IO::File'     => 0,
                                 'FileHandle'   => 0,
                                 'File::Spec'   => 0,
                                 'File::Glob'   => 0,
                                 'FileHandle'   => 0,
                                 'Getopt::Long' => 0,
                                 'Fcntl'        => 0,
                                 'IO::Seekable' => 0,
                                 'YAML'         => 0,
                                },
              ($ExtUtils::MakeMaker::VERSION ge '6.31'? ('LICENSE'              => 'perl', ) : ()),
              'clean'        => { FILES => 't/*.out t/test.cfg *~ */*~' }
             );
