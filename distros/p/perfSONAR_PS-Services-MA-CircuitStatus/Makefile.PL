use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME' => 'perfSONAR_PS::Services::MA::CircuitStatus',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Services/MA/CircuitStatus.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"base" => 0,
	"Fcntl" => 0,
	"Log::Log4perl" => 1.00,
	"Module::Load" => 0.10,
	"Params::Validate" => 0.64,
	"perfSONAR_PS::Client::LS::Remote" => 0.09,
	"perfSONAR_PS::Client::Status::SQL" => 0.09,
	"perfSONAR_PS::Client::Status::MA" => 0.09,
	"perfSONAR_PS::Client::Topology::MA" => 0.09,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::Error_compat" => 0.09,
	"perfSONAR_PS::Messages" => 0.09,
	"perfSONAR_PS::Services::Base" => 0.09,
	"perfSONAR_PS::Services::MA::General" => 0.09,
        "perfSONAR_PS::Time" => 0.09,
        "perfSONAR_PS::Transport" => 0.09,
        "strict" => 0,
        "warnings" => 0,
    },
);
