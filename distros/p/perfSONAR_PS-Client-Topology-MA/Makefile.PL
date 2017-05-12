use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Client::Topology::MA',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Client/Topology/MA.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"Log::Log4perl" => 1.00,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::Transport" => 0.09,
        "strict" => 0,
    }
);
