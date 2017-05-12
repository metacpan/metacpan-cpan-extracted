use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Web::App::Lib::EntityRecord",
	VERSION_FROM => "lib/Web/App/Lib/EntityRecord.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	META_MERGE      => {
		resources => {
			license     =>      'http://dev.perl.org/licenses/',
			homepage    =>      'http://perlhug.com',
			bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-App',
			repository  =>      'git://web-app.git.sourceforge.net/gitroot/web-app/web-app',
#			MailingList =>      'makemaker@perl.org',
		},
	},
	PREREQ_PM => {
		'Web::App'      => '1.01',
		'Project::Easy' => '0.17'
	}
);
