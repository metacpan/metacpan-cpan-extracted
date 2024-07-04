{
	resources => {
		'CRUD' => {
			path => '/todos',
			name => 'CRUD for todo entities',
			description => 'These endpoints allow standard CRUD operations on todos',
		},
	},

	openapi => {
		path => '/openapi.yaml',
		formatter => 'YAML',
		info => {
			title => 'Whelk TodoApp example',
			description =>
				'This application contains a single resource which implements a standard CRUD for todo objects',
			contact => {
				email => 'contact@bbrtj.eu',
			},
			version => '1.0.0',
		}
	},
}

