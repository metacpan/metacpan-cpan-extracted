use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Yandex::Dictionary',
	 ABSTRACT => 'a simple API for Yandex.Dictionary',
	 VERSION_FROM => 'lib/Yandex/Dictionary.pm',
	 PREREQ_PM => {
		 'HTML::Entities' => 0,
		 'HTTP::Tiny' => 0,
		 'JSON' => 0,
		 'URI::Escape' => 0,
		 'strict' => 0,
		 'utf8' => 0,
		 'warnings' => 0,
	 },
	 TEST_REQUIRES => {
		 'Test::More' => 0,
	 },
	 AUTHOR => [
		 'James Axl <axlrose112@gmail.com>',
	 ],
	 LICENSE => 'perl',
	  test => {
		  'TESTS' => 't/*.t',
	  }
  );

