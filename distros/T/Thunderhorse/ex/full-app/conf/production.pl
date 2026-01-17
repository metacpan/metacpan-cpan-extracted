{
	app_url => 'https://somewhere.com',

	modules => {
		Logger => {
			outputs => [
				file => {
					maxlevel => 'warning',
					filename => app->path->child('logs.log')->stringify,
					mode => 'append',
					'utf-8' => true,
				},
			]
		},
	},
}

