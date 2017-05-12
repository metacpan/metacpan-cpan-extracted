use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::RDB',
    'VERSION_FROM'	=> 'RDB.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
                        'Getopt::Std'  => 0,
                        'Data::Dumper' => 0,
                        'XML::DOM'     => '1.29',
                        'DBIx::DBSchema'  => '.16',
                        'DBIx::Recordset' => '.23',
                        'DBIx::Sequence' => '.04',
                        'URI::Escape' => '3.16',
                        'IO::File' => '1.08',
                        'DBI' => '1.35',
      }, # e.g., Module::Name => 1.1
          'EXE_FILES' => [ 'xml_rdb' ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RDB.pm', # retrieve abstract from module
       AUTHOR     => 'Mark Trostler <trostler@juniper.net>') : ()),
);
