use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Client::Status::SQL',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Client/Status/SQL.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"Log::Log4perl" => 1.00,
	"perfSONAR_PS::DB::SQL" => 0.09,
	"perfSONAR_PS::Status::Common" => 0.09,
	"perfSONAR_PS::Status::Link" => 0.09,
        "strict" => 0,
    }
);
