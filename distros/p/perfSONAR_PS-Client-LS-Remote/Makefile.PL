use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Client::LS::Remote',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Client/LS/Remote.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"fields" => 0,
	"Log::Log4perl" => 1.00,
	"perfSONAR_PS::Client::Echo" => 0.09,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::Messages" => 0.09,
	"perfSONAR_PS::Transport" => 0.09,
        "strict" => 0,
        "Test::More" => 0,
        "warnings" => 0,
    }
);
