# base config for all tests
{
	'+modules' => [qw(Logger::Simple)],
	modules_init => {
		'Logger::Simple' => {
			log_format => '# LOG: %s - %s - %s',
			stdout => 1,
		},
	},
}

