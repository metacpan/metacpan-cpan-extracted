use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService-Hatena-AsinCount',
    VERSION_FROM        => 'lib/WebService/Hatena/AsinCount.pm',
    PREREQ_PM           => {
        'Test::More'    => '0',
	'XML::TreePP'	=> '0.03',
	'LWP::UserAgent' => '0',
    },
);
