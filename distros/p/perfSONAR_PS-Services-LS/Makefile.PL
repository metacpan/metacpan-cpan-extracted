use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Services::LS',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Services/LS/LS.pm',
    'AUTHOR' => 'Jason Zurawski <zurawski@internet2.edu>',
    'PREREQ_PM' => {
        "base" => 0,
        "English" => 0,
        "Error" => 0,
        "Exporter" => 0,
        "fields" => 0,
        "IO::File" => 1.00,
        "Log::Log4perl" => 1.00,
        "Log::Dispatch::Screen" => 1.00,
        "Log::Dispatch::FileRotate" => 1.00,
        "Log::Dispatch::Syslog" => 1.00,
	"Params::Validate" => 0.64,
        "Digest::MD5" => 2.33,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::DB::XMLDB" => 0.09,
	"perfSONAR_PS::Error_compat" => 0.09,
	"perfSONAR_PS::Messages" => 0.09,
	"perfSONAR_PS::Services::Base" => 0.09,
	"perfSONAR_PS::Services::MA::General" => 0.09,
        "XML::LibXML" => 1.58,
        "strict" => 0,
	"Time::HiRes" => 1.85,
        "warnings" => 0
    }
);
