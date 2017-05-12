use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::DB::XMLDB',
    'VERSION_FROM' => 'lib/perfSONAR_PS/DB/XMLDB.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"English" => 0,
	"fields" => 0,
	"Log::Log4perl" => 1.00,
	"Params::Validate" => 0.64,
	"perfSONAR_PS::Common" => 0.09,
	"Sleepycat::DbXml" => 2.00,
        "strict" => 0,
        "warnings" => 0,
	"XML::LibXML" => 1.58,
    }
);
