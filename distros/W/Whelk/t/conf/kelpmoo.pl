{
	modules => [qw(JSON Whelk)],
	modules_init => {
		Routes => {
			base => 'KelpMoo::Controller',
			rebless => 1,
		},

		Whelk => {
			resources => {
				'+KelpMoo::SomeResource' => '/',
			},
			openapi => '/openapi.json',
		},
	}
}

