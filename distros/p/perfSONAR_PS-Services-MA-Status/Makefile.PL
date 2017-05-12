use ExtUtils::MakeMaker;

my @exe_files = ( "psCreateStatusDB" );

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Services::MA::Status',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Services/MA/Status.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"base" => 0,
	"DBI" => 0,
	"fields" => 0,
	"Log::Log4perl" => 1.00,
	"Params::Validate" => 0.64,
	"perfSONAR_PS::Client::LS::Remote" => 0.09,
	"perfSONAR_PS::Client::Status::SQL" => 0.09,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::Messages" => 0.09,
	"perfSONAR_PS::Services::Base" => 0.09,
        "perfSONAR_PS::Time" => 0.09,
        "perfSONAR_PS::Topology::ID" => 0.09,
        "strict" => 0,
        "warnings" => 0,
    },

    EXE_FILES => \@exe_files,
);
