use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::DB::RRD',
    'VERSION_FROM' => 'lib/perfSONAR_PS/DB/RRD.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"Data::Compare" => 0,
        "fields" => 0,
	"Log::Log4perl" => 1.00,
	"Params::Validate" => 0.64,
	"perfSONAR_PS::Common" => 0.09,
	"RRDp" => 1.20,
        "strict" => 0,
	"Test::More" => 0,
        "warnings" => 0,
    }
);
