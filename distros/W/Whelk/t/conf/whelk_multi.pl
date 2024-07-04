{
	wrapper => 'WithStatus',
	resources => {
		'Test' => '/test',
		'Test::Deep' => {
			path => '/deep',
			formatter => 'YAML',
		},
	},
}

