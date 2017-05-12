use ExtUtils::MakeMaker;
WriteMakefile( NAME => "Tie::TransactHash",
	       VERSION_FROM => "lib/Tie/TransactHash.pm",
	       EXE_FILES => ["bin/edit-db.pl"],
	       PREREQ_PM => { "Tie::IxHash" => 1.2}, #there was no version
	       dist => {COMPRESS => "gzip",
			SUFFIX => "gz" }
	     );
