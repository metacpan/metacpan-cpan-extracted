use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "Sql::Simple",
              VERSION_FROM => 'lib/Sql/Simple.pm',
	      PREREQ_PM => { 
		'Carp' => '0', 
		'Data::Dumper' => '0' 
	      },
              dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
              AUTHOR          => 'Ryan Dietrich <ryan[at]dietrich.net>',
	      ABSTRACT        => 'Generates SQL statements'
             );
