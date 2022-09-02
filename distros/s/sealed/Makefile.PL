use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "sealed",
	VERSION_FROM => "lib/sealed.pm",
	PREREQ_PM => {
	  'B::Generate' => 0,
	  'APR::Request' => 0,
	},
	test => { TESTS => "bench.pl" },
);
