return {
	controllers => [
		'^LoadingTestController',
	],
	modules => {
		'^LoadingTestModule' => {
			test_option => app->sth,
		},
	},
};

