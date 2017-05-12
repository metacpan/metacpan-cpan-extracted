use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'ZConf',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/ZConf.pm',
			  ABSTRACT_FROM       => 'lib/ZConf.pm',
			  INST_SCRIPT => 'bin',
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							'Net::LDAP' => 0,
							'Net::LDAP::LDAPhash' => 0,
							'Net::LDAP::Makepath' => 0,
							'File::Path' => 0,
							'File::BaseDir' => 0,
							'Chooser' => 0,
							'ZML' => 0,
							'Sys::Hostname' => 0,
							'Net::LDAP::AutoServer' => 0,
							'Net::LDAP::AutoDNs' => 0,
							'Module::List' => 0,
							'Error::Helper'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'ZConf-*' },
			  );
