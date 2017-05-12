use ExtUtils::MakeMaker;

my @exe_files = ( "genLinkStatus.pl" );

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Collectors::LinkStatus',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Collectors/LinkStatus.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"base" => 0,
	"Exporter" => 0,
	"fields" => 0,
	"Log::Log4perl" => 1.00,
	"Module::Load" => 0.10,
	"Net::SNMP" => "5.0.0",
	"perfSONAR_PS::Client::Status::MA" => 0.09,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::DB::File" => 0.09,
	"perfSONAR_PS::Collectors::Base" => 0.09,
	"perfSONAR_PS::Status::Common" => 0.09,
        "strict" => 0,
	"Time::HiRes" => 1.85,
        "warnings" => 0,
    },

    EXE_FILES => \@exe_files,
);
