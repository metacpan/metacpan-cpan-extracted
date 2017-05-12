use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Base',
    'VERSION' => 0.092,
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
        "strict" => 0,
        "base" => 0,
        "fields" => 0,
        "version" => 0,
	"warnings" => 0,
	"Exporter" => 0,
	"Params::Validate" => 0.64,
	"Log::Log4perl" => 1.00,
	"Time::HiRes" => 1.85,
	"IO::File" => 0,
	"XML::LibXML" => 1.58,
	"LWP::UserAgent" => 2.032,
	"Params::Validate" => 0.70,
	"Data::Compare" => 0.09,
	"Data::Dumper" => 2.101,
	"Error" => 0,
	"Carp" => 0,
	"Test::More" => 0,
    }
);
