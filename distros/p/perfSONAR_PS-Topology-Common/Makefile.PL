use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Topology::Common',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Topology/Common.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"base" => 0,
	"Exporter" => 0,
	"Log::Log4perl" => 1.00,
	"perfSONAR_PS::Common" => 0.09,
	"strict" => 0,
	"Test::More" => 0,
        "warnings" => 0,
    }
);
