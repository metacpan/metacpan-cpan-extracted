use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Services::MA::Base',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Services/MA/General.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
        "base" => 0,
        "Exporter" => 0,
	"Log::Log4perl" => 1.00,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::Messages" => 0.09,
        "strict" => 0,
        "warnings" => 0,
    }
);
