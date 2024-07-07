{
	modules => [qw(JSON Whelk)],
	modules_init => {
		Routes => {
			base => 'CustomController',
			rebless => 1,
		},

		Whelk => {
			resources => {
				'Test' => '/',
			},
			openapi => '/openapi.json',
		},
	}
}

