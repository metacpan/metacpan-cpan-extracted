use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Web::App",
	VERSION_FROM => "lib/Web/App.pm",
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
		'Class::Easy'     => '0.09',
		'Project::Easy'   => '0.18',
		'Data::Dump::XML' => 1,
		'XML::LibXSLT'    => '1.60',
		'CGI::Minimal'    => '1.29',
	}
);
