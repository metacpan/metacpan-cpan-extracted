{
	controllers => [qw(API)],

	modules => {
		Template => {
			paths => [app->path->child('views')->stringify],
			conf => {
				OUTLINE_TAG => qr{\V*%%},    # allows the use of indented %% tags
			}
		},

		Logger => {
			outputs => [
				# logger outputs are defined in development.pl and production.pl
			]
		},
	},
}

